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
import '../../../core/widgets/cardly_text_field.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../../core/widgets/cardly_visual_card.dart';
import '../domain/card_model.dart';

class CardEditView extends ConsumerStatefulWidget {
  final String cardId;

  const CardEditView({super.key, required this.cardId});

  @override
  ConsumerState<CardEditView> createState() => _CardEditViewState();
}

class _CardEditViewState extends ConsumerState<CardEditView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _holderController;
  late TextEditingController _numberController;
  late TextEditingController _issuerController;
  late TextEditingController _notesController;

  late CardCategory _selectedCategory;
  late CardVisualTheme _selectedTheme;
  DateTime? _selectedExpiry;
  late bool _isContactless;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final cards = ref.read(cardListProvider);
    final card = cards.firstWhere(
      (c) => c.id == widget.cardId,
      orElse: () => CardItem(
        id: '',
        title: '',
        holderName: '',
        lastFourDigits: '',
        issuer: '',
        category: CardCategory.other,
      ),
    );

    _titleController = TextEditingController(text: card.title);
    _holderController = TextEditingController(text: card.holderName);
    _numberController = TextEditingController(text: card.lastFourDigits);
    _issuerController = TextEditingController(text: card.issuer);
    _notesController = TextEditingController(text: card.notes ?? '');

    _selectedCategory = card.category;
    _selectedTheme = card.theme;
    _selectedExpiry = card.expiryDate;
    _isContactless = card.isContactless;

    _titleController.addListener(_markDirty);
    _holderController.addListener(_markDirty);
    _numberController.addListener(_markDirty);
    _issuerController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _holderController.dispose();
    _numberController.dispose();
    _issuerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool?> _showUnsavedChangesSheet() {
    return CardlyBottomSheet.show<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Perubahan Belum Disimpan',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ada modifikasi yang belum tersimpan. Jika keluar sekarang, seluruh perubahan akan hilang.',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          CardlyButton(
            text: 'Lanjutkan Edit',
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: AppSpacing.sm),
          CardlyButton(
            text: 'Tetap Keluar',
            variant: CardlyButtonVariant.quiet,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedCard = CardItem(
      id: widget.cardId,
      title: _titleController.text.trim(),
      holderName: _holderController.text.trim(),
      lastFourDigits: _numberController.text.trim(),
      issuer: _issuerController.text.trim(),
      category: _selectedCategory,
      theme: _selectedTheme,
      expiryDate: _selectedExpiry,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isContactless: _isContactless,
    );

    await ref.read(cardListProvider.notifier).updateCard(updatedCard);

    if (mounted) {
      CardlyToast.showSuccess(context, 'Perubahan kartu berhasil disimpan');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _showUnsavedChangesSheet();
        if (shouldLeave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Kartu'),
          actions: [
            TextButton(
              onPressed: _saveChanges,
              child: Text(
                'Simpan',
                style: AppTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.lime : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
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
                // Live visual preview
                CardlyVisualCard(
                  title: _titleController.text.isEmpty
                      ? 'Nama Kartu'
                      : _titleController.text,
                  holderName: _holderController.text.isEmpty
                      ? 'NAMA PEMILIK'
                      : _holderController.text,
                  maskedNumber: _selectedCategory == CardCategory.payment
                      ? CardlyFormatters.maskCardNumber(_numberController.text)
                      : _numberController.text,
                  expiryDate: _selectedExpiry != null
                      ? CardlyFormatters.formatExpiry(_selectedExpiry!)
                      : null,
                  issuer: _issuerController.text.isEmpty
                      ? 'Penerbit'
                      : _issuerController.text,
                  theme: _selectedTheme,
                  isContactless: _isContactless,
                  categoryName: _selectedCategory.displayName,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title / Nickname
                CardlyTextField(
                  controller: _titleController,
                  label: 'Nama / Label Kartu',
                  hint: 'cth. BCA Prioritas Harian',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Label kartu wajib diisi'
                      : null,
                ),

                const SizedBox(height: AppSpacing.md),

                // Holder name
                CardlyTextField(
                  controller: _holderController,
                  label: 'Nama Pemilik',
                  hint: 'cth. MA\'RUF AMIN',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama pemilik wajib diisi'
                      : null,
                ),

                const SizedBox(height: AppSpacing.md),

                // Number
                CardlyTextField(
                  controller: _numberController,
                  label: _selectedCategory == CardCategory.payment
                      ? '4 Digit Terakhir'
                      : 'Nomor Referensi',
                  hint: _selectedCategory == CardCategory.payment
                      ? 'cth. 4582'
                      : 'cth. 3171010190001',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    if (_selectedCategory == CardCategory.payment)
                      LengthLimitingTextInputFormatter(4),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nomor wajib diisi';
                    }
                    if (_selectedCategory == CardCategory.payment &&
                        v.trim().length != 4) {
                      return 'Hanya masukkan 4 digit terakhir';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Issuer
                CardlyTextField(
                  controller: _issuerController,
                  label: 'Bank / Penerbit',
                  hint: 'cth. Bank Central Asia',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Penerbit wajib diisi'
                      : null,
                ),

                const SizedBox(height: AppSpacing.md),

                // Expiry Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _selectedExpiry ??
                          DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedExpiry = picked;
                        _isDirty = true;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masa Berlaku',
                                style: AppTypography.caption(context)
                                    .copyWith(color: AppColors.mutedText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedExpiry != null
                                    ? CardlyFormatters.formatExpiry(
                                        _selectedExpiry!,
                                      )
                                    : 'Pilih tanggal kedaluwarsa (opsional)',
                                style: AppTypography.bodyMedium(context),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedExpiry != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedExpiry = null;
                                _isDirty = true;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Theme selection
                Text(
                  'Tema Visual Kartu',
                  style: AppTypography.titleSmall(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: CardVisualTheme.values.map((theme) {
                    final isSelected = _selectedTheme == theme;
                    final color = theme.backgroundColor;

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTheme = theme;
                            _isDirty = true;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.lime
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.lime.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: theme.textColor,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.md),

                // Contactless toggle
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Fitur Pembayaran Nirkontak (Contactless)',
                    style: AppTypography.bodyMedium(context),
                  ),
                  value: _isContactless,
                  activeThumbColor: AppColors.lime,
                  activeTrackColor: AppColors.ink,
                  onChanged: (val) {
                    setState(() {
                      _isContactless = val;
                      _isDirty = true;
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Notes
                CardlyTextField(
                  controller: _notesController,
                  label: 'Catatan Pribadi (Opsional)',
                  hint: 'cth. Kartu utama belanja bulanan',
                  maxLines: 3,
                ),

                const SizedBox(height: AppSpacing.xl),

                CardlyButton(text: 'Simpan Perubahan', onPressed: _saveChanges),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
