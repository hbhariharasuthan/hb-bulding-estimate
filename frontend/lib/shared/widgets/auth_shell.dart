import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../modules/auth/providers/auth_provider.dart';
import '../../modules/auth/views/login_page.dart';
import '../../modules/dashboard/views/dashboard_page.dart';

/// Shows a splash until auth is bootstrapped, then login or dashboard.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.ready) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const DashboardPage();
    }

    return const LoginPage();
  }
}
