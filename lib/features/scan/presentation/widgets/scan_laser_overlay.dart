import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Overlay pemandu pemindaian dengan bingkai sudut presisi,
/// scrim transparan di luar area kartu, dan animasi laser neon Lime.
/// Desain bersih & tajam tanpa filter hijau berkabut (clean viewfinder).
class ScanLaserOverlay extends StatefulWidget {
  final double aspectRatio;
  final bool isScanning;
  final String hintText;
  final String detectedBadge;
  final bool isDocumentLocked;
  final Offset? focusScreenPosition;
  final bool isFocusing;
  final ValueChanged<Offset>? onTapToFocus;
  final String? qualityWarning;
  final VoidCallback? onWarningTap;
  final double autoCaptureProgress;

  const ScanLaserOverlay({
    super.key,
    this.aspectRatio = 1.58, // Rasio kartu ID standar (ISO/IEC 7810 ID-1)
    this.isScanning = true,
    this.hintText = 'Posisikan dokumen dalam bingkai',
    this.detectedBadge = '',
    this.isDocumentLocked = false,
    this.focusScreenPosition,
    this.isFocusing = false,
    this.onTapToFocus,
    this.qualityWarning,
    this.onWarningTap,
    this.autoCaptureProgress = 0.0,
  });

  @override
  State<ScanLaserOverlay> createState() => _ScanLaserOverlayState();
}

class _ScanLaserOverlayState extends State<ScanLaserOverlay>
    with TickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _focusController;
  late Animation<double> _focusScaleAnimation;
  late Animation<double> _focusOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animasi Laser Vertikal Halus
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    if (widget.isScanning) {
      _laserController.repeat(reverse: true);
    }

    // 2. Animasi Auto-Focus / Tap Reticle
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _focusScaleAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _focusOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _focusController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );
    if (widget.isFocusing) {
      _focusController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant ScanLaserOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isScanning && !_laserController.isAnimating) {
      _laserController.repeat(reverse: true);
    } else if (!widget.isScanning && _laserController.isAnimating) {
      _laserController.stop();
    }

    if (widget.isFocusing && !oldWidget.isFocusing) {
      _focusController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameWidth = constraints.maxWidth - 48.0;
        final frameHeight = frameWidth / widget.aspectRatio;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            widget.onTapToFocus?.call(details.localPosition);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Scrim Mask di sekeliling bingkai kartu (Hole punch bening di tengah)
              CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _OverlayScrimPainter(
                  cardRect: Rect.fromCenter(
                    center: Offset(
                      constraints.maxWidth / 2,
                      constraints.maxHeight / 2,
                    ),
                    width: frameWidth,
                    height: frameHeight,
                  ),
                  cornerRadius: AppRadius.card,
                ),
              ),

              // 2. Bingkai Sudut Presisi & Laser (100% Bersih & Transparan di dalam)
              Center(
                child: SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: Stack(
                    children: [
                      // Siku Sudut Konveks Presisi & Outline Border
                      CustomPaint(
                        size: Size(frameWidth, frameHeight),
                        painter: _CornerBracketPainter(
                          bracketColor: AppColors.lime,
                          bracketLength: 28.0,
                          strokeWidth: 3.5,
                          cornerRadius: AppRadius.card,
                        ),
                      ),

                      // Garis Laser Bergerak Naik-Turun (Ramping & Tajam)
                      if (widget.isScanning)
                        AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            final topPos =
                                _laserAnimation.value * (frameHeight - 4.0);
                            return Positioned(
                              top: topPos,
                              left: 8.0,
                              right: 8.0,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2.0),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.lime,
                                      AppColors.white,
                                      AppColors.lime,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.lime.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 6.0,
                                      spreadRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Badge Deteksi (jika ada teks dari luar)
                      if (widget.detectedBadge.isNotEmpty)
                        Positioned(
                          top: 14.0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: AppColors.lime.withValues(alpha: 0.6),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                widget.detectedBadge,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Indikator Auto-Shutter Countdown / Kunci Kartu
                      if (widget.autoCaptureProgress > 0.0)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: AppColors.lime,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.lime.withValues(alpha: 0.45),
                                  blurRadius: 14.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 15.0,
                                  height: 15.0,
                                  child: CircularProgressIndicator(
                                    value: widget.autoCaptureProgress,
                                    strokeWidth: 2.2,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.lime,
                                        ),
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  widget.autoCaptureProgress >= 0.95
                                      ? 'Menjepret...'
                                      : 'Menstabilkan kartu...',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Banner Peringatan Kualitas (Blur Goyang / Kurang Cahaya / Silau)
              if (widget.qualityWarning != null &&
                  widget.qualityWarning!.isNotEmpty)
                Positioned(
                  top: (constraints.maxHeight / 2) - (frameHeight / 2) - 46.0,
                  left: 20.0,
                  right: 20.0,
                  child: Center(
                    child: GestureDetector(
                      onTap: widget.onWarningTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 6.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xF21C1C1E),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14.0,
                              color: Color(0xFFFFB74D),
                            ),
                            const SizedBox(width: 6.0),
                            Flexible(
                              child: Text(
                                widget.qualityWarning!,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Teks Petunjuk di bawah bingkai
              if (widget.hintText.isNotEmpty)
                Positioned(
                  top: (constraints.maxHeight / 2) + (frameHeight / 2) + 20.0,
                  left: 24.0,
                  right: 24.0,
                  child: Center(
                    child: Text(
                      widget.hintText,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 6.0,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // 4. Reticle Auto-Focus & Tap-to-Focus
              if (widget.isFocusing && widget.focusScreenPosition != null)
                AnimatedBuilder(
                  animation: _focusController,
                  builder: (context, child) {
                    final pos = widget.focusScreenPosition!;
                    final scale = _focusScaleAnimation.value;
                    final opacity = _focusOpacityAnimation.value;

                    return Positioned(
                      left: pos.dx - 32.0,
                      top: pos.dy - 32.0,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale,
                          child: _FocusReticleWidget(),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget Reticle Auto-Focus & Tap-to-Focus Minimalis & Elegan
class _FocusReticleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.0,
      height: 64.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48.0, 48.0),
            painter: _ReticleCornerPainter(),
          ),
          Container(
            width: 4.0,
            height: 4.0,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticleCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.lime
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const len = 9.0;

    // Kiri Atas
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);

    // Kanan Atas
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Kiri Bawah
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - len),
      paint,
    );

    // Kanan Bawah
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - len, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter untuk menggelapkan area layar di luar bingkai kartu (Hole Punch)
class _OverlayScrimPainter extends CustomPainter {
  final Rect cardRect;
  final double cornerRadius;

  _OverlayScrimPainter({required this.cardRect, required this.cornerRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holeRRect = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(cornerRadius),
    );
    final holePath = Path()..addRRect(holeRRect);

    // Potong lubang di tengah layar
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _OverlayScrimPainter oldDelegate) {
    return oldDelegate.cardRect != cardRect;
  }
}

/// Painter untuk menggambar 4 siku sudut tebal aksen Lime di kartu
/// DENGAN KURVA KONVEKS MATEMATIS PERSIS (TIDAK KEBALIK).
class _CornerBracketPainter extends CustomPainter {
  final Color bracketColor;
  final double bracketLength;
  final double strokeWidth;
  final double cornerRadius;

  _CornerBracketPainter({
    required this.bracketColor,
    required this.bracketLength,
    required this.strokeWidth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = cornerRadius;
    final len = bracketLength;

    // 1. Garis bantu border sekeliling kartu (bersih, rapi seperti Figma)
    final guidePaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(r),
      ),
      guidePaint,
    );

    // 2. Empat Siku Sudut Tebal di 4 Pojok (100% Konveks Sesuai RRect)
    final paint = Paint()
      ..color = bracketColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawCorners(canvas, size, r, len, paint);
  }

  void _drawCorners(
    Canvas canvas,
    Size size,
    double r,
    double len,
    Paint paint,
  ) {
    // 1. Sudut Kiri Atas (Kuadran Barat Laut)
    final topLeft = Path()
      ..moveTo(0, len)
      ..lineTo(0, r)
      ..arcTo(Rect.fromLTWH(0, 0, 2 * r, 2 * r), math.pi, math.pi / 2, false)
      ..lineTo(len, 0);
    canvas.drawPath(topLeft, paint);

    // 2. Sudut Kanan Atas (Kuadran Timur Laut)
    final topRight = Path()
      ..moveTo(size.width - len, 0)
      ..lineTo(size.width - r, 0)
      ..arcTo(
        Rect.fromLTWH(size.width - 2 * r, 0, 2 * r, 2 * r),
        -math.pi / 2,
        math.pi / 2,
        false,
      )
      ..lineTo(size.width, len);
    canvas.drawPath(topRight, paint);

    // 3. Sudut Kanan Bawah (Kuadran Tenggara)
    final bottomRight = Path()
      ..moveTo(size.width, size.height - len)
      ..lineTo(size.width, size.height - r)
      ..arcTo(
        Rect.fromLTWH(size.width - 2 * r, size.height - 2 * r, 2 * r, 2 * r),
        0,
        math.pi / 2,
        false,
      )
      ..lineTo(size.width - len, size.height);
    canvas.drawPath(bottomRight, paint);

    // 4. Sudut Kiri Bawah (Kuadran Barat Daya - Tidak Kebalik)
    final bottomLeft = Path()
      ..moveTo(len, size.height)
      ..lineTo(r, size.height)
      ..arcTo(
        Rect.fromLTWH(0, size.height - 2 * r, 2 * r, 2 * r),
        math.pi / 2,
        math.pi / 2,
        false,
      )
      ..lineTo(0, size.height - len);
    canvas.drawPath(bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) {
    return oldDelegate.bracketColor != bracketColor;
  }
}
