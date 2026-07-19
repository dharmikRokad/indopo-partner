import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static final TokenManager instance = TokenManager._internal();

  TokenManager._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'partner_access_token';
  static const String _refreshTokenKey = 'partner_refresh_token';
  static const String _partnerEmailKey = 'partner_email';

  String? _inMemoryAccessToken;
  String? _inMemoryRefreshToken;
  String? _inMemoryEmail;

  final _sessionExpiryController = StreamController<void>.broadcast();
  Stream<void> get sessionExpiryStream => _sessionExpiryController.stream;

  String? get token => _inMemoryAccessToken;
  String? get refreshToken => _inMemoryRefreshToken;
  String? get email => _inMemoryEmail;

  void notifySessionExpired() {
    _sessionExpiryController.add(null);
  }

  /// Initializes TokenManager by loading stored credentials
  Future<void> init() async {
    try {
      _inMemoryAccessToken = await _secureStorage.read(key: _accessTokenKey);
      _inMemoryRefreshToken = await _secureStorage.read(key: _refreshTokenKey);
      _inMemoryEmail = await _secureStorage.read(key: _partnerEmailKey);
    } catch (e) {
      print('Error initializing TokenManager: $e');
    }
  }

  /// Saves the access token and email configuration
  Future<void> saveToken({
    required String token,
    required String email,
    required bool rememberMe,
  }) async {
    _inMemoryAccessToken = token;
    _inMemoryEmail = email;

    try {
      await _secureStorage.write(key: _accessTokenKey, value: token);
      await _secureStorage.write(key: _partnerEmailKey, value: email);
    } catch (e) {
      print('Error saving credentials to SecureStorage: $e');
    }
  }

  /// Saves the refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    _inMemoryRefreshToken = refreshToken;
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      print('Error saving refresh token to SecureStorage: $e');
    }
  }

  /// Clears token both in memory and in secure storage (logout)
  Future<void> clearToken() async {
    _inMemoryAccessToken = null;
    _inMemoryRefreshToken = null;
    _inMemoryEmail = null;
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _partnerEmailKey);
    } catch (e) {
      print('Error clearing credentials from SecureStorage: $e');
    }
  }

  void dispose() {
    _sessionExpiryController.close();
  }
}
