import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../vault/presentation/pin_screen.dart';
import 'widgets/auth_illustrations.dart';
import 'widgets/cardly_brand_header.dart';

/// Welcome View resmi Cardly dengan tombol dinamis adaptif berbasis status akun perangkat
/// (docs/4. Authentication/05 Welcome.png & 05 Welcome • Gelap.png)
class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});

  @override
  ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView> {
  bool _isBiometric = false;
  bool _hasPin = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityState();
  }

  Future<void> _checkSecurityState() async {
    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final isBio = await secureStorage.isBiometricEnabled();
      final hasP = await secureStorage.hasAppPin();

      if (!mounted) return;
      setState(() {
        _isBiometric = isBio;
        _hasPin = hasP;
      });

      final profile = ref.read(userProfileProvider);
      // Jika pengguna sudah memiliki akun aktif dan biometrik menyala, pemicu popup native biometrik OS
      if (profile.isLoggedIn && isBio) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            _handleBiometricUnlock(autoTrigger: true);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _handleBiometricUnlock({bool autoTrigger = false}) async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final canCheck = await biometricService.canCheckBiometrics();
      if (!canCheck) {
        if (!autoTrigger && mounted) {
          CardlyToast.showInfo(
            context,
            'Sensor biometrik tidak tersedia di perangkat ini.',
          );
        }
        return;
      }

      final result = await biometricService.authenticateDetailed(
        localizedReason:
            'Pindai sidik jari atau Face ID Anda untuk masuk ke Cardly.',
      );

      if (!mounted) return;

      if (result.success) {
        HapticFeedback.mediumImpact();
        ref.read(userProfileProvider.notifier).setBiometricActive(true);
        context.go('/shell');
        return;
      }

      if (!autoTrigger && !result.isNotEnrolled) {
        HapticFeedback.vibrate();
        CardlyToast.showError(
          context,
          result.errorMessage ?? 'Verifikasi biometrik tidak cocok.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _handlePinUnlock() async {
    final unlocked = await PinScreen.showAsBottomSheet(
      context,
      mode: PinScreenMode.verify,
      title: 'Masukkan PIN Brankas',
      subtitle: 'Masukkan 6 digit angka PIN Anda untuk membuka Cardly.',
    );

    if (unlocked == true && mounted) {
      HapticFeedback.mediumImpact();
      context.go('/shell');
    }
  }

  Future<void> _handleSwitchAccount() async {
    ref.read(userProfileProvider.notifier).logout();
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.signOut();
    await supabase.signOutGoogle();

    if (mounted) {
      setState(() {
        _isBiometric = false;
        _hasPin = false;
      });
      context.push('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final profile = ref.watch(userProfileProvider);

    // Pengguna dianggap terdaftar jika memiliki sesi aktif di perangkat
    final hasEnrolledAccount = profile.isLoggedIn;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Header Lockup
              const CardlyBrandLogo(iconSize: 28.0, fontSize: 22.0),

              const SizedBox(height: 12.0),

              // Area Konten Utama Terpusat & Seimbang
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hero Ilustrasi Kartu Bertumpuk Besar & Responsif
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                bottom: 20.0,
                              ),
                              child: Center(
                                child: OnboardingCardsIllustration(
                                  height: (screenHeight * 0.35).clamp(
                                    250.0,
                                    320.0,
                                  ),
                                ),
                              ),
                            ),

                            // Headline
                            Text(
                              hasEnrolledAccount
                                  ? 'Selamat datang\nkembali di\nruang Anda.'
                                  : 'Ruang pribadi\nuntuk yang\npenting.',
                              style: AppTypography.display.copyWith(
                                fontSize: 34.0,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: isDark ? AppColors.white : AppColors.ink,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 12.0),

                            // Subtitle
                            Text(
                              hasEnrolledAccount
                                  ? 'Buka brankas kartu & dokumen pribadi dengan aman.'
                                  : 'Semua kartu dan dokumen penting, dalam satu tempat.',
                              style: AppTypography.body.copyWith(
                                fontSize: 15.0,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.muted,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16.0),

              // Aksi Tombol Dinamis (Adaptive Buttons)
              if (hasEnrolledAccount) ...[
                // Keadaan 1: Perangkat Memiliki Akun Terdaftar
                if (_isBiometric) ...[
                  CardlyPrimaryButton(
                    text: _isAuthenticating
                        ? 'Memindai Biometrik...'
                        : 'Buka dengan Biometrik',
                    leadingIcon: const Icon(
                      Icons.fingerprint_rounded,
                      size: 22.0,
                      color: AppColors.ink,
                    ),
                    isLoading: _isAuthenticating,
                    onPressed: () => _handleBiometricUnlock(),
                  ),
                  const SizedBox(height: 12.0),
                  CardlySecondaryButton(
                    text: 'Masukkan PIN Brankas',
                    onPressed: _handlePinUnlock,
                  ),
                ] else if (_hasPin) ...[
                  CardlyPrimaryButton(
                    text: 'Buka dengan PIN Brankas',
                    leadingIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20.0,
                      color: AppColors.ink,
                    ),
                    onPressed: _handlePinUnlock,
                  ),
                  const SizedBox(height: 12.0),
                  CardlySecondaryButton(
                    text: 'Masuk dengan Sandi Akun',
                    onPressed: () => context.push('/login'),
                  ),
                ] else ...[
                  CardlyPrimaryButton(
                    text: 'Buka Ruang Pribadi',
                    onPressed: () => context.go('/shell'),
                  ),
                  const SizedBox(height: 12.0),
                  CardlySecondaryButton(
                    text: 'Masuk Ulang',
                    onPressed: () => context.push('/login'),
                  ),
                ],

                const SizedBox(height: 8.0),
                Center(
                  child: TextButton(
                    onPressed: _handleSwitchAccount,
                    child: Text(
                      'Masuk dengan Akun Lain',
                      style: AppTypography.bodySmall(context).copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Keadaan 2: Pengguna Baru / Belum Ada Akun / Setelah Logout
                CardlyPrimaryButton(
                  text: 'Masuk',
                  onPressed: () => context.push('/login'),
                ),
                const SizedBox(height: 12.0),
                CardlySecondaryButton(
                  text: 'Buat Akun',
                  onPressed: () => context.push('/register'),
                ),
                const SizedBox(height: 12.0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
