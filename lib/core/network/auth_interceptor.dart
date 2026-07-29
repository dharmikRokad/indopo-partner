import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'token_manager.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  // Helper to fetch stored tokens
  Future<String?> getAccessToken() async => TokenManager.instance.token;
  Future<String?> getRefreshToken() async => TokenManager.instance.refreshToken;

  // Helper to save new tokens
  Future<void> saveTokens(String access, String refresh) async {
    await TokenManager.instance.saveToken(
      token: access,
      email: TokenManager.instance.email ?? '',
      rememberMe: true,
    );
    await TokenManager.instance.saveRefreshToken(refresh);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!options.headers.containsKey('Authorization')) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Avoid infinite loops if refresh-token endpoint itself fails with 401
    if (err.requestOptions.path.contains(ApiEndpoints.refreshToken)) {
      await TokenManager.instance.clearToken();
      TokenManager.instance.notifySessionExpired();
      return handler.next(err);
    }

    // Check if error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      final refreshToken = await getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Use a clean Dio instance for refreshing to avoid recursive interceptor calls
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          // Call Refresh Token API
          final refreshResponse = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final resData = refreshResponse.data['data'] as Map<String, dynamic>;
            final newAccessToken = resData['accessToken'] as String;
            final newRefreshToken = resData['refreshToken'] as String;

            // Save the new tokens
            await saveTokens(newAccessToken, newRefreshToken);

            // Retry the original request with the new access token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final response = await dio.fetch(options);
            return handler.resolve(response);
          }
        } catch (e) {
          // Refresh failed (e.g., refresh token expired or revoked)
          // Handle Logout / Redirect to Login
          print('Refresh token expired, logging out...: $e');
          await TokenManager.instance.clearToken();
          TokenManager.instance.notifySessionExpired();
        }
      } else {
        await TokenManager.instance.clearToken();
        TokenManager.instance.notifySessionExpired();
      }
    }
    return handler.next(err);
  }
}
