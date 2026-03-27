import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/di/locator.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'modules/masters/views/material_page.dart';
import 'modules/masters/views/material_standards_page.dart';
import 'modules/masters/views/property_page.dart';
import 'modules/masters/views/units_page.dart';
import 'modules/settings/providers/site_settings_provider.dart';
import 'modules/settings/views/site_settings_page.dart';
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
  final siteSettingsProvider = SiteSettingsProvider(repository: getIt());
  await siteSettingsProvider.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SiteSettingsProvider>.value(
          value: siteSettingsProvider,
        ),
      ],
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
        AppRoutes.material: (_) => const MaterialMasterPage(),
        AppRoutes.property: (_) => const PropertyPage(),
        AppRoutes.units: (_) => const UnitsPage(),
        AppRoutes.materialStandards: (_) => const MaterialStandardsPage(),
        AppRoutes.siteSettings: (_) => const SiteSettingsPage(),
      },
    );
  }
}
