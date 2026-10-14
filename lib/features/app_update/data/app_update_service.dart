import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_update_info.dart';

/// Status & Progres Unduhan Berkas APK Pembaruan (OTA In-App Downloader)
class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double progress; // Nilai 0.0 sampai 1.0

  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
  });

  String get formattedDownloaded =>
      (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get formattedTotal =>
      totalBytes > 0 ? (totalBytes / (1024 * 1024)).toStringAsFixed(1) : '...';
  int get percentage => (progress * 100).clamp(0, 100).toInt();
}

/// Provider resmi untuk AppUpdateService
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

/// Layanan In-App Updater & Dual-Source Update Checker (Supabase & GitHub)
class AppUpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentBuildNumber = 1;

  static const String githubRawUrl =
      'https://raw.githubusercontent.com/Mrmarc-bit/cardly_apps/main/version.json';
  static const String githubReleasesApiUrl =
      'https://api.github.com/repos/Mrmarc-bit/cardly_apps/releases/latest';

  static const MethodChannel _updaterChannel = MethodChannel(
    'com.cardly.app/updater',
  );

  /// Memeriksa ketersediaan versi baru dengan mekanisme Dual-Source:
  /// 1. Prioritas Utama: Supabase Backend (Tabel `app_versions`)
  /// 2. Fallback Otomatis: GitHub Repository (raw `version.json` atau Releases API)
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Mode testing headless
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }

    AppUpdateInfo? updateInfo;

    // 1. Coba periksa melalui Supabase
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_versions')
          .select()
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        updateInfo = AppUpdateInfo.fromJson(response);
      }
    } catch (_) {
      // Supabase table belum dibuat atau offline, lanjutkan ke fallback GitHub
    }

    // 2. Fallback ke GitHub jika Supabase belum ada data atau gagal koneksi
    updateInfo ??= await _fetchFromGitHub();

    if (updateInfo == null) return null;

    // Bandingkan apakah versi remote lebih tinggi dari versi saat ini
    final hasNewVersion =
        isNewerVersion(updateInfo.latestVersion, currentVersion) ||
        updateInfo.buildNumber > currentBuildNumber;

    if (hasNewVersion) {
      return updateInfo;
    }

    return null;
  }

  /// Membaca konfigurasi versi dari GitHub Repository resmi
  Future<AppUpdateInfo?> _fetchFromGitHub() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      // Coba raw version.json terlebih dahulu
      final request = await client.getUrl(Uri.parse(githubRawUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        return AppUpdateInfo.fromJson(jsonMap);
      }
    } catch (_) {
      // Abaikan dan lanjut ke GitHub Releases API
    }

    try {
      // Coba GitHub Releases API resmi
      final req = await client.getUrl(Uri.parse(githubReleasesApiUrl));
      req.headers.set('User-Agent', 'Cardly-App');
      final res = await req.close();

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final releaseJson = jsonDecode(body) as Map<String, dynamic>;

        // Cari aset file .apk di assets
        final assets = releaseJson['assets'] as List<dynamic>?;
        String apkDownloadUrl = '';
        int apkSize = 0;

        if (assets != null && assets.isNotEmpty) {
          for (final asset in assets) {
            final name = (asset['name'] as String?)?.toLowerCase() ?? '';
            if (name.endsWith('.apk')) {
              apkDownloadUrl = (asset['browser_download_url'] as String?) ?? '';
              apkSize = (asset['size'] as num?)?.toInt() ?? 0;
              break;
            }
          }
        }

        if (apkDownloadUrl.isEmpty) {
          apkDownloadUrl = (releaseJson['html_url'] as String?) ?? '';
        }

        return AppUpdateInfo(
          latestVersion:
              (releaseJson['tag_name'] as String?)?.replaceAll('v', '') ??
              '1.0.0',
          buildNumber: 99,
          downloadUrl: apkDownloadUrl,
          changelog:
              (releaseJson['body'] as String?)
                  ?.split('\n')
                  .map(
                    (l) => l.replaceAll(RegExp(r'^[\*\-\d\.\s]+'), '').trim(),
                  )
                  .where((l) => l.isNotEmpty)
                  .toList() ??
              const [],
          fileSizeBytes: apkSize,
        );
      }
    } catch (e) {
      debugPrint('[AppUpdateService] GitHub check error: $e');
    } finally {
      client.close();
    }

    return null;
  }

  /// Membandingkan dua string versi semantik (e.g. '1.0.1' > '1.0.0')
  bool isNewerVersion(String remoteVersion, String localVersion) {
    try {
      final remoteParts = remoteVersion.split('.').map(int.parse).toList();
      final localParts = localVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length && i < localParts.length; i++) {
        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
      return remoteParts.length > localParts.length;
    } catch (_) {
      return false;
    }
  }

  /// Mengunduh file APK secara stream in-app dengan progress real-time (Pendekatan B)
  Stream<DownloadProgress> downloadApk({
    required String downloadUrl,
    required String savePath,
  }) async* {
    final client = HttpClient();
    client.autoUncompress = true;

    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Download server returned HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength;
      final file = File(savePath);
      final sink = file.openWrite();

      int downloaded = 0;

      await for (final chunk in response) {
        downloaded += chunk.length;
        sink.add(chunk);

        final progress = contentLength > 0 ? (downloaded / contentLength) : 0.0;
        yield DownloadProgress(
          downloadedBytes: downloaded,
          totalBytes: contentLength,
          progress: progress,
        );
      }

      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Mendapatkan path file sementara untuk menyimpan berkas APK unduhan
  Future<String> getApkDestinationPath() async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/cardly_update.apk';
  }

  /// Memicu installer paket APK bawaan Android melalui FileProvider native
  Future<bool> triggerApkInstall(String apkFilePath) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _updaterChannel.invokeMethod<bool>('installApk', {
        'filePath': apkFilePath,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah aplikasi memiliki izin untuk memasang APK (Android 8.0+)
  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return true;
    try {
      final result = await _updaterChannel.invokeMethod<bool>('canRequestPackageInstalls');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Membuka halaman Pengaturan sistem Android untuk mengizinkan instalasi dari Cardly
  Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _updaterChannel.invokeMethod<bool>('openInstallPermissionSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
