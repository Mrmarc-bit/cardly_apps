import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_text_field.dart';
import '../domain/document_model.dart';

class AddDocumentSourceView extends ConsumerStatefulWidget {
  const AddDocumentSourceView({super.key});

  @override
  ConsumerState<AddDocumentSourceView> createState() =>
      _AddDocumentSourceViewState();
}

class _AddDocumentSourceViewState extends ConsumerState<AddDocumentSourceView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _docNumberController = TextEditingController();
  final _issuerController = TextEditingController();

  DocumentCategory _selectedCategory = DocumentCategory.identity;
  DocumentFileType _selectedFileType = DocumentFileType.pdf;
  bool _isVaultProtected = true;
  String _simulatedFileName = 'ktp_digital_scan.pdf';
  int _simulatedFileSize = 1450000;

  @override
  void dispose() {
    _titleController.dispose();
    _docNumberController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  void _chooseSource(
    String sourceName,
    DocumentFileType type,
    String dummyName,
    int bytes,
  ) {
    setState(() {
      _selectedFileType = type;
      _simulatedFileName = dummyName;
      _simulatedFileSize = bytes;
      if (_titleController.text.isEmpty) {
        _titleController.text = dummyName
            .replaceAll('.pdf', '')
            .replaceAll('.jpg', '')
            .replaceAll('_', ' ')
            .toUpperCase();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File dipilih dari $sourceName: $dummyName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    final newDoc = DocumentItem(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      category: _selectedCategory,
      fileType: _selectedFileType,
      filePath: 'app_secure_storage/$_simulatedFileName',
      fileSizeBytes: _simulatedFileSize,
      documentNumber: _docNumberController.text.trim().isEmpty
          ? null
          : _docNumberController.text.trim(),
      issuer: _issuerController.text.trim().isEmpty
          ? null
          : _issuerController.text.trim(),
      createdAt: DateTime.now(),
      isVaultProtected: _isVaultProtected,
    );

    await ref.read(documentListProvider.notifier).addDocument(newDoc);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen berhasil ditambahkan ke Cardly')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Dokumen')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Sumber Dokumen',
                style: AppTypography.titleMedium(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Import dari kamera, galeri foto, atau file PDF perangkat Anda.',
                style: AppTypography.bodySmall(context)
                    .copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3 Sources
              Row(
                children: [
                  Expanded(
                    child: _buildSourceCard(
                      context,
                      icon: Icons.camera_alt_outlined,
                      label: 'Pindai Kamera',
                      onTap: () => context.push('/scan'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildSourceCard(
                      context,
                      icon: Icons.photo_library_outlined,
                      label: 'Galeri Foto',
                      onTap: () => _chooseSource(
                        'Galeri',
                        DocumentFileType.jpg,
                        'foto_dokumen.jpg',
                        840000,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildSourceCard(
                      context,
                      icon: Icons.upload_file_outlined,
                      label: 'Berkas PDF',
                      onTap: () => _chooseSource(
                        'Berkas',
                        DocumentFileType.pdf,
                        'berkas_dokumen.pdf',
                        2100000,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Selected file banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(color: AppColors.lime, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: isDark ? AppColors.lime : AppColors.ink,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _simulatedFileName,
                            style: AppTypography.bodyMedium(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                          Text(
                            'Tipe: ${_selectedFileType.name.toUpperCase()} • Tersedia secara lokal',
                            style: AppTypography.caption(context)
                                .copyWith(color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Informasi Dokumen',
                style: AppTypography.titleMedium(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              CardlyTextField(
                controller: _titleController,
                label: 'Nama Dokumen',
                hint: 'cth. KTP Elektronik, SIM A',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama dokumen wajib diisi'
                    : null,
              ),

              const SizedBox(height: AppSpacing.md),

              // Category dropdown
              DropdownButtonFormField<DocumentCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori Dokumen',
                ),
                items: DocumentCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Document Number
              CardlyTextField(
                controller: _docNumberController,
                label: 'Nomor Dokumen (Opsional)',
                hint: 'cth. 3171010190001',
              ),

              const SizedBox(height: AppSpacing.md),

              // Issuer
              CardlyTextField(
                controller: _issuerController,
                label: 'Instansi Penerbit (Opsional)',
                hint: 'cth. Disdukcapil DKI Jakarta, Kepolisian RI',
              ),

              const SizedBox(height: AppSpacing.lg),

              // Vault Protection Switch
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Proteksi dengan Brankas Aman',
                  style: AppTypography.bodyMedium(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Memerlukan otentikasi biometrik atau PIN untuk membuka pratinjau dokumen ini.',
                  style: AppTypography.bodySmall(context)
                      .copyWith(color: AppColors.mutedText),
                ),
                value: _isVaultProtected,
                activeThumbColor: AppColors.lime,
                activeTrackColor: AppColors.ink,
                onChanged: (val) => setState(() => _isVaultProtected = val),
              ),

              const SizedBox(height: AppSpacing.xl),

              CardlyButton(text: 'Simpan Dokumen', onPressed: _saveDocument),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isDark ? AppColors.white : AppColors.ink,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.caption(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.ink,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
