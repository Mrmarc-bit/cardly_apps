import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/cardly_toast.dart';
import 'pin_screen.dart';

class SecuritySettingsView extends ConsumerStatefulWidget {
  const SecuritySettingsView({super.key});

  @override
  ConsumerState<SecuritySettingsView> createState() =>
      _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends ConsumerState<SecuritySettingsView> {
  bool _useBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final enabled = await secureStorage.isBiometricEnabled();
    if (mounted) {
      setState(() => _useBiometrics = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secSettings = ref.watch(securitySettingsProvider);
    final secNotifier = ref.read(securitySettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan & Privasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Proteksi Brankas
            Text(
              'Proteksi & Kunci Otomatis',
              style: AppTypography.titleSmall(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Material(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Batas Waktu Kunci Otomatis'),
                    subtitle: Text(
                      'Terkunci setelah: ${secSettings.autoLockOption}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _showAutoLockPicker(secSettings.autoLockOption),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text(
                      'Otentikasi Biometrik (Face ID / Sidik Jari)',
                    ),
                    subtitle: const Text(
                      'Gunakan biometrik untuk membuka kunci',
                    ),
                    value: _useBiometrics,
                    activeThumbColor: AppColors.lime,
                    activeTrackColor: AppColors.ink,
                    onChanged: (val) async {
                      if (val) {
                        final biometricService = ref.read(
                          biometricServiceProvider,
                        );
                        final canCheck = await biometricService
                            .canCheckBiometrics();
                        if (!canCheck) {
                          if (!context.mounted) return;
                          CardlyToast.showError(
                            context,
                            'Sensor biometrik tidak tersedia di perangkat ini.',
                          );
                          return;
                        }

                        final authRes = await biometricService
                            .authenticateDetailed(
                              localizedReason: 'Pindai sidik jari atau Face ID Anda untuk mengaktifkan kunci biometrik Cardly.',
                            );

                        if (!authRes.success) {
                          if (!context.mounted) return;
                          CardlyToast.showError(
                            context,
                            authRes.errorMessage ?? 'Verifikasi biometrik dibatalkan. Pengaturan tidak diubah.',
                          );
                          return;
                        }
                      }

                      setState(() => _useBiometrics = val);
                      final secureStorage = ref.read(
                        secureStorageServiceProvider,
                      );
                      await secureStorage.setBiometricEnabled(val);
                      ref
                          .read(userProfileProvider.notifier)
                          .setBiometricActive(val);

                      if (!context.mounted) return;
                      HapticFeedback.mediumImpact();
                      CardlyToast.showSuccess(
                        context,
                        val
                            ? 'Biometrik berhasil diverifikasi dan diaktifkan!'
                            : 'Biometrik dinonaktifkan',
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text('Samarkan Layar di App Switcher'),
                    subtitle: const Text(
                      'Cegah intipan saat berpindah aplikasi di perangkat',
                    ),
                    value: secSettings.hideInAppSwitcher,
                    activeThumbColor: AppColors.lime,
                    activeTrackColor: AppColors.ink,
                    onChanged: (val) {
                      secNotifier.setHideInAppSwitcher(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Section 2: Kredensial
            Text(
              'Kredensial Keamanan',
              style: AppTypography.titleSmall(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Material(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Ubah PIN Brankas 6-Digit'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePinDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Section 3: Zona Bahaya
            Text(
              'Tindakan Kritis',
              style: AppTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w700, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.sm),

            Material(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Hapus Seluruh Data Lokal',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Reset database dan hapus seluruh kartu & dokumen secara permanen',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.error,
                ),
                onTap: () => context.push('/vault/wipe'),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showAutoLockPicker(String currentOpt) {
    final secNotifier = ref.read(securitySettingsProvider.notifier);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Pilih Batas Waktu Kunci Otomatis',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...['Segera', '30 Detik', '1 Menit', '5 Menit'].map((opt) {
              return ListTile(
                title: Text(opt),
                trailing: currentOpt == opt
                    ? const Icon(Icons.check, color: AppColors.ink)
                    : null,
                onTap: () {
                  secNotifier.setAutoLockOption(opt);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final hasPin = await secureStorage.hasAppPin();

    if (!mounted) return;
    await PinScreen.showAsBottomSheet(
      context,
      mode: hasPin ? PinScreenMode.change : PinScreenMode.create,
      title: hasPin ? 'Ubah PIN Brankas' : 'Buat PIN Brankas Baru',
    );
  }
}
