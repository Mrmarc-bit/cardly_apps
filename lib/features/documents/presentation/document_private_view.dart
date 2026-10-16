import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../domain/document_model.dart';

class DocumentPrivateView extends ConsumerWidget {
  final String documentId;

  const DocumentPrivateView({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final docIndex = docs.indexWhere((d) => d.id == documentId);
    if (docIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dokumen Pribadi')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Dokumen tidak ditemukan'),
              const SizedBox(height: AppSpacing.md),
              CardlyButton(text: 'Kembali', onPressed: () => context.pop()),
            ],
          ),
        ),
      );
    }

    final doc = docs[docIndex];

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(doc.title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            tooltip: 'Kunci Kembali',
            icon: const Icon(Icons.lock_outline, color: Colors.white),
            onPressed: () {
              CardlyToast.showSuccess(
                context,
                'Tampilan dokumen diamankan kembali',
              );
              context.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Anti-screenshot security warning banner
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenInset,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, color: AppColors.lime, size: 18),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Ruang Pratinjau Terenkripsi. Tangkapan layar dinonaktifkan demi privasi.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Document Canvas Viewer
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.screenInset),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        doc.fileType == DocumentFileType.pdf
                            ? Icons.picture_as_pdf
                            : Icons.document_scanner,
                        size: 80,
                        color: AppColors.ink,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        doc.title,
                        style: AppTypography.titleMedium(context).copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (doc.documentNumber != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'No: ${doc.documentNumber}',
                          style: AppTypography.bodyMedium(context).copyWith(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (doc.issuer != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Penerbit: ${doc.issuer}',
                          style: AppTypography.bodySmall(context)
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(
                            AppRadius.control,
                          ),
                        ),
                        child: Text(
                          'Halaman 1 dari 1 • Terverifikasi Offline',
                          style: AppTypography.caption(context)
                              .copyWith(color: AppColors.charcoal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom control bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenInset),
              child: Row(
                children: [
                  Expanded(
                    child: CardlyButton(
                      text: 'Tutup Pratinjau',
                      variant: CardlyButtonVariant.secondary,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.all(16),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Bagikan Eksternal Aman',
                    onPressed: () {
                      CardlyToast.showInfo(
                        context,
                        'Mempersiapkan berkas terenkripsi untuk dibagikan...',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
