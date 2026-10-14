import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

enum NoticeBannerVariant {
  info,
  warning,
  error,
  success;

  Color get iconColor {
    switch (this) {
      case NoticeBannerVariant.info:
        return AppColors.info;
      case NoticeBannerVariant.warning:
        return AppColors.warning;
      case NoticeBannerVariant.error:
        return AppColors.error;
      case NoticeBannerVariant.success:
        return AppColors.success;
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case NoticeBannerVariant.info:
        return Icons.verified_user_outlined;
      case NoticeBannerVariant.warning:
        return Icons.warning_amber_rounded;
      case NoticeBannerVariant.error:
        return Icons.error_outline_rounded;
      case NoticeBannerVariant.success:
        return Icons.check_circle_outline_rounded;
    }
  }
}

/// Banner notifikasi / privasi Cardly sesuai prinsip "Pesan dengan ikon, bukan warna saja"
class CardlyNoticeBanner extends StatelessWidget {
  final String title;
  final String? description;
  final NoticeBannerVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;

  const CardlyNoticeBanner({
    super.key,
    required this.title,
    this.description,
    this.variant = NoticeBannerVariant.info,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.charcoal : AppColors.white;
    final borderColor = isDark ? AppColors.elevatedDark : AppColors.softGray;
    final effectiveIcon = icon ?? variant.defaultIcon;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.inputRadius,
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(effectiveIcon, color: variant.iconColor, size: 22.0),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.compactBodyMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      description!,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
