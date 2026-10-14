import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';
import 'cardly_visual_card.dart';
import 'cardly_buttons.dart';
import '../../features/cards/domain/card_model.dart';

/// Komponen tumpukan kartu fisik interaktif (*Wallet Stack*) ala Apple Wallet.
/// Mengizinkan kartu-kartu bertumpuk sebagian (*overlapping stack*),
/// dan dapat diketuk untuk diangkat (*lift out*) ke tampilan fokus beserta aksi cepat.
class CardlyWalletStack extends StatefulWidget {
  final List<CardItem> cards;
  final ValueChanged<CardItem>? onCardTap;
  final VoidCallback? onAddCardTap;
  final double stackPeekHeight;

  const CardlyWalletStack({
    super.key,
    required this.cards,
    this.onCardTap,
    this.onAddCardTap,
    this.stackPeekHeight = 68.0,
  });

  @override
  State<CardlyWalletStack> createState() => _CardlyWalletStackState();
}

class _CardlyWalletStackState extends State<CardlyWalletStack> {
  int? _expandedIndex;

  void _toggleCard(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });
  }

  void _collapse() {
    if (_expandedIndex != null) {
      HapticFeedback.selectionClick();
      setState(() => _expandedIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = widget.cards;

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wallet_outlined,
              size: 48.0,
              color: isDark ? AppColors.mediumGray : AppColors.muted,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Belum ada kartu di dompet.',
              style: AppTypography.sectionHeading.copyWith(
                color: isDark ? AppColors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 16.0),
            if (widget.onAddCardTap != null)
              CardlyPrimaryButton(
                text: 'Tambah Kartu Sekarang',
                onPressed: widget.onAddCardTap,
              ),
          ],
        ),
      );
    }

    // Perhitungan tinggi tumpukan kartu
    const double cardBaseHeight = 210.0;
    final int count = cards.length;
    final bool isAnyExpanded = _expandedIndex != null;

    final double totalHeight = isAnyExpanded
        ? cardBaseHeight +
              200.0 // Ruang untuk kartu terangkat + action bar
        : (count - 1) * widget.stackPeekHeight + cardBaseHeight + 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Status Tumpukan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAnyExpanded
                            ? AppColors.lime
                            : (isDark ? AppColors.mediumGray : AppColors.muted),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        isAnyExpanded
                            ? 'Kartu ${_expandedIndex! + 1} dari $count Terpilih'
                            : '$count Kartu dalam Dompet',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              if (isAnyExpanded)
                GestureDetector(
                  onTap: _collapse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : AppColors.white,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: isDark
                            ? AppColors.elevatedDark
                            : AppColors.softGray,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.unfold_less,
                          size: 14.0,
                          color: isDark ? AppColors.white : AppColors.ink,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          'Tutup',
                          style: AppTypography.tinyLabel.copyWith(
                            color: isDark ? AppColors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  'Ketuk kartu',
                  style: AppTypography.tinyLabel.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.muted,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8.0),

        // Stage Tumpukan Kartu
        AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < count; i++)
                if (i != _expandedIndex)
                  _buildCardLayer(
                    context: context,
                    index: i,
                    card: cards[i],
                    totalCards: count,
                    cardHeight: cardBaseHeight,
                    isDark: isDark,
                  ),
              if (_expandedIndex != null)
                _buildCardLayer(
                  context: context,
                  index: _expandedIndex!,
                  card: cards[_expandedIndex!],
                  totalCards: count,
                  cardHeight: cardBaseHeight,
                  isDark: isDark,
                ),
            ],
          ),
        ),

        // Panel Aksi Kartu yang Sedang Terbuka
        if (isAnyExpanded)
          _buildExpandedActionPanel(
            context: context,
            card: cards[_expandedIndex!],
            isDark: isDark,
          ),
      ],
    );
  }

  Widget _buildCardLayer({
    required BuildContext context,
    required int index,
    required CardItem card,
    required int totalCards,
    required double cardHeight,
    required bool isDark,
  }) {
    final bool isSelected = _expandedIndex == index;
    final bool isAnyExpanded = _expandedIndex != null;

    double topPosition;
    double scale = 1.0;
    double opacity = 1.0;

    if (!isAnyExpanded) {
      // Kondisi Diam: Kartu saling menumpuk teratur ke bawah
      topPosition = index * widget.stackPeekHeight;
      // Sedikit efek skala kedalaman untuk kartu di belakang
      scale = 1.0 - ((totalCards - 1 - index) * 0.012).clamp(0.0, 0.05);
    } else {
      if (isSelected) {
        // Kartu yang dipilih diangkat paling atas
        topPosition = 0.0;
        scale = 1.0;
        opacity = 1.0;
      } else if (index < _expandedIndex!) {
        // Kartu di atas yang dipilih disembunyikan/geser ke atas
        topPosition = -30.0;
        scale = 0.94;
        opacity = 0.0;
      } else {
        // Kartu di bawah yang dipilih tuck down ke bawah kartu terpilih
        topPosition =
            cardHeight + 10.0 + ((index - _expandedIndex! - 1) * 20.0);
        scale = 0.95;
        opacity = 0.45;
      }
    }

    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      top: topPosition,
      left: 0.0,
      right: 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        scale: scale,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.35 : 0.18,
                  ),
                  blurRadius: isSelected ? 24.0 : 12.0,
                  offset: Offset(0, isSelected ? 12.0 : 6.0),
                  spreadRadius: isSelected ? 1.0 : -2.0,
                ),
              ],
            ),
            child: CardlyVisualCard(
              nickname: card.nickname,
              issuer: card.issuer,
              lastFourDigits: card.lastFourDigits,
              category: card.category.label,
              network: card.network,
              colorTheme: card.colorTheme,
              isContactless: card.isContactless,
              holderName: card.holderName,
              expiryDate: card.expiryDate != null
                  ? '${card.expiryDate!.month.toString().padLeft(2, '0')}/${card.expiryDate!.year.toString().substring(2)}'
                  : null,
              aspectRatio: null, // Mengikuti container tinggi
              showActionButton: isSelected,
              actionButtonText: 'Buka Detail ↗',
              onActionTap: () {
                if (widget.onCardTap != null) {
                  widget.onCardTap!(card);
                }
              },
              onTap: () {
                if (isAnyExpanded && !isSelected) {
                  _toggleCard(index);
                } else if (isAnyExpanded && isSelected) {
                  if (widget.onCardTap != null) {
                    widget.onCardTap!(card);
                  }
                } else {
                  _toggleCard(index);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedActionPanel({
    required BuildContext context,
    required CardItem card,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.white,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isDark ? AppColors.elevatedDark : AppColors.softGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.nickname,
                    style: AppTypography.sectionHeading.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    '${card.issuer} • ${card.category.label}',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: AppColors.lime.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  card.network,
                  style: AppTypography.tinyLabel.copyWith(
                    color: isDark ? AppColors.lime : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: CardlySecondaryButton(
                  text: 'Tutup Tumpukan',
                  onPressed: _collapse,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: CardlyPrimaryButton(
                  text: 'Lihat Detail ↗',
                  onPressed: () {
                    if (widget.onCardTap != null) {
                      widget.onCardTap!(card);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
