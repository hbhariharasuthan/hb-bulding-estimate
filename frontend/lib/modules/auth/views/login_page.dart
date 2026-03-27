import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/brand_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_footer.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_logo.dart';
import '../providers/auth_provider.dart';
import '../../settings/providers/site_settings_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    setState(() {
      _emailError = Validators.email(_emailCtrl.text);
      _passwordError = Validators.password(_passwordCtrl.text);
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final result = await auth.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;

      if (result.success && result.hasToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Login failed'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteSettingsProvider>();
    final bgPath = site.settings?.loginBackground?.trim();
    final bgUrl = (bgPath != null && bgPath.isNotEmpty)
        ? ApiConfig.buildUri(bgPath).toString()
        : null;

    return Scaffold(
      appBar: const AppHeader(showMenu: false, showLogout: false),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (bgUrl != null)
            Image.network(
              bgUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(
                    'theme_ref/hbbe-theme/assets/Backgrounds/Spline.png',
                    fit: BoxFit.cover,
                  ),
            ),
          if (bgUrl == null)
            Image.asset(
              'theme_ref/hbbe-theme/assets/Backgrounds/Spline.png',
              fit: BoxFit.cover,
            ),
          Container(
            color: Colors.white.withValues(alpha: 0.88),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.loginMaxWidth,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.screenPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppLogo(
                              height: 88,
                              imagePath: site.settings?.siteLogo,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              site.siteName.isNotEmpty
                                  ? site.siteName
                                  : AppConfig.appName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: BrandColors.primaryBlue),
                            ),
                            const SizedBox(height: 32),
                            AppInput(
                              label: 'Email',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              errorText: _emailError,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Password',
                              controller: _passwordCtrl,
                              obscureText: true,
                              autocorrect: false,
                              errorText: _passwordError,
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Sign in',
                              loading: _loading,
                              onPressed: _onSignIn,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const AppFooter(),
            ],
          ),
        ],
      ),
    );
  }
}
