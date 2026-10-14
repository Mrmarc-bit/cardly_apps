import 'package:flutter/material.dart';

/// Radius baku sesuai spesifikasi DESAIN.md
abstract final class AppRadius {
  // 12 pt untuk control kecil / chips / filter badges
  static const double control = 12.0;
  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(control),
  );

  // 16 pt untuk input field / dropdown / notification banner
  static const double input = 16.0;
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(input),
  );

  // 24 pt untuk card tampilan / payment card / container modal
  static const double card = 24.0;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );

  // 32 pt untuk modal sheet bagian atas / feature card besar
  static const double feature = 32.0;
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(feature),
  );

  // 999 pt untuk pills / FAB bulat / circular buttons
  static const double pill = 999.0;
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
