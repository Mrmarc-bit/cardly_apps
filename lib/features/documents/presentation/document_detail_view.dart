import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../domain/document_model.dart';
import '../../vault/presentation/pin_screen.dart';

class DocumentDetailView extends ConsumerWidget {
  final String documentId;

  const DocumentDetailView({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final docIndex = docs.indexWhere((d) => d.id == documentId);
    if (docIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Dokumen')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.file_copy_outlined,
                size: 48,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Dokumen tidak ditemukan',
                style: AppTypography.titleMedium(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              CardlyButton(text: 'Kembali', onPressed: () => context.pop()),
            ],
          ),
        ),
      );
    }

    final doc = docs[docIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Dokumen'),
        actions: [
          IconButton(
            tooltip: 'Tindakan dokumen',
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showDocumentActions(context, ref, doc),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Mockup Card
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.softGray,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        doc.fileType == DocumentFileType.pdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.mutedText
                            : AppColors.mediumGray,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        doc.title,
                        style: AppTypography.titleSmall(context)
                            .copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.fileType.name.toUpperCase()} • ${CardlyFormatters.formatFileSize(doc.fileSizeBytes)}',
                        style: AppTypography.caption(context)
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: doc.isVaultProtected
                            ? AppColors.ink
                            : AppColors.lime,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            doc.isVaultProtected
                                ? Icons.lock
                                : Icons.lock_open_rounded,
                            size: 14,
                            color: doc.isVaultProtected
                                ? Colors.white
                                : AppColors.ink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doc.isVaultProtected ? 'Brankas' : 'Standar',
                            style: AppTypography.caption(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: doc.isVaultProtected
                                  ? Colors.white
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Button to open full preview
            CardlyButton(
              text: 'Buka Dokumen Lengkap',
              icon: Icons.visibility_outlined,
              onPressed: () async {
                if (doc.isVaultProtected) {
                  final secureStorage = ref.read(secureStorageServiceProvider);
                  final hasPin = await secureStorage.hasAppPin();
                  if (context.mounted) {
                    final success = await PinScreen.showAsBottomSheet(
                      context,
                      mode: hasPin
                          ? PinScreenMode.verify
                          : PinScreenMode.create,
                      title: 'Buka Dokumen Pribadi',
                      subtitle: 'Masukkan PIN untuk membuka pratinjau dokumen rahasia.',
                    );
                    if (success == true && context.mounted) {
                      context.push('/documents/${doc.id}/private-view');
                    }
                  }
                } else {
                  context.push('/documents/${doc.id}/private-view');
                }
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Metadata Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Dokumen',
                    style: AppTypography.titleMedium(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildMetaRow(
                    context,
                    label: 'Kategori',
                    value: doc.category.displayName,
                    icon: Icons.folder_outlined,
                  ),
                  if (doc.documentNumber != null &&
                      doc.documentNumber!.isNotEmpty) ...[
                    const Divider(height: AppSpacing.lg),
                    _buildMetaRow(
                      context,
                      label: 'Nomor Dokumen',
                      value: doc.documentNumber!,
                      icon: Icons.tag,
                      isCopyable: true,
                    ),
                  ],
                  if (doc.issuer != null && doc.issuer!.isNotEmpty) ...[
                    const Divider(height: AppSpacing.lg),
                    _buildMetaRow(
                      context,
                      label: 'Instansi Penerbit',
                      value: doc.issuer!,
                      icon: Icons.account_balance_outlined,
                    ),
                  ],
                  const Divider(height: AppSpacing.lg),
                  _buildMetaRow(
                    context,
                    label: 'Tanggal Ditambahkan',
                    value: CardlyFormatters.formatDate(doc.createdAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                  if (doc.expiryDate != null) ...[
                    const Divider(height: AppSpacing.lg),
                    _buildMetaRow(
                      context,
                      label: 'Masa Berlaku',
                      value: CardlyFormatters.formatExpiry(doc.expiryDate!),
                      icon: Icons.event_available_outlined,
                    ),
                  ],
                  const Divider(height: AppSpacing.lg),
                  _buildMetaRow(
                    context,
                    label: 'Ukuran Berkas',
                    value: CardlyFormatters.formatFileSize(doc.fileSizeBytes),
                    icon: Icons.data_usage_outlined,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildMetaRow(
                    context,
                    label: 'Penyimpanan',
                    value: 'Penyimpanan Privat Lokal (Terenkripsi)',
                    icon: Icons.security_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Action: Delete
            CardlyButton(
              text: 'Hapus Dokumen',
              variant: CardlyButtonVariant.destructive,
              icon: Icons.delete_outline,
              onPressed: () => _confirmDelete(context, ref, doc),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mutedText),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption(context)
                    .copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Salin nomor',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              CardlyToast.showSuccess(
                context,
                'Nomor dokumen berhasil disalin',
              );
            },
          ),
      ],
    );
  }

  void _showDocumentActions(
    BuildContext context,
    WidgetRef ref,
    DocumentItem doc,
  ) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            doc.title,
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('Buka Pratinjau'),
            onTap: () {
              Navigator.pop(context);
              context.push('/documents/${doc.id}/private-view');
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm_add_outlined),
            title: const Text('Setel Pengingat Masa Berlaku'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reminders/create');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Hapus Dokumen',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, doc);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DocumentItem doc) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.delete_forever_outlined,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hapus Dokumen?',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700, color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dokumen "${doc.title}" beserta file fisik lokal akan dihapus permanen dari ruang penyimpanan aman Anda.',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          CardlyButton(
            text: 'Hapus Dokumen',
            variant: CardlyButtonVariant.destructive,
            onPressed: () {
              ref.read(documentListProvider.notifier).deleteDocument(doc.id);
              Navigator.pop(context);
              context.pop();
              CardlyToast.showSuccess(context, 'Dokumen berhasil dihapus');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          CardlyButton(
            text: 'Batal',
            variant: CardlyButtonVariant.quiet,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
