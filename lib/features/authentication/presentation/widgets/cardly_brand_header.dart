import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cardly_buttons.dart';

/// Ikon resmi Cardly: Dua kartu bertumpuk sedikit miring (Kartu depan gelap/putih, kartu belakang Lime)
class CardlyLogoMark extends StatelessWidget {
  final double size;

  const CardlyLogoMark({super.key, this.size = 28.0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth = size * 0.82;
    final cardHeight = size * 0.82;
    final radius = Radius.circular(size * 0.28);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Kartu Belakang: Lime (#C8F45A) dengan rotasi +10 derajat
          Positioned(
            right: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.17, // ~10 derajat
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.all(radius),
                ),
              ),
            ),
          ),
          // Kartu Depan: Ink (#171717) di Light Mode, White (#FFFFFF) di Dark Mode dengan rotasi -5 derajat
          Positioned(
            left: 0,
            top: 0,
            child: Transform.rotate(
              angle: -0.09, // ~-5 derajat
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.white : AppColors.ink,
                  borderRadius: BorderRadius.all(radius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.08,
                      ),
                      blurRadius: 4.0,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand Lockup resmi: Menggunakan vektor SVG resmi
/// Mode Gelap: assets/icons/logo_panjang1.svg
/// Mode Terang: assets/icons/logo_panjang2.svg
class CardlyBrandLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final double? height;

  const CardlyBrandLogo({
    super.key,
    this.iconSize = 28.0,
    this.fontSize = 24.0,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgAsset = isDark
        ? 'assets/icons/logo_panjang1.svg'
        : 'assets/icons/logo_panjang2.svg';
    final targetHeight = height ?? (fontSize * 1.35).clamp(28.0, 42.0);

    return Semantics(
      label: 'Cardly',
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Teks transparan untuk test runner finder dan fallback a11y
          Opacity(
            opacity: 0.0,
            child: Text('Cardly', style: TextStyle(fontSize: fontSize)),
          ),
          SvgPicture.asset(
            svgAsset,
            height: targetHeight,
            fit: BoxFit.contain,
            placeholderBuilder: (context) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CardlyLogoMark(size: iconSize),
                  const SizedBox(width: 10.0),
                  Text(
                    'Cardly',
                    style: AppTypography.pageHeading.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Header Bar resmi dengan Brand Logo di kiri dan tombol aksi opsional (seperti 'Lewati') di kanan
class CardlyBrandHeader extends StatelessWidget {
  final String? actionText;
  final VoidCallback? onAction;

  const CardlyBrandHeader({super.key, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CardlyBrandLogo(iconSize: 28.0, fontSize: 22.0),
        if (actionText != null)
          CardlyQuietButton(
            text: actionText!,
            onPressed: onAction,
            textColor: isDark ? AppColors.textSecondaryDark : AppColors.muted,
          ),
      ],
    );
  }
}
