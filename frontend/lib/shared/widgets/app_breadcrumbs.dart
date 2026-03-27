import 'package:flutter/material.dart';

import '../../core/constants/brand_colors.dart';

class AppBreadcrumbs extends StatelessWidget {
  const AppBreadcrumbs({
    super.key,
    required this.items,
    this.showBack = true,
  });

  final List<String> items;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final lastIndex = items.length - 1;
    final canPop = Navigator.canPop(context);

    final children = <Widget>[];

    if (showBack && canPop) {
      children.add(
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, size: 14),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            foregroundColor: BrandColors.primaryBlue,
            side: const BorderSide(color: Color(0x33004B93)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    for (var i = 0; i < items.length; i++) {
      final isLast = i == lastIndex;
      final text = items[i];
      children.add(
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                color: isLast ? BrandColors.primaryBlue : Colors.black54,
                letterSpacing: 0.2,
              ),
        ),
      );
      if (!isLast) {
        children.add(
          const Text(
            '/',
            style: TextStyle(color: Colors.black38),
          ),
        );
      }
    }

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: children,
    );
  }
}

