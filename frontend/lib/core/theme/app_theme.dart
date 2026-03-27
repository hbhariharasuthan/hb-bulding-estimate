import 'package:flutter/material.dart';

import '../constants/brand_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.primaryBlue,
          primary: BrandColors.primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEEF1F8),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 1.1),
          border: _defaultInputBorder,
          enabledBorder: _defaultInputBorder,
          focusedBorder: _defaultInputBorder,
          errorBorder: _defaultInputBorder,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Color(0x334A5367),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: BrandColors.primaryBlue,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      );
}

const _defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
