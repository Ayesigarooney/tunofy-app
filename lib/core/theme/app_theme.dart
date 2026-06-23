// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary dark palette
  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF16161F);
  static const Color surfaceVariant = Color(0xFF22222F);
  static const Color surfaceElevated = Color(0xFF2A2A3A);

  // Accent palette
  static const Color accentOrange = Color(0xFFFF6B00);
  static const Color accentGreen = Color(0xFF1DB954);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF6A6A80);
  static const Color textDisabled = Color(0xFF404050);

  // Status colors
  static const Color liveRed = Color(0xFFFF3B3B);
  static const Color success = Color(0xFF1DB954);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF453A);

  // Dividers
  static const Color divider = Color(0xFF1E1E2E);
  static const Color border = Color(0xFF2A2A3A);

  // Light theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F7);
  static const Color lightSurfaceVariant = Color(0xFFEAEAEF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF4A4A6A);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceVariant: AppColors.surfaceVariant,
        primary: AppColors.accentOrange,
        secondary: AppColors.accentGreen,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(isLight: false),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentOrange,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.accentOrange.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      extensions: const [],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceVariant: AppColors.lightSurfaceVariant,
        primary: AppColors.accentOrange,
        secondary: AppColors.accentGreen,
        onBackground: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
        onPrimary: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: _buildTextTheme(isLight: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.accentOrange,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _buildTextTheme({required bool isLight}) {
    final baseColor = isLight ? AppColors.lightTextPrimary : AppColors.textPrimary;
    final secondaryColor = isLight ? AppColors.lightTextSecondary : AppColors.textSecondary;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 26, fontWeight: FontWeight.w700, color: baseColor, letterSpacing: -0.3,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w700, color: baseColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: baseColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: baseColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w600, color: baseColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: baseColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w400, color: baseColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: baseColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: baseColor, letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500, color: secondaryColor, letterSpacing: 0.5,
      ),
    );
  }
}
