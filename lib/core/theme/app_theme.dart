import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'daftar_theme_extension.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.danger,
        onPrimary: AppColors.text,
        onSecondary: AppColors.white,
        onSurface: AppColors.text,
      ),
      textTheme: TextTheme(
        titleLarge: AppTypography.h1.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: AppTypography.h2.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        // centerTitle: false,
        titleTextStyle: AppTypography.h1.copyWith(
          color: AppColors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.white, size: 24),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(
            color: AppColors.greyLight.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.white,
          elevation: 4,
          shadowColor: AppColors.secondary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          textStyle: AppTypography.label.copyWith(
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: AppColors.greyLight.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: AppColors.greyLight.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        floatingLabelStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      extensions: [
        DaftarThemeExtension(
          surfaceColor: AppColors.surface,
          cardDecoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.greyLight.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.02),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          daftarBoxDecoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.surfaceGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
