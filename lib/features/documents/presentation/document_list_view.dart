import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_empty_state.dart';
import '../domain/document_model.dart';

class DocumentListView extends ConsumerStatefulWidget {
  const DocumentListView({super.key});

  @override
  ConsumerState<DocumentListView> createState() => _DocumentListViewState();
}

class _DocumentListViewState extends ConsumerState<DocumentListView> {
  DocumentCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter documents
    final filteredDocs = documents.where((doc) {
      if (_selectedCategory != null && doc.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(q);
        final matchDocNum =
            doc.documentNumber?.toLowerCase().contains(q) ?? false;
        final matchIssuer = doc.issuer?.toLowerCase().contains(q) ?? false;
        if (!matchTitle && !matchDocNum && !matchIssuer) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumen'),
        actions: [
          IconButton(
            tooltip: 'Cari Dokumen',
            icon: Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.search,
            ),
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                setState(() => _searchQuery = '');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Minimalist Search Input
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenInset,
              vertical: 8.0,
            ),
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
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColors.white : AppColors.ink,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari judul, nomor, atau penerbit...',
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
                      child: Icon(
                        Icons.close,
                        size: 18.0,
                        color: isDark ? AppColors.mediumGray : AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Category chips bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenInset,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _buildCategoryChip(
                  label: 'Semua',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...DocumentCategory.values.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: _buildCategoryChip(
                      label: cat.displayName,
                      isSelected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content list or empty state
          Expanded(
            child: filteredDocs.isEmpty
                ? CardlyEmptyState(
                    title: _searchQuery.isNotEmpty
                        ? 'Dokumen tidak ditemukan'
                        : 'Belum ada dokumen',
                    description: _searchQuery.isNotEmpty
                        ? 'Coba gunakan kata kunci pencarian lain atau pilih kategori Semua.'
                        : 'Simpan pindaian KTP, SIM, ijazah, atau polis asuransi Anda dengan aman di Cardly.',
                    icon: Icons.folder_open_outlined,
                    buttonText: _searchQuery.isNotEmpty
                        ? null
                        : 'Tambah Dokumen',
                    onButtonPressed: _searchQuery.isNotEmpty
                        ? null
                        : () => context.push('/documents/create'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenInset),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return _buildDocumentTile(context, doc, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: filteredDocs.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/documents/create'),
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
              icon: const Icon(Icons.add),
              label: Text(
                'Tambah',
                style: AppTypography.titleSmall(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.lime : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(context).copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.ink : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(
    BuildContext context,
    DocumentItem doc,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => context.push('/documents/${doc.id}'),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // File type icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Center(
                child: Text(
                  doc.fileType.name.toUpperCase(),
                  style: AppTypography.caption(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Document details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc.title,
                          style: AppTypography.titleSmall(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (doc.isVaultProtected) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: AppColors.mutedText,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        doc.category.displayName,
                        style: AppTypography.caption(context)
                            .copyWith(color: AppColors.mutedText),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                      Text(
                        CardlyFormatters.formatFileSize(doc.fileSizeBytes),
                        style: AppTypography.caption(context)
                            .copyWith(color: AppColors.mutedText),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                      Text(
                        CardlyFormatters.formatDate(doc.createdAt),
                        style: AppTypography.caption(context)
                            .copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
