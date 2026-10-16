import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../../core/widgets/cardly_visual_card.dart';
import '../domain/card_model.dart';

class CardDetailView extends ConsumerWidget {
  final String cardId;

  const CardDetailView({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardIndex = cards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kartu')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.credit_card_off,
                size: 48,
                color: AppColors.mutedText,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Kartu tidak ditemukan',
                style: AppTypography.titleMedium(context)
                    .copyWith(color: isDark ? AppColors.white : AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.lg),
              CardlyButton(text: 'Kembali', onPressed: () => context.pop()),
            ],
          ),
        ),
      );
    }

    final card = cards[cardIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kartu'),
        actions: [
          IconButton(
            tooltip: card.isFavorite
                ? 'Hapus dari Favorit'
                : 'Tambah ke Favorit',
            icon: Icon(
              card.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: card.isFavorite ? Colors.redAccent : null,
            ),
            onPressed: () {
              ref.read(cardListProvider.notifier).toggleFavorite(card.id);
              CardlyToast.showSuccess(
                context,
                card.isFavorite
                    ? 'Dihapus dari favorit'
                    : 'Ditambahkan ke favorit',
              );
            },
          ),
          IconButton(
            tooltip: 'Menu opsi',
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showActionMenu(context, ref, card),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Preview Banner
            CardlyVisualCard(
              title: card.title,
              holderName: card.holderName,
              maskedNumber: card.category == CardCategory.payment
                  ? CardlyFormatters.maskCardNumber(card.lastFourDigits)
                  : card.lastFourDigits,
              expiryDate: card.expiryDate != null
                  ? CardlyFormatters.formatExpiry(card.expiryDate!)
                  : null,
              issuer: card.issuer,
              theme: card.theme,
              isContactless: card.isContactless,
              categoryName: card.category.displayName,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Metadata card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Kartu',
                    style: AppTypography.titleMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildMetaRow(
                    context,
                    label: 'Kategori',
                    value: card.category.displayName,
                    icon: Icons.category_outlined,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildMetaRow(
                    context,
                    label: 'Penerbit / Institusi',
                    value: card.issuer,
                    icon: Icons.account_balance_outlined,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildMetaRow(
                    context,
                    label: card.category == CardCategory.payment
                        ? '4 Digit Terakhir'
                        : 'Nomor Referensi',
                    value: card.lastFourDigits,
                    icon: Icons.tag_outlined,
                    isCopyable: true,
                  ),
                  if (card.expiryDate != null) ...[
                    const Divider(height: AppSpacing.lg),
                    _buildMetaRow(
                      context,
                      label: 'Masa Berlaku',
                      value: CardlyFormatters.formatExpiry(card.expiryDate!),
                      icon: Icons.event_outlined,
                    ),
                  ],
                  if (card.notes != null && card.notes!.isNotEmpty) ...[
                    const Divider(height: AppSpacing.lg),
                    _buildMetaRow(
                      context,
                      label: 'Catatan Pribadi',
                      value: card.notes!,
                      icon: Icons.notes_outlined,
                    ),
                  ],
                  const Divider(height: AppSpacing.lg),
                  _buildMetaRow(
                    context,
                    label: 'Status Arsip',
                    value: card.isArchived ? 'Diarsipkan' : 'Aktif',
                    icon: Icons.archive_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Security note for payment cards
            if (card.category == CardCategory.payment)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : AppColors.mist,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.softGray,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Cardly hanya menyimpan 4 digit referensi. CVV, PIN, atau data kredensial tidak pernah diminta.',
                        style: AppTypography.bodySmall(context)
                            .copyWith(color: AppColors.mutedText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CardlyButton(
                    text: 'Edit Kartu',
                    variant: CardlyButtonVariant.secondary,
                    icon: Icons.edit_outlined,
                    onPressed: () => context.push('/cards/${card.id}/edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CardlyButton(
                    text: card.isArchived ? 'Buka Arsip' : 'Arsipkan',
                    variant: CardlyButtonVariant.quiet,
                    icon: card.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                    onPressed: () => _confirmArchive(context, ref, card),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CardlyButton(
              text: 'Hapus Kartu',
              variant: CardlyButtonVariant.destructive,
              icon: Icons.delete_outline,
              onPressed: () => _confirmDelete(context, ref, card),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isCopyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mutedText),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption(context)
                    .copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            tooltip: 'Salin',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              CardlyToast.showSuccess(
                context,
                'Nomor berhasil disalin ke clipboard',
              );
            },
          ),
      ],
    );
  }

  void _showActionMenu(BuildContext context, WidgetRef ref, CardItem card) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.title,
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Informasi Kartu'),
            onTap: () {
              Navigator.pop(context);
              context.push('/cards/${card.id}/edit');
            },
          ),
          ListTile(
            leading: Icon(
              card.isFavorite ? Icons.favorite_border : Icons.favorite,
            ),
            title: Text(
              card.isFavorite ? 'Hapus dari Favorit' : 'Jadikan Favorit',
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(cardListProvider.notifier).toggleFavorite(card.id);
            },
          ),
          ListTile(
            leading: Icon(
              card.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            title: Text(card.isArchived ? 'Batalkan Arsip' : 'Arsipkan Kartu'),
            onTap: () {
              Navigator.pop(context);
              _confirmArchive(context, ref, card);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Hapus Kartu',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, card);
            },
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, CardItem card) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            card.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            size: 44,
            color: AppColors.charcoal,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            card.isArchived ? 'Buka Arsip Kartu?' : 'Arsipkan Kartu?',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            card.isArchived
                ? 'Kartu "${card.title}" akan dikembalikan ke daftar aktif kartu Anda.'
                : 'Kartu "${card.title}" akan dipindahkan ke folder arsip dan disembunyikan dari daftar utama.',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          CardlyButton(
            text: card.isArchived ? 'Ya, Buka Arsip' : 'Ya, Arsipkan',
            onPressed: () {
              ref
                  .read(cardListProvider.notifier)
                  .archiveCard(card.id, !card.isArchived);
              Navigator.pop(context);
              CardlyToast.showSuccess(
                context,
                card.isArchived
                    ? 'Kartu dikembalikan dari arsip'
                    : 'Kartu berhasil diarsipkan',
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          CardlyButton(
            text: 'Batal',
            variant: CardlyButtonVariant.quiet,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CardItem card) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.delete_forever_outlined,
            size: 44,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hapus Kartu Permanen?',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700, color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Data kartu "${card.title}" akan dihapus dari penyimpanan perangkat. Tindakan ini tidak dapat dibatalkan.',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          CardlyButton(
            text: 'Hapus Kartu',
            variant: CardlyButtonVariant.destructive,
            onPressed: () {
              ref.read(cardListProvider.notifier).deleteCard(card.id);
              Navigator.pop(context); // Close bottom sheet
              context.pop(); // Pop back to cards list
              CardlyToast.showSuccess(context, 'Kartu berhasil dihapus');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          CardlyButton(
            text: 'Batal',
            variant: CardlyButtonVariant.quiet,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
