import 'dart:io';

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
import '../../../core/widgets/cardly_toast.dart';
import '../../../core/widgets/cardly_visual_card.dart';
import '../../app_update/data/app_update_service.dart';
import '../../app_update/presentation/app_update_modal.dart';

/// Tampilan Beranda resmi Cardly sesuai referensi:
/// - docs/5. Home/10 Beranda • Terang.png
/// - docs/5. Home/11 Beranda • Gelap.png
/// - docs/5. Home/69 Beranda • 360.png
class HomeDashboardView extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const HomeDashboardView({super.key, this.onSwitchTab});

  @override
  ConsumerState<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends ConsumerState<HomeDashboardView> {
  bool _isMasked = true;
  late final PageController _cardPageController;

  @override
  void initState() {
    super.initState();
    _cardPageController = PageController(viewportFraction: 0.90);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardListProvider.notifier).refresh();
      ref.read(documentListProvider.notifier).refresh();
      ref.read(reminderListProvider.notifier).refresh();
      _checkAutoUpdate();
    });
  }

  Future<void> _checkAutoUpdate() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final updateService = ref.read(appUpdateServiceProvider);
      final info = await updateService.checkForUpdate();
      if (info != null && mounted) {
        // Tampilkan notifikasi native di status bar / drawer HP
        updateService.showSystemNotification(
          version: info.latestVersion,
          changelog: info.changelog.isNotEmpty
              ? info.changelog.first
              : 'Pembaruan versi ${info.latestVersion} telah tersedia.',
        );

        // Tampilkan toast in-app resmi Cardly
        CardlyToast.showInfo(
          context,
          'Pembaruan Cardly v${info.latestVersion} tersedia!',
        );

        // Buka modal bottom sheet rilis
        AppUpdateModal.show(context, info);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  void _toggleMasking() {
    HapticFeedback.selectionClick();
    setState(() => _isMasked = !_isMasked);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat pagi';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat sore';
    } else {
      return 'Selamat malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProfileProvider);
    final cards = ref.watch(cardListProvider);
    final docs = ref.watch(documentListProvider);
    final reminders = ref.watch(reminderListProvider);

    final featuredCards = cards.take(4).toList();
    final recentDocs = docs.take(2).toList();
    final pendingReminders = reminders.where((r) => !r.isCompleted).toList();
    final urgentReminder = pendingReminders.isNotEmpty
        ? pendingReminders.first
        : null;

    final cardBg = isDark ? AppColors.charcoal : AppColors.white;
    final borderColor = isDark ? AppColors.elevatedDark : AppColors.softGray;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky Top Navigation Bar (Salam, Nama Pengguna, Lonceng Notifikasi, Avatar)
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16.0,
                horizontalPadding,
                12.0,
              ),
              child: _buildTopStickyHeader(user, isDark, borderColor),
            ),
            // Area Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  4.0,
                  horizontalPadding,
                  16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Ringkasan: Dompet Saya
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 18.0,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: AppRadius.cardRadius,
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dompet Saya',
                            style: AppTypography.compactBodyMedium.copyWith(
                              color: isDark ? AppColors.white : AppColors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 15.0,
                            ),
                          ),
                          const SizedBox(height: 14.0),
                          Row(
                            children: [
                              // Jumlah Kartu
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onSwitchTab?.call(1),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${cards.length}',
                                      style: AppTypography.tabular(
                                        AppTypography.largeHeading.copyWith(
                                          fontSize: 32.0,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.white
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      'kartu',
                                      style: AppTypography.compactBody.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.muted,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24.0),
                              // Jumlah Dokumen
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => widget.onSwitchTab?.call(2),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${docs.length}',
                                      style: AppTypography.tabular(
                                        AppTypography.largeHeading.copyWith(
                                          fontSize: 32.0,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.white
                                              : AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      'dokumen',
                                      style: AppTypography.compactBody.copyWith(
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.muted,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Status Masking Interaktif
                              InkWell(
                                onTap: _toggleMasking,
                                borderRadius: BorderRadius.circular(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isMasked
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 16.0,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.muted,
                                      ),
                                      const SizedBox(width: 5.0),
                                      Text(
                                        _isMasked
                                            ? 'Disamarkan'
                                            : 'Ditampilkan',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 12.0,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // Bagian: Kartu pilihan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kartu pilihan',
                          style: AppTypography.sectionHeading.copyWith(
                            color: isDark ? AppColors.white : AppColors.ink,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onSwitchTab?.call(1),
                          child: Text(
                            'Lihat semua',
                            style: AppTypography.captionMedium.copyWith(
                              color: isDark ? AppColors.white : AppColors.ink,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    // Carousel Kartu Pilihan dengan Snapping Halus
                    if (featuredCards.isEmpty)
                      CardlyEmptyState(
                        icon: Icons.credit_card_outlined,
                        title: 'Belum ada kartu.',
                        description: 'Tambahkan kartu pertama tanpa menyimpan kredensial lengkap.',
                        actionButtonText: 'Tambah Kartu',
                        onActionPressed: () => context.push('/cards/create'),
                      )
                    else
                      SizedBox(
                        height: 195.0,
                        child: PageView.builder(
                          controller: _cardPageController,
                          itemCount: featuredCards.length,
                          itemBuilder: (context, idx) {
                            final card = featuredCards[idx];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: CardlyVisualCard(
                                aspectRatio: null,
                                nickname: card.nickname,
                                issuer: card.issuer,
                                lastFourDigits: card.lastFourDigits,
                                isMasked: _isMasked,
                                category: card.category.label,
                                network: card.network,
                                colorTheme: card.colorTheme,
                                showActionButton: true,
                                actionButtonText: 'Lihat Detail ↗',
                                onActionTap: () =>
                                    context.push('/cards/${card.id}'),
                                onTap: () => context.push('/cards/${card.id}'),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 24.0),

                    // Aksi Cepat (4 Grid Buttons Sesuai Desain docs/5. Home/10 Beranda • Terang.png)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _QuickActionButton(
                          icon: Icons.add_rounded,
                          label: 'Tambah Kartu',
                          onTap: () => context.push('/cards/create'),
                        ),
                        _QuickActionButton(
                          icon: Icons.crop_free_rounded,
                          label: 'Scan Dokumen',
                          onTap: () => context.push('/documents/scan'),
                        ),
                        _QuickActionButton(
                          icon: Icons.create_new_folder_outlined,
                          label: 'Buat Folder',
                          onTap: () => context.push('/folders/create'),
                        ),
                        _QuickActionButton(
                          icon: Icons.notifications_none_rounded,
                          label: 'Pengingat',
                          onTap: () => context.push('/reminders'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28.0),

                    // Bagian: Baru ditambahkan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Baru ditambahkan',
                          style: AppTypography.sectionHeading.copyWith(
                            color: isDark ? AppColors.white : AppColors.ink,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onSwitchTab?.call(2),
                          child: Text(
                            'Lihat semua',
                            style: AppTypography.captionMedium.copyWith(
                              color: isDark ? AppColors.white : AppColors.ink,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    // Kontainer Berkas Baru Ditambahkan
                    if (recentDocs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 28.0,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52.0,
                              height: 52.0,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.elevatedDark
                                    : AppColors.softGray,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.description_outlined,
                                size: 26.0,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 14.0),
                            Text(
                              'Belum ada dokumen tersimpan',
                              style: AppTypography.bodySemiBold.copyWith(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.white : AppColors.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Pindai KTP, SIM, atau dokumen penting untuk akses cepat dan aman.',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.muted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/documents/scan');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18.0,
                                  vertical: 9.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lime,
                                  borderRadius: AppRadius.pillRadius,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.lime.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 10.0,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      size: 16.0,
                                      color: AppColors.ink,
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      'Pindai Dokumen',
                                      style: AppTypography.tinyLabel.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(color: borderColor, width: 1.0),
                        ),
                        child: Column(
                          children: List.generate(recentDocs.length, (index) {
                            final doc = recentDocs[index];
                            final isLast = index == recentDocs.length - 1;
                            final isFirstDoc = index == 0;

                            return Column(
                              children: [
                                _RecentItemTile(
                                  icon: isFirstDoc
                                      ? Icons.verified_outlined
                                      : Icons.description_outlined,
                                  title: doc.title,
                                  subtitle:
                                      '${doc.category.displayName} • ${CardlyFormatters.formatDate(doc.createdAt)}',
                                  onTap: () =>
                                      context.push('/documents/${doc.id}'),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1.0,
                                    indent: 64.0,
                                    endIndent: 16.0,
                                    color: borderColor,
                                  ),
                              ],
                            );
                          }),
                        ),
                      ),

                    // Kartu Peringatan Kedaluwarsa Mendesak Standalone (docs/5. Home/10 Beranda • Terang.png)
                    if (urgentReminder != null) ...[
                      const SizedBox(height: 12.0),
                      GestureDetector(
                        onTap: () => context.push('/reminders'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 14.0,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: AppRadius.cardRadius,
                            border: Border.all(color: borderColor, width: 1.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.elevatedDark
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: AppRadius.inputRadius,
                                ),
                                child: const Icon(
                                  Icons.calendar_month_outlined,
                                  size: 20.0,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${urgentReminder.title} • 30 hari lagi',
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
                                      'Kedaluwarsa ${CardlyFormatters.formatDate(urgentReminder.reminderDate)}',
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
                      ),
                    ],

                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStickyHeader(
    UserProfile user,
    bool isDark,
    Color borderColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
                fontSize: 13.0,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              user.fullName,
              style: AppTypography.largeHeading.copyWith(
                fontSize: 26.0,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.ink,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Tombol Lonceng dengan Badge Titik Lime
            InkWell(
              onTap: () => _showNotificationSheet(context, isDark),
              borderRadius: BorderRadius.circular(999.0),
              child: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: isDark ? AppColors.white : AppColors.ink,
                      size: 22.0,
                    ),
                    Positioned(
                      top: 10.0,
                      right: 11.0,
                      child: Container(
                        width: 8.0,
                        height: 8.0,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            // Avatar Bulat (Foto Profil jika ada, fallback ke Inisial)
            GestureDetector(
              onTap: () => widget.onSwitchTab?.call(4), // Tab Profil
              child: Builder(
                builder: (context) {
                  final hasAvatar =
                      user.avatarPath.isNotEmpty &&
                      File(user.avatarPath).existsSync();
                  if (hasAvatar) {
                    return Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.lime : AppColors.ink,
                          width: 1.5,
                        ),
                        image: DecorationImage(
                          image: FileImage(File(user.avatarPath)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 44.0,
                    height: 44.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : AppColors.softGray,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'M',
                      style: AppTypography.bodySemiBold.copyWith(
                        fontSize: 16.0,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showNotificationSheet(BuildContext context, bool isDark) {
    final pkg = ref.read(packageInfoProvider).valueOrNull;
    final verTitle = pkg != null
        ? 'Versi ${pkg.version} Terpasang'
        : 'Versi Terpasang Aktif';

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.charcoal : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.elevatedDark
                          : AppColors.softGray,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pemberitahuan & Aktivitas',
                      style: AppTypography.sectionHeading.copyWith(
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lime.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Terkini',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.lime : AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                _buildNotificationItem(
                  isDark: isDark,
                  icon: Icons.system_update_rounded,
                  title: verTitle,
                  desc: 'Aplikasi berjalan pada rilis terbaru dengan proteksi privasi mandiri.',
                  time: 'Aktif',
                ),
                const SizedBox(height: 12.0),
                _buildNotificationItem(
                  isDark: isDark,
                  icon: Icons.shield_outlined,
                  title: 'Brankas Data Siap & Terkunci',
                  desc: 'Seluruh kartu dan dokumen Anda disimpan secara terenkripsi di perangkat ini.',
                  time: 'Hari ini',
                ),
                const SizedBox(height: 20.0),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? AppColors.elevatedDark
                            : AppColors.softGray,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/reminders');
                    },
                    child: Text(
                      'Buka Pengingat Masa Berlaku',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String desc,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.ink : AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: isDark ? AppColors.elevatedDark : AppColors.softGray,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.lime : AppColors.ink,
              size: 18.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                        color: isDark ? AppColors.white : AppColors.ink,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11.0,
                        color: isDark ? AppColors.mediumGray : AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12.0,
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
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final boxSize = screenWidth < 380 ? 56.0 : 64.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: boxSize + 12.0,
        child: Column(
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.white,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(
                  color: isDark ? AppColors.elevatedDark : AppColors.softGray,
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 24.0,
                color: isDark ? AppColors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevatedDark : AppColors.softGray,
                borderRadius: AppRadius.inputRadius,
              ),
              child: Icon(
                icon,
                size: 20.0,
                color: isDark ? AppColors.white : AppColors.ink,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.compactBodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
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
              color: isDark ? AppColors.mediumGray : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
