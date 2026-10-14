import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

/// Layanan In-App Updater & Multi-Source Update Checker (GitHub & Supabase)
class AppUpdateService {
  static const String currentVersion = '1.0.3';
  static const int currentBuildNumber = 4;

  /// Membaca versi semantik yang aktif dari sistem operasi secara dinamis
  Future<String> getLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) return info.version;
    } catch (_) {}
    return currentVersion;
  }

  /// Membaca build number yang aktif dari sistem operasi secara dinamis
  Future<int> getLocalBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final parsed = int.tryParse(info.buildNumber);
      if (parsed != null) return parsed;
    } catch (_) {}
    return currentBuildNumber;
  }

  static const String githubRawUrl =
      'https://raw.githubusercontent.com/Mrmarc-bit/cardly_apps/main/version.json';
  static const String githubReleasesApiUrl =
      'https://api.github.com/repos/Mrmarc-bit/cardly_apps/releases/latest';

  static const MethodChannel _updaterChannel = MethodChannel(
    'com.cardly.app/updater',
  );

  /// Memeriksa ketersediaan versi baru dengan mekanisme Multi-Source:
  /// Mengambil data dari GitHub (Releases API & version.json) dan Supabase (app_versions),
  /// lalu memilih kandidat versi/build number tertinggi secara otomatis.
  Future<AppUpdateInfo?> checkForUpdate() async {
    // Mode testing headless
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }

    final localVer = await getLocalVersion();
    final localBuild = await getLocalBuildNumber();

    AppUpdateInfo? bestUpdate;

    // 1. Ambil dari GitHub (Prioritaskan GitHub Releases API resmi real-time)
    try {
      final githubInfo = await _fetchFromGitHub();
      if (githubInfo != null) {
        bestUpdate = githubInfo;
      }
    } catch (_) {}

    // 2. Ambil dari Supabase Database (Tabel app_versions)
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_versions')
          .select()
          .order('build_number', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final supabaseInfo = AppUpdateInfo.fromJson(response);
        if (bestUpdate == null ||
            isNewerVersion(
              supabaseInfo.latestVersion,
              bestUpdate.latestVersion,
            ) ||
            (supabaseInfo.latestVersion == bestUpdate.latestVersion &&
                supabaseInfo.buildNumber > bestUpdate.buildNumber)) {
          bestUpdate = supabaseInfo;
        }
      }
    } catch (_) {
      // Supabase table belum dibuat atau offline, gunakan data dari GitHub
    }

    if (bestUpdate == null) return null;

    // Bandingkan apakah versi remote lebih tinggi dari versi lokal saat ini
    final hasNewVersion =
        isNewerVersion(bestUpdate.latestVersion, localVer) ||
        (bestUpdate.latestVersion == localVer &&
            bestUpdate.buildNumber > localBuild);

    if (hasNewVersion) {
      return bestUpdate;
    }

    return null;
  }

  /// Membaca konfigurasi versi dari GitHub Repository resmi
  Future<AppUpdateInfo?> _fetchFromGitHub() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    // 1. Prioritaskan GitHub Releases API resmi: Real-time tanpa jeda CDN cache
    try {
      final req = await client.getUrl(Uri.parse(githubReleasesApiUrl));
      req.headers.set('User-Agent', 'Cardly-App');
      final res = await req.close();

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final releaseJson = jsonDecode(body) as Map<String, dynamic>;

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

        final rawTag = (releaseJson['tag_name'] as String?) ?? '1.0.0';
        final cleanVersion = rawTag.replaceAll('v', '').trim();

        client.close();
        return AppUpdateInfo(
          latestVersion: cleanVersion,
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
    } catch (_) {
      // Jika Releases API mengalami rate-limit atau gagal, beralih ke raw version.json
    }

    // 2. Fallback: Raw version.json
    try {
      final request = await client.getUrl(
        Uri.parse('$githubRawUrl?_t=${DateTime.now().millisecondsSinceEpoch}'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final jsonMap = jsonDecode(body) as Map<String, dynamic>;
        client.close();
        return AppUpdateInfo.fromJson(jsonMap);
      }
    } catch (_) {}

    client.close();
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
      final result = await _updaterChannel.invokeMethod<bool>(
        'canRequestPackageInstalls',
      );
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Membuka halaman Pengaturan sistem Android untuk mengizinkan instalasi dari Cardly
  Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _updaterChannel.invokeMethod<bool>(
        'openInstallPermissionSettings',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
