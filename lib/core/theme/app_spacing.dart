import 'package:flutter/material.dart';

/// 8-point rhythm spacing tokens sesuai spesifikasi DESAIN.md
abstract final class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Semantic Spacing Aliases
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s16;
  static const double lg = s24;
  static const double xl = s32;
  static const double xxl = s48;

  // Insets Standar Layar
  static const double screenInset = 24.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenInset,
  );
  static const EdgeInsets screenPaddingWithTop = EdgeInsets.fromLTRB(
    screenInset,
    s16,
    screenInset,
    s24,
  );
}
