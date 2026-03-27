import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/brand_colors.dart';
import '../../core/config/app_config.dart';

/// HB partner logo + optional tagline (uses [AppAssets.hbLogo]).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 72,
    this.showTagline = true,
    this.taglineStyle,
  });

  final double height;
  final bool showTagline;
  final TextStyle? taglineStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.hbLogo,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.business,
            size: height * 0.6,
            color: BrandColors.primaryBlue,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            AppConfig.companyTagline,
            textAlign: TextAlign.center,
            style: taglineStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: BrandColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ],
    );
  }
}
