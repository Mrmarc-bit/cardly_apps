import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';
import '../theme/app_motion.dart';
import '../utils/formatters.dart';

/// Tema warna kartu resmi Cardly sesuai DESAIN.md
enum CardColorTheme {
  lime,
  black,
  white,
  gray;

  static const CardColorTheme ink = CardColorTheme.black;
  static const CardColorTheme charcoal = CardColorTheme.black;
  static const CardColorTheme mist = CardColorTheme.gray;

  Color get backgroundColor {
    switch (this) {
      case CardColorTheme.lime:
        return AppColors.lime;
      case CardColorTheme.black:
        return const Color(0xFF252525);
      case CardColorTheme.white:
        return AppColors.white;
      case CardColorTheme.gray:
        return AppColors.softGray;
    }
  }

  Color get textColor {
    switch (this) {
      case CardColorTheme.lime:
        return AppColors.ink;
      case CardColorTheme.black:
        return AppColors.white;
      case CardColorTheme.white:
        return AppColors.ink;
      case CardColorTheme.gray:
        return AppColors.ink;
    }
  }

  Color get borderColor {
    switch (this) {
      case CardColorTheme.white:
        return const Color(0xFFE5E5E2);
      case CardColorTheme.black:
        return const Color(0xFF333333);
      default:
        return Colors.transparent;
    }
  }
}

/// Widget visual kartu resmi Cardly sesuai Figma
/// (docs/6. Cards/12 Kartu Saya.png & 16 Tampilan kartu.png)
class CardlyVisualCard extends StatefulWidget {
  final String nickname;
  final String holderName;
  final String issuer;
  final String? lastFourDigits;
  final String? expiryDate;
  final String category;
  final String network; // Visa, Mastercard, GPN, Identitas, dll.
  final CardColorTheme colorTheme;
  final bool isContactless;
  final VoidCallback? onTap;
  final bool showActionButton;
  final String actionButtonText;
  final double? aspectRatio;
  final VoidCallback? onActionTap;
  final bool isCompact; // True untuk tampilan 2-column Grid di Kartu Saya
  final bool isMasked; // True untuk menyamarkan nomor kartu penuh (•••• ••••)

  const CardlyVisualCard({
    super.key,
    String? nickname,
    String? title,
    String? holderName,
    required this.issuer,
    String? lastFourDigits,
    String? maskedNumber,
    this.expiryDate,
    String? category,
    String? categoryName,
    this.network = 'Visa',
    CardColorTheme? colorTheme,
    CardColorTheme? theme,
    this.isContactless = true,
    this.onTap,
    this.showActionButton = false,
    this.actionButtonText = 'Lihat Detail ↗',
    this.onActionTap,
    this.aspectRatio = 1.58,
    this.isCompact = false,
    this.isMasked = false,
    bool showChip = false, // Backwards compatibility
    bool enableSheen = false, // Backwards compatibility
  }) : nickname = nickname ?? title ?? 'Kartu',
       holderName = holderName ?? 'PEMILIK',
       lastFourDigits = lastFourDigits ?? maskedNumber,
       category = category ?? categoryName ?? 'PEMBAYARAN',
       colorTheme = colorTheme ?? theme ?? CardColorTheme.lime;

  @override
  State<CardlyVisualCard> createState() => _CardlyVisualCardState();
}

class _CardlyVisualCardState extends State<CardlyVisualCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.colorTheme;
    final textColor = theme.textColor;
    final bgColor = theme.backgroundColor;
    final maskedNum = widget.isMasked
        ? '•••• ••••'
        : Formatters.maskCardNumber(widget.lastFourDigits);
    final isCompact = widget.isCompact;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isCompact
            ? BorderRadius.circular(20.0)
            : AppRadius.cardRadius,
        border: Border.all(color: theme.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 16.0 : 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Baris Atas: Kategori & Ikon Contactless / Verified Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.category.toUpperCase(),
                style: AppTypography.tinyLabel.copyWith(
                  color: textColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: isCompact ? 9.5 : 11.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(
                widget.isContactless
                    ? Icons.contactless_outlined
                    : Icons.verified_outlined,
                color: textColor.withValues(alpha: 0.85),
                size: isCompact ? 19.0 : 24.0,
              ),
            ],
          ),

          // Baris Tengah: Nama Panggilan (Harian / KTP / BPJS) & Penerbit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.nickname,
                      style: AppTypography.largeHeading.copyWith(
                        color: textColor,
                        fontSize: isCompact ? 18.0 : 24.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      widget.issuer,
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: isCompact ? 11.5 : 13.0,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.showActionButton && !isCompact)
                GestureDetector(
                  onTap: widget.onActionTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 7.0,
                    ),
                    decoration: BoxDecoration(
                      color: textColor == AppColors.white
                          ? AppColors.white
                          : AppColors.ink,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      widget.actionButtonText,
                      style: AppTypography.tinyLabel.copyWith(
                        color: textColor == AppColors.white
                            ? AppColors.ink
                            : AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Baris Bawah: Nomor Masking Tabular & Label Jaringan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                maskedNum,
                style: AppTypography.tabular(
                  AppTypography.bodySemiBold.copyWith(
                    color: textColor,
                    letterSpacing: isCompact ? 1.4 : 2.0,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 14.0 : 18.0,
                  ),
                ),
              ),
              Text(
                widget.network,
                style: AppTypography.bodySemiBold.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 11.5 : 14.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final wrappedContent = widget.aspectRatio != null
        ? AspectRatio(aspectRatio: widget.aspectRatio!, child: cardContent)
        : cardContent;

    if (widget.onTap == null) {
      return wrappedContent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? AppMotion.pressedScale : 1.0,
        duration: AppMotion.pressDuration,
        curve: AppMotion.defaultCurve,
        child: wrappedContent,
      ),
    );
  }
}
