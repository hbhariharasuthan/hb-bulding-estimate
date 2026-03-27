/// Central API paths relative to [ApiConfig.baseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  /// Custom Laravel-style login (JSON).
  static const String loginCustom = '/api/v1/auth/login';

  /// fastapi-users OAuth2 password flow (form body).
  static const String loginJwt = '/auth/jwt/login';

  static const String plans = '/api/v1/plans';
  static const String plansUpload = '/api/v1/plans/upload';
}
