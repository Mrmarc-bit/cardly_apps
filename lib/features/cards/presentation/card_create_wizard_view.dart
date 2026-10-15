import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_text_field.dart';
import '../../../core/widgets/cardly_visual_card.dart';
import '../../../core/widgets/cardly_notice_banner.dart';
import '../../../app/providers.dart';
import '../domain/card_model.dart';

class CardCreateWizardView extends ConsumerStatefulWidget {
  const CardCreateWizardView({super.key});

  @override
  ConsumerState<CardCreateWizardView> createState() =>
      _CardCreateWizardViewState();
}

class _CardCreateWizardViewState extends ConsumerState<CardCreateWizardView> {
  int _currentStep =
      1; // 1: Kategori, 2: Detail, 3: Tampilan, 4: Ringkasan, 5: Sukses

  CardCategory _category = CardCategory.pembayaran;
  final TextEditingController _nicknameController = TextEditingController(
    text: 'Harian',
  );
  final TextEditingController _issuerController = TextEditingController(
    text: 'Bank Central Asia',
  );
  final TextEditingController _digitsController = TextEditingController(
    text: '4582',
  );
  String _network = 'Visa';
  CardColorTheme _colorTheme = CardColorTheme.lime;

  String? _digitsError;
  String? _nicknameError;

  @override
  void dispose() {
    _nicknameController.dispose();
    _issuerController.dispose();
    _digitsController.dispose();
    super.dispose();
  }

  void _validateAndProceedStep2() {
    setState(() {
      _nicknameError = null;
      _digitsError = null;
    });

    final nick = _nicknameController.text.trim();
    final digits = _digitsController.text.trim();

    if (nick.isEmpty) {
      setState(() => _nicknameError = 'Nama panggilan wajib diisi.');
      return;
    }

    if (_category == CardCategory.pembayaran) {
      if (digits.length != 4) {
        setState(() => _digitsError = 'Nomor wajib tepat 4 digit terakhir.');
        return;
      }
    }

    setState(() => _currentStep = 3);
  }

  void _saveCard() async {
    final newCard = CardItem(
      id: const Uuid().v4(),
      category: _category,
      nickname: _nicknameController.text.trim(),
      issuer: _issuerController.text.trim(),
      network: _network,
      lastFourDigits: _digitsController.text.trim(),
      colorTheme: _colorTheme,
    );

    await ref.read(cardListProvider.notifier).addCard(newCard);
    setState(() => _currentStep = 5); // Tampilkan Layar Sukses
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentStep == 5) {
      return _buildSuccessScreen(isDark);
    }

    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 1) {
          setState(() => _currentStep -= 1);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.ink : AppColors.mist,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentStep > 1) {
                setState(() => _currentStep -= 1);
              } else {
                context.pop();
              }
            },
          ),
          title: Text(_getAppBarTitle()),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.softGray,
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                'LANGKAH $_currentStep DARI 4',
                style: AppTypography.tinyLabel.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: _buildStepContent(isDark),
          ),
        ),
        bottomSheet: Container(
          color: isDark ? AppColors.ink : AppColors.mist,
          padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
          child: _buildBottomButton(),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 1:
        return 'Tambah Kartu';
      case 2:
        return 'Detail kartu baru';
      case 3:
        return 'Tampilan kartu';
      case 4:
        return 'Ringkasan kartu';
      default:
        return 'Tambah Kartu';
    }
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Category(isDark);
      case 2:
        return _buildStep2Details(isDark);
      case 3:
        return _buildStep3Theme(isDark);
      case 4:
        return _buildStep4Review(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: Pilih Kategori ---
  Widget _buildStep1Category(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kartu apa yang ingin disimpan?',
          style: AppTypography.largeHeading.copyWith(
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          'Pilih kategori agar detail dan pengingat tetap relevan.',
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
          ),
        ),
        const SizedBox(height: 24.0),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : AppColors.white,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.elevatedDark : AppColors.softGray,
            ),
          ),
          child: Column(
            children: CardCategory.values.map((cat) {
              final isSelected = _category == cat;
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _category = cat;
                    _currentStep = 2;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(cat),
                        size: 22.0,
                        color: isSelected
                            ? (isDark ? AppColors.white : AppColors.ink)
                            : (isDark ? AppColors.mediumGray : AppColors.muted),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Text(
                          'Kartu ${cat.label.toLowerCase()}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20.0,
                        color: isDark ? AppColors.mediumGray : AppColors.muted,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 80.0),
      ],
    );
  }

  IconData _getCategoryIcon(CardCategory cat) {
    switch (cat) {
      case CardCategory.pembayaran:
        return Icons.credit_card_outlined;
      case CardCategory.identitas:
        return Icons.badge_outlined;
      case CardCategory.pendidikan:
        return Icons.school_outlined;
      case CardCategory.kesehatan:
        return Icons.favorite_border_rounded;
      case CardCategory.keanggotaan:
        return Icons.card_membership_rounded;
      case CardCategory.kendaraan:
        return Icons.directions_car_outlined;
      case CardCategory.lainnya:
        return Icons.layers_outlined;
    }
  }

  // --- STEP 2: Detail Metadata ---
  Widget _buildStep2Details(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardlyTextField(
          controller: _nicknameController,
          label: 'Nama panggilan',
          hintText: 'Misal: Harian, KTP Utama, Dompet',
          errorText: _nicknameError,
        ),
        const SizedBox(height: 16.0),
        CardlyTextField(
          controller: _issuerController,
          label: 'Penerbit',
          hintText: 'Misal: BCA, Mandiri, Kemendagri',
        ),
        const SizedBox(height: 16.0),
        // Dropdown Jaringan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jaringan / Tipe',
              style: AppTypography.captionMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
              ),
            ),
            const SizedBox(height: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.white,
                borderRadius: AppRadius.inputRadius,
                border: Border.all(
                  color: isDark ? AppColors.elevatedDark : AppColors.softGray,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _network,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.charcoal : AppColors.white,
                  items: ['Visa', 'Mastercard', 'GPN', 'Identitas', 'Lainnya']
                      .map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: AppTypography.body.copyWith(
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _network = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        CardlyTextField(
          controller: _digitsController,
          label: 'Empat digit terakhir',
          hintText: '4582',
          keyboardType: TextInputType.number,
          maxLength: 4,
          errorText: _digitsError,
        ),
        const SizedBox(height: 8.0),
        Text(
          'Hanya 4 digit. Jangan masukkan nomor kartu lengkap.',
          style: AppTypography.caption.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
          ),
        ),
        const SizedBox(height: 24.0),
        const CardlyNoticeBanner(
          variant: NoticeBannerVariant.info,
          title: 'Tidak untuk kredensial pembayaran',
          description:
              'Cardly tidak meminta CVV, PIN, atau nomor kartu lengkap.',
        ),
        const SizedBox(height: 80.0),
      ],
    );
  }

  // --- STEP 3: Tampilan Warna Kartu ---
  Widget _buildStep3Theme(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Preview
        CardlyVisualCard(
          nickname: _nicknameController.text.isNotEmpty
              ? _nicknameController.text
              : 'Harian',
          issuer: _issuerController.text.isNotEmpty
              ? _issuerController.text
              : 'Bank Central Asia',
          lastFourDigits: _digitsController.text.isNotEmpty
              ? _digitsController.text
              : '4582',
          category: _category.label,
          network: _network,
          colorTheme: _colorTheme,
        ),
        const SizedBox(height: 28.0),
        Text(
          'Buat mudah dikenali.',
          style: AppTypography.largeHeading.copyWith(
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          'Warna hanya mengubah tampilan di Cardly, bukan kartu asli.',
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
          ),
        ),
        const SizedBox(height: 24.0),
        // 4 Pilihan Warna (Lime, Black, White, Gray)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: CardColorTheme.values.map((theme) {
            final isSelected = _colorTheme == theme;
            return GestureDetector(
              onTap: () => setState(() => _colorTheme = theme),
              child: Column(
                children: [
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.ink
                            : (isDark
                                  ? AppColors.elevatedDark
                                  : AppColors.softGray),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: theme.textColor, size: 24.0)
                        : null,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    theme.name.toUpperCase(),
                    style: AppTypography.tinyLabel.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 80.0),
      ],
    );
  }

  // --- STEP 4: Ringkasan & Konfirmasi ---
  Widget _buildStep4Review(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardlyVisualCard(
          nickname: _nicknameController.text,
          issuer: _issuerController.text,
          lastFourDigits: _digitsController.text,
          category: _category.label,
          network: _network,
          colorTheme: _colorTheme,
        ),
        const SizedBox(height: 24.0),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : AppColors.white,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: isDark ? AppColors.elevatedDark : AppColors.softGray,
            ),
          ),
          child: Column(
            children: [
              _buildReviewRow('Nama', _nicknameController.text, isDark),
              const Divider(),
              _buildReviewRow('Penerbit', _issuerController.text, isDark),
              const Divider(),
              _buildReviewRow(
                'Nomor',
                '•••• ${_digitsController.text}',
                isDark,
              ),
              const Divider(),
              _buildReviewRow('Jaringan', _network, isDark),
            ],
          ),
        ),
        const SizedBox(height: 20.0),
        const CardlyNoticeBanner(
          variant: NoticeBannerVariant.info,
          title: 'Periksa sekali lagi',
          description: 'Pastikan data 4 digit nomor kartu dan nama penerbit sudah sesuai.',
        ),
        const SizedBox(height: 80.0),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySemiBold.copyWith(
              color: isDark ? AppColors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    switch (_currentStep) {
      case 1:
        return CardlyPrimaryButton(
          text: 'Lanjut ke detail',
          onPressed: () => setState(() => _currentStep = 2),
        );
      case 2:
        return CardlyPrimaryButton(
          text: 'Lanjut ke tampilan',
          onPressed: _validateAndProceedStep2,
        );
      case 3:
        return CardlyPrimaryButton(
          text: 'Lanjut ke ringkasan',
          onPressed: () => setState(() => _currentStep = 4),
        );
      case 4:
        return CardlyPrimaryButton(text: 'Simpan Kartu', onPressed: _saveCard);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 5: Layar Sukses (45 Kartu tersimpan) ---
  Widget _buildSuccessScreen(bool isDark) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.ink : AppColors.mist,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 48.0),
                    Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: const BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 44.0,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      '${_nicknameController.text} siap ditemukan.',
                      style: AppTypography.largeHeading.copyWith(
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Metadata kartu berhasil disimpan ke dompet Anda.',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32.0),
                    CardlyVisualCard(
                      nickname: _nicknameController.text,
                      issuer: _issuerController.text,
                      lastFourDigits: _digitsController.text,
                      category: _category.label,
                      network: _network,
                      colorTheme: _colorTheme,
                    ),
                  ],
                ),
                Column(
                  children: [
                    CardlyPrimaryButton(
                      text: 'Lihat kartu',
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: 12.0),
                    CardlySecondaryButton(
                      text: 'Kembali ke Beranda',
                      onPressed: () => context.go('/shell'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
