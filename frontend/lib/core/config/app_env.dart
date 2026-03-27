import 'package:flutter/foundation.dart';

/// Vite-like flags: `import.meta.env.DEV` / production.
class AppEnv {
  AppEnv._();

  static bool get isDev => kDebugMode;
  static bool get isProd => kReleaseMode;
}
