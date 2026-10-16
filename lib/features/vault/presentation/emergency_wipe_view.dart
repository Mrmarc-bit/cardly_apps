import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_text_field.dart';
import '../../../core/widgets/cardly_toast.dart';

class EmergencyWipeView extends ConsumerStatefulWidget {
  const EmergencyWipeView({super.key});

  @override
  ConsumerState<EmergencyWipeView> createState() => _EmergencyWipeViewState();
}

class _EmergencyWipeViewState extends ConsumerState<EmergencyWipeView> {
  final _confirmationController = TextEditingController();
  bool _isMatch = false;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(() {
      final matches = _confirmationController.text.trim() == 'HAPUS';
      if (matches != _isMatch) {
        setState(() => _isMatch = matches);
      }
    });
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  void _executeWipe() async {
    final db = ref.read(appDatabaseProvider);
    await db.wipeAllData();

    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.clearAll();

    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.clearAll();

    ref.read(cardListProvider.notifier).refresh();
    ref.read(documentListProvider.notifier).refresh();
    ref.read(reminderListProvider.notifier).refresh();

    if (mounted) {
      CardlyToast.showSuccess(
        context,
        'Seluruh data lokal berhasil dihapus secara permanen.',
      );
      // Navigate to welcome
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hapus Data Lokal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tindakan Destruktif Permanen',
              style: AppTypography.display(context).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Semua kartu pembayaran tersimpan, dokumen identitas, scan berkas, pengaturan brankas, dan kunci enkripsi pada perangkat ini akan dihapus tuntas.',
              style: AppTypography.bodySmall(context)
                  .copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.error),
              ),
              child: const Text(
                'PERINGATAN: Tindakan ini tidak dapat dibatalkan. Cardly tidak memiliki server pusat, sehingga data yang terhapus tidak dapat dipulihkan oleh siapa pun.',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Ketik "HAPUS" untuk konfirmasi:',
              style: AppTypography.titleSmall(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),

            CardlyTextField(
              controller: _confirmationController,
              hint: 'Ketik HAPUS dengan huruf kapital',
            ),

            const SizedBox(height: AppSpacing.xl),

            CardlyButton(
              text: 'Hapus Seluruh Data Sekarang',
              variant: CardlyButtonVariant.destructive,
              icon: Icons.delete_forever,
              onPressed: _isMatch ? _executeWipe : null,
            ),

            const SizedBox(height: AppSpacing.md),

            CardlyButton(
              text: 'Batalkan dan Kembali',
              variant: CardlyButtonVariant.quiet,
              onPressed: () => context.pop(),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
