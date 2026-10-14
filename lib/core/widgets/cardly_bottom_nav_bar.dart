import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

/// Item destinasi Bottom Navigation Bar Cardly
class CardlyNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const CardlyNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Bottom Navigation Bar kustom Cardly sesuai spesifikasi DESAIN.md
class CardlyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  CardlyBottomNavBar({
    super.key,
    required this.currentIndex,
    ValueChanged<int>? onItemSelected,
    ValueChanged<int>? onTap,
  }) : onItemSelected = onItemSelected ?? onTap ?? ((_) {});

  static const List<CardlyNavItem> items = [
    CardlyNavItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    CardlyNavItem(
      label: 'Kartu',
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card_rounded,
    ),
    CardlyNavItem(
      label: 'Dokumen',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
    ),
    CardlyNavItem(
      label: 'Brankas',
      icon: Icons.lock_outline_rounded,
      activeIcon: Icons.lock_rounded,
    ),
    CardlyNavItem(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.ink : AppColors.white;
    final borderColor = isDark ? AppColors.elevatedDark : AppColors.softGray;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onItemSelected(index),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44.0,
                        minHeight: 44.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lime
                                  : Colors.transparent,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: 22.0,
                              color: isSelected
                                  ? AppColors.ink
                                  : (isDark
                                        ? AppColors.mediumGray
                                        : AppColors.muted),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            item.label,
                            style: AppTypography.tinyLabel.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? (isDark ? AppColors.white : AppColors.ink)
                                  : (isDark
                                        ? AppColors.mediumGray
                                        : AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
