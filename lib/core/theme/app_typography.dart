import 'package:flutter/material.dart';

/// Subclass TextStyle yang mengimplementasikan operator call()
/// sehingga dapat diakses baik sebagai properti TextStyle (AppTypography.body.copyWith(...))
/// maupun sebagai fungsi context (AppTypography.body(context).copyWith(...))
class CardlyTextStyle extends TextStyle {
  const CardlyTextStyle({
    super.inherit = true,
    super.color,
    super.backgroundColor,
    super.fontSize,
    super.fontWeight,
    super.fontStyle,
    super.letterSpacing,
    super.wordSpacing,
    super.textBaseline,
    super.height,
    super.leadingDistribution,
    super.locale,
    super.foreground,
    super.background,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.debugLabel,
    super.fontFamily = 'Inter',
    super.fontFamilyFallback,
    super.package,
    super.overflow,
  });

  /// Memungkinkan pemanggilan AppTypography.name([context])
  /// dengan adaptasi warna teks otomatis sesuai mode terang (#171717) / gelap (#FFFFFF)
  TextStyle call([BuildContext? context]) {
    if (context != null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return copyWith(
        color:
            color ??
            (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717)),
      );
    }
    return this;
  }
}

/// Typography scale resmi Cardly sesuai spesifikasi DESAIN.md (Inter font scale)
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  // Feature: Tabular numerals untuk nomor kartu dan tanggal agar tidak goyang
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static const CardlyTextStyle display = CardlyTextStyle(
    fontSize: 40.0,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: -1.1,
  );

  static const CardlyTextStyle largeHeading = CardlyTextStyle(
    fontSize: 30.0,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.8,
  );

  static const CardlyTextStyle pageHeading = CardlyTextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static const CardlyTextStyle sectionHeading = CardlyTextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.2,
  );

  static const CardlyTextStyle body = CardlyTextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.38,
    letterSpacing: 0.0,
  );

  static const CardlyTextStyle bodyMedium = CardlyTextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.38,
    letterSpacing: 0.0,
  );

  static const CardlyTextStyle bodySemiBold = CardlyTextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.38,
    letterSpacing: 0.0,
  );

  static const CardlyTextStyle compactBody = CardlyTextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.0,
  );

  static const CardlyTextStyle compactBodyMedium = CardlyTextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.0,
  );

  static const CardlyTextStyle caption = CardlyTextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.2,
  );

  static const CardlyTextStyle captionMedium = CardlyTextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.2,
  );

  static const CardlyTextStyle tinyLabel = CardlyTextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    height: 1.27,
    letterSpacing: 0.4,
  );

  // Semantic aliases
  static const CardlyTextStyle titleMedium = sectionHeading;
  static const CardlyTextStyle titleSmall = compactBodyMedium;
  static const CardlyTextStyle bodySmall = compactBody;

  // Suffix aliases for backward compatibility
  static const CardlyTextStyle displayStyle = display;
  static const CardlyTextStyle pageHeadingStyle = pageHeading;
  static const CardlyTextStyle bodyStyle = body;
  static const CardlyTextStyle bodyMediumStyle = bodyMedium;
  static const CardlyTextStyle bodySemiBoldStyle = bodySemiBold;
  static const CardlyTextStyle captionStyle = caption;
  static const CardlyTextStyle captionMediumStyle = captionMedium;

  // Tabular numeric variant untuk nomor kartu & tanggal
  static TextStyle tabular(TextStyle base) {
    return base.copyWith(fontFeatures: tabularFigures);
  }
}
