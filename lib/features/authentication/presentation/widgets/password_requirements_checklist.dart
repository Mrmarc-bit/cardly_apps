import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Checklist Kriteria Kata Sandi Berstandar Enterprise.
/// Ditempatkan di luar field input untuk menjaga kerapian visual tanpa membuat field melebar.
class PasswordRequirementsChecklist extends StatelessWidget {
  final String password;

  const PasswordRequirementsChecklist({super.key, required this.password});

  bool get hasMinLength => password.length >= 12;
  bool get hasUpperAndLower =>
      password.contains(RegExp(r'[A-Z]')) &&
      password.contains(RegExp(r'[a-z]'));
  bool get hasDigit => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar =>
      password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/`~]'));

  /// Memeriksa apakah seluruh kriteria enterprise terpenuhi
  bool get isAllSatisfied =>
      hasMinLength && hasUpperAndLower && hasDigit && hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.charcoal.withValues(alpha: 0.6)
            : AppColors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.softGray,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_outlined,
                size: 16.0,
                color: isDark ? AppColors.lime : AppColors.ink,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Standar Keamanan Kata Sandi',
                style: AppTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.0,
                  color: isDark ? AppColors.white : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          _RequirementRow(
            label: 'Minimal 12 karakter',
            isSatisfied: hasMinLength,
            isDark: isDark,
          ),
          const SizedBox(height: 6.0),
          _RequirementRow(
            label: 'Kombinasi huruf besar (A-Z) & kecil (a-z)',
            isSatisfied: hasUpperAndLower,
            isDark: isDark,
          ),
          const SizedBox(height: 6.0),
          _RequirementRow(
            label: 'Minimal satu angka (0-9)',
            isSatisfied: hasDigit,
            isDark: isDark,
          ),
          const SizedBox(height: 6.0),
          _RequirementRow(
            label: 'Minimal satu karakter simbol khusus (!@#\$%...)',
            isSatisfied: hasSpecialChar,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool isSatisfied;
  final bool isDark;

  const _RequirementRow({
    required this.label,
    required this.isSatisfied,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSatisfied
                ? (isDark ? AppColors.lime : Colors.green.shade600)
                : Colors.transparent,
            border: Border.all(
              color: isSatisfied
                  ? Colors.transparent
                  : (isDark ? AppColors.elevatedDark : AppColors.softGray),
              width: 1.5,
            ),
          ),
          child: isSatisfied
              ? Icon(
                  Icons.check,
                  size: 11.0,
                  color: isDark ? AppColors.ink : Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11.8,
              color: isSatisfied
                  ? (isDark ? AppColors.white : AppColors.ink)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.muted),
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
