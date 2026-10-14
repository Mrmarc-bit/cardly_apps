import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_visual_card.dart';
import '../../../core/widgets/cardly_wallet_stack.dart';
import '../../../core/widgets/cardly_empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../app/providers.dart';
import '../domain/card_model.dart';

enum CardDisplayMode { grid, list, stack }

class CardListView extends ConsumerStatefulWidget {
  const CardListView({super.key});

  @override
  ConsumerState<CardListView> createState() => _CardListViewState();
}

class _CardListViewState extends ConsumerState<CardListView> {
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CardDisplayMode _displayMode =
      CardDisplayMode.grid; // Default Grid sesuai 12 Kartu Saya.png

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCards = ref.watch(cardListProvider);

    final filtered = allCards.where((c) {
      if (_selectedCategory != 'Semua' &&
          c.category.label != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNick = c.nickname.toLowerCase().contains(q);
        final matchIssuer = c.issuer.toLowerCase().contains(q);
        final matchCategory = c.category.label.toLowerCase().contains(q);
        if (!matchNick && !matchIssuer && !matchCategory) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar (Sesuai 12 Kartu Saya.png: "Kartu Saya" & "Data contoh")
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kartu Saya',
                    style: AppTypography.pageHeading.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 26.0,
                    ),
                  ),
                ],
              ),
            ),

            // Minimalist Unified Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : AppColors.white,
                  borderRadius: AppRadius.inputRadius,
                  border: Border.all(
                    color: isDark
                        ? AppColors.elevatedDark
                        : const Color(0xFFE5E5E2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20.0,
                      color: isDark ? AppColors.mediumGray : AppColors.muted,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.white : AppColors.ink,
                          fontSize: 14.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari kartu atau penerbit...',
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: AppTypography.body.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark.withValues(
                                    alpha: 0.6,
                                  )
                                : AppColors.muted.withValues(alpha: 0.7),
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.close,
                            size: 18.0,
                            color: isDark
                                ? AppColors.mediumGray
                                : AppColors.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14.0),

            // Filter Chips Horizontal (Chip aktif: LIME sesuai 12 Kartu Saya.png)
            SizedBox(
              height: 38.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: ['Semua', ...CardCategory.values.map((c) => c.label)]
                    .map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lime
                                  : (isDark
                                        ? AppColors.charcoal
                                        : const Color(0xFFEBEBE8)),
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              cat,
                              style: AppTypography.compactBodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.ink
                                    : (isDark
                                          ? AppColors.white
                                          : AppColors.ink),
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),

            const SizedBox(height: 16.0),

            // Card Count & Mode View Toggle (Sesuai 12 Kartu Saya.png)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} kartu tersimpan',
                    style: AppTypography.sectionHeading.copyWith(
                      color: isDark ? AppColors.white : AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Terbaru ↓',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.muted,
                          fontSize: 13.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Icon Grid Toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _displayMode = CardDisplayMode.grid),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 20.0,
                          color: _displayMode == CardDisplayMode.grid
                              ? (isDark ? AppColors.lime : AppColors.ink)
                              : (isDark
                                    ? AppColors.mediumGray
                                    : AppColors.muted),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Icon List Toggle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _displayMode = CardDisplayMode.list),
                        child: Icon(
                          Icons.view_agenda_outlined,
                          size: 20.0,
                          color: _displayMode == CardDisplayMode.list
                              ? (isDark ? AppColors.lime : AppColors.ink)
                              : (isDark
                                    ? AppColors.mediumGray
                                    : AppColors.muted),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Icon Stack Toggle
                      GestureDetector(
                        onTap: () => setState(
                          () => _displayMode = CardDisplayMode.stack,
                        ),
                        child: Icon(
                          Icons.layers_outlined,
                          size: 20.0,
                          color: _displayMode == CardDisplayMode.stack
                              ? (isDark ? AppColors.lime : AppColors.ink)
                              : (isDark
                                    ? AppColors.mediumGray
                                    : AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14.0),

            // Tampilan Utama Kartu: Grid (Default Figma), List, atau Stack
            Expanded(
              child: filtered.isEmpty
                  ? CardlyEmptyState(
                      icon: Icons.credit_card_outlined,
                      title: 'Kartu pertama Anda.',
                      description: 'Simpan metadata kartu penting. Cukup empat digit terakhir untuk kartu pembayaran.',
                      actionButtonText: 'Tambah Kartu',
                      onActionPressed: () => context.push('/cards/create'),
                    )
                  : _buildCardsBody(filtered, isDark),
            ),
          ],
        ),
      ),
      bottomSheet: filtered.isEmpty
          ? null
          : Container(
              color: isDark ? AppColors.ink : AppColors.mist,
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
              child: CardlyPrimaryButton(
                text: 'Tambah Kartu',
                onPressed: () => context.push('/cards/create'),
              ),
            ),
    );
  }

  Widget _buildCardsBody(List<CardItem> cards, bool isDark) {
    switch (_displayMode) {
      case CardDisplayMode.grid:
        // 2-Column Grid persis sesuai docs/6. Cards/12 Kartu Saya.png
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 90.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.82,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CardlyVisualCard(
                    isCompact: true,
                    aspectRatio: null,
                    nickname: card.nickname,
                    issuer: card.issuer,
                    lastFourDigits: card.lastFourDigits,
                    category: card.category.label,
                    network: card.network,
                    colorTheme: card.colorTheme,
                    isContactless: card.isContactless,
                    onTap: () => context.push('/cards/${card.id}'),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  Formatters.formatDate(card.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            );
          },
        );

      case CardDisplayMode.list:
        // Full width single column sesuai 16 Tampilan kartu.png
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 90.0),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardlyVisualCard(
                    isCompact: false,
                    aspectRatio: 1.58,
                    nickname: card.nickname,
                    issuer: card.issuer,
                    lastFourDigits: card.lastFourDigits,
                    category: card.category.label,
                    network: card.network,
                    colorTheme: card.colorTheme,
                    isContactless: card.isContactless,
                    onTap: () => context.push('/cards/${card.id}'),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    Formatters.formatDate(card.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.muted,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case CardDisplayMode.stack:
        // Interaktif Wallet Stack
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 90.0),
          child: CardlyWalletStack(
            cards: cards,
            onCardTap: (card) => context.push('/cards/${card.id}'),
            onAddCardTap: () => context.push('/cards/create'),
          ),
        );
    }
  }
}
