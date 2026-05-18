import 'package:dio/dio.dart';
import 'auth_service.dart';

/// Dio HTTP interceptor for automatic token refresh
/// Handles:
///   - Adding Authorization header to requests
///   - Automatic token refresh on 401 responses
///   - Redirecting to login on refresh failure
class AuthInterceptor extends QueuedInterceptor {
  final AuthService authService;
  final Function(String) onUnauthorized; // Callback to redirect to login

  AuthInterceptor({
    required this.authService,
    required this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add Authorization header with access token
    final token = await authService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        // Try to refresh token
        final refreshed = await authService.refreshToken();

        if (refreshed != null) {
          // Retry original request with new token
          final options = err.requestOptions;
          final token = await authService.getAccessToken();
          options.headers['Authorization'] = 'Bearer $token';

          final dio = Dio();
          final response = await dio.request(
            options.path,
            options: options,
          );

          return handler.resolve(response);
        } else {
          // Refresh failed, redirect to login
          onUnauthorized('Session expired');
          return handler.next(err);
        }
      } catch (e) {
        // Token refresh error, redirect to login
        onUnauthorized('Authentication failed');
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
