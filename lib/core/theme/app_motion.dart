import 'package:flutter/animation.dart';

/// Motion specifications resmi Cardly sesuai spesifikasi DESAIN.md Section 8
abstract final class AppMotion {
  // Durasi animasi mikro
  static const Duration pressDuration = Duration(
    milliseconds: 100,
  ); // 80-120 ms
  static const Duration carouselSnapDuration = Duration(
    milliseconds: 220,
  ); // 200-240 ms
  static const Duration bottomSheetDuration = Duration(milliseconds: 240);
  static const Duration favoriteToggleDuration = Duration(milliseconds: 160);
  static const Duration skeletonPulseDuration = Duration(milliseconds: 1000);
  static const Duration successFeedbackDuration = Duration(
    milliseconds: 180,
  ); // 160-200 ms
  static const Duration themeSwitchDuration = Duration(milliseconds: 180);
  static const Duration navigationDuration = Duration(milliseconds: 160);
  static const Duration modalDialogDuration = Duration(
    milliseconds: 160,
  ); // 120-200 ms
  static const Duration privacyRevealDuration = Duration(milliseconds: 100);

  // Kurva waktu baku
  static const Curve defaultCurve = Curves.easeOut;
  static const Curve snapCurve = Curves.easeOutCubic;
  static const Curve pulseCurve = Curves.easeInOut;

  // Nilai transformasi touch feedback
  static const double pressedOpacity = 0.88;
  static const double pressedScale = 0.98;
}
