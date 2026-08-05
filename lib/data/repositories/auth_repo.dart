import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/token_manager.dart';
import '../../core/network_copy/local_storage.dart';
import '../../core/services/push_notification_service.dart';
import '../models/partner_model.dart';
import '../models/partner_type.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final LocalStorage _localStorage;

  AuthRepository(this._apiClient, this._localStorage);

  Future<PartnerModel?> checkActiveSession() async {
    await TokenManager.instance.init();
    final token = TokenManager.instance.token;
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final partner = PartnerModel.fromApiJson(resData);
        if (!partner.isActive) {
          await logout();
        }
        return partner;
      }
    } catch (e, s) {
      print('[AuthRepository] checkActiveSession error: $e');
      print('[AuthRepository] checkActiveSession error: $s');
      await logout();
    }
    return null;
  }

  Future<PartnerModel> login({
    required String email,
    required String password,
    required PartnerType selectedRole,
  }) async {
    // Save selected role first
    await _localStorage.saveSelectedRole(selectedRole.key);

    final fcmToken = PushNotificationService.instance.fcmToken;

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'] as Map<String, dynamic>;
        final accessToken = resData['accessToken'] as String;
        final refreshToken = resData['refreshToken'] as String;
        final partnerJson = resData['partner'] as Map<String, dynamic>;

        final partner = PartnerModel.fromApiJson(partnerJson);

        if (!partner.isActive) {
          throw Exception('Account is suspended, contact support');
        }

        // Role validation check
        if (partner.role != selectedRole) {
          throw Exception('Credentials do not match the selected role');
        }

        // Save tokens
        await TokenManager.instance.saveToken(
          token: accessToken,
          email: email,
          rememberMe: true,
        );
        await TokenManager.instance.saveRefreshToken(refreshToken);

        return partner;
      } else {
        throw Exception(response.data?['message'] ?? 'Login failed');
      }
    } catch (e, s) {
      print('[AuthRepository] login error: $e');
      print('[AuthRepository] login error: $s');
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenManager.instance.clearToken();
    await _localStorage.clearSelectedRole();
  }

  Future<void> changePassword(String newPassword) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {'newPassword': newPassword},
      );
      if (response.statusCode != 200) {
        throw Exception(
          response.data?['message'] ?? 'Failed to change password',
        );
      }
    } catch (e) {
      print('[AuthRepository] changePassword error: $e');
      rethrow;
    }
  }

  Future<void> deactivateAccount() async {
    try {
      final response = await _apiClient.delete(ApiEndpoints.deactivate);
      if (response.statusCode != 200) {
        throw Exception(
          response.data?['message'] ?? 'Failed to deactivate account',
        );
      }
      await logout();
    } catch (e) {
      print('[AuthRepository] deactivateAccount error: $e');
      rethrow;
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.availability,
        data: {'isAvailable': isAvailable},
      );
      if (response.statusCode != 200) {
        throw Exception(
          response.data?['message'] ?? 'Failed to update availability',
        );
      }
    } catch (e) {
      print('[AuthRepository] updateAvailability error: $e');
      rethrow;
    }
  }

  /// Request password reset link to be sent to user's email.
  Future<String> requestForgotPassword({required String email}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {
          'email': email.trim(),
          'redirectTo': 'indopo-partner://reset-password',
        },
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final message =
            responseData['message']?.toString() ??
            'Password reset email sent successfully.';
        return message;
      }
      return 'Password reset email sent successfully.';
    } catch (e) {
      print('[AuthRepository] requestForgotPassword error: $e');
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      throw Exception(cleanMsg);
    }
  }

  /// Reset password using the recovery access token from deep link.
  Future<String> resetPassword({
    required String accessToken,
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'newPassword': newPassword,
          'email': email,
          'accessToken': accessToken,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final message =
            responseData['message']?.toString() ??
            'Password has been reset successfully.';
        return message;
      }
      return 'Password has been reset successfully.';
    } catch (e) {
      print('[AuthRepository] resetPassword error: $e');
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      throw Exception(cleanMsg);
    }
  }

  /// Submit a request to become a partner.
  Future<String> submitBecomePartnerRequest({
    required String name,
    required String email,
    required String phone,
    required String orgName,
    required String orgAddress,
    required PartnerType partnerType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.becomePartner,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'orgName': orgName.trim(),
          'orgAddress': orgAddress.trim(),
          'partnerType': partnerType.apiValue,
        },
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final message =
            responseData['message']?.toString() ??
            'Your request to become a partner has been submitted successfully.';
        return message;
      }
      return 'Your request to become a partner has been submitted successfully.';
    } catch (e) {
      print('[AuthRepository] submitBecomePartnerRequest error: $e');
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      throw Exception(cleanMsg);
    }
  }
}
