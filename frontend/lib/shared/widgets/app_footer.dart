import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/brand_colors.dart';

/// Thin footer bar: logo + copyright (matches partner site style).
class AppFooter extends StatelessWidget {
  const AppFooter({
    super.key,
    this.logoHeight = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  final double logoHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year.toString();

    return Material(
      color: Colors.white,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: BrandColors.footerBorder, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, -1),
              blurRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Image.asset(
                  AppAssets.hbLogo,
                  height: logoHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.business,
                    size: logoHeight * 0.75,
                    color: BrandColors.primaryCyan,
                  ),
                ),
                Text(
                  '© $year ${AppConfig.siteDomain}. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BrandColors.footerText,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
