import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

/// OTP-based authentication service for Flutter mobile
/// Handles: requestOtp, verifyOtp, resendOtp, token refresh
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  // Token storage keys
  static const String _accessTokenKey = 'ndjigi_access_token';
  static const String _refreshTokenKey = 'ndjigi_refresh_token';
  static const String _userKey = 'ndjigi_user';

  AuthService({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  /// Request OTP code via phone number
  /// POST /auth/otp/request
  /// Body: { phone }
  /// Returns: { phone_masked }
  Future<String?> requestOtp(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/otp/request',
        data: {'phone': phone},
      );

      if (response.statusCode == 200) {
        // Return masked phone for display
        return response.data['data']['phone_masked'];
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Verify OTP code and authenticate user
  /// POST /auth/otp/verify
  /// Body: { phone, otp_code }
  /// Returns: { access_token, refresh_token, user }
  Future<Map<String, dynamic>> verifyOtp(String phone, String otpCode) async {
    try {
      final response = await _dio.post(
        '/auth/otp/verify',
        data: {
          'phone': phone,
          'otp_code': otpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Store tokens securely
        await _secureStorage.write(
          key: _accessTokenKey,
          value: data['access_token'],
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: data['refresh_token'],
        );
        await _secureStorage.write(
          key: _userKey,
          value: data['user'].toString(), // Serialize user object
        );

        return data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Resend OTP code (60-second cooldown)
  /// POST /auth/otp/resend
  /// Body: { phone }
  Future<void> resendOtp(String phone) async {
    try {
      final response = await _dio.post(
        '/auth/otp/resend',
        data: {'phone': phone},
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Setup TOTP 2FA after OTP verification
  /// POST /auth/totp/setup
  /// Body: { login_token, totp_code }
  /// Returns: { access_token, refresh_token, user }
  Future<Map<String, dynamic>> totpSetup(String loginToken, String totpCode) async {
    try {
      final response = await _dio.post(
        '/auth/totp/setup',
        data: {
          'login_token': loginToken,
          'totp_code': totpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Store tokens securely
        await _secureStorage.write(
          key: _accessTokenKey,
          value: data['access_token'],
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: data['refresh_token'],
        );
        await _secureStorage.write(
          key: _userKey,
          value: data['user'].toString(),
        );

        return data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Verify TOTP 2FA code for existing setup
  /// POST /auth/totp/verify
  /// Body: { login_token, totp_code }
  /// Returns: { access_token, refresh_token, user }
  Future<Map<String, dynamic>> totpVerify(String loginToken, String totpCode) async {
    try {
      final response = await _dio.post(
        '/auth/totp/verify',
        data: {
          'login_token': loginToken,
          'totp_code': totpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Store tokens securely
        await _secureStorage.write(
          key: _accessTokenKey,
          value: data['access_token'],
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: data['refresh_token'],
        );
        await _secureStorage.write(
          key: _userKey,
          value: data['user'].toString(),
        );

        return data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Refresh access token
  /// POST /auth/refresh
  /// Body: { refresh_token }
  /// Returns: { access_token, refresh_token, expires_in }
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];

        // Update stored token
        await _secureStorage.write(
          key: _accessTokenKey,
          value: data['access_token'],
        );

        // Update refresh token if new one provided
        if (data['refresh_token'] != null) {
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: data['refresh_token'],
          );
        }

        return data;
      }

      return null;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  /// Logout user
  /// POST /auth/logout
  /// Body: { refresh_token, access_token }
  Future<void> logout() async {
    try {
      final refreshToken = await getRefreshToken();
      final accessToken = await getAccessToken();

      if (refreshToken != null && accessToken != null) {
        await _dio.post(
          '/auth/logout',
          data: {
            'refresh_token': refreshToken,
            'access_token': accessToken,
          },
        );
      }

      // Clear stored tokens
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userKey);
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Handle Dio errors
  void _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final message = error.response?.data['message'] ?? 'Unknown error';

      if (statusCode == 429) {
        // Rate limited
        final code = error.response?.data['code'];
        if (code == 'OTP_BLOCKED') {
          throw Exception('Trop de tentatives. Réessayez dans 15 minutes.');
        } else if (code == 'RESEND_COOLDOWN') {
          throw Exception('Attendez avant de renvoyer le code.');
        }
      } else if (statusCode == 400) {
        throw Exception(message);
      } else if (statusCode == 401) {
        throw Exception('Authentification échouée.');
      }
    }

    throw Exception('Erreur réseau: ${error.message}');
  }
}
