import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF004532);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF065F46);
  static const onPrimaryContainer = Color(0xFF8BD6B7);
  static const secondary = Color(0xFF944A23);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFD9E70);
  static const onSecondaryContainer = Color(0xFF76340E);
  static const background = Color(0xFFF8F9FB);
  static const onBackground = Color(0xFF191C1E);
  static const surface = Color(0xFFF8F9FB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F6);
  static const surfaceContainer = Color(0xFFEDEEF0);
  static const surfaceContainerHigh = Color(0xFFE7E8EA);
  static const surfaceDim = Color(0xFFD9DADC);
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF3F4944);
  static const outlineVariant = Color(0xFFBEC9C2);
  static const outline = Color(0xFF6F7973);
  static const surfaceTint = Color(0xFF1B6B51);
  static const tertiaryContainer = Color(0xFF804300);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          outline: AppColors.outline,
          error: AppColors.error,
          onError: AppColors.onError,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
      );
}
