import 'dart:convert';
import 'dart:io';

/// Skrip Otomasi Rilis & Sinkronisasi Versi Cardly
/// Menjadikan pubspec.yaml sebagai Single Source of Truth (SSOT).
/// Menghitung SHA256, ukuran bytes, dan memperbarui version.json secara otomatis.
///
/// Penggunaan:
///   dart run tool/release.dart [versi+build]
/// Contoh:
///   dart run tool/release.dart 1.0.5+6
void main(List<String> args) async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml tidak ditemukan di direktori aktif.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(
    r'^version:\s*([0-9\.]+)\+?([0-9]*)$',
    multiLine: true,
  );
  final match = versionRegex.firstMatch(pubspecContent);

  if (match == null) {
    stderr.writeln('Error: Format version di pubspec.yaml tidak valid.');
    exit(1);
  }

  String targetVersion;
  int targetBuildNumber;

  if (args.isNotEmpty) {
    final input = args.first.replaceAll('v', '').trim();
    if (input.contains('+')) {
      final parts = input.split('+');
      targetVersion = parts[0];
      targetBuildNumber = int.tryParse(parts[1]) ?? 1;
    } else {
      targetVersion = input;
      final currentBuild = int.tryParse(match.group(2) ?? '0') ?? 0;
      targetBuildNumber = currentBuild + 1;
    }
  } else {
    targetVersion = match.group(1)!;
    final currentBuild = int.tryParse(match.group(2) ?? '0') ?? 0;
    targetBuildNumber = currentBuild + 1;
  }

  stdout.writeln('==============================================');
  stdout.writeln('Cardly Automated Release Engine');
  stdout.writeln('Target Versi : v$targetVersion');
  stdout.writeln('Nomor Build  : $targetBuildNumber');
  stdout.writeln('Tag Rilis    : v$targetVersion');
  stdout.writeln('==============================================');

  // 1. Perbarui pubspec.yaml secara otomatis
  stdout.writeln('\n[1/5] Memperbarui pubspec.yaml...');
  final updatedPubspec = pubspecContent.replaceFirst(
    versionRegex,
    'version: $targetVersion+$targetBuildNumber',
  );
  pubspecFile.writeAsStringSync(updatedPubspec);
  stdout.writeln('  -> Versi disetel ke: $targetVersion+$targetBuildNumber');

  // 2. Jalankan kompilasi APK Release
  stdout.writeln(
    '\n[2/5] Mengompilasi APK Android Release (flutter build apk --release)...',
  );
  final buildProcess = await Process.start('flutter', [
    'build',
    'apk',
    '--release',
  ], mode: ProcessStartMode.inheritStdio);
  final buildExitCode = await buildProcess.exitCode;
  if (buildExitCode != 0) {
    stderr.writeln('Error: Kompilasi APK gagal (exit code $buildExitCode).');
    exit(buildExitCode);
  }

  // 3. Verifikasi berkas APK dan hitung metadata
  stdout.writeln(
    '\n[3/5] Menghitung checksum SHA-256 dan ukuran berkas APK...',
  );
  final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
  if (!apkFile.existsSync()) {
    stderr.writeln('Error: File APK tidak ditemukan di ${apkFile.path}');
    exit(1);
  }

  final apkSizeBytes = apkFile.lengthSync();
  final shaProcess = await Process.run('shasum', ['-a', '256', apkFile.path]);
  final shaOutput = (shaProcess.stdout as String).trim().split(' ').first;

  stdout.writeln(
    '  -> Ukuran: ${(apkSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB ($apkSizeBytes bytes)',
  );
  stdout.writeln('  -> SHA256: $shaOutput');

  // 4. Perbarui version.json otomatis
  stdout.writeln(
    '\n[4/5] Memperbarui version.json & landing_page/version.json...',
  );
  final todayStr = DateTime.now().toIso8601String().split('T').first;
  final downloadUrl =
      'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v$targetVersion/cardly-release-v$targetVersion.apk';

  // Baca changelog lama jika ada, atau buat default
  List<dynamic> changelog = [
    'Pembaruan performa, perbaikan bug, dan stabilitas keamanan rilis v$targetVersion',
  ];
  final versionJsonFile = File('version.json');
  if (versionJsonFile.existsSync()) {
    try {
      final existingData = jsonDecode(
        versionJsonFile.readAsStringSync(),
      ) as Map<String, dynamic>;
      if (existingData['changelog'] is List &&
          (existingData['changelog'] as List).isNotEmpty) {
        changelog = existingData['changelog'] as List<dynamic>;
      }
    } catch (_) {}
  }

  final versionData = {
    'latest_version': targetVersion,
    'build_number': targetBuildNumber,
    'is_force_update': false,
    'download_url': downloadUrl,
    'release_date': todayStr,
    'changelog': changelog,
    'file_size_bytes': apkSizeBytes,
    'variants': [
      {
        'arch': 'universal',
        'label': 'Universal (Semua HP)',
        'badge': 'Kompatibilitas Penuh',
        'desc': 'Memuat pustaka 64-bit dan 32-bit, dijamin dapat dipasang di seluruh perangkat Android',
        'file_name': 'cardly-release-v$targetVersion.apk',
        'download_url': downloadUrl,
        'file_size_bytes': apkSizeBytes,
        'sha256': shaOutput,
      },
    ],
  };

  final formattedJson =
      '${const JsonEncoder.withIndent('  ').convert(versionData)}\n';
  versionJsonFile.writeAsStringSync(formattedJson);

  final landingVersionFile = File('landing_page/version.json');
  if (landingVersionFile.parent.existsSync()) {
    landingVersionFile.writeAsStringSync(formattedJson);
  }
  stdout.writeln('  -> version.json berhasil disinkronkan 100% otomatis!');

  // 5. Informasi langkah final
  stdout.writeln('\n[5/5] Selesai!');
  stdout.writeln('==============================================');
  stdout.writeln(
    'Rilis v$targetVersion (Build $targetBuildNumber) siap dipublikasikan:',
  );
  stdout.writeln(
    '  git add pubspec.yaml version.json landing_page/version.json',
  );
  stdout.writeln(
    '  git commit -m "chore(release): v$targetVersion+$targetBuildNumber"',
  );
  stdout.writeln('  git tag -a v$targetVersion -m "Release v$targetVersion"');
  stdout.writeln('  git push origin main && git push origin v$targetVersion');
  stdout.writeln('==============================================');
}
