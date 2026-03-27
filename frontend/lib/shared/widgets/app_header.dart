import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/brand_colors.dart';
import '../../modules/auth/providers/auth_provider.dart';
import '../../modules/settings/providers/site_settings_provider.dart';
import 'header_menu.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.showMenu = true,
    this.showLogout = true,
  });

  final bool showMenu;
  final bool showLogout;

  ImageProvider<Object>? _logoFor(String? path) {
    final p = path?.trim();
    if (p == null || p.isEmpty) return null;
    final isAbsolute = p.startsWith('http://') || p.startsWith('https://');
    return NetworkImage(isAbsolute ? p : ApiConfig.buildUri(p).toString());
  }

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteSettingsProvider>();
    final logo = _logoFor(site.settings?.siteLogo);

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          logo == null
              ? Image.asset(
                  AppAssets.hbLogo,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.business,
                    color: BrandColors.primaryCyan,
                    size: 28,
                  ),
                )
              : Image(
                  image: logo,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    AppAssets.hbLogo,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
          const SizedBox(width: 12),
          Text(
            site.siteName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BrandColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
      actions: [
        if (showMenu) const HeaderMenu(),
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
