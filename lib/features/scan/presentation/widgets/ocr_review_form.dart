import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cardly_buttons.dart';
import '../../../../core/widgets/cardly_text_field.dart';
import '../../data/document_scan_service.dart';

/// Layar Tinjau Hasil OCR & Koreksi Manual Lengkap (Screen 23: Tinjau hasil OCR)
/// Menyesuaikan formulir secara cerdas dan otomatis untuk KTP, SIM, Kartu Bank, dan Dokumen Fisik.
class OcrReviewForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController numberController;
  final TextEditingController nameController;
  final TextEditingController expiryController;
  final TextEditingController issuerController;

  // Detail Tambahan KTP / Identitas
  final TextEditingController? birthPlaceDateController;
  final TextEditingController? genderController;
  final TextEditingController? bloodTypeController;
  final TextEditingController? addressController;
  final TextEditingController? rtRwController;
  final TextEditingController? kelDesaController;
  final TextEditingController? kecamatanController;
  final TextEditingController? religionController;
  final TextEditingController? maritalStatusController;
  final TextEditingController? occupationController;
  final TextEditingController? nationalityController;

  // Detail Tambahan Kartu Bank
  final TextEditingController? bankNameController;
  final TextEditingController? last4Controller;

  // Status & Tipe
  final RecognizedDocumentType recognizedType;
  final bool isLifetimeExpiry;
  final ValueChanged<bool> onLifetimeToggle;
  final bool isVaultProtected;
  final ValueChanged<bool> onVaultToggle;
  final bool autoSetReminder;
  final ValueChanged<bool> onReminderToggle;
  final String? imagePath;

  // Tindakan
  final VoidCallback? onBack;
  final VoidCallback? onRetake;
  final VoidCallback? onEditCrop;
  final VoidCallback onSaveDocument;
  final VoidCallback onSaveCard;

  const OcrReviewForm({
    super.key,
    required this.titleController,
    required this.numberController,
    required this.nameController,
    required this.expiryController,
    required this.issuerController,
    this.birthPlaceDateController,
    this.genderController,
    this.bloodTypeController,
    this.addressController,
    this.rtRwController,
    this.kelDesaController,
    this.kecamatanController,
    this.religionController,
    this.maritalStatusController,
    this.occupationController,
    this.nationalityController,
    this.bankNameController,
    this.last4Controller,
    this.recognizedType = RecognizedDocumentType.generalDocument,
    required this.isLifetimeExpiry,
    required this.onLifetimeToggle,
    required this.isVaultProtected,
    required this.onVaultToggle,
    required this.autoSetReminder,
    required this.onReminderToggle,
    this.imagePath,
    this.onBack,
    this.onRetake,
    this.onEditCrop,
    required this.onSaveDocument,
    required this.onSaveCard,
  });

  @override
  State<OcrReviewForm> createState() => _OcrReviewFormState();
}

class _OcrReviewFormState extends State<OcrReviewForm> {
  late RecognizedDocumentType _activeType;

  @override
  void initState() {
    super.initState();
    _activeType = widget.recognizedType;
  }

  @override
  void didUpdateWidget(covariant OcrReviewForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recognizedType != widget.recognizedType) {
      _activeType = widget.recognizedType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.ink : AppColors.mist,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.0,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali ke panduan pindai',
        ),
        title: Text(
          'Tinjau Hasil OCR',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
        actions: [
          if (widget.onRetake != null)
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppColors.lime : AppColors.ink,
              ),
              onPressed: widget.onRetake,
              tooltip: 'Pindai ulang berkas',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: 16.0,
        ),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Badge Hasil Ekstraksi On-Device & Status Dokumen Terdeteksi
            _buildSmartDetectionBadge(isDark),

            const SizedBox(height: 12.0),

            // Pengalih Tipe Dokumen Manual & Cepat
            _buildDocumentTypeSelector(isDark),

            const SizedBox(height: 16.0),

            // 2. Card Hero Preview dengan Sudut Rounded Fisik (ISO/IEC 7810 ID-1 standard)
            _buildCardPreview(isDark),

            const SizedBox(height: 24.0),

            // 3. Form Input Field Lengkap yang Menyesuaikan Jenis Dokumen
            if (_activeType == RecognizedDocumentType.ktp) ...[
              _buildKtpDetailedForm(isDark),
            ] else if (_activeType == RecognizedDocumentType.bankCard) ...[
              _buildBankCardForm(isDark),
            ] else ...[
              _buildGeneralDocumentForm(isDark),
            ],

            const SizedBox(height: 20.0),

            // 4. Opsi Pengingat Cerdas Masa Berlaku
            if (!widget.isLifetimeExpiry) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
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
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: AppColors.lime.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.lime,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pasang Pengingat Masa Berlaku',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                          Text(
                            'Ingatkan 30 hari sebelum kedaluwarsa',
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
                    Switch(
                      value: widget.autoSetReminder,
                      onChanged: widget.onReminderToggle,
                      activeThumbColor: AppColors.lime,
                      activeTrackColor: AppColors.lime.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
            ],

            // 5. Opsi Keamanan Brankas Pribadi
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
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
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: AppColors.lime.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.lime,
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kunci di Brankas Pribadi',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                        Text(
                          'Wajib PIN / Biometrik untuk melihat pratinjau',
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
                  Switch(
                    value: widget.isVaultProtected,
                    onChanged: widget.onVaultToggle,
                    activeThumbColor: AppColors.lime,
                    activeTrackColor: AppColors.lime.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28.0),

            // 6. Tombol Simpan Berkas
            Text(
              'PILIH PENYIMPANAN TUJUAN',
              style: AppTypography.captionStyle.copyWith(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.6)
                    : AppColors.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12.0),

            CardlyButton(
              text: 'Simpan ke Dokumen Penting',
              icon: Icons.description_outlined,
              onPressed: widget.onSaveDocument,
            ),

            const SizedBox(height: 12.0),

            CardlyButton(
              text: 'Simpan ke Dompet Kartu',
              variant: CardlyButtonVariant.secondary,
              icon: Icons.credit_card_outlined,
              onPressed: widget.onSaveCard,
            ),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  // --- Sub-widgets Komponen Tinjau OCR ---

  Widget _buildDocumentTypeSelector(bool isDark) {
    final types = [
      (RecognizedDocumentType.ktp, 'e-KTP', Icons.badge_outlined),
      (
        RecognizedDocumentType.bankCard,
        'Kartu Bank',
        Icons.credit_card_outlined,
      ),
      (
        RecognizedDocumentType.generalDocument,
        'Dokumen Umum',
        Icons.description_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.charcoal
            : AppColors.softGray.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: types.map((item) {
          final isSelected = _activeType == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _activeType = item.$1;
                  if (_activeType == RecognizedDocumentType.ktp &&
                      (widget.titleController.text.isEmpty ||
                          widget.titleController.text.contains('Dokumen'))) {
                    widget.titleController.text = 'KTP Republik Indonesia';
                  } else if (_activeType == RecognizedDocumentType.bankCard &&
                      (widget.titleController.text.isEmpty ||
                          widget.titleController.text.contains('Dokumen'))) {
                    widget.titleController.text = 'Kartu Debit / Bank';
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.lime : AppColors.ink)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.control - 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      size: 15.0,
                      color: isSelected
                          ? (isDark ? AppColors.ink : AppColors.white)
                          : (isDark ? AppColors.mutedText : AppColors.muted),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppColors.ink : AppColors.white)
                            : (isDark
                                  ? AppColors.white.withValues(alpha: 0.8)
                                  : AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSmartDetectionBadge(bool isDark) {
    String badgeTitle = 'Ekstraksi Teks On-Device (Offline)';
    String badgeSubtitle =
        'Harap periksa dan koreksi data di bawah sebelum menyimpan berkas.';
    IconData badgeIcon = Icons.auto_awesome_rounded;

    if (_activeType == RecognizedDocumentType.ktp) {
      badgeTitle = 'KTP Republik Indonesia (e-KTP)';
      badgeSubtitle =
          'Format NIK 16 digit, data personal, dan alamat terdeteksi otomatis.';
      badgeIcon = Icons.verified_user_rounded;
    } else if (_activeType == RecognizedDocumentType.bankCard) {
      badgeTitle = 'Kartu Bank / Debit Terdeteksi';
      badgeSubtitle = 'Penerbit dan 4 digit terakhir berhasil dibaca secara aman (PCI-DSS).';
      badgeIcon = Icons.account_balance_wallet_rounded;
    } else if (_activeType == RecognizedDocumentType.sim) {
      badgeTitle = 'Surat Izin Mengemudi (SIM)';
      badgeSubtitle =
          'Nomor registrasi pengemudi dan tanggal berlaku terdeteksi.';
      badgeIcon = Icons.directions_car_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.lime.withValues(alpha: 0.15)
            : AppColors.lime.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.lime, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 34.0,
            height: 34.0,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: AppColors.ink, size: 19.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeTitle,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  badgeSubtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(bool isDark) {
    final hasImage =
        widget.imagePath != null && File(widget.imagePath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.08)
              : AppColors.softGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail dengan Sudut Rounded Proporsional (ISO 7810 ID-1)
          GestureDetector(
            onTap: widget.onEditCrop,
            child: Container(
              width: 72.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevatedDark : AppColors.softGray,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: AppColors.lime.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.5),
                      child: Image.file(
                        File(widget.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.credit_card_rounded,
                        color: AppColors.lime,
                        size: 26.0,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titleController.text.isNotEmpty
                      ? widget.titleController.text
                      : 'Dokumen Baru',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  widget.numberController.text.isNotEmpty
                      ? widget.numberController.text
                      : 'Nomor Belum Ditentukan',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontFamily: 'monospace',
                    color: AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13.0,
                      color: AppColors.lime,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Auto-crop aktif',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.onEditCrop != null)
            InkWell(
              onTap: widget.onEditCrop,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.softGray,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.crop_rotate_rounded,
                      size: 14.0,
                      color: isDark ? AppColors.lime : AppColors.ink,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'Sesuaikan',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Form Spesifik KTP (Lengkap & Otomatis) ---

  Widget _buildKtpDetailedForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('INFORMASI IDENTITAS POKOK', isDark),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.titleController,
          label: 'Nama Dokumen',
          hintText: 'KTP Republik Indonesia',
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.numberController,
          label: 'Nomor Induk Kependudukan (NIK)',
          hintText: '16 digit angka resmi',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.nameController,
          label: 'Nama Lengkap (Sesuai KTP)',
          hintText: 'Nama lengkap pemilik',
        ),
        const SizedBox(height: 12.0),

        if (widget.birthPlaceDateController != null) ...[
          CardlyTextField(
            controller: widget.birthPlaceDateController,
            label: 'Tempat / Tanggal Lahir',
            hintText: 'Contoh: JAKARTA, 01-01-1990',
          ),
          const SizedBox(height: 12.0),
        ],

        Row(
          children: [
            Expanded(
              child: CardlyTextField(
                controller: widget.genderController,
                label: 'Jenis Kelamin',
                hintText: 'LAKI-LAKI / PEREMPUAN',
              ),
            ),
            const SizedBox(width: 10.0),
            SizedBox(
              width: 110.0,
              child: CardlyTextField(
                controller: widget.bloodTypeController,
                label: 'Gol. Darah',
                hintText: 'A / B / AB / O',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20.0),
        _buildSectionHeader('ALAMAT & WILAYAH DOMISILI', isDark),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.addressController,
          label: 'Alamat Lengkap',
          hintText: 'Jalan, Gang, atau Nomor Rumah',
        ),
        const SizedBox(height: 12.0),

        Row(
          children: [
            SizedBox(
              width: 120.0,
              child: CardlyTextField(
                controller: widget.rtRwController,
                label: 'RT / RW',
                hintText: '001/002',
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: CardlyTextField(
                controller: widget.kelDesaController,
                label: 'Kelurahan / Desa',
                hintText: 'Kelurahan domisili',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.kecamatanController,
          label: 'Kecamatan',
          hintText: 'Kecamatan domisili',
        ),

        const SizedBox(height: 20.0),
        _buildSectionHeader('STATUS & LEGALITAS KTP', isDark),
        const SizedBox(height: 12.0),

        Row(
          children: [
            Expanded(
              child: CardlyTextField(
                controller: widget.religionController,
                label: 'Agama',
                hintText: 'ISLAM / LAINNYA',
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: CardlyTextField(
                controller: widget.maritalStatusController,
                label: 'Status Perkawinan',
                hintText: 'KAWIN / BELUM KAWIN',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        Row(
          children: [
            Expanded(
              child: CardlyTextField(
                controller: widget.occupationController,
                label: 'Pekerjaan',
                hintText: 'KARYAWAN SWASTA / LAINNYA',
              ),
            ),
            const SizedBox(width: 10.0),
            SizedBox(
              width: 100.0,
              child: CardlyTextField(
                controller: widget.nationalityController,
                label: 'Warga',
                hintText: 'WNI',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        _buildExpiryField(isDark),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.issuerController,
          label: 'Instansi Penerbit',
          hintText: 'Disdukcapil RI',
        ),
      ],
    );
  }

  // --- Form Spesifik Kartu Bank / Pembayaran ---

  Widget _buildBankCardForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('INFORMASI KARTU BANK & FINANSIAL', isDark),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.titleController,
          label: 'Nama Kartu',
          hintText: 'Contoh: BCA Mastercard Debit',
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.issuerController,
          label: 'Bank Penerbit',
          hintText: 'Bank Central Asia (BCA)',
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.nameController,
          label: 'Nama Pemegang Kartu',
          hintText: 'Nama tercetak di kartu',
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.numberController,
          label: 'Nomor Kartu (4 Digit Terakhir Disamarkan)',
          hintText: '•••• •••• •••• 1234',
          readOnly: true,
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.expiryController,
          label: 'Masa Berlaku (Valid Thru)',
          hintText: 'MM/YY (Contoh: 12/28)',
        ),

        const SizedBox(height: 14.0),

        // Banner Keamanan Perbankan Standar PRD & AGENTS.md
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.control),
            border: Border.all(
              color: AppColors.lime.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.lime,
                size: 20.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'Cardly tidak pernah menyimpan 16 digit lengkap, PIN, atau CVV perbankan demi keamanan Anda.',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Form Dokumen Umum / SIM / Fisik A4 ---

  Widget _buildGeneralDocumentForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('INFORMASI BERKAS TERDETEKSI', isDark),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.titleController,
          label: 'Nama Dokumen / Kartu',
          hintText: 'Contoh: Ijazah, Sertifikat, SIM A',
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.numberController,
          label: 'Nomor Identitas / Registrasi',
          hintText: 'Nomor tertera pada berkas',
        ),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.nameController,
          label: 'Nama Lengkap Tertera',
          hintText: 'Nama pemilik berkas',
        ),
        const SizedBox(height: 12.0),

        _buildExpiryField(isDark),
        const SizedBox(height: 12.0),

        CardlyTextField(
          controller: widget.issuerController,
          label: 'Instansi / Lembaga Penerbit',
          hintText: 'Contoh: Korlantas Polri, Universitas, Dinas',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.captionStyle.copyWith(
        color: isDark
            ? AppColors.white.withValues(alpha: 0.6)
            : AppColors.muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildExpiryField(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CardlyTextField(
            controller: widget.expiryController,
            label: 'Masa Berlaku',
            hintText: widget.isLifetimeExpiry ? 'SEUMUR HIDUP' : 'DD/MM/YYYY',
            readOnly: widget.isLifetimeExpiry,
          ),
        ),
        const SizedBox(width: 12.0),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: FilterChip(
            label: const Text('Seumur Hidup'),
            selected: widget.isLifetimeExpiry,
            onSelected: (val) {
              widget.onLifetimeToggle(val);
              if (val) {
                widget.expiryController.text = 'SEUMUR HIDUP';
              } else {
                widget.expiryController.text = '31/12/2028';
              }
            },
            selectedColor: AppColors.lime,
            checkmarkColor: AppColors.ink,
            labelStyle: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: widget.isLifetimeExpiry
                  ? AppColors.ink
                  : (isDark ? AppColors.white : AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}
