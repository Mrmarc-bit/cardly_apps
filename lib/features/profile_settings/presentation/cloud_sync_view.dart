import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cardly_buttons.dart';

/// Tampilan Pengaturan Sinkronisasi Cloud Supabase Cardly
class CloudSyncView extends ConsumerStatefulWidget {
  const CloudSyncView({super.key});

  @override
  ConsumerState<CloudSyncView> createState() => _CloudSyncViewState();
}

class _CloudSyncViewState extends ConsumerState<CloudSyncView> {
  bool _isSyncing = false;
  String? _statusFeedback;
  bool _isFeedbackError = false;

  Future<void> _handleSyncNow() async {
    final syncService = ref.read(cloudSyncServiceProvider);
    setState(() {
      _isSyncing = true;
      _statusFeedback = null;
    });

    try {
      final report = await syncService.syncAll();
      if (!mounted) return;

      if (report.isSuccess) {
        // Refresh local lists
        ref.read(cardListProvider.notifier).refresh();
        ref.read(documentListProvider.notifier).refresh();
        ref.read(reminderListProvider.notifier).refresh();

        setState(() {
          _isFeedbackError = false;
          _statusFeedback =
              'Sinkronisasi sukses! ${report.totalItems} item disinkronkan (${report.cardsPushed + report.cardsPulled} kartu, ${report.documentsPushed + report.documentsPulled} dokumen, ${report.remindersPushed + report.remindersPulled} pengingat).';
        });
      } else {
        setState(() {
          _isFeedbackError = true;
          _statusFeedback =
              report.errorMessage ?? 'Gagal melakukan sinkronisasi.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFeedbackError = true;
        _statusFeedback = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final supabase = ref.watch(supabaseServiceProvider);
    final syncService = ref.watch(cloudSyncServiceProvider);
    final cards = ref.watch(cardListProvider);
    final documents = ref.watch(documentListProvider);
    final reminders = ref.watch(reminderListProvider);
    final profile = ref.watch(userProfileProvider);

    final lastSync = syncService.lastSyncTime;
    final lastSyncFormatted = Formatters.formatDateTime(lastSync);

    final currentUser = supabase.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.ink : AppColors.mist,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Sinkronisasi Cloud',
          style: AppTypography.pageHeading.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: AppSpacing.md,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            // Info Akun & Sesi
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.softGray,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akun Tertaut',
                    style: AppTypography.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.lime,
                        child: Text(
                          (currentUser?.email ?? profile.fullName).isNotEmpty
                              ? (currentUser?.email ?? profile.fullName)[0]
                                    .toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: AppTypography.bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.white : AppColors.ink,
                              ),
                            ),
                            Text(
                              currentUser?.email ?? profile.email,
                              style: AppTypography.caption(context).copyWith(
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
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Ringkasan Data Lokal yang Disinkronkan
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.softGray,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Siap Sinkron',
                    style: AppTypography.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBadge(
                        label: 'Kartu',
                        count: cards.length,
                        icon: Icons.credit_card_rounded,
                        isDark: isDark,
                      ),
                      _StatBadge(
                        label: 'Dokumen',
                        count: documents.length,
                        icon: Icons.description_rounded,
                        isDark: isDark,
                      ),
                      _StatBadge(
                        label: 'Pengingat',
                        count: reminders.length,
                        icon: Icons.alarm_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terakhir Sinkron:',
                        style: AppTypography.caption(context).copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.muted,
                        ),
                      ),
                      Text(
                        lastSyncFormatted,
                        style: AppTypography.caption(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_statusFeedback != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _isFeedbackError
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: _isFeedbackError
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isFeedbackError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _isFeedbackError ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _statusFeedback!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isFeedbackError
                              ? (isDark
                                    ? Colors.red.shade200
                                    : Colors.red.shade900)
                              : (isDark
                                    ? Colors.green.shade200
                                    : Colors.green.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Tombol Sinkronisasi Utama
            if (_isSyncing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.lime),
                ),
              )
            else
              CardlyPrimaryButton(
                text: 'Sinkronkan Sekarang',
                onPressed: _handleSyncNow,
              ),

            const SizedBox(height: AppSpacing.xl),

            // Jaminan Keamanan Row Level Security
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.charcoal.withValues(alpha: 0.5)
                    : AppColors.softGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.lime,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Privasi Mutlak: Kredensial sensitif perbankan (nomor kartu 16 digit lengkap, PIN, CVV) tidak pernah disimpan di database atau dikirim ke cloud. Setiap data Anda diisolasi menggunakan Enkripsi End-to-End & Row Level Security (RLS).',
                      style: AppTypography.caption(context).copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.lime),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: AppTypography.pageHeadingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.ink,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption(context).copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
