import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API base URL (Vite-style: `assets/env/defaults.env` + `--dart-define`).
///
/// Precedence: `--dart-define=API_BASE_URL=...` → `.env` → fallback.
class ApiConfig {
  ApiConfig._();

  static const String _fallback = 'http://localhost:8000';

  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return _fallback;
  }

  static Uri buildUri(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized');
  }
}
