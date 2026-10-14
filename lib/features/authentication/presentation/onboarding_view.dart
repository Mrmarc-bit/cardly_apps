import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../app/providers.dart';
import 'widgets/cardly_brand_header.dart';
import 'widgets/auth_illustrations.dart';

class _SlideData {
  final String stepLabel;
  final String title;
  final String description;
  final Widget illustration;

  const _SlideData({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.illustration,
  });
}

/// Onboarding View resmi Cardly (docs/4. Authentication/02, 03, 04 Onboarding.png)
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = const [
    _SlideData(
      stepLabel: 'KENALI CARDLY / 01',
      title: 'Semua kartu, satu tempat.',
      description:
          'Simpan kartu penting dan temukan semuanya dengan lebih mudah.',
      illustration: OnboardingCardsIllustration(),
    ),
    _SlideData(
      stepLabel: 'KENALI CARDLY / 02',
      title: 'Dokumen lebih teratur.',
      description: 'Kelompokkan identitas dan dokumen penting agar mudah ditemukan saat dibutuhkan.',
      illustration: OnboardingDocumentIllustration(),
    ),
    _SlideData(
      stepLabel: 'KENALI CARDLY / 03',
      title: 'Privasi tetap terjaga.',
      description:
          'Kunci brankas dengan biometrik dan sembunyikan informasi sensitif.',
      illustration: OnboardingPrivacyIllustration(),
    ),
  ];

  Future<void> _completeOnboarding() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setOnboardingDone(true);
    if (!mounted) return;
    context.go('/welcome');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Brand & Lewati
              CardlyBrandHeader(
                actionText: 'Lewati',
                onAction: _completeOnboarding,
              ),

              const SizedBox(height: 12.0),

              // Konten PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return LayoutBuilder(
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
                                // Ilustrasi Komposisi Vektor Menyesuaikan Tinggi Layar
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4.0,
                                    bottom: 24.0,
                                  ),
                                  child: Center(child: slide.illustration),
                                ),

                                // Eyebrow Langkah
                                Text(
                                  slide.stepLabel,
                                  style: AppTypography.tinyLabel.copyWith(
                                    color: isDark
                                        ? AppColors.mediumGray
                                        : AppColors.muted,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),

                                // Judul Besar Bold
                                Text(
                                  slide.title,
                                  style: AppTypography.display.copyWith(
                                    fontSize: 32.0,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.ink,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10.0),

                                // Deskripsi
                                Text(
                                  slide.description,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 15.0,
                                    height: 1.4,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16.0),

              // Indikator Titik Animatif (Pill Aktif + Lingkaran Inaktif)
              Row(
                children: List.generate(_slides.length, (idx) {
                  final isActive = idx == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 6.0),
                    width: isActive ? 24.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? AppColors.white : AppColors.ink)
                          : (isDark
                                ? AppColors.elevatedDark
                                : AppColors.softGray),
                      borderRadius: AppRadius.pillRadius,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20.0),

              // Tombol Utama (Lanjut / Mulai Sekarang)
              CardlyPrimaryButton(
                text: _currentPage == _slides.length - 1
                    ? 'Mulai Sekarang'
                    : 'Lanjut',
                onPressed: _nextPage,
              ),

              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}
