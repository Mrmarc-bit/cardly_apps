import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

/// Utilitas untuk menampilkan Modal Bottom Sheet resmi Cardly (Radius atas 32 pt)
abstract final class CardlyBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    bool isDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.charcoal : AppColors.white;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: bgColor,
      barrierColor: AppColors.modalScrim,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle Bar
                  Center(
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.elevatedDark
                            : AppColors.softGray,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  ),
                  if (title != null && title.isNotEmpty) ...[
                    const SizedBox(height: 20.0),
                    Text(
                      title,
                      style: AppTypography.pageHeadingStyle.copyWith(
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ] else ...[
                    const SizedBox(height: 12.0),
                  ],
                  // Konten Anak
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
