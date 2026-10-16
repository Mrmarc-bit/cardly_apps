import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_service.dart';

/// Handler Otomatis Pembaruan Versi & Pembersihan Cache (On-Update Lifecycle Routine)
/// Bertanggung jawab mendeteksi ketika aplikasi baru selesai di-update,
/// membersihkan berkas APK sementara dari disk (~30-60 MB),
/// menyegarkan cache memori grafis/gambar, dan memperbarui rekam jejak versi di penyimpanan lokal.
class AppUpgradeHandler {
  AppUpgradeHandler._();

  /// Menjalankan rutinitas pasca-update jika terdeteksi transisi versi aplikasi
  static Future<void> handleUpgradeIfNeeded(SharedPreferences prefs) async {
    try {
      final storage = LocalStorageService(prefs);
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final lastVersion = storage.lastAppVersion;
      final lastBuild = storage.lastBuildNumber;

      // 1. Kasus Aplikasi Baru Diperbarui (Update Transition)
      if (lastVersion.isNotEmpty &&
          (currentVersion != lastVersion || currentBuild != lastBuild)) {
        // a. Bersihkan berkas APK unduhan lama di temporary directory
        await cleanTemporaryApkFiles();

        // b. Bersihkan Image Cache memori Flutter agar tidak memuat aset usang
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        // c. Simpan versi & build number aktif yang baru
        await storage.setLastAppVersion(currentVersion);
        await storage.setLastBuildNumber(currentBuild);
        return;
      }

      // 2. Kasus Instalasi Baru Pertama Kali (Fresh Install)
      if (lastVersion.isEmpty) {
        await cleanTemporaryApkFiles();
        await storage.setLastAppVersion(currentVersion);
        await storage.setLastBuildNumber(currentBuild);
      }
    } catch (_) {
      // Abaikan kegagalan non-kritis agar startup aplikasi tetap berjalan mulus
    }
  }

  /// Menghapus seluruh berkas APK yang tertinggal di folder temporary
  static Future<void> cleanTemporaryApkFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final list = tempDir.listSync();
      for (final entity in list) {
        if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
