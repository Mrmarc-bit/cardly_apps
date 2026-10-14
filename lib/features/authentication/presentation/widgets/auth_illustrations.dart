import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Mendeteksi apakah aplikasi sedang berjalan dalam pengujian otomatis (automated widget test).
/// Jika ya, animasi berulang dialihkan ke mode statis/forward agar `tester.pumpAndSettle()`
/// tidak mengalami timeout, sedangkan di aplikasi nyata berjalan looping terus-menerus.
bool _isTestEnvironment() {
  return WidgetsBinding.instance.runtimeType.toString().contains('Test');
}

/// Widget wrapper yang memeriksa keberadaan aset Lottie JSON di `assets/animations/`.
/// Jika file JSON tersedia, widget akan memutar animasi Lottie secara otomatis.
/// Jika belum tersedia, widget akan merender ilustrasi interaktif modern bawaan Flutter.
class _LottieAutoDetector extends StatefulWidget {
  final String darkAsset;
  final String lightAsset;
  final String fallbackAsset;
  final Widget child;

  const _LottieAutoDetector({
    required this.darkAsset,
    required this.lightAsset,
    required this.fallbackAsset,
    required this.child,
  });

  @override
  State<_LottieAutoDetector> createState() => _LottieAutoDetectorState();
}

class _LottieAutoDetectorState extends State<_LottieAutoDetector> {
  String? _resolvedLottiePath;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _checkLottieAvailability();
    }
  }

  Future<void> _checkLottieAvailability() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final candidates = [
      isDark ? widget.darkAsset : widget.lightAsset,
      widget.fallbackAsset,
    ];

    for (final path in candidates) {
      try {
        await rootBundle.load(path);
        if (mounted) {
          setState(() {
            _resolvedLottiePath = path;
          });
          return;
        }
      } catch (_) {
        // Aset belum ditambahkan oleh pengguna, lanjutkan pengecekan
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolvedLottiePath != null) {
      return Lottie.asset(
        _resolvedLottiePath!,
        repeat: true,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => widget.child,
      );
    }
    return widget.child;
  }
}

/// Komponen kilau cahaya diagonal (reflective shimmer sweep) yang bergerak melintasi permukaan kartu
class _CardShimmerSweep extends StatelessWidget {
  final double progress; // 0.0 sampai 1.0
  final BorderRadius borderRadius;

  const _CardShimmerSweep({required this.progress, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0 || progress >= 1.0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: FractionalTranslation(
          translation: Offset(progress * 2.8 - 1.4, 0.0),
          child: Transform.rotate(
            angle: 0.45,
            child: Container(
              width: 85.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.28),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Komponen laser scanner pengaman vertikal untuk kartu privasi
class _SecurityScanBeam extends StatelessWidget {
  final double progress;

  const _SecurityScanBeam({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.0 || progress >= 1.0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(22.0)),
        child: Align(
          alignment: Alignment(0.0, progress * 2.2 - 1.1),
          child: Container(
            height: 3.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.lime.withValues(alpha: 0.0),
                  AppColors.lime.withValues(alpha: 0.85),
                  AppColors.lime.withValues(alpha: 0.0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lime.withValues(alpha: 0.6),
                  blurRadius: 8.0,
                  spreadRadius: 1.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 1. ONBOARDING KARTU & WELCOME HERO: CARD FLIP ALTERNATION (SWAP DEPAN-BELAKANG)
/// ============================================================================
/// Animasi bertukar posisi (card flip & swap):
/// Kartu depan dan belakang bergantian secara looping terus-menerus dengan efek
/// 3D perspective depth, levitasi sinusoidal, dan kilau cahaya reflektif.
class OnboardingCardsIllustration extends StatefulWidget {
  final double? height;

  const OnboardingCardsIllustration({super.key, this.height});

  @override
  State<OnboardingCardsIllustration> createState() =>
      _OnboardingCardsIllustrationState();
}

class _OnboardingCardsIllustrationState
    extends State<OnboardingCardsIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;

  // Controller pertukaran kartu berkelanjutan (4 detik per siklus lengkap)
  late final AnimationController _swapController;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;

  late final AnimationController _beaconController;
  late final Animation<double> _beaconPulse;

  @override
  void initState() {
    super.initState();
    final inTest = _isTestEnvironment();

    // 1. Entrance Spring
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _entranceScale = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    // 2. Card Swap Alternation Loop (4.200 ms per 2 kali swap lengkap)
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    // 3. Shimmer Sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
    );

    // 4. Contactless Beacon Pulse
    _beaconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _beaconPulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _beaconController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    if (!inTest) {
      _swapController.repeat();
      _shimmerController.repeat();
      _beaconController.repeat(reverse: true);
    } else {
      _swapController.forward();
      _shimmerController.forward();
      _beaconController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _swapController.dispose();
    _shimmerController.dispose();
    _beaconController.dispose();
    super.dispose();
  }

  /// Membangun Widget Kartu Lime (#C8F45A) - BCA Harian
  Widget _buildLimeCard(bool isDark) {
    return Container(
      width: 285.0,
      height: 172.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18.0,
            offset: const Offset(0, 8.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KARTU UTAMA',
                style: AppTypography.tinyLabel.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.85),
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Transform.rotate(
                angle: 1.5708,
                child: Opacity(
                  opacity: _beaconPulse.value,
                  child: const Icon(
                    Icons.wifi,
                    size: 18.0,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Harian',
                style: AppTypography.largeHeading.copyWith(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                'Bank Central Asia',
                style: AppTypography.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '•••• 4582',
                  style: AppTypography.tabular(
                    AppTypography.bodySemiBold.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: 1.2,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Visa',
                style: AppTypography.bodySemiBold.copyWith(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Membangun Widget Kartu Gelap (Ink / Charcoal) - Mandiri Cadangan
  Widget _buildDarkCard(bool isDark) {
    return Container(
      width: 285.0,
      height: 172.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : AppColors.ink,
        borderRadius: const BorderRadius.all(Radius.circular(20.0)),
        border: Border.all(
          color: isDark ? const Color(0xFF383838) : Colors.black,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 18.0,
            offset: const Offset(0, 8.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRIORITAS',
                style: AppTypography.tinyLabel.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Transform.rotate(
                angle: 1.5708,
                child: Opacity(
                  opacity: _beaconPulse.value,
                  child: const Icon(
                    Icons.wifi,
                    size: 18.0,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cadangan',
                style: AppTypography.largeHeading.copyWith(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                'Bank Mandiri',
                style: AppTypography.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '•••• 8821',
                  style: AppTypography.tabular(
                    AppTypography.bodySemiBold.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Mastercard',
                style: AppTypography.bodySemiBold.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.charcoal : const Color(0xFFEBEBE8);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final effectiveHeight =
        widget.height ?? (screenHeight * 0.38).clamp(270.0, 340.0);

    return _LottieAutoDetector(
      darkAsset: 'assets/animations/onboarding_cards_dark.json',
      lightAsset: 'assets/animations/onboarding_cards_light.json',
      fallbackAsset: 'assets/animations/onboarding_cards.json',
      child: Container(
        width: double.infinity,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: const BorderRadius.all(Radius.circular(32.0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _swapController,
              _shimmerController,
              _beaconController,
            ]),
            builder: (context, child) {
              final t = _swapController.value;

              // Hitung status fase pertukaran kartu:
              // Fase 1: t in [0.0, 0.5] (Kartu Lime di depan, Kartu Ink di belakang)
              // Transisi 1: t in [0.38, 0.52] (Kartu Lime meluncur ke belakang, Ink maju ke depan)
              // Fase 2: t in [0.5, 1.0] (Kartu Ink di depan, Kartu Lime di belakang)
              // Transisi 2: t in [0.88, 1.00] (Kartu Ink meluncur ke belakang, Lime maju ke depan)

              final bool limeIsFront;
              double limeScale = 1.0;
              double limeTranslateX = 0.0;
              double limeTranslateY = 0.0;
              double limeRotate = -0.05;
              double lime3dY = 0.0;

              double darkScale = 0.90;
              double darkTranslateX = 14.0;
              double darkTranslateY = 12.0;
              double darkRotate = 0.08;
              double dark3dY = 0.0;

              // Floating Sinusoidal Parallax halus
              final floatWave = math.sin(t * 2 * math.pi) * 6.0;

              if (t < 0.38) {
                // Posisi stabil: Lime depan, Dark belakang
                limeIsFront = true;
                limeScale = 1.0;
                limeTranslateY = -floatWave;
                limeRotate = -0.05 + (floatWave * 0.002);

                darkScale = 0.90;
                darkTranslateX = 14.0;
                darkTranslateY = 12.0 + floatWave;
                darkRotate = 0.08 - (floatWave * 0.002);
              } else if (t < 0.52) {
                // Transisi 1: Swap Lime -> Belakang, Dark -> Depan
                final p = (t - 0.38) / 0.14;
                final curve = Curves.easeInOutCubic.transform(p);
                limeIsFront = p < 0.5;

                // Lime meluncur ke atas dan melengkung ke belakang dalam 3D
                final arcY = -math.sin(p * math.pi) * 44.0;
                limeTranslateY = (curve * 12.0) + arcY;
                limeTranslateX = curve * 14.0;
                limeScale = 1.0 - (curve * 0.10);
                limeRotate = -0.05 + (curve * 0.13);
                lime3dY = math.sin(p * math.pi) * 0.25;

                // Dark maju ke depan
                darkTranslateX = 14.0 - (curve * 14.0);
                darkTranslateY = 12.0 - (curve * 12.0);
                darkScale = 0.90 + (curve * 0.10);
                darkRotate = 0.08 - (curve * 0.13);
                dark3dY = -math.sin(p * math.pi) * 0.15;
              } else if (t < 0.88) {
                // Posisi stabil: Dark depan, Lime belakang
                limeIsFront = false;
                darkScale = 1.0;
                darkTranslateX = 0.0;
                darkTranslateY = floatWave;
                darkRotate = -0.05 - (floatWave * 0.002);

                limeScale = 0.90;
                limeTranslateX = 14.0;
                limeTranslateY = 12.0 - floatWave;
                limeRotate = 0.08 + (floatWave * 0.002);
              } else {
                // Transisi 2: Swap Dark -> Belakang, Lime -> Depan
                final p = (t - 0.88) / 0.12;
                final curve = Curves.easeInOutCubic.transform(p);
                limeIsFront = p >= 0.5;

                // Dark meluncur ke atas dan melengkung ke belakang dalam 3D
                final arcY = -math.sin(p * math.pi) * 44.0;
                darkTranslateY = (curve * 12.0) + arcY;
                darkTranslateX = curve * 14.0;
                darkScale = 1.0 - (curve * 0.10);
                darkRotate = -0.05 + (curve * 0.13);
                dark3dY = math.sin(p * math.pi) * 0.25;

                // Lime maju ke depan
                limeTranslateX = 14.0 - (curve * 14.0);
                limeTranslateY = 12.0 - (curve * 12.0);
                limeScale = 0.90 + (curve * 0.10);
                limeRotate = 0.08 - (curve * 0.13);
                lime3dY = -math.sin(p * math.pi) * 0.15;
              }

              // Card Lime Widget dengan Transform
              final limeWidget = Transform.translate(
                offset: Offset(limeTranslateX, limeTranslateY),
                child: Transform.scale(
                  scale: limeScale,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(lime3dY)
                      ..rotateZ(limeRotate),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        _buildLimeCard(isDark),
                        if (limeIsFront)
                          _CardShimmerSweep(
                            progress: _shimmerAnim.value,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );

              // Card Dark Widget dengan Transform
              final darkWidget = Transform.translate(
                offset: Offset(darkTranslateX, darkTranslateY),
                child: Transform.scale(
                  scale: darkScale,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(dark3dY)
                      ..rotateZ(darkRotate),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        _buildDarkCard(isDark),
                        if (!limeIsFront)
                          _CardShimmerSweep(
                            progress: _shimmerAnim.value,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );

              return Transform.scale(
                scale: _entranceScale.value,
                child: SizedBox(
                  width: 320.0,
                  height: 215.0,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: limeIsFront
                        ? [darkWidget, limeWidget]
                        : [limeWidget, darkWidget],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 2. ONBOARDING DOKUMEN: ANIMASI KREATIF BERKAS MASUK FOLDER
/// ============================================================================
/// Tampilan folder interaktif dengan saku dokumen:
/// Berkas (KTP & Lembar Dokumen) melayang, bibir folder terbuka dalam 3D,
/// berkas meluncur masuk ke dalam folder, folder menutup dengan bounce rapi,
/// dan lencana Lime folder berdenyut aktif.
class OnboardingDocumentIllustration extends StatefulWidget {
  final double? height;

  const OnboardingDocumentIllustration({super.key, this.height});

  @override
  State<OnboardingDocumentIllustration> createState() =>
      _OnboardingDocumentIllustrationState();
}

class _OnboardingDocumentIllustrationState
    extends State<OnboardingDocumentIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;

  // Controller animasi alur berkas masuk ke folder (looping 4 detik)
  late final AnimationController _folderLoopController;

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    final inTest = _isTestEnvironment();

    // 1. Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _entranceScale = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    // 2. Continuous Folder Flow Controller (4.0 detik)
    _folderLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // 3. Shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _shimmerAnim = CurvedAnimation(
      parent: _shimmerController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    if (!inTest) {
      _folderLoopController.repeat();
      _shimmerController.repeat();
    } else {
      _folderLoopController.forward();
      _shimmerController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _folderLoopController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.charcoal : const Color(0xFFEBEBE8);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final effectiveHeight =
        widget.height ?? (screenHeight * 0.38).clamp(270.0, 340.0);

    return _LottieAutoDetector(
      darkAsset: 'assets/animations/onboarding_docs_dark.json',
      lightAsset: 'assets/animations/onboarding_docs_light.json',
      fallbackAsset: 'assets/animations/onboarding_docs.json',
      child: Container(
        width: double.infinity,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: const BorderRadius.all(Radius.circular(32.0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _folderLoopController,
              _shimmerController,
            ]),
            builder: (context, child) {
              final t = _folderLoopController.value;

              // Timeline Berkas Masuk Folder:
              // 0.00 -> 0.25: Dokumen mengambang di atas, folder siap
              // 0.25 -> 0.55: Dokumen meluncur turun ke dalam saku folder
              // 0.55 -> 0.70: Saku folder menutup dengan efek bounce, kilau shimmer
              // 0.70 -> 0.85: Dokumen tersimpan rapi & levitasi folder bersama
              // 0.85 -> 1.00: Dokumen mengambang keluar kembali untuk loop berikutnya

              final double docY;
              final double docRotation;
              final double flapAngle;
              final bool isStored;

              if (t < 0.20) {
                // Posisi mengambang di atas
                final hover = math.sin(t * 10 * math.pi) * 3.0;
                docY = -52.0 + hover;
                docRotation = -0.04;
                flapAngle = 0.22 * (t / 0.20); // flap mulai terbuka
                isStored = false;
              } else if (t < 0.52) {
                // Dokumen meluncur masuk ke dalam folder
                final p = (t - 0.20) / 0.32;
                final curve = Curves.easeInOutCubic.transform(p);
                docY = -52.0 + (curve * 66.0); // -52 -> +14
                docRotation = -0.04 * (1.0 - curve);
                flapAngle = 0.22;
                isStored = p > 0.8;
              } else if (t < 0.70) {
                // Folder menutup rapat dengan bounce
                final p = (t - 0.52) / 0.18;
                final bounce = Curves.easeOutBack.transform(p);
                docY = 14.0;
                docRotation = 0.0;
                flapAngle = 0.22 * (1.0 - bounce);
                isStored = true;
              } else if (t < 0.88) {
                // Berkas tersimpan rapi, folder levitasi santai
                final hover = math.sin((t - 0.70) * 8 * math.pi) * 3.5;
                docY = 14.0 + hover;
                docRotation = 0.0;
                flapAngle = 0.0;
                isStored = true;
              } else {
                // Re-float ke atas untuk loop berikutnya
                final p = (t - 0.88) / 0.12;
                final curve = Curves.easeInOutCubic.transform(p);
                docY = 14.0 - (curve * 66.0);
                docRotation = -0.04 * curve;
                flapAngle = 0.18 * curve;
                isStored = false;
              }

              return Transform.scale(
                scale: _entranceScale.value,
                child: SizedBox(
                  width: 320.0,
                  height: 220.0,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. FOLDER BACK PLATE (Dinding Belakang Map & Tab Dokumen)
                      Positioned(
                        bottom: 12.0,
                        child: Container(
                          width: 290.0,
                          height: 165.0,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF282828)
                                : const Color(0xFFE2E2DF),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(22.0),
                            ),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF383838)
                                  : const Color(0xFFD6D6D2),
                              width: 1.2,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              margin: const EdgeInsets.only(
                                left: 14.0,
                                top: 10.0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lime.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 14.0,
                                    color: AppColors.lime,
                                  ),
                                  const SizedBox(width: 5.0),
                                  Text(
                                    'Koleksi Berkas',
                                    style: AppTypography.tinyLabel.copyWith(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.lime
                                          : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. DOKUMEN BERGERAK MASUK: LEMBAR BERKAS SEKUNDER (Kontrak / Paspor)
                      Positioned(
                        bottom: 24.0,
                        child: Transform.translate(
                          offset: Offset(8.0, docY - 14.0),
                          child: Transform.rotate(
                            angle: docRotation + 0.04,
                            child: Container(
                              width: 245.0,
                              height: 140.0,
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF323232)
                                    : const Color(0xFFF9F9F7),
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF444444)
                                      : const Color(0xFFE0E0DC),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 10.0,
                                    offset: const Offset(0, 4.0),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 70.0,
                                        height: 7.0,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF4A4A4A)
                                              : const Color(0xFFDCDCD8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.verified_outlined,
                                        size: 14.0,
                                        color: AppColors.lime,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  Container(
                                    width: 140.0,
                                    height: 5.5,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF444444)
                                          : const Color(0xFFE4E4E0),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(height: 7.0),
                                  Container(
                                    width: 100.0,
                                    height: 5.5,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF444444)
                                          : const Color(0xFFE4E4E0),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 3. DOKUMEN UTAMA BERGERAK MASUK: KARTU IDENTITAS RESMI (KTP)
                      Positioned(
                        bottom: 24.0,
                        child: Transform.translate(
                          offset: Offset(-4.0, docY),
                          child: Transform.rotate(
                            angle: docRotation,
                            child: Container(
                              width: 270.0,
                              height: 155.0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                                vertical: 14.0,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2E2E2E)
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(18.0),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF404040)
                                      : const Color(0xFFE2E2DC),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.30 : 0.12,
                                    ),
                                    blurRadius: 14.0,
                                    offset: const Offset(0, 6.0),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header KTP
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Identitas',
                                          style: AppTypography.sectionHeading
                                              .copyWith(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.white
                                                    : AppColors.ink,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 3.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.lime,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'AKTIF',
                                          style: AppTypography.tinyLabel
                                              .copyWith(
                                                fontSize: 9.0,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),

                                  // Body KTP (Avatar Foto + Garis Bar)
                                  Row(
                                    children: [
                                      Container(
                                        width: 44.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.elevatedDark
                                              : const Color(0xFFEDEDED),
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person_outline_rounded,
                                          size: 26.0,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 14.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 7.5,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.elevatedDark
                                                    : const Color(0xFFEDEDED),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                            const SizedBox(height: 7.0),
                                            Container(
                                              height: 7.5,
                                              width: 110.0,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.elevatedDark
                                                    : const Color(0xFFEDEDED),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                            const SizedBox(height: 7.0),
                                            Container(
                                              height: 7.5,
                                              width: 70.0,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.elevatedDark
                                                    : const Color(0xFFEDEDED),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Footer Riil KTP
                                  Text(
                                    'KTP Republik Indonesia • DKI Jakarta',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.mediumGray
                                          : AppColors.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 4. FOLDER FRONT POCKET / FLAP (Saku Depan yang Terbuka & Mengunci Berkas)
                      Positioned(
                        bottom: 12.0,
                        child: Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateX(flapAngle),
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 290.0,
                            height: 105.0,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF222222)
                                        .withValues(alpha: 0.94)
                                  : const Color(0xFFF2F2EE)
                                        .withValues(alpha: 0.95),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(22.0),
                                bottomRight: Radius.circular(22.0),
                                topLeft: Radius.circular(16.0),
                                topRight: Radius.circular(16.0),
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.lime.withValues(alpha: 0.45)
                                    : AppColors.ink.withValues(alpha: 0.20),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10.0,
                                  offset: const Offset(0, 3.0),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Bibir Saku dengan Aksen Garis Lime
                                Positioned(
                                  top: 0,
                                  left: 20.0,
                                  right: 20.0,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: AppColors.lime,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.lime.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 6.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Shimmer Sheen saat berkas tersimpan
                                _CardShimmerSweep(
                                  progress: _shimmerAnim.value,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(22.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 5. LENCANA MENGAMBANG FOLDER LIME (Dengan Denyut & Indikator Tersimpan)
                      Positioned(
                        right: 8.0,
                        bottom: 8.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          width: 58.0,
                          height: 58.0,
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(18.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 12.0,
                                offset: const Offset(0, 5.0),
                              ),
                              BoxShadow(
                                color: AppColors.lime.withValues(
                                  alpha: isStored ? 0.65 : 0.35,
                                ),
                                blurRadius: isStored ? 14.0 : 8.0,
                                spreadRadius: isStored ? 2.0 : 0.5,
                              ),
                            ],
                          ),
                          child: Icon(
                            isStored
                                ? Icons.check_circle_outline_rounded
                                : Icons.folder_outlined,
                            size: 28.0,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 3. ONBOARDING PRIVASI: ANIMASI DATA ENKRIPSI/BINER & GEMBOK BUKA-KUNCI
/// ============================================================================
/// Fitur kartu brankas keamanan tingkat tinggi:
/// - Data sensitif secara aktif beralih antara teks, ciphertext biner/hex, dan masked bullets.
/// - Sinar laser pemindai keamanan vertikal.
/// - Lencana gembok Lime dengan animasi shackle buka -> "KLIK" mengunci rapat.
class OnboardingPrivacyIllustration extends StatefulWidget {
  final double? height;

  const OnboardingPrivacyIllustration({super.key, this.height});

  @override
  State<OnboardingPrivacyIllustration> createState() =>
      _OnboardingPrivacyIllustrationState();
}

class _OnboardingPrivacyIllustrationState
    extends State<OnboardingPrivacyIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;

  // Controller pemindaian & siklus enkripsi berkelanjutan (3.800 ms)
  late final AnimationController _securityLoopController;

  late final Animation<double> _scanBeam;

  @override
  void initState() {
    super.initState();
    final inTest = _isTestEnvironment();

    // 1. Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _entranceScale = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    // 2. Continuous Security Loop
    _securityLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _scanBeam = CurvedAnimation(
      parent: _securityLoopController,
      curve: const Interval(0.12, 0.72, curve: Curves.easeInOutCubic),
    );

    _entranceController.forward();
    if (!inTest) {
      _securityLoopController.repeat();
    } else {
      _securityLoopController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _securityLoopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? AppColors.charcoal : const Color(0xFFEBEBE8);
    final cardBg = isDark ? const Color(0xFF2E2E2E) : AppColors.white;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final effectiveHeight =
        widget.height ?? (screenHeight * 0.38).clamp(270.0, 340.0);

    return _LottieAutoDetector(
      darkAsset: 'assets/animations/onboarding_privacy_dark.json',
      lightAsset: 'assets/animations/onboarding_privacy_light.json',
      fallbackAsset: 'assets/animations/onboarding_privacy.json',
      child: Container(
        width: double.infinity,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: const BorderRadius.all(Radius.circular(32.0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _securityLoopController,
            ]),
            builder: (context, child) {
              final t = _securityLoopController.value;

              // Timeline Enkripsi & Gembok:
              // 0.00 -> 0.35: Gembok TERBUKA, data terbaca / mulai dipindai
              // 0.35 -> 0.65: Laser menyapu data -> data berubah menjadi KODE BINER & CIPHER
              // 0.65 -> 0.75: "KLIK!" Gembok MENGUNCI RAPAT dengan denyut neon Lime
              // 0.75 -> 0.90: Data terkunci total (bullet ••••), status AMAN
              // 0.90 -> 1.00: Transisi halus membuka kembali untuk siklus berikutnya

              final bool isLocked = t >= 0.60 && t < 0.95;
              final double lockBounce = (t >= 0.60 && t <= 0.70)
                  ? 1.0 + (math.sin((t - 0.60) * 10 * math.pi) * 0.18)
                  : 1.0;

              // String data biner dinamis yang berganti sesuai posisi scanner
              final String cipherDataText;
              final Color cipherColor;

              if (t < 0.28) {
                cipherDataText = 'NIK: 3171024508930002';
                cipherColor = isDark ? AppColors.white : AppColors.ink;
              } else if (t < 0.60) {
                // Saat tersapu laser: kode biner / hex scramble aktif
                final int step = (t * 24).toInt() % 4;
                switch (step) {
                  case 0:
                    cipherDataText = '01100010 01100001 01111000';
                    break;
                  case 1:
                    cipherDataText = '11010010 10110001 01101111';
                    break;
                  case 2:
                    cipherDataText = '01010111 01101001 01110010';
                    break;
                  default:
                    cipherDataText = 'SHA256: 7f83b1657ff1fc53';
                }
                cipherColor = AppColors.lime;
              } else {
                // Terenkripsi aman
                cipherDataText = '•••• •••• •••• •••• [AES-256]';
                cipherColor = isDark
                    ? AppColors.lime.withValues(alpha: 0.9)
                    : const Color(0xFF2E7D32);
              }

              // Levitas halus kartu
              final floatY = math.sin(t * 2 * math.pi) * 4.0;

              return Transform.scale(
                scale: _entranceScale.value,
                child: SizedBox(
                  width: 320.0,
                  height: 220.0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // KARTU BRANKAS DOKUMEN PRIBADI
                      Transform.translate(
                        offset: Offset(0.0, floatY),
                        child: Stack(
                          children: [
                            Container(
                              width: 285.0,
                              height: 182.0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 16.0,
                              ),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(22.0),
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? (isLocked
                                            ? AppColors.lime.withValues(
                                                alpha: 0.4,
                                              )
                                            : const Color(0xFF383838))
                                      : (isLocked
                                            ? AppColors.lime.withValues(
                                                alpha: 0.5,
                                              )
                                            : const Color(0xFFE2E2DC)),
                                  width: 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.32 : 0.08,
                                    ),
                                    blurRadius: 14.0,
                                    offset: const Offset(0, 5.0),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Dokumen pribadi
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Dokumen pribadi',
                                          style: AppTypography.sectionHeading
                                              .copyWith(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? AppColors.white
                                                    : AppColors.ink,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 3.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLocked
                                              ? AppColors.lime
                                              : (isDark
                                                    ? AppColors.elevatedDark
                                                    : const Color(0xFFEDEDED)),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isLocked
                                                  ? Icons.lock_rounded
                                                  : Icons.lock_open_rounded,
                                              size: 11.0,
                                              color: isLocked
                                                  ? AppColors.ink
                                                  : (isDark
                                                        ? AppColors.white
                                                        : AppColors.ink),
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              isLocked ? 'TERKUNCI' : 'PINDAI',
                                              style: AppTypography.tinyLabel
                                                  .copyWith(
                                                    fontSize: 9.0,
                                                    fontWeight: FontWeight.w800,
                                                    color: isLocked
                                                        ? AppColors.ink
                                                        : (isDark
                                                              ? AppColors.white
                                                              : AppColors.ink),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),

                                  // Baris Data Sensitif & Kode Biner
                                  Row(
                                    children: [
                                      Container(
                                        width: 44.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.elevatedDark
                                              : const Color(0xFFEDEDED),
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        child: Icon(
                                          isLocked
                                              ? Icons.fingerprint_rounded
                                              : Icons.person_outline_rounded,
                                          size: 26.0,
                                          color: isLocked
                                              ? AppColors.lime
                                              : (isDark
                                                    ? AppColors
                                                          .textSecondaryDark
                                                    : AppColors.muted),
                                        ),
                                      ),
                                      const SizedBox(width: 14.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Teks Data Enkripsi / Biner Dinamis
                                            Text(
                                              cipherDataText,
                                              style: AppTypography.tabular(
                                                AppTypography.bodySemiBold
                                                    .copyWith(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: cipherColor,
                                                      letterSpacing: 0.6,
                                                    ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6.0),
                                            // Aliran Bit Biner Matrix Sekunder
                                            Text(
                                              '01000011 01100001 01110010 01100100',
                                              style: AppTypography.tabular(
                                                AppTypography.tinyLabel
                                                    .copyWith(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? AppColors.lime
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                )
                                                          : AppColors.ink
                                                                .withValues(
                                                                  alpha: 0.45,
                                                                ),
                                                      letterSpacing: 0.4,
                                                    ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5.0),
                                            Container(
                                              height: 5.0,
                                              width: 75.0,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.elevatedDark
                                                    : const Color(0xFFEDEDED),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),

                                  // Footer Keamanan Riil
                                  Text(
                                    'Enkripsi AES-256 • Tersimpan di Perangkat',
                                    style: AppTypography.caption.copyWith(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.mediumGray
                                          : AppColors.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Sinar Laser Pemindaian Keamanan Vertikal
                            _SecurityScanBeam(progress: _scanBeam.value),
                          ],
                        ),
                      ),

                      // LENCANA MENGAMBANG GEMBOK LIME: BUKA -> "KLIK" MENGUNCI RAPAT
                      Positioned(
                        right: 4.0,
                        bottom: 4.0,
                        child: Transform.scale(
                          scale: lockBounce,
                          child: Container(
                            width: 60.0,
                            height: 60.0,
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(18.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 14.0,
                                  offset: const Offset(0, 5.0),
                                ),
                                BoxShadow(
                                  color: AppColors.lime.withValues(
                                    alpha: isLocked ? 0.70 : 0.35,
                                  ),
                                  blurRadius: isLocked ? 16.0 : 8.0,
                                  spreadRadius: isLocked ? 2.5 : 0.5,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ikon kunci/gembok membuka & mengunci
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                                  child: isLocked
                                      ? const Icon(
                                          Icons.lock_rounded,
                                          key: ValueKey('locked'),
                                          size: 30.0,
                                          color: AppColors.ink,
                                        )
                                      : const Icon(
                                          Icons.lock_outline_rounded,
                                          key: ValueKey('unlocked'),
                                          size: 30.0,
                                          color: AppColors.ink,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
