import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';

/// Kartu Banner Keamanan & Privasi resmi (docs/4. Authentication/05 Welcome.png & 61 Aktifkan biometrik.png)
class AuthSecurityCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const AuthSecurityCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.verified_user_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.elevatedDark : AppColors.softGray,
          width: 1.0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              icon,
              size: 20.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySemiBold.copyWith(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12.0,
                    height: 1.35,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
