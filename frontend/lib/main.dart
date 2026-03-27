import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/di/locator.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'routes/app_routes.dart';
import 'shared/widgets/auth_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/env/defaults.env');
  await setupLocator();

  final authProvider = AuthProvider(
    repository: getIt(),
    storage: getIt(),
    tokenRef: getIt(),
  );
  await authProvider.bootstrap();

  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const AuthShell(),
        AppRoutes.dashboard: (_) => const AuthShell(),
      },
    );
  }
}
