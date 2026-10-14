import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cardly_buttons.dart';

/// Layar editor penyesuaian pemotongan & rotasi 90° sesuai Figma Screen 52 (Potong & putar)
class CropRotateEditor extends StatefulWidget {
  final int initialQuarterTurns;
  final String documentTitlePreview;
  final String documentCategoryPreview;
  final String? imagePath;
  final VoidCallback onRetake;
  final ValueChanged<int> onConfirmCrop;

  const CropRotateEditor({
    super.key,
    this.initialQuarterTurns = 0,
    this.documentTitlePreview = 'SIM A',
    this.documentCategoryPreview = 'KARTU IDENTITAS',
    this.imagePath,
    required this.onRetake,
    required this.onConfirmCrop,
  });

  @override
  State<CropRotateEditor> createState() => _CropRotateEditorState();
}

class _CropRotateEditorState extends State<CropRotateEditor> {
  late int _quarterTurns;

  @override
  void initState() {
    super.initState();
    _quarterTurns = widget.initialQuarterTurns;
  }

  void _rotateClockwise() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _resetCrop() {
    setState(() {
      _quarterTurns = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? AppColors.white : AppColors.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onRetake,
          tooltip: 'Kembali',
        ),
        title: Text(
          'Potong & putar',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Data contoh',
                style: TextStyle(
                  fontSize: 12.0,
                  color: isDark ? Colors.white54 : AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: 8.0,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Teks Panduan (Sesuai Figma 52)
              Text(
                'Sesuaikan batas dokumen. Hindari area di luar dokumen.',
                style: AppTypography.body.copyWith(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
              ),
              const SizedBox(height: 16.0),

              // 2. Viewport Pemotongan Gelap & Bingkai Batas Lime
              Container(
                padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kartu dengan Rotasi Halus & Border Neon Lime
                    AnimatedRotation(
                      turns: _quarterTurns / 4.0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      child: AspectRatio(
                        aspectRatio: 1.586,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: AppColors.lime,
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lime.withValues(alpha: 0.3),
                                blurRadius: 16.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              (widget.imagePath != null &&
                                  File(widget.imagePath!).existsSync())
                              ? Image.file(
                                  File(widget.imagePath!),
                                  fit: BoxFit.cover,
                                )
                              : _buildPlaceholderCard(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // Keterangan Bawah di Kotak Gelap
                    const Text(
                      'Ilustrasi kamera • tanpa foto pribadi',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // 3. Tombol Putar 90° & Atur Ulang (Sesuai Figma 52)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.rotate_right_rounded,
                      label: 'Putar 90°',
                      onTap: _rotateClockwise,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.refresh_rounded,
                      label: 'Atur ulang',
                      onTap: _resetCrop,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // 4. Kartu Keamanan / Edukasi Pratinjau Aman (Sesuai Figma 52)
              Container(
                padding: const EdgeInsets.all(14.0),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.softGray,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 18.0,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pratinjau data contoh',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Tidak ada foto atau nomor identitas asli dalam contoh ini.',
                            style: TextStyle(
                              fontSize: 11.5,
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
              ),

              const SizedBox(height: 20.0),

              // 5. Tombol Utama (Gunakan hasil scan)
              CardlyButton(
                text: 'Gunakan hasil scan',
                icon: Icons.check_rounded,
                onPressed: () => widget.onConfirmCrop(_quarterTurns),
              ),

              const SizedBox(height: 8.0),

              // 6. Tombol Ambil Ulang (Sesuai Figma 52)
              Center(
                child: TextButton(
                  onPressed: widget.onRetake,
                  child: Text(
                    'Ambil ulang',
                    style: TextStyle(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFEBEBEA);
    final fg = isDark ? AppColors.white : AppColors.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.0, color: fg),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.documentTitlePreview,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Icon(
                Icons.badge_outlined,
                size: 22.0,
                color: AppColors.ink,
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 44.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 28.0,
                  color: Colors.black38,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8.0,
                      width: 100.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCDCDC),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Container(
                      height: 7.0,
                      width: 140.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Container(
                      height: 7.0,
                      width: 110.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Text(
            'Pratinjau disamarkan • Data contoh',
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
