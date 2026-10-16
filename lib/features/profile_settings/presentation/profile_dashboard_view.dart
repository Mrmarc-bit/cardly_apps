import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_bottom_sheet.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../../../core/widgets/cardly_toast.dart';
import '../../app_update/data/app_update_service.dart';
import '../../app_update/presentation/app_update_modal.dart';

class ProfileDashboardView extends ConsumerWidget {
  const ProfileDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final versionStr = packageInfoAsync.when(
      data: (info) => 'v${info.version}',
      loading: () => 'v...',
      error: (_, _) => 'Cardly',
    );
    final fullVersionStr = packageInfoAsync.when(
      data: (info) =>
          'Cardly v${info.version} (Build ${info.buildNumber}) • Indonesia',
      loading: () => 'Cardly • Indonesia',
      error: (_, _) => 'Cardly • Indonesia',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenInset,
          vertical: AppSpacing.sm,
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
                  GestureDetector(
                    onTap: () => _showAvatarBottomSheet(context, ref, profile),
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.lime.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                (profile.avatarPath.isNotEmpty &&
                                    File(profile.avatarPath).existsSync())
                                ? Image.file(
                                    File(profile.avatarPath),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
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
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.cardBackground,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
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
                    title: const Text('Sinkronisasi Cloud'),
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
                    subtitle: Text('$versionStr • Cek versi rilis terbaru'),
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
                fullVersionStr,
                style: AppTypography.caption(context)
                    .copyWith(color: AppColors.mutedText),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showAvatarBottomSheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar =
        profile.avatarPath.isNotEmpty && File(profile.avatarPath).existsSync();

    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Avatar Preview
          Center(
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lime.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.file(
                            File(profile.avatarPath),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              profile.fullName.isNotEmpty
                                  ? profile.fullName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Foto Profil',
            style: AppTypography.titleMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih metode untuk memperbarui foto profil Cardly Anda',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action Option Tiles
          _AvatarOptionTile(
            icon: Icons.photo_camera_rounded,
            title: 'Ambil Foto dari Kamera',
            subtitle: 'Buka kamera untuk mengambil foto baru',
            isDark: isDark,
            onTap: () => _pickAndSaveAvatar(context, ref, ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AvatarOptionTile(
            icon: Icons.photo_library_rounded,
            title: 'Pilih dari Galeri',
            subtitle: 'Pilih berkas foto dari galeri gawai Anda',
            isDark: isDark,
            onTap: () => _pickAndSaveAvatar(context, ref, ImageSource.gallery),
          ),

          if (hasAvatar) ...[
            const SizedBox(height: AppSpacing.sm),
            _AvatarOptionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Hapus Foto Profil',
              subtitle: 'Gunakan kembali inisial nama sebagai avatar',
              isDark: isDark,
              isDestructive: true,
              onTap: () {
                ref.read(userProfileProvider.notifier).removeAvatar();
                Navigator.pop(context);
                CardlyToast.showSuccess(
                  context,
                  'Foto profil berhasil dihapus.',
                );
              },
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          CardlyButton(
            text: 'Batal',
            variant: CardlyButtonVariant.quiet,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSaveAvatar(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    ref.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (xFile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${appDir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(xFile.path)
          .copy('${avatarDir.path}/$fileName');

      ref.read(userProfileProvider.notifier).updateAvatar(savedFile.path);

      if (context.mounted) {
        Navigator.pop(context);
        CardlyToast.showSuccess(context, 'Foto profil berhasil diperbarui!');
      }
    } catch (e) {
      if (context.mounted) {
        CardlyToast.showError(context, 'Gagal memperbarui foto profil: $e');
      }
    } finally {
      ref.read(isExternalOperationInProgressProvider.notifier).state = false;
    }
  }

  void _editProfileDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: profile.fullName);
    final emailController = TextEditingController(text: profile.email);
    final hasAvatar =
        profile.avatarPath.isNotEmpty && File(profile.avatarPath).existsSync();

    CardlyBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ubah Profil Akun',
            style: AppTypography.titleMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Perbarui nama lengkap, alamat email, atau foto profil Anda',
            style: AppTypography.bodySmall(context)
                .copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Avatar change button
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showAvatarBottomSheet(context, ref, profile);
              },
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lime.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasAvatar
                          ? Image.file(
                              File(profile.avatarPath),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                profile.fullName.isNotEmpty
                                    ? profile.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.charcoal : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lime, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showAvatarBottomSheet(context, ref, profile);
              },
              child: const Text(
                'Ganti Foto Profil',
                style: TextStyle(
                  color: AppColors.lime,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: isDark ? AppColors.charcoal : AppColors.mist,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.softGray,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.softGray,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Alamat Email',
              prefixIcon: const Icon(Icons.mail_outline),
              filled: true,
              fillColor: isDark ? AppColors.charcoal : AppColors.mist,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.softGray,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.softGray,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: const BorderSide(color: AppColors.lime, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          CardlyPrimaryButton(
            text: 'Simpan Perubahan',
            onPressed: () {
              ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                  );
              Navigator.pop(context);
              CardlyToast.showSuccess(context, 'Profil berhasil diperbarui.');
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
    CardlyToast.showInfo(context, 'Memeriksa ketersediaan versi terbaru...');

    final updateService = ref.read(appUpdateServiceProvider);
    final info = await updateService.checkForUpdate();

    if (!context.mounted) return;

    if (info != null) {
      AppUpdateModal.show(context, info);
    } else {
      final localVer = await updateService.getLocalVersion();
      if (!context.mounted) return;
      CardlyToast.showSuccess(
        context,
        'Cardly sudah menggunakan versi terbaru (v$localVer)!',
      );
    }
  }
}

class _AvatarOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _AvatarOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.white : AppColors.ink);
    final iconBg = isDestructive
        ? AppColors.error.withValues(alpha: 0.12)
        : AppColors.lime.withValues(alpha: isDark ? 0.2 : 0.25);
    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.lime : AppColors.ink);

    return Material(
      color: isDark ? AppColors.charcoal : AppColors.mist,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption(context).copyWith(
                        color: isDestructive
                            ? AppColors.error.withValues(alpha: 0.8)
                            : AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkBorder : AppColors.softGray,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
