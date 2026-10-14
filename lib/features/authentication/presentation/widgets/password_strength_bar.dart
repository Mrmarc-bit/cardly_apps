import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';

/// Indikator Kekuatan Sandi 4 Segmen (docs/4. Authentication/07 Buat akun.png)
class PasswordStrengthBar extends StatelessWidget {
  final int strength; // 0 sampai 4

  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color activeColor;
    String statusLabel;

    switch (strength) {
      case 0:
        activeColor = isDark ? AppColors.elevatedDark : AppColors.softGray;
        statusLabel = 'Masukkan kata sandi';
        break;
      case 1:
        activeColor = AppColors.error;
        statusLabel = 'Lemah • minimal 8 karakter';
        break;
      case 2:
        activeColor = AppColors.warning;
        statusLabel = 'Cukup • tambahkan kombinasi angka atau simbol';
        break;
      case 3:
      case 4:
      default:
        // Di Figma: Hijau (#2E7D32 atau AppColors.success)
        activeColor = const Color(0xFF2E7D32);
        statusLabel = 'Kuat • memenuhi standar keamanan';
        break;
    }

    final inactiveColor = isDark ? AppColors.elevatedDark : AppColors.softGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4 Segmen Bar Horizontal
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                height: 4.0,
                margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
                decoration: BoxDecoration(
                  color: isFilled ? activeColor : inactiveColor,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6.0),
        // Status teks di bawah bar
        Text(
          statusLabel,
          style: AppTypography.caption.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: strength >= 3
                ? activeColor
                : (isDark ? AppColors.mediumGray : AppColors.muted),
          ),
        ),
      ],
    );
  }
}
