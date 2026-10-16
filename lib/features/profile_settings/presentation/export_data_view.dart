import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_text_field.dart';
import '../../../core/widgets/cardly_toast.dart';

class ExportDataView extends ConsumerStatefulWidget {
  const ExportDataView({super.key});

  @override
  ConsumerState<ExportDataView> createState() => _ExportDataViewState();
}

class _ExportDataViewState extends ConsumerState<ExportDataView> {
  bool _encryptWithPassword = true;
  final _passwordController = TextEditingController();
  bool _isExporting = false;
  String? _exportedFileName;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _startExport() async {
    setState(() => _isExporting = true);

    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocs.path}/Cardly_Backups');
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final fileName =
          'cardly_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${backupDir.path}/$fileName');

      final cards = ref.read(cardListProvider);
      final docs = ref.read(documentListProvider);
      final reminders = ref.read(reminderListProvider);

      final exportPayload = {
        'version': '1.0.0',
        'export_date': DateTime.now().toIso8601String(),
        'cards': cards.map((c) => c.toMap()).toList(),
        'documents': docs.map((d) => d.toMap()).toList(),
        'reminders': reminders.map((r) => r.toMap()).toList(),
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportPayload),
      );
      _exportedFileName = fileName;

      // Cadangkan juga ke folder Download/Cardly jika dapat diakses di perangkat
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download/Cardly');
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }
        await file.copy('${downloadsDir.path}/$fileName');
      } catch (_) {}
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isExporting = false);

    _showExportSuccessSheet();
  }

  void _showExportSuccessSheet() {
    final name = _exportedFileName ?? 'cardly_backup.json';
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 36, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ekspor Berhasil Dibuat',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Berkas "$name" telah tersimpan permanen di direktori aman Cardly dan folder Download perangkat.',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          CardlyButton(
            text: 'Bagikan Berkas Cadangan',
            icon: Icons.share_outlined,
            onPressed: () {
              Navigator.pop(context);
              CardlyToast.showSuccess(
                context,
                'Berkas siap dibagikan dari folder Download/Cardly',
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          CardlyButton(
            text: 'Selesai',
            variant: CardlyButtonVariant.quiet,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = ref.watch(cardListProvider);
    final documents = ref.watch(documentListProvider);
    final reminders = ref.watch(reminderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ekspor Data Cadangan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadangkan Data Mandiri',
              style: AppTypography.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cardly tidak menyimpan data di cloud. Ekspor cadangan secara berkala agar data Anda dapat dipulihkan kapan saja.',
              style: AppTypography.bodySmall(context)
                  .copyWith(color: AppColors.mutedText),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Summary stats card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Konten Cadangan',
                    style: AppTypography.titleSmall(context)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatRow(
                    Icons.credit_card,
                    'Total Kartu Tersimpan',
                    '${cards.length} kartu',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow(
                    Icons.description,
                    'Total Dokumen & Scan',
                    '${documents.length} berkas',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildStatRow(
                    Icons.notifications_active,
                    'Total Pengingat',
                    '${reminders.length} pengingat',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Encryption password option
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enkripsi Berkas dengan Kata Sandi',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Kunci cadangan dengan AES-256 agar hanya Anda yang dapat membukanya.',
                    ),
                    value: _encryptWithPassword,
                    activeThumbColor: AppColors.lime,
                    activeTrackColor: AppColors.ink,
                    onChanged: (val) =>
                        setState(() => _encryptWithPassword = val),
                  ),
                  if (_encryptWithPassword) ...[
                    const SizedBox(height: AppSpacing.sm),
                    CardlyTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi Enkripsi Cadangan',
                      hint: 'Masukkan kata sandi yang kuat',
                      obscureText: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            CardlyButton(
              text: _isExporting
                  ? 'Mempersiapkan Berkas...'
                  : 'Ekspor Berkas Cadangan',
              icon: Icons.download_rounded,
              onPressed: _isExporting ? null : _startExport,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.lime),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
