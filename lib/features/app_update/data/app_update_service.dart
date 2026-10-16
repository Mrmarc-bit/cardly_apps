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
  /// Membaca versi semantik yang aktif dari sistem operasi secara dinamis
  Future<String> getLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) return info.version;
    } catch (_) {}
    return '1.0.0';
  }

  /// Membaca build number yang aktif dari sistem operasi secara dinamis
  Future<int> getLocalBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final parsed = int.tryParse(info.buildNumber);
      if (parsed != null) return parsed;
    } catch (_) {}
    return 1;
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
        String cleanVersion = rawTag.replaceAll('v', '').trim();
        int buildNum = 0;
        if (cleanVersion.contains('+')) {
          final parts = cleanVersion.split('+');
          cleanVersion = parts[0];
          buildNum = int.tryParse(parts[1]) ?? 0;
        }

        if (buildNum == 0) {
          final bodyText = (releaseJson['body'] as String?) ?? '';
          final match = RegExp(
            r'build[\s\-_:]*(\d+)',
            caseSensitive: false,
          ).firstMatch(bodyText);
          if (match != null) {
            buildNum = int.tryParse(match.group(1) ?? '0') ?? 0;
          }
        }

        client.close();
        return AppUpdateInfo(
          latestVersion: cleanVersion,
          buildNumber: buildNum,
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

  /// Meminta izin notifikasi runtime di Android 13+ (POST_NOTIFICATIONS)
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _updaterChannel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return res ?? false;
    } catch (_) {
      return true;
    }
  }

  /// Menampilkan notifikasi pembaruan di status bar / drawer sistem Android/iOS
  Future<void> showSystemNotification({
    required String version,
    required String changelog,
  }) async {
    try {
      await requestNotificationPermission();
      await _updaterChannel.invokeMethod('showUpdateNotification', {
        'version': version,
        'changelog': changelog,
      });
    } catch (_) {}
  }

  /// Membersihkan berkas APK usang di temporary directory untuk menghemat disk (~30-60 MB)
  /// dan mencegah instalasi paket APK lama yang tersisa dari pembaruan sebelumnya.
  Future<void> cleanStaleUpdateApks({String? keepFilePath}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;

      final list = tempDir.listSync();
      for (final entity in list) {
        if (entity is File && entity.path.toLowerCase().endsWith('.apk')) {
          if (keepFilePath != null && entity.path == keepFilePath) {
            continue;
          }
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Mengunduh file APK secara stream in-app dengan progress real-time (Pendekatan B)
  Stream<DownloadProgress> downloadApk({
    required String downloadUrl,
    required String savePath,
  }) async* {
    // Bersihkan berkas APK usang lain dan hapus file partial sebelumnya jika ada
    await cleanStaleUpdateApks(keepFilePath: savePath);
    try {
      final existingFile = File(savePath);
      if (existingFile.existsSync()) {
        existingFile.deleteSync();
      }
    } catch (_) {}

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

  /// Mendapatkan path file sementara untuk menyimpan berkas APK unduhan dengan penamaan versi eksplisit
  Future<String> getApkDestinationPath({AppUpdateInfo? info}) async {
    final tempDir = await getTemporaryDirectory();
    if (info != null) {
      final safeVer = info.latestVersion.replaceAll(
        RegExp(r'[^a-zA-Z0-9_\.]'),
        '_',
      );
      return '${tempDir.path}/cardly_v${safeVer}_b${info.buildNumber}.apk';
    }
    return '${tempDir.path}/cardly_latest_update.apk';
  }

  /// Memeriksa apakah berkas APK versi ini sudah berhasil diunduh secara lokal dan valid
  Future<String?> getValidDownloadedApkPath(AppUpdateInfo info) async {
    try {
      final path = await getApkDestinationPath(info: info);
      final file = File(path);
      if (file.existsSync()) {
        final length = file.lengthSync();
        if (length > 0) {
          // Jika ukuran byte rilis ada di metadata, pastikan integritas berkas utuh
          if (info.fileSizeBytes > 0 &&
              (length - info.fileSizeBytes).abs() > 4096) {
            // Berkas corrupt atau tidak utuh, hapus agar diunduh ulang bersih
            try {
              file.deleteSync();
            } catch (_) {}
            return null;
          }
          return path;
        }
      }
    } catch (_) {}
    return null;
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
