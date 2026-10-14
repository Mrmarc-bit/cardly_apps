import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cardly_buttons.dart';

enum ScanDocumentType { idCard, document, paymentCard }

/// Layar / Komponen Edukasi Sebelum Pindai (Screen 49: Sebelum Scan)
class PreScanSheet extends StatelessWidget {
  final ScanDocumentType selectedType;
  final ValueChanged<ScanDocumentType> onTypeChanged;
  final VoidCallback onStartScan;
  final VoidCallback onPickFromGallery;

  const PreScanSheet({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onStartScan,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Ikon Kamera Aksen Lime
          Center(
            child: Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                color: AppColors.lime,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lime.withValues(alpha: 0.45),
                    blurRadius: 14.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.ink,
                size: 26.0,
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // Judul & Subtitle
          Text(
            'Panduan Memindai Dokumen',
            style: AppTypography.pageHeading.copyWith(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4.0),
          Text(
            'Posisikan berkas Anda untuk hasil pembacaan teks (OCR) yang optimal dan presisi.',
            style: AppTypography.body.copyWith(
              fontSize: 12.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16.0),

          // Pilihan Jenis Dokumen yang Dipindai
          Text(
            'PILIH JENIS BERKAS',
            style: AppTypography.captionStyle.copyWith(
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.6)
                  : AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10.0),

          Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  context,
                  type: ScanDocumentType.idCard,
                  title: 'Kartu Identitas',
                  subtitle: 'KTP, SIM, ID',
                  icon: Icons.badge_outlined,
                  isSelected: selectedType == ScanDocumentType.idCard,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildTypeChip(
                  context,
                  type: ScanDocumentType.document,
                  title: 'Dokumen Fisik',
                  subtitle: 'A4, Ijazah, Polis',
                  icon: Icons.description_outlined,
                  isSelected: selectedType == ScanDocumentType.document,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildTypeChip(
                  context,
                  type: ScanDocumentType.paymentCard,
                  title: 'Kartu Bank / Lain',
                  subtitle: 'Debit, Member',
                  icon: Icons.credit_card_outlined,
                  isSelected: selectedType == ScanDocumentType.paymentCard,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20.0),

          // 3 Tips Petunjuk Praktis
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.charcoal
                  : AppColors.softGray.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.08)
                    : AppColors.softGray,
              ),
            ),
            child: Column(
              children: [
                _buildTipRow(
                  icon: Icons.crop_free_rounded,
                  title: 'Bingkai Rata',
                  description:
                      'Letakkan di permukaan datar dengan latar kontras.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12.0),
                _buildTipRow(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Pencahayaan Jelas',
                  description: 'Hindari pantulan silau atau bayangan gelap di atas teks.',
                  isDark: isDark,
                ),
                const SizedBox(height: 12.0),
                _buildTipRow(
                  icon: Icons.security_rounded,
                  title: '100% On-Device',
                  description: 'OCR diproses lokal tanpa koneksi cloud untuk privasi mutlak.',
                  isDark: isDark,
                  isLime: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),

          // Tombol Tindakan
          CardlyButton(
            text: 'Buka Kamera Pindai',
            icon: Icons.camera_alt_outlined,
            onPressed: onStartScan,
          ),
          const SizedBox(height: 8.0),
          CardlyButton(
            text: 'Pilih dari Galeri Foto',
            variant: CardlyButtonVariant.secondary,
            icon: Icons.photo_library_outlined,
            onPressed: onPickFromGallery,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required ScanDocumentType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTypeChanged(type),
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.lime.withValues(alpha: 0.15)
                      : AppColors.lime.withValues(alpha: 0.25))
                : (isDark ? AppColors.charcoal : AppColors.white),
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: isSelected
                  ? AppColors.lime
                  : (isDark
                        ? AppColors.white.withValues(alpha: 0.1)
                        : AppColors.softGray),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22.0,
                color: isSelected
                    ? (isDark ? AppColors.lime : AppColors.ink)
                    : (isDark
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.ink),
              ),
              const SizedBox(height: 6.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.ink,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.0,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    bool isLime = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: isLime
                ? AppColors.lime
                : (isDark ? AppColors.elevatedDark : AppColors.softGray),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16.0,
            color: isLime
                ? AppColors.ink
                : (isDark ? AppColors.white : AppColors.ink),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
