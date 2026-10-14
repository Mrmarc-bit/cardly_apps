import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PrivacyInfoView extends StatelessWidget {
  const PrivacyInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Privasi & Keamanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.lime),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: 48,
                    color: isDark ? AppColors.lime : AppColors.ink,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Prinsip Keamanan Cardly',
                    style: AppTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Cardly dirancang dengan prinsip Private by Design. Privasi Anda bukan fitur tambahan, melainkan pondasi utama aplikasi.',
                    style: AppTypography.bodySmall(context).copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _buildPillar(
              context,
              isDark,
              icon: Icons.cloud_off_rounded,
              title: '1. Kedaulatan Data 100% Offline',
              description: 'Semua kartu, pindaian dokumen, dan catatan disimpan secara eksklusif pada penyimpanan lokal perangkat Anda. Tidak ada server cloud terpusat yang dapat disadap atau bocor.',
            ),

            const SizedBox(height: AppSpacing.md),

            _buildPillar(
              context,
              isDark,
              icon: Icons.no_encryption_gmailerrorred_rounded,
              title: '2. Nol Kredensial Perbankan',
              description: 'Cardly bukan aplikasi pembayaran atau dompet perbankan. Kami secara ketat melarang dan tidak menyediakan formulir untuk nomor kartu 16-digit lengkap, CVV/CVC, maupun PIN ATM.',
            ),

            const SizedBox(height: AppSpacing.md),

            _buildPillar(
              context,
              isDark,
              icon: Icons.vpn_key_rounded,
              title: '3. Enkripsi Berbasis Perangkat Keras',
              description: 'Kunci otentikasi lokal dan konfigurasi Brankas diamankan menggunakan modul perangkat keras bawaan OS (iOS Secure Enclave & Android Keystore).',
            ),

            const SizedBox(height: AppSpacing.md),

            _buildPillar(
              context,
              isDark,
              icon: Icons.track_changes_outlined,
              title: '4. Nol Pelacak & Tanpa Iklan',
              description: 'Tidak ada SDK analitik pihak ketiga yang memantau kebiasaan Anda. Riwayat pencarian dan aktivitas harian tidak pernah keluar dari gawai Anda.',
            ),

            const SizedBox(height: AppSpacing.md),

            _buildPillar(
              context,
              isDark,
              icon: Icons.delete_sweep_rounded,
              title: '5. Hak Penghapusan Mutlak',
              description: 'Anda memiliki kendali 100% atas data Anda. Tombol Hapus Data Lokal memungkinkan Anda membersihkan seluruh database dan arsip perangkat keras dalam hitungan detik.',
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPillar(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.lime),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall(context)
                      .copyWith(color: AppColors.mutedText, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
