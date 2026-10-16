import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

/// Konfigurasi Dual-Theme Cardly (Terang & Gelap) sesuai spesifikasi DESAIN.md
abstract final class AppTheme {
  /// Transisi halaman horizontal slide (Cupertino style) yang mulus, stabil,
  /// dan bebas efek layer lepas (Zoom M3) di seluruh platform (Android, iOS, Desktop).
  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      );

  /// Tema Terang (Light)
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.white,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.mist,
      cardColor: AppColors.white,
      dividerColor: AppColors.softGray,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mist,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
        actionsIconTheme: IconThemeData(color: AppColors.ink),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        displayMedium: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        displaySmall: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        headlineLarge: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        headlineMedium: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        headlineSmall: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        titleLarge: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        titleMedium: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        titleSmall: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        bodyLarge: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        labelLarge: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        labelMedium: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
        labelSmall: TextStyle(color: AppColors.ink, fontFamily: 'Inter'),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.softGray, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.softGray, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.softGray, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
        labelStyle: AppTypography.body.copyWith(color: AppColors.muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          elevation: 0,
          textStyle: AppTypography.bodySemiBold,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
          minimumSize: const Size(double.infinity, 52.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        elevation: 6,
        insetPadding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
      ),
    );
  }

  /// Tema Gelap (Dark)
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.ink,
      secondary: AppColors.lime,
      onSecondary: AppColors.ink,
      surface: AppColors.charcoal,
      onSurface: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      cardColor: AppColors.charcoal,
      dividerColor: AppColors.elevatedDark,
      pageTransitionsTheme: _pageTransitionsTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.white),
        actionsIconTheme: IconThemeData(color: AppColors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        displayMedium: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        displaySmall: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        headlineLarge: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        headlineMedium: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        headlineSmall: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        titleLarge: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        titleMedium: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        titleSmall: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        bodyLarge: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        labelLarge: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        labelMedium: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
        labelSmall: TextStyle(color: AppColors.white, fontFamily: 'Inter'),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ink,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.mediumGray,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.charcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.elevatedDark, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoal,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.elevatedDark,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.elevatedDark,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelStyle: AppTypography.body.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          elevation: 0,
          textStyle: AppTypography.bodySemiBold,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.pillRadius,
          ),
          minimumSize: const Size(double.infinity, 52.0),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontFamily: 'Inter',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          side: const BorderSide(color: AppColors.elevatedDark, width: 1),
        ),
        elevation: 6,
        insetPadding: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
      ),
    );
  }
}
