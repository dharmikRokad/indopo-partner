import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../error/exceptions.dart';
import 'api_endpoints.dart';
import 'token_manager.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add interceptor to attach JWT token and handle token refreshing on 401
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenManager.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = TokenManager.instance.refreshToken;
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio();
                refreshDio.options.baseUrl = ApiEndpoints.baseUrl;
                final response = await refreshDio.post(
                  ApiEndpoints.refreshToken,
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 && response.data != null) {
                  final resData = response.data['data'] as Map<String, dynamic>;
                  final newAccessToken = resData['accessToken'] as String;
                  final newRefreshToken = resData['refreshToken'] as String;

                  await TokenManager.instance.saveToken(
                    token: newAccessToken,
                    email: TokenManager.instance.email ?? '',
                    rememberMe: true,
                  );
                  await TokenManager.instance.saveRefreshToken(newRefreshToken);

                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';

                  final retryResponse = await _dio.fetch(options);
                  return handler.resolve(retryResponse);
                }
              } catch (e) {
                print('Silent token refresh failed: $e');
                await TokenManager.instance.clearToken();
                TokenManager.instance.notifySessionExpired();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // Add Pretty Dio Logger for API requests/responses debugging
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  /// GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException('Connection timeout. Please check your internet connection.');
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final responseData = error.response!.data;
      String message = 'Something went wrong';

      if (responseData is Map<String, dynamic>) {
        message = responseData['message'] ?? responseData['error'] ?? message;
      } else if (responseData is String && responseData.isNotEmpty) {
        message = responseData;
      }

      if (statusCode == 401 || statusCode == 403) {
        return AuthException(message);
      }

      return ServerException(message);
    }

    return const ServerException('An unexpected error occurred. Please try again.');
  }
}
