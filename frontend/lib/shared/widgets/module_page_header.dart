import 'package:flutter/material.dart';

import '../../core/constants/brand_colors.dart';
import 'app_breadcrumbs.dart';

class ModulePageHeader extends StatelessWidget {
  const ModulePageHeader({
    super.key,
    required this.title,
    required this.breadcrumbs,
  });

  final String title;
  final List<String> breadcrumbs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x15004B93)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryBlue,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppBreadcrumbs(items: breadcrumbs),
          ),
        ],
      ),
    );
  }
}

