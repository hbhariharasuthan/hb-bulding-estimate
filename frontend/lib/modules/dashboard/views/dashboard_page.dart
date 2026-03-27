import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/brand_colors.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Dashboard',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: BrandColors.primaryBlue),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You are signed in.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        'Token: ${auth.token != null && auth.token!.length > 24 ? '${auth.token!.substring(0, 24)}…' : '—'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<AuthProvider>().logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
