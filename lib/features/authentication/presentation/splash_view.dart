import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../app/providers.dart';
import 'widgets/cardly_animated_logo.dart';

/// Splash Screen resmi Cardly (docs/4. Authentication/01 Splash.png & 01 Splash • Gelap.png)
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with TickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulseAnimController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _entranceController;
  late final Animation<double> _sloganFade;
  late final Animation<Offset> _sloganSlide;
  late final Animation<double> _indicatorFade;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    // Pulse micro-animation untuk indikator garis lime
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    // Entrance animation controller untuk koreografi teks slogan, indikator, dan footer
    // Total durasi 2400 ms:
    // - 0 - 1100 ms: Fokus pada animasi logo Lottie (kartu & huruf Cardly)
    // - 1100 - 1700 ms: Slogan masuk dengan slide up + fade in halus
    // - 1440 - 1950 ms: Garis indikator lime muncul
    // - 1680 - 2200 ms: Footer caption muncul
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _sloganFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.46, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _sloganSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.46, 0.72, curve: Curves.easeOutCubic),
          ),
        );

    _indicatorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.60, 0.82, curve: Curves.easeOut),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.70, 0.92, curve: Curves.easeOut),
      ),
    );

    // Default timer 2800 ms (durasi ~2600 ms animasi Lottie + buffer transisi)
    _timer = Timer(const Duration(milliseconds: 2800), _navigateNext);
  }

  void _onAnimationLoaded(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration + const Duration(milliseconds: 250), _navigateNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseAnimController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    _timer?.cancel();
    ref.read(isSplashCompletedProvider.notifier).state = true;
    final storage = ref.read(localStorageServiceProvider);
    if (!storage.isOnboardingDone) {
      context.go('/onboarding');
      return;
    }

    if (storage.isLoggedIn) {
      context.go('/shell');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap:
              _navigateNext, // Pengguna dapat melewati animasi dengan ketukan
          child: Stack(
            children: [
              // Logo, Slogan Banner, & Indikator Lime terpusat secara vertikal di layar
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CardlyAnimatedLogo(
                        isDark: isDark,
                        onLoaded: (comp) => _onAnimationLoaded(comp.duration),
                      ),
                      const SizedBox(height: 24.0),

                      // Animasi Masuk Teks Slogan (Slide up & Fade in setelah logo terbentuk)
                      SlideTransition(
                        position: _sloganSlide,
                        child: FadeTransition(
                          opacity: _sloganFade,
                          child: Text(
                            'Your cards. Your documents. One private space.',
                            style: AppTypography.body.copyWith(
                              fontSize: 16.0,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      // Indikator Garis Lime dengan Micro-Animation Pulse & Entrance Fade
                      FadeTransition(
                        opacity: _indicatorFade,
                        child: AnimatedBuilder(
                          animation: _pulseAnimController,
                          builder: (context, child) {
                            return Transform.scale(
                              scaleX: _pulseAnimation.value,
                              child: Container(
                                width: 48.0,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: AppColors.lime,
                                  borderRadius: AppRadius.pillRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.lime.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8.0,
                                      spreadRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Keterangan di bagian bawah layar secara seimbang
              Positioned(
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
                child: FadeTransition(
                  opacity: _footerFade,
                  child: Text(
                    'Semua kartu dan dokumen penting, dalam satu tempat.',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12.0,
                      color: isDark ? AppColors.mediumGray : AppColors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
