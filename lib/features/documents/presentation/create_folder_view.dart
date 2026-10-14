import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../domain/folder_model.dart';

/// Halaman / Bottom sheet Buat Folder Cardly sesuai docs/5. Home/58 Buat folder.png & 58 Buat folder • Gelap.png
class CreateFolderView extends ConsumerStatefulWidget {
  const CreateFolderView({super.key});

  @override
  ConsumerState<CreateFolderView> createState() => _CreateFolderViewState();
}

class _CreateFolderViewState extends ConsumerState<CreateFolderView> {
  final _nameController = TextEditingController(text: 'Identitas pribadi');
  String _selectedLocation = 'Brankas';
  bool _isPrivate = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showLocationPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.charcoal : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.elevatedDark
                          : AppColors.softGray,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Pilih Lokasi Folder',
                  style: AppTypography.sectionHeading.copyWith(
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.lock_outline_rounded,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                  title: Text(
                    'Brankas',
                    style: AppTypography.bodySemiBold.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Penyimpanan terenkripsi dengan proteksi biometrik.',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.muted,
                    ),
                  ),
                  trailing: _selectedLocation == 'Brankas'
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.lime,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedLocation = 'Brankas');
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.folder_open_rounded,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                  title: Text(
                    'Dokumen Utama',
                    style: AppTypography.bodySemiBold.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Penyimpanan lokal dokumen umum.',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.muted,
                    ),
                  ),
                  trailing: _selectedLocation == 'Dokumen Utama'
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.lime,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedLocation = 'Dokumen Utama');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSubmit() {
    final folderName = _nameController.text.trim();
    if (folderName.isEmpty) return;

    final newFolder = FolderItem(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: folderName,
      location: _selectedLocation,
      isPrivate: _isPrivate,
      iconName: _selectedLocation == 'Brankas' ? 'lock' : 'folder',
      colorHex: '#C8F45A',
      createdAt: DateTime.now(),
    );

    ref.read(folderListProvider.notifier).createFolder(newFolder);
    CardlyToast.showSuccess(context, 'Folder "$folderName" berhasil dibuat.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.charcoal : AppColors.white;
    final borderColor = isDark ? AppColors.elevatedDark : AppColors.softGray;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Buat Folder',
          style: AppTypography.pageHeading.copyWith(
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12.0),

              // Ikon Hero Folder + Tengah (docs/5. Home/58 Buat folder.png)
              Center(
                child: SizedBox(
                  width: 80.0,
                  height: 68.0,
                  child: CustomPaint(
                    painter: _FolderIconPainter(
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32.0),

              // Input Kartu Tertutup: Nama Folder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.inputRadius,
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama folder',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    TextFormField(
                      controller: _nameController,
                      style: AppTypography.compactBodyMedium.copyWith(
                        fontSize: 16.0,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Dropdown Kartu Tertutup: Lokasi
              InkWell(
                onTap: () => _showLocationPicker(isDark),
                borderRadius: AppRadius.inputRadius,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppRadius.inputRadius,
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _selectedLocation,
                            style: AppTypography.compactBodyMedium.copyWith(
                              fontSize: 16.0,
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? AppColors.white : AppColors.ink,
                        size: 24.0,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Baris Sakelar: Dokumen pribadi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dokumen pribadi',
                          style: AppTypography.compactBodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Minta autentikasi saat membuka isi.',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isPrivate = !_isPrivate);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50.0,
                      height: 30.0,
                      padding: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: _isPrivate
                            ? AppColors.lime
                            : (isDark
                                  ? AppColors.elevatedDark
                                  : AppColors.softGray),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _isPrivate
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: BoxDecoration(
                            color: _isPrivate
                                ? AppColors.ink
                                : (isDark ? AppColors.white : AppColors.white),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24.0),

              // Kartu Edukasi / Keamanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.info,
                      size: 22.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Folder untuk mengelompokkan',
                            style: AppTypography.compactBodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.white : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Memindahkan dokumen tidak membuat salinan file baru.',
                            style: AppTypography.caption.copyWith(
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

              const SizedBox(height: 32.0),

              // Tombol Aksi Utama: Buat Folder
              CardlyPrimaryButton(
                text: 'Buat Folder',
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter untuk menggambar outline ikon folder Cardly dengan simbol plus
class _FolderIconPainter extends CustomPainter {
  final Color color;

  _FolderIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 12.0;

    // Garis outline folder dengan tab di atas
    path.moveTo(r, 10.0);
    path.lineTo(w * 0.35, 10.0);
    path.quadraticBezierTo(w * 0.42, 10.0, w * 0.48, 16.0);
    path.lineTo(w - r, 16.0);
    path.quadraticBezierTo(w, 16.0, w, 16.0 + r);
    path.lineTo(w, h - r);
    path.quadraticBezierTo(w, h, w - r, h);
    path.lineTo(r, h);
    path.quadraticBezierTo(0, h, 0, h - r);
    path.lineTo(0, 10.0 + r);
    path.quadraticBezierTo(0, 10.0, r, 10.0);
    path.close();

    canvas.drawPath(path, paint);

    // Simbol plus di tengah folder
    final centerX = w / 2;
    final centerY = (h + 16.0) / 2;
    const plusSize = 9.0;

    canvas.drawLine(
      Offset(centerX - plusSize, centerY),
      Offset(centerX + plusSize, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - plusSize),
      Offset(centerX, centerY + plusSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _FolderIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
