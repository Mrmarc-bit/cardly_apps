import 'package:flutter/material.dart';

/// Design tokens warna resmi Cardly sesuai spesifikasi DESAIN.md (Figma Handoff 1.0)
abstract final class AppColors {
  // Brand & Accent Tokens
  static const Color lime = Color(0xFFC8F45A);
  static const Color ink = Color(0xFF171717);
  static const Color charcoal = Color(0xFF252525);
  static const Color white = Color(0xFFFFFFFF);
  static const Color mist = Color(0xFFF5F5F3);
  static const Color softGray = Color(0xFFEBEBE8);
  static const Color mediumGray = Color(0xFF8B8B87);
  static const Color muted = Color(0xFF666666);
  static const Color elevatedDark = Color(0xFF303030);
  static const Color textSecondaryDark = Color(0xFFB6B6B6);

  // Status & Semantic Tokens
  static const Color success = Color(0xFF367A48);
  static const Color warning = Color(0xFF9A6B18);
  static const Color error = Color(0xFFB93838);
  static const Color info = Color(0xFF3B6D8C);

  // Card Palette Presets
  static const Color cardLime = Color(0xFFC8F45A);
  static const Color cardBlack = Color(0xFF171717);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardGray = Color(0xFFEBEBE8);

  // Modal Scrim
  static const Color modalScrim = Color(0x80000000); // 50% Black

  // Semantic & Context Aliases
  static const Color mutedText = muted;
  static const Color inkBlack = ink;
  static const Color cardBackground = white;
  static const Color darkCard = charcoal;
  static const Color border = softGray;
  static const Color darkBorder = elevatedDark;
}
