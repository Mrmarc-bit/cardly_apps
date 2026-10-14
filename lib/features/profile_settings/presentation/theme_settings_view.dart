import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ThemeSettingsView extends ConsumerWidget {
  const ThemeSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tampilan & Tema')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Tema Aplikasi',
              style: AppTypography.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sesuaikan kenyamanan visual antarmuka Cardly sesuai preferensi Anda.',
              style: AppTypography.bodySmall(context)
                  .copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Option 1: System
            _buildThemeOptionCard(
              context,
              ref,
              mode: ThemeMode.system,
              title: 'Ikuti Pengaturan Sistem',
              subtitle: 'Secara otomatis beralih antara Terang dan Gelap mengikuti sistem perangkat Anda.',
              isSelected: currentMode == ThemeMode.system,
              icon: Icons.brightness_auto,
            ),

            const SizedBox(height: AppSpacing.md),

            // Option 2: Light Mode
            _buildThemeOptionCard(
              context,
              ref,
              mode: ThemeMode.light,
              title: 'Mode Terang (Mist)',
              subtitle: 'Latar Mist bersih (#F5F5F3) dengan teks hitam pekat Ink (#171717) dan aksen Lime.',
              isSelected: currentMode == ThemeMode.light,
              icon: Icons.light_mode,
            ),

            const SizedBox(height: AppSpacing.md),

            // Option 3: Dark Mode
            _buildThemeOptionCard(
              context,
              ref,
              mode: ThemeMode.dark,
              title: 'Mode Gelap (Ink Black)',
              subtitle: 'Latar gelap pekat (#171717) dengan kontras tinggi yang ramah mata di malam hari.',
              isSelected: currentMode == ThemeMode.dark,
              icon: Icons.dark_mode,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Live Accent Info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.lime, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 20,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Aksen warna Cardly Lime (#C8F45A) selalu konsisten memberikan sentuhan modern dan kontras prima pada kedua tema.',
                      style: AppTypography.bodySmall(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setTheme(mode);
      },
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? AppColors.lime
                : isDark
                ? AppColors.darkBorder
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.lime : AppColors.mutedText,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? null : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(context)
                        .copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.lime
                      : (isDark ? AppColors.mutedText : AppColors.softGray),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
