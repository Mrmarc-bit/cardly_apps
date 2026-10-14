import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cardly_buttons.dart';

/// Layar penanganan saat izin kamera belum diberikan atau ditolak (Screens 50-51)
class CameraPermissionView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onImportFallback;
  final VoidCallback onClose;

  const CameraPermissionView({
    super.key,
    required this.onOpenSettings,
    required this.onImportFallback,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: onClose,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Ikon Kamera Terkunci dengan Lingkaran Aksen
              Center(
                child: Container(
                  width: 88.0,
                  height: 88.0,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal : AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.no_photography_outlined,
                        size: 40.0,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                      Positioned(
                        right: 18.0,
                        bottom: 18.0,
                        child: Container(
                          width: 20.0,
                          height: 20.0,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 11.0,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Judul & Penjelasan
              Text(
                'Akses Kamera Diperlukan',
                style: AppTypography.pageHeading.copyWith(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10.0),

              Text(
                'Cardly membutuhkan izin kamera untuk memindai dokumen fisik dan mengekstrak teks secara instan. Seluruh proses pembacaan (OCR) berlangsung secara offline di ponsel Anda demi keamanan data.',
                style: AppTypography.body.copyWith(
                  fontSize: 14.0,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28.0),

              // Kartu Edukasi Privasi
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.08)
                        : AppColors.softGray,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: const BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.ink,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privasi Mutlak Cardly',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Kamera hanya aktif saat layar pindaian terbuka dan foto tidak pernah diunggah ke server pihak ketiga.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.muted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Tombol Aksi Utama & Fallback (FR-SCAN-002)
              CardlyButton(
                text: 'Buka Pengaturan Perangkat',
                icon: Icons.settings_outlined,
                onPressed: onOpenSettings,
              ),

              const SizedBox(height: 12.0),

              CardlyButton(
                text: 'Impor File Saja (Tanpa Kamera)',
                variant: CardlyButtonVariant.secondary,
                icon: Icons.upload_file_outlined,
                onPressed: onImportFallback,
              ),

              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
