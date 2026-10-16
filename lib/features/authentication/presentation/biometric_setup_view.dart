import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../../app/providers.dart';
import 'widgets/auth_security_card.dart';

/// Biometric Setup View (docs/4. Authentication/61 Aktifkan biometrik.png & Gelap)
class BiometricSetupView extends ConsumerStatefulWidget {
  const BiometricSetupView({super.key});

  @override
  ConsumerState<BiometricSetupView> createState() => _BiometricSetupViewState();
}

class _BiometricSetupViewState extends ConsumerState<BiometricSetupView> {
  bool _isLoading = false;

  void _enableBiometric() async {
    setState(() => _isLoading = true);
    final biometricService = ref.read(biometricServiceProvider);
    final authResult = await biometricService.authenticateDetailed(
      localizedReason:
          'Konfirmasi biometrik untuk mengaktifkan kunci keamanan Cardly.',
    );

    if (authResult.success) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.setBiometricEnabled(true);
      ref.read(userProfileProvider.notifier).setBiometricActive(true);

      if (!mounted) return;
      final hasPin = await secureStorage.hasAppPin();
      if (!hasPin && mounted) {
        context.go('/pin-setup');
      } else if (mounted) {
        context.go('/shell');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (authResult.isNotEnrolled) {
      _showNotEnrolledDialog();
    } else {
      CardlyToast.showError(
        context,
        authResult.errorMessage ??
            'Verifikasi biometrik belum berhasil. Coba lagi atau lewati.',
      );
    }
  }

  void _showNotEnrolledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Biometrik Belum Terdaftar di HP'),
        content: const Text(
          'Sensor biometrik terdeteksi di perangkat Anda, namun belum ada data sidik jari atau Face ID yang didaftarkan di Pengaturan sistem Android.\n\nAnda dapat tetap mengaktifkan kunci biometrik sekarang agar siap digunakan setelah mendaftarkan sidik jari di Pengaturan HP.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final secureStorage = ref.read(secureStorageServiceProvider);
              await secureStorage.setBiometricEnabled(true);
              ref.read(userProfileProvider.notifier).setBiometricActive(true);
              if (!mounted) return;
              final hasPin = await secureStorage.hasAppPin();
              if (!hasPin && mounted) {
                context.go('/pin-setup');
              } else if (mounted) {
                context.go('/shell');
              }
            },
            child: const Text('Tetap Aktifkan'),
          ),
        ],
      ),
    );
  }

  void _skip() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final hasPin = await secureStorage.hasAppPin();
    if (!hasPin && mounted) {
      context.go('/pin-setup');
    } else if (mounted) {
      context.go('/shell');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: _skip,
        ),
        title: Text(
          'Kunci biometrik',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Ikon Sidik Jari Kotak Rounded Lime (#C8F45A)
              Container(
                width: 88.0,
                height: 88.0,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: AppRadius.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16.0,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 48.0,
                  color: AppColors.ink,
                ),
              ),

              const SizedBox(height: 28.0),

              // Headline & Subtitle
              Text(
                'Buka lebih mudah.',
                style: AppTypography.display.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.ink,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Gunakan autentikasi perangkat untuk membuka brankas dan dokumen pribadi. Anda tetap dapat menggunakan PIN aplikasi.',
                  style: AppTypography.body.copyWith(
                    fontSize: 14.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.muted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),

              // Kartu Keamanan Opsional Sesuai Perangkat
              const AuthSecurityCard(
                title: 'Opsional, sesuai perangkat',
                description: 'Cardly meminta hasil autentikasi sistem, bukan menampilkan data biometrik Anda.',
                icon: Icons.shield_outlined,
              ),

              const SizedBox(height: 20.0),

              // Tombol Aksi Bawah
              CardlyPrimaryButton(
                text: 'Aktifkan biometrik',
                isLoading: _isLoading,
                onPressed: _enableBiometric,
              ),
              const SizedBox(height: 12.0),
              CardlySecondaryButton(
                text: 'Lewati untuk sekarang',
                onPressed: _skip,
              ),

              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }
}
