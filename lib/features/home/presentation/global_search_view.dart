import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_empty_state.dart';

/// Halaman Pencarian Global Cardly sesuai referensi:
/// - docs/5. Home/26 Pencarian.png & 26 Pencarian • Gelap.png
/// - docs/5. Home/27 Hasil pencarian.png & 27 Hasil pencarian • Gelap.png
class GlobalSearchView extends ConsumerStatefulWidget {
  const GlobalSearchView({super.key});

  @override
  ConsumerState<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends ConsumerState<GlobalSearchView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _activeFilter = 'Semua'; // 'Semua', 'Kartu', 'Dokumen', 'Tag'

  final List<String> _recentSearches = ['SIM A', 'KTP', 'Pendidikan'];

  final List<String> _categories = [
    'Pembayaran',
    'Identitas',
    'Kendaraan',
    'Pendidikan',
    'Favorit',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearRecentSearches() {
    HapticFeedback.selectionClick();
    setState(() => _recentSearches.clear());
  }

  void _selectSearchTerm(String term) {
    HapticFeedback.selectionClick();
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.charcoal : AppColors.white;
    final borderColor = isDark ? AppColors.elevatedDark : AppColors.softGray;

    final cards = ref.watch(cardListProvider);
    final documents = ref.watch(documentListProvider);

    final qLower = _query.toLowerCase();

    final matchingCards = _query.isEmpty
        ? []
        : cards.where((c) {
            return c.nickname.toLowerCase().contains(qLower) ||
                c.issuer.toLowerCase().contains(qLower) ||
                c.category.displayName.toLowerCase().contains(qLower);
          }).toList();

    final matchingDocs = _query.isEmpty
        ? []
        : documents.where((d) {
            return d.title.toLowerCase().contains(qLower) ||
                (d.issuer?.toLowerCase().contains(qLower) ?? false) ||
                d.category.displayName.toLowerCase().contains(qLower);
          }).toList();

    final matchingTags = _query.isEmpty
        ? []
        : _categories
              .where((cat) => cat.toLowerCase().contains(qLower))
              .toList();

    final totalResults =
        matchingCards.length + matchingDocs.length + matchingTags.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _query.isEmpty ? 'Pencarian' : 'Hasil pencarian',
          style: AppTypography.pageHeading.copyWith(
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kotak Pencarian Tertutup (Enclosed Search Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.inputRadius,
                  border: Border.all(
                    color: isDark ? AppColors.white : AppColors.ink,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.compactBodyMedium.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.white : AppColors.ink,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Cari kartu, dokumen, atau kategori...',
                          hintStyle: AppTypography.compactBody.copyWith(
                            color: isDark
                                ? AppColors.mediumGray
                                : AppColors.muted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 20.0,
                          color: isDark ? AppColors.white : AppColors.ink,
                        ),
                      )
                    else
                      Icon(
                        Icons.search_rounded,
                        size: 24.0,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10.0),

              // Keterangan di Bawah Kotak Pencarian
              Text(
                _query.isEmpty
                    ? 'Pencarian tidak menggunakan nomor kartu atau identitas.'
                    : '$totalResults hasil untuk "$_query" · tanpa pencarian nomor',
                style: AppTypography.caption.copyWith(
                  fontSize: 12.0,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                ),
              ),

              const SizedBox(height: 20.0),

              // Konten Berdasarkan Status Query
              if (_query.isEmpty) ...[
                // Bagian: Pencarian terakhir
                if (_recentSearches.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pencarian terakhir',
                        style: AppTypography.sectionHeading.copyWith(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.ink,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearRecentSearches,
                        child: Text(
                          'Hapus',
                          style: AppTypography.captionMedium.copyWith(
                            fontSize: 13.0,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Column(
                      children: List.generate(_recentSearches.length, (index) {
                        final term = _recentSearches[index];
                        final isLast = index == _recentSearches.length - 1;

                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _selectSearchTerm(term),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0,
                                  vertical: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 22.0,
                                      color: isDark
                                          ? AppColors.white
                                          : AppColors.ink,
                                    ),
                                    const SizedBox(width: 14.0),
                                    Expanded(
                                      child: Text(
                                        term,
                                        style: AppTypography.compactBodyMedium
                                            .copyWith(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.white
                                                  : AppColors.ink,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20.0,
                                      color: isDark
                                          ? AppColors.mediumGray
                                          : AppColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1.0,
                                indent: 54.0,
                                endIndent: 16.0,
                                color: borderColor,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 28.0),
                ],

                // Bagian: Jelajahi kategori
                Text(
                  'Jelajahi kategori',
                  style: AppTypography.sectionHeading.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _categories.map((cat) {
                    return GestureDetector(
                      onTap: () => _selectSearchTerm(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 9.0,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.charcoal
                              : AppColors.softGray,
                          borderRadius: BorderRadius.circular(999.0),
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: Text(
                          cat,
                          style: AppTypography.caption.copyWith(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36.0),

                // Kartu Info Privasi di Bawah (docs/5. Home/26 Pencarian.png)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.info,
                        size: 22.0,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temukan tanpa membuka informasi pribadi',
                              style: AppTypography.compactBodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.white : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              'Nama dan tag membantu pencarian. Isi dokumen pribadi tetap memerlukan autentikasi.',
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Filter Kategori (docs/5. Home/27 Hasil pencarian.png)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Semua', 'Kartu', 'Dokumen', 'Tag'].map((
                      filter,
                    ) {
                      final isSelected = _activeFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _activeFilter = filter);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.lime
                                  : (isDark
                                        ? AppColors.charcoal
                                        : AppColors.softGray),
                              borderRadius: BorderRadius.circular(999.0),
                            ),
                            child: Text(
                              filter,
                              style: AppTypography.caption.copyWith(
                                fontSize: 13.0,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.ink
                                    : (isDark
                                          ? AppColors.white
                                          : AppColors.ink),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24.0),

                // Hasil Pencarian: Kartu, Dokumen, Tag
                if (totalResults == 0)
                  CardlyEmptyState(
                    icon: Icons.search_rounded,
                    title: 'Tidak ada hasil.',
                    description: 'Coba nama, kategori, atau tag lain. Nomor sensitif tidak dicari.',
                    actionButtonText: 'Hapus pencarian',
                    onActionPressed: () => _searchController.clear(),
                  )
                else ...[
                  // Bagian: Kartu
                  if ((_activeFilter == 'Semua' || _activeFilter == 'Kartu') &&
                      matchingCards.isNotEmpty) ...[
                    Text(
                      'Kartu',
                      style: AppTypography.sectionHeading.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        children: List.generate(matchingCards.length, (i) {
                          final c = matchingCards[i];
                          return InkWell(
                            onTap: () => context.push('/cards/${c.id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 24.0,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.ink,
                                  ),
                                  const SizedBox(width: 14.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.nickname,
                                          style: AppTypography.compactBodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15.0,
                                                color: isDark
                                                    ? AppColors.white
                                                    : AppColors.ink,
                                              ),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          '${c.category.displayName} · ${c.issuer}',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 13.0,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20.0,
                                    color: isDark
                                        ? AppColors.mediumGray
                                        : AppColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // Bagian: Dokumen
                  if ((_activeFilter == 'Semua' ||
                          _activeFilter == 'Dokumen') &&
                      matchingDocs.isNotEmpty) ...[
                    Text(
                      'Dokumen',
                      style: AppTypography.sectionHeading.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        children: List.generate(matchingDocs.length, (i) {
                          final d = matchingDocs[i];
                          return InkWell(
                            onTap: () => context.push('/documents/${d.id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 24.0,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.ink,
                                  ),
                                  const SizedBox(width: 14.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.title,
                                          style: AppTypography.compactBodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15.0,
                                                color: isDark
                                                    ? AppColors.white
                                                    : AppColors.ink,
                                              ),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          '${d.category.displayName} · ${d.fileType.name.toUpperCase()} · ${CardlyFormatters.formatDate(d.createdAt)}',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 13.0,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20.0,
                                    color: isDark
                                        ? AppColors.mediumGray
                                        : AppColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // Bagian: Tag
                  if ((_activeFilter == 'Semua' || _activeFilter == 'Tag') &&
                      matchingTags.isNotEmpty) ...[
                    Text(
                      'Tag',
                      style: AppTypography.sectionHeading.copyWith(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        children: List.generate(matchingTags.length, (i) {
                          final t = matchingTags[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 22.0,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.ink,
                                ),
                                const SizedBox(width: 14.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t,
                                        style: AppTypography.compactBodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15.0,
                                              color: isDark
                                                  ? AppColors.white
                                                  : AppColors.ink,
                                            ),
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        '1 dokumen ditandai',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 13.0,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20.0,
                                  color: isDark
                                      ? AppColors.mediumGray
                                      : AppColors.muted,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
