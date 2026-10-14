import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../app_update/data/app_update_service.dart';
import '../../app_update/presentation/app_update_modal.dart';

class ProfileDashboardView extends ConsumerWidget {
  const ProfileDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final cards = ref.watch(cardListProvider);
    final documents = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Avatar & Name Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
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
                          style: AppTypography.titleMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email,
                          style: AppTypography.bodySmall(context)
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Ubah Profil',
                    onPressed: () => _editProfileDialog(context, ref, profile),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Local Vault Guarantee Banner
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
                    Icons.verified_outlined,
                    color: AppColors.lime,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Berdaulat Penuh',
                          style: AppTypography.titleSmall(context)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${cards.length} kartu & ${documents.length} dokumen tersimpan secara lokal tanpa server.',
                          style: AppTypography.caption(context)
                              .copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Menu Section: Pengaturan Aplikasi
            Text(
              'Pengaturan',
              style: AppTypography.titleSmall(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Material(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text('Keamanan & Brankas'),
                    subtitle: const Text('Biometrik, PIN, dan proteksi kunci'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/vault/security'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_outlined),
                    title: const Text('Sinkronisasi Cloud Supabase'),
                    subtitle: const Text(
                      'Cadangan cloud aman & Row Level Security',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/sync'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Tampilan & Tema'),
                    subtitle: const Text('Mode Terang, Gelap, atau Sistem'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/theme'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: const Text('Ekspor Cadangan Data'),
                    subtitle: const Text('Simpan berkas cadangan terenkripsi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/export'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Informasi Privasi & Keamanan'),
                    subtitle: const Text('Transparansi penyimpanan data lokal'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/privacy'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.system_update_rounded),
                    title: const Text('Periksa Pembaruan Aplikasi'),
                    subtitle: const Text('v1.0.0 • Cek versi rilis terbaru'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _handleManualUpdateCheck(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Logout Button
            CardlyButton(
              text: 'Keluar Akun',
              variant: CardlyButtonVariant.quiet,
              icon: Icons.logout,
              onPressed: () => _confirmLogout(context, ref),
            ),

            const SizedBox(height: AppSpacing.lg),

            Center(
              child: Text(
                'Cardly v1.0.0 (Build 100) • Indonesia',
                style: AppTypography.caption(context)
                    .copyWith(color: AppColors.mutedText),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _editProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final nameController = TextEditingController(text: profile.fullName);
    final emailController = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Profil Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () {
              ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.logout, size: 44, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keluar dari Cardly?',
            style: AppTypography.titleMedium(context)
                .copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Data Anda tetap aman tersimpan di perangkat lokal.',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          CardlyButton(
            text: 'Keluar',
            variant: CardlyButtonVariant.destructive,
            onPressed: () async {
              ref.read(userProfileProvider.notifier).logout();
              final supabase = ref.read(supabaseServiceProvider);
              await supabase.signOut();
              await supabase.signOutGoogle();
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/welcome');
              }
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

  Future<void> _handleManualUpdateCheck(
    BuildContext context,
    WidgetRef ref,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memeriksa ketersediaan versi terbaru...'),
        duration: Duration(seconds: 2),
      ),
    );

    final updateService = ref.read(appUpdateServiceProvider);
    final info = await updateService.checkForUpdate();

    if (!context.mounted) return;

    if (info != null) {
      AppUpdateModal.show(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cardly sudah menggunakan versi terbaru (v1.0.0)!'),
          backgroundColor: AppColors.ink,
        ),
      );
    }
  }
}
