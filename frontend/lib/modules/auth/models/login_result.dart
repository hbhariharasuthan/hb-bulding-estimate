/// Result of a login attempt against the custom API envelope.
class LoginResult {
  const LoginResult({
    required this.success,
    this.accessToken,
    this.message,
    this.errors,
  });

  final bool success;
  final String? accessToken;
  final String? message;
  final Map<String, dynamic>? errors;

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;
}
