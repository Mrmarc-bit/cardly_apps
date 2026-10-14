import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'cardly_brand_header.dart';

/// Widget animasi resmi Cardly Brand Lockup (Logo Mark + Teks Cardly)
/// Menggunakan aset Lottie JSON yang disesuaikan untuk mode terang dan gelap:
/// - Light Mode: `assets/animations/screen_gelap.json` (elemen gelap/ink di atas latar mist/terang)
/// - Dark Mode:  `assets/animations/screen_terang.json` (elemen terang/putih di atas latar ink/gelap)
class CardlyAnimatedLogo extends StatelessWidget {
  /// Tinggi wadah tata letak luar (default 64.0 agar rapi terhadap ritme vertikal)
  final double height;

  /// Override opsional untuk mode gelap; jika null otomatis membaca [Theme.of(context)]
  final bool? isDark;

  /// Menentukan apakah animasi berulang (default false untuk splash sequence)
  final bool repeat;

  /// AnimationController opsional jika ingin kontrol manual frame / timeline
  final Animation<double>? controller;

  /// Callback saat Lottie composition selesai dimuat (berguna untuk sinkronisasi timer)
  final void Function(LottieComposition)? onLoaded;

  const CardlyAnimatedLogo({
    super.key,
    this.height = 64.0,
    this.isDark,
    this.repeat = false,
    this.controller,
    this.onLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final darkTheme =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);

    // Pemilihan aset sesuai kontras tema:
    // - Mode Gelap: menggunakan 'screen_terang.json' karena tipografi & kartu depan berwarna putih (#FFFFFF)
    // - Mode Terang: menggunakan 'screen_gelap.json' karena tipografi & kartu depan berwarna gelap (#171717)
    final assetPath = darkTheme
        ? 'assets/animations/screen_terang.json'
        : 'assets/animations/screen_gelap.json';

    // Komposisi Lottie berukuran 1280x720 (rasio 16:9).
    // Konten aktif animasi (ikon + teks) berada tepat di titik tengah (lebar ~420pt).
    // Untuk menghasilkan ukuran visual lockup ~180pt (serasi dengan CardlyBrandLogo),
    // kanvas Lottie diskalakan ke lebar 540pt dengan tinggi 303.75pt.
    const canvasWidth = 540.0;
    const canvasHeight = canvasWidth * 720.0 / 1280.0;

    return Semantics(
      label: 'Cardly',
      header: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Teks untuk aksesibilitas & widget test finder
            const SizedBox.shrink(
              child: Opacity(opacity: 0.0, child: Text('Cardly')),
            ),
            Center(
              child: OverflowBox(
                minWidth: 0,
                maxWidth: canvasWidth,
                minHeight: 0,
                maxHeight: canvasHeight,
                child: Lottie.asset(
                  assetPath,
                  width: canvasWidth,
                  height: canvasHeight,
                  fit: BoxFit.contain,
                  repeat: repeat,
                  controller: controller,
                  onLoaded: onLoaded,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback anggun ke komponen vektor statis resmi jika aset tidak tersedia
                    return const CardlyBrandLogo(
                      iconSize: 42.0,
                      fontSize: 36.0,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
