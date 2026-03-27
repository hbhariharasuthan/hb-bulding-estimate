import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';

class HeaderMenu extends StatelessWidget {
  const HeaderMenu({super.key});

  void _go(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<String>(
          tooltip: 'Master',
          onSelected: (value) => _go(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: AppRoutes.material, child: Text('Material')),
            PopupMenuItem(value: AppRoutes.property, child: Text('Property')),
            PopupMenuItem(value: AppRoutes.units, child: Text('Units')),
            PopupMenuItem(
              value: AppRoutes.materialStandards,
              child: Text('MATERIAL STANDARDS'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('MASTER'),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Plans',
          onSelected: (value) => _go(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: AppRoutes.planPreprocess,
              child: Text('Upload & Preprocess'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('PLANS'),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Settings',
          onSelected: (value) => _go(context, value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: AppRoutes.siteSettings, child: Text('Site Settings')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('SETTINGS'),
          ),
        ),
      ],
    );
  }
}
