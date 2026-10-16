import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import 'pin_screen.dart';

import '../../../app/app_router.dart';

/// Gerbang Kunci Sesi Global Cardly (App Lock Gate)
/// Memproteksi seluruh antarmuka aplikasi ketika sesi terkunci karena batas waktu
/// kunci otomatis tercapai atau aplikasi kembali dibuka dari latar belakang.
class AppLockGate extends ConsumerWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  static bool isPublicRoute(String path) {
    if (path.isEmpty ||
        path == '/' ||
        path == '/splash' ||
        path == '/onboarding' ||
        path == '/welcome') {
      return true;
    }
    if (path.startsWith('/login') ||
        path.startsWith('/register') ||
        path.startsWith('/forgot-password') ||
        path.startsWith('/reset-password')) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final isLocked = ref.watch(appLockedProvider);
    final isSplashDone = ref.watch(isSplashCompletedProvider);

    String currentPath = '/splash';
    try {
      currentPath = appRouter.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {}

    // Jangan kunci jika splash belum selesai, belum login, sesi tidak terkunci, atau di rute publik
    if (!isSplashDone ||
        !user.isLoggedIn ||
        !isLocked ||
        isPublicRoute(currentPath)) {
      return child;
    }

    // Jika sesi terkunci dan akun aktif di halaman terlindungi, blokir dengan layar kunci Master Cardly
    return _AppLockOverlay(user: user);
  }
}

class _AppLockOverlay extends ConsumerStatefulWidget {
  final UserProfile user;

  const _AppLockOverlay({required this.user});

  @override
  ConsumerState<_AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends ConsumerState<_AppLockOverlay> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _attemptBiometricAuth(autoTrigger: true);
        }
      });
    });
  }

  Future<void> _attemptBiometricAuth({bool autoTrigger = false}) async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final canCheck = await biometricService.canCheckBiometrics();
      if (!canCheck) {
        if (!autoTrigger && mounted) {
          CardlyToast.showInfo(
            context,
            'Sensor biometrik tidak tersedia. Silakan gunakan PIN.',
          );
        }
        return;
      }

      final result = await biometricService.authenticateDetailed(
        localizedReason: 'Pindai biometrik untuk membuka Cardly.',
      );

      if (!mounted) return;

      if (result.success) {
        HapticFeedback.mediumImpact();
        ref.read(appLockedProvider.notifier).unlock();
        ref.read(vaultLockedProvider.notifier).unlock();
        return;
      }

      if (!autoTrigger && !result.isNotEnrolled && mounted) {
        HapticFeedback.vibrate();
        CardlyToast.showError(
          context,
          result.errorMessage ?? 'Verifikasi biometrik tidak cocok.',
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _handlePinUnlock() async {
    final verified = await PinScreen.showAsBottomSheet(
      context,
      mode: PinScreenMode.verify,
      title: 'Buka Kunci Cardly',
      subtitle: 'Masukkan 6 digit angka PIN Anda untuk membuka aplikasi.',
    );

    if (verified == true && mounted) {
      HapticFeedback.mediumImpact();
      ref.read(appLockedProvider.notifier).unlock();
      ref.read(vaultLockedProvider.notifier).unlock();
    }
  }

  Future<void> _handleSwitchAccount() async {
    ref.read(userProfileProvider.notifier).logout();
    ref.read(appLockedProvider.notifier).unlock();
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.signOut();
    await supabase.signOutGoogle();
    try {
      appRouter.go('/welcome');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.user;
    final hasAvatar =
        user.avatarPath.isNotEmpty && File(user.avatarPath).existsSync();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Menekan back pada layar kunci meminimalkan aplikasi ke layar beranda HP
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.ink : AppColors.mist,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenInset,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Shield & Brand Identity Icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lime.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 42,
                      color: AppColors.ink,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title & Subtitle
                Text(
                  'Cardly Terkunci',
                  style: AppTypography.largeHeading.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Sesi diamankan otomatis demi menjaga privasi kartu dan dokumen Anda.',
                  style: AppTypography.bodySmall(context)
                      .copyWith(color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // User Identity Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: hasAvatar
                              ? Image.file(
                                  File(user.avatarPath),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName
                              : 'Pengguna Cardly',
                          style: AppTypography.titleSmall(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Action Buttons
                CardlyButton(
                  text: 'Buka dengan Biometrik',
                  icon: Icons.fingerprint_rounded,
                  isLoading: _isAuthenticating,
                  onPressed: () => _attemptBiometricAuth(autoTrigger: false),
                ),

                const SizedBox(height: AppSpacing.sm),

                CardlyButton(
                  text: 'Buka dengan PIN',
                  variant: CardlyButtonVariant.secondary,
                  icon: Icons.pin_outlined,
                  onPressed: _handlePinUnlock,
                ),

                const SizedBox(height: AppSpacing.md),

                CardlyButton(
                  text: 'Keluar / Ganti Akun',
                  variant: CardlyButtonVariant.quiet,
                  onPressed: _handleSwitchAccount,
                ),

                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
