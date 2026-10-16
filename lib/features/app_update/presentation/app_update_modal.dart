import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/cardly_buttons.dart';
import '../data/app_update_service.dart';
import '../domain/app_update_info.dart';

/// Modal Dialog Pembaruan Aplikasi Resmi Cardly (In-App Downloader & Installer)
class AppUpdateModal extends ConsumerStatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateModal({super.key, required this.updateInfo});

  /// Menampilkan modal bottom sheet pembaruan aplikasi
  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isDismissible: !info.isForceUpdate,
      enableDrag: !info.isForceUpdate,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.charcoal : AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      builder: (_) => AppUpdateModal(updateInfo: info),
    );
  }

  @override
  ConsumerState<AppUpdateModal> createState() => _AppUpdateModalState();
}

class _AppUpdateModalState extends ConsumerState<AppUpdateModal> {
  bool _isDownloading = false;
  bool _permissionNeeded = false;
  DownloadProgress? _downloadProgress;
  String? _errorMessage;
  String? _downloadedFilePath;
  StreamSubscription<DownloadProgress>? _downloadSub;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: _checkPermissionAndResumeInstall,
    );
    _checkExistingDownloadedApk();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _downloadSub?.cancel();
    super.dispose();
  }

  /// Memeriksa apakah berkas APK versi ini sudah pernah selesai diunduh sebelumnya
  Future<void> _checkExistingDownloadedApk() async {
    final updateService = ref.read(appUpdateServiceProvider);
    final existingPath = await updateService.getValidDownloadedApkPath(
      widget.updateInfo,
    );
    if (existingPath != null && mounted) {
      setState(() {
        _downloadedFilePath = existingPath;
      });
    }
  }

  /// Mendeteksi saat pengguna kembali dari Pengaturan HP dan otomatis melanjutkan instalasi
  Future<void> _checkPermissionAndResumeInstall() async {
    final updateService = ref.read(appUpdateServiceProvider);
    final canInstall = await updateService.canRequestPackageInstalls();
    if (canInstall && mounted) {
      setState(() {
        _permissionNeeded = false;
      });
      if (_downloadedFilePath != null) {
        await updateService.triggerApkInstall(_downloadedFilePath!);
      }
    }
  }

  Future<void> _startDownloadAndInstall() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMessage = null;
    });

    final updateService = ref.read(appUpdateServiceProvider);

    // Cek apakah berkas APK sudah pernah diunduh secara utuh
    final existingPath = await updateService.getValidDownloadedApkPath(
      widget.updateInfo,
    );
    if (existingPath != null) {
      setState(() {
        _downloadedFilePath = existingPath;
      });
      await _handleInstallApk(existingPath);
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final destPath = await updateService.getApkDestinationPath(
        info: widget.updateInfo,
      );
      final stream = updateService.downloadApk(
        downloadUrl: widget.updateInfo.downloadUrl,
        savePath: destPath,
      );

      _downloadSub = stream.listen(
        (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _errorMessage = 'Gagal mengunduh berkas: $e';
            });
          }
        },
        onDone: () async {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _downloadedFilePath = destPath;
            });
            // Double pulse tactile feedback saat unduhan selesai
            HapticFeedback.lightImpact();
            await Future.delayed(const Duration(milliseconds: 100));
            HapticFeedback.lightImpact();

            // Otomatis periksa izin & picu pemasang paket APK Android
            await _handleInstallApk(destPath);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }

  Future<void> _handleInstallApk(String filePath) async {
    final updateService = ref.read(appUpdateServiceProvider);
    final canInstall = await updateService.canRequestPackageInstalls();
    if (!canInstall && mounted) {
      setState(() {
        _permissionNeeded = true;
      });
      return;
    }
    await updateService.triggerApkInstall(filePath);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.updateInfo.isForceUpdate && !_isDownloading,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenInset,
            vertical: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis handle bottom sheet
              Center(
                child: Container(
                  width: 38.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.2)
                        : AppColors.softGray,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              const SizedBox(height: 20.0),

              // Header Ikon & Badge Versi Baru
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52.0,
                    height: 52.0,
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lime.withValues(alpha: 0.45),
                          blurRadius: 16.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.ink,
                      size: 26.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9.0,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.lime.withValues(alpha: 0.2)
                                    : AppColors.lime.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: AppColors.lime,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                'v${widget.updateInfo.latestVersion}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.lime,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            if (widget.updateInfo.isForceUpdate)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  'Wajib',
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Pembaruan Versi Tersedia',
                          style: AppTypography.pageHeading.copyWith(
                            fontSize: 19.0,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),

              // Daftar Catatan Rilis (Changelog)
              if (widget.updateInfo.changelog.isNotEmpty) ...[
                Text(
                  'APA YANG BARU:',
                  style: AppTypography.captionStyle.copyWith(
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.6)
                        : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.elevatedDark
                        : AppColors.softGray.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: isDark
                          ? AppColors.white.withValues(alpha: 0.08)
                          : AppColors.softGray,
                    ),
                  ),
                  child: Column(
                    children: widget.updateInfo.changelog
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2.0),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.lime,
                                    size: 14.0,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark
                                          ? AppColors.white
                                          : AppColors.ink,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 18.0),
              ],

              // Tampilan Progres Pengunduhan Berkas APK
              if (_isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mengunduh pembaruan...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                        Text(
                          '${_downloadProgress?.percentage ?? 0}%',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: _downloadProgress?.progress ?? 0.0,
                        backgroundColor: isDark
                            ? AppColors.white.withValues(alpha: 0.1)
                            : AppColors.softGray,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.lime,
                        ),
                        minHeight: 7.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    if (_downloadProgress != null)
                      Text(
                        '${_downloadProgress!.formattedDownloaded} MB / ${_downloadProgress!.formattedTotal} MB',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16.0),
              ],

              // Pesan Kesalahan jika gagal
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // Indikator Berkas Sudah Siap Pasang
              if (_downloadedFilePath != null && !_isDownloading) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.lime.withValues(
                      alpha: isDark ? 0.15 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(
                      color: AppColors.lime.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.lime,
                        size: 20.0,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'Berkas pembaruan sudah terunduh dan siap dipasang langsung di perangkat Anda.',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
              ],

              // Panduan Izin Sumber Tidak Dikenal jika diperlukan (Android 8.0+)
              if (_permissionNeeded) ...[
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.security_rounded,
                            color: AppColors.warning,
                            size: 18.0,
                          ),
                          SizedBox(width: 8.0),
                          Text(
                            'Keamanan Android: Izin Sumber Mandiri',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Karena Cardly diunduh langsung dari rilis resmi GitHub (bukan Play Store), sistem Android meminta konfirmasi "Izinkan dari sumber ini". Berkas APK Cardly 100% aman, terverifikasi, dan bebas malware.',
                        style: TextStyle(
                          fontSize: 12.0,
                          height: 1.4,
                          color: isDark ? AppColors.white : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.white
                              : AppColors.ink,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.border
                                : AppColors.mediumGray,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.control,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.settings_rounded, size: 16.0),
                        label: const Text('Buka Pengaturan Izin'),
                        onPressed: () async {
                          await ref
                              .read(appUpdateServiceProvider)
                              .openInstallPermissionSettings();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
              ],

              // Tombol Tindakan
              if (_downloadedFilePath != null) ...[
                CardlyButton(
                  text: 'Pasang Sekarang',
                  icon: Icons.install_mobile_rounded,
                  onPressed: () {
                    _handleInstallApk(_downloadedFilePath!);
                  },
                ),
              ] else if (!_isDownloading) ...[
                CardlyButton(
                  text: 'Perbarui Sekarang',
                  icon: Icons.download_rounded,
                  onPressed: _startDownloadAndInstall,
                ),
                if (!widget.updateInfo.isForceUpdate) ...[
                  const SizedBox(height: 8.0),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Nanti Saja',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
