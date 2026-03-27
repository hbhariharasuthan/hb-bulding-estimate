import 'package:flutter/material.dart';

import '../constants/brand_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.primaryBlue,
          primary: BrandColors.primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: BrandColors.pageBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: BrandColors.primaryBlue,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      );
}
