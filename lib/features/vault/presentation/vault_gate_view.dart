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
import '../../documents/domain/document_model.dart';

import 'pin_screen.dart';

class VaultGateView extends ConsumerStatefulWidget {
  const VaultGateView({super.key});

  @override
  ConsumerState<VaultGateView> createState() => _VaultGateViewState();
}

class _VaultGateViewState extends ConsumerState<VaultGateView> {
  void _authenticateAndUnlock() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final hasPin = await secureStorage.hasAppPin();
    final userProfile = ref.read(userProfileProvider);

    if (!hasPin) {
      if (!mounted) return;
      // Belum ada PIN, arahkan pengguna membuat PIN pertama kali
      final created = await PinScreen.showAsBottomSheet(
        context,
        mode: PinScreenMode.create,
        title: 'Buat PIN Brankas Baru',
        subtitle: 'Atur 6 digit PIN untuk mengamankan brankas dokumen rahasia.',
      );
      if (created == true && mounted) {
        ref.read(vaultLockedProvider.notifier).unlock();
        CardlyToast.showSuccess(
          context,
          'PIN dibuat & Brankas berhasil dibuka!',
        );
      }
      return;
    }

    if (userProfile.isBiometricActive) {
      // Jika biometrik aktif, tawarkan dialog biometrik dengan fallback PIN
      if (!mounted) return;
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
              child: const Icon(
                Icons.fingerprint,
                size: 36,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Verifikasi Biometrik Cardly',
              style: AppTypography.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sentuh sensor sidik jari atau gunakan PIN 6-digit untuk membuka Brankas Dokumen.',
              style: AppTypography.bodySmall(context)
                  .copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            CardlyButton(
              text: 'Buka dengan Biometrik',
              icon: Icons.fingerprint,
              onPressed: () async {
                final biometricService = ref.read(biometricServiceProvider);
                final authRes = await biometricService.authenticateDetailed(
                  localizedReason: 'Pindai sidik jari atau Face ID untuk membuka Brankas Dokumen.',
                );
                if (!mounted) return;
                if (authRes.success) {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                  ref.read(vaultLockedProvider.notifier).unlock();
                  CardlyToast.showSuccess(
                    context,
                    'Brankas berhasil dibuka dengan biometrik',
                  );
                } else {
                  HapticFeedback.vibrate();
                  CardlyToast.showError(
                    context,
                    authRes.errorMessage ?? 'Verifikasi biometrik tidak cocok.',
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            CardlyButton(
              text: 'Gunakan PIN 6-Digit',
              variant: CardlyButtonVariant.quiet,
              onPressed: () {
                Navigator.pop(context);
                _promptPinUnlock();
              },
            ),
          ],
        ),
      );
    } else {
      // Langsung buka layar input PIN 6-Digit resmi
      _promptPinUnlock();
    }
  }

  void _promptPinUnlock() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final hasPin = await secureStorage.hasAppPin();

    if (!mounted) return;
    final success = await PinScreen.showAsBottomSheet(
      context,
      mode: hasPin ? PinScreenMode.verify : PinScreenMode.create,
      title: hasPin ? 'Buka Brankas Dokumen' : 'Buat PIN Brankas Baru',
      subtitle: hasPin
          ? 'Masukkan 6 digit PIN untuk membuka dokumen rahasia.'
          : 'Atur 6 digit PIN untuk pertama kali membuka Brankas.',
    );

    if (success == true && mounted) {
      ref.read(vaultLockedProvider.notifier).unlock();
      CardlyToast.showSuccess(context, 'Brankas berhasil dibuka');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(vaultLockedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final documents = ref.watch(documentListProvider);
    final vaultDocs = documents.where((d) => d.isVaultProtected).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brankas'),
        actions: [
          if (!isLocked)
            TextButton.icon(
              onPressed: () {
                ref.read(vaultLockedProvider.notifier).lock();
                CardlyToast.showSuccess(
                  context,
                  'Brankas berhasil dikunci kembali',
                );
              },
              icon: const Icon(Icons.lock, size: 18, color: AppColors.error),
              label: Text(
                'Kunci',
                style: AppTypography.caption(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: AppColors.error),
              ),
            ),
          IconButton(
            tooltip: 'Pengaturan Keamanan',
            icon: const Icon(Icons.security),
            onPressed: () => context.push('/vault/security'),
          ),
        ],
      ),
      body: isLocked
          ? _buildLockedView(context, isDark)
          : _buildUnlockedView(context, isDark, vaultDocs),
    );
  }

  Widget _buildLockedView(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenInset),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.softGray,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 48,
                color: isDark ? AppColors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Brankas Terkunci',
              style: AppTypography.display(context).copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ruang penyimpanan dokumen terenkripsi. Otentikasi identitas Anda menggunakan biometrik atau PIN untuk melihat dokumen rahasia.',
              style: AppTypography.bodySmall(context)
                  .copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            CardlyButton(
              text: 'Buka dengan Biometrik / PIN',
              icon: Icons.fingerprint,
              onPressed: _authenticateAndUnlock,
            ),
            const SizedBox(height: AppSpacing.md),
            CardlyButton(
              text: 'Pengaturan Keamanan',
              variant: CardlyButtonVariant.quiet,
              icon: Icons.shield_outlined,
              onPressed: () => context.push('/vault/security'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedView(
    BuildContext context,
    bool isDark,
    List<DocumentItem> vaultDocs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Unlocked
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: AppColors.lime),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_open, color: AppColors.ink),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesi Brankas Aktif',
                        style: AppTypography.titleSmall(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Brankas akan otomatis terkunci jika aplikasi diminimalkan.',
                        style: AppTypography.caption(context)
                            .copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Text(
            'Dokumen Sangat Rahasia (${vaultDocs.length})',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (vaultDocs.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.folder_shared_outlined,
                    size: 40,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Belum ada dokumen di dalam Brankas',
                    style: AppTypography.bodyMedium(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aktifkan proteksi brankas saat menambahkan dokumen baru.',
                    style: AppTypography.caption(context)
                        .copyWith(color: AppColors.mutedText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CardlyButton(
                    text: 'Tambah Dokumen ke Brankas',
                    onPressed: () => context.push('/documents/create'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vaultDocs.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final doc = vaultDocs[index];
                return ListTile(
                  tileColor: isDark
                      ? AppColors.darkCard
                      : AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  leading: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.lime,
                  ),
                  title: Text(
                    doc.title,
                    style: AppTypography.bodyMedium(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${doc.category.displayName} • ${CardlyFormatters.formatFileSize(doc.fileSizeBytes)}',
                    style: AppTypography.caption(context),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/documents/${doc.id}/private-view'),
                );
              },
            ),

          const SizedBox(height: AppSpacing.xl),

          CardlyButton(
            text: 'Kunci Brankas Sekarang',
            variant: CardlyButtonVariant.secondary,
            icon: Icons.lock_outline,
            onPressed: () {
              ref.read(vaultLockedProvider.notifier).lock();
              CardlyToast.showSuccess(context, 'Brankas berhasil dikunci');
            },
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
