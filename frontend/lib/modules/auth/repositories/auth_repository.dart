import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../models/login_result.dart';

/// Auth API via Dio (injectable).
class AuthRepository {
  AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// `POST /api/v1/auth/login` — custom JSON envelope.
  Future<LoginResult> loginWithCustomApi({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.loginCustom,
        data: {'email': email, 'password': password},
      );

      final json = response.data;
      if (json == null) {
        return const LoginResult(
          success: false,
          message: 'Empty response',
        );
      }

      final success = json['success'] == true;
      final message = json['message']?.toString();

      if (!success) {
        return LoginResult(
          success: false,
          message: message ?? 'Login failed',
          errors: json['errors'] is Map<String, dynamic>
              ? json['errors'] as Map<String, dynamic>
              : null,
        );
      }

      final data = json['data'];
      final token = data is Map<String, dynamic>
          ? data['access_token']?.toString()
          : null;

      return LoginResult(
        success: true,
        accessToken: token,
        message: message,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : e.message;
      return LoginResult(
        success: false,
        message: msg ?? 'Network error (${e.response?.statusCode ?? '—'})',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// `POST /auth/jwt/login` — OAuth2 password form (optional).
  Future<String?> loginWithJwtForm({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.loginJwt,
        data: {
          'username': username,
          'password': password,
          'grant_type': '',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      return response.data?['access_token']?.toString();
    } on DioException {
      return null;
    }
  }
}
