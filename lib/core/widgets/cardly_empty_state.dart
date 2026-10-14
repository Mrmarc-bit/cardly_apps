import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';
import 'cardly_buttons.dart';

/// Komponen Empty State Cardly sesuai spesifikasi DESAIN.md (Ikon bulat Lime, judul tegas)
class CardlyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionButtonText;
  final String? buttonText;
  final VoidCallback? onActionPressed;
  final VoidCallback? onButtonPressed;

  const CardlyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionButtonText,
    this.buttonText,
    this.onActionPressed,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveButtonText = buttonText ?? actionButtonText;
    final effectiveCallback = onButtonPressed ?? onActionPressed;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container Ikon Bulat Lime
            Container(
              width: 72.0,
              height: 72.0,
              decoration: const BoxDecoration(
                color: AppColors.lime,
                borderRadius: AppRadius.cardRadius,
              ),
              child: Icon(icon, size: 36.0, color: AppColors.ink),
            ),
            const SizedBox(height: 24.0),
            // Judul Empty State
            Text(
              title,
              style: AppTypography.pageHeadingStyle.copyWith(
                color: isDark ? AppColors.white : AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            // Deskripsi Penjelasan
            Text(
              description,
              style: AppTypography.bodyStyle.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (effectiveButtonText != null && effectiveCallback != null) ...[
              const SizedBox(height: 28.0),
              CardlyPrimaryButton(
                text: effectiveButtonText,
                onPressed: effectiveCallback,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
