import 'dart:convert';
import 'dart:io';

/// Skrip Otomasi Rilis, CLI Interaktif & Disk Maintenance Cardly
/// Menjadikan pubspec.yaml sebagai Single Source of Truth (SSOT).
/// Menghitung SHA256, ukuran bytes, memperbarui version.json, auto-publish ke GitHub,
/// dan menyediakan hook pembersihan cache disk (Gradle & Build).
///
/// Penggunaan:
///   ./scripts/release.sh                 (Mode interaktif dengan menu pilihan)
///   ./scripts/release.sh 1.0.5+6         (Mode cepat langsung menentukan versi)
///   ./scripts/release.sh --clean         (Mode pembersihan cache & disk optimization)

// ANSI Color codes
const reset = '\x1B[0m';
const bold = '\x1B[1m';
const green = '\x1B[32m';
const cyan = '\x1B[36m';
const yellow = '\x1B[33m';
const red = '\x1B[31m';
const gray = '\x1B[90m';

void main(List<String> args) async {
  // Handle argumen bantuan CLI
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('');
    stdout.writeln(
      '$cyan$bold Cardly Automated Release Engine & Disk Maintenance$reset',
    );
    stdout.writeln('Penggunaan:');
    stdout.writeln(
      '  ./scripts/release.sh                 Mode interaktif (Pilihan Versi, Auto-Publish & Cache Clean)',
    );
    stdout.writeln(
      '  ./scripts/release.sh [versi+build]   Mode cepat (contoh: 1.0.7+8)',
    );
    stdout.writeln(
      '  ./scripts/release.sh --clean         Pembersihan cache Gradle & proyek (~1-14 GB)',
    );
    stdout.writeln('');
    exit(0);
  }

  // Handle mode pembersihan cache langsung (Disk Optimization)
  if (args.contains('--clean') || args.contains('--clean-only')) {
    stdout.writeln('');
    stdout.writeln(
      '$cyan$bold======================================================$reset',
    );
    stdout.writeln(
      '$cyan$bold          CARDLY DISK & CACHE OPTIMIZATION            $reset',
    );
    stdout.writeln(
      '$cyan$bold======================================================$reset',
    );
    await runCacheCleanupMenu();
    exit(0);
  }

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln(
      '$red Error: pubspec.yaml tidak ditemukan di direktori aktif.$reset',
    );
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(
    r'^version:\s*([0-9\.]+)\+?([0-9]*)$',
    multiLine: true,
  );
  final match = versionRegex.firstMatch(pubspecContent);

  if (match == null) {
    stderr.writeln(
      '$red Error: Format version di pubspec.yaml tidak valid.$reset',
    );
    exit(1);
  }

  final currentVersion = match.group(1)!;
  final currentBuild = int.tryParse(match.group(2) ?? '0') ?? 0;

  String targetVersion;
  int targetBuildNumber;

  // Header Banner
  stdout.writeln('');
  stdout.writeln(
    '$cyan$bold======================================================$reset',
  );
  stdout.writeln(
    '$cyan$bold           CARDLY AUTOMATED RELEASE ENGINE            $reset',
  );
  stdout.writeln(
    '$cyan$bold======================================================$reset',
  );
  stdout.writeln(
    'Versi saat ini di pubspec.yaml : $bold$yellow$currentVersion (Build $currentBuild)$reset',
  );

  // Cek Status Git Workspace
  final gitStatusResult = await Process.run('git', ['status', '--porcelain']);
  final gitStatusOutput = (gitStatusResult.stdout as String).trim();
  final dirtyFiles = gitStatusOutput
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .where(
        (line) =>
            !line.contains('pubspec.yaml') &&
            !line.contains('version.json') &&
            !line.contains('cardly-release.jks'),
      )
      .toList();

  if (dirtyFiles.isNotEmpty) {
    stdout.writeln(
      'Status Git Workspace           : ${yellow}Ada ${dirtyFiles.length} perubahan belum di-commit$reset',
    );
    stdout.writeln(
      '$gray  (File selain pubspec & version.json tidak akan dimasukkan ke commit rilis)$reset',
    );
  } else {
    stdout.writeln('Status Git Workspace           : $green Bersih ✓$reset');
  }
  stdout.writeln('');

  // Skenario 1: Jika argumen diberikan lewat CLI (Mode Non-Interaktif)
  if (args.isNotEmpty) {
    final input = args.first.replaceAll('v', '').trim();
    if (input.contains('+')) {
      final parts = input.split('+');
      targetVersion = parts[0];
      targetBuildNumber = int.tryParse(parts[1]) ?? (currentBuild + 1);
    } else {
      targetVersion = input;
      targetBuildNumber = currentBuild + 1;
    }
  } else {
    // Skenario 2: Mode Interaktif Terminal
    final versionParts = currentVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    while (versionParts.length < 3) {
      versionParts.add(0);
    }
    final nextPatchVersion =
        '${versionParts[0]}.${versionParts[1]}.${versionParts[2] + 1}';
    final nextBuild = currentBuild + 1;

    stdout.writeln('$bold$cyan Pilih skenario rilis:$reset');
    stdout.writeln(
      '  $bold[1] Versi Baru$reset   -> $green$nextPatchVersion+$nextBuild$reset  $gray(Auto-increment patch & build)$reset',
    );
    stdout.writeln(
      '  $bold[2] Perbarui$reset     -> $yellow$currentVersion+$nextBuild$reset  $gray(Versi tetap, naikkan build)$reset',
    );
    stdout.writeln(
      '  $bold[3] Mulai Awal$reset   -> ${cyan}1.0.0+1$reset     $gray(Reset penomoran ke awal)$reset',
    );
    stdout.writeln(
      '  $bold[4] Kustom$reset       -> $gray Tentukan versi manual$reset',
    );
    stdout.writeln(
      '  $bold[q] Batal$reset        -> $gray Batalkan rilis$reset',
    );
    stdout.writeln('');

    stdout.write('$bold Masukkan pilihan [1-4 / q]: $reset');
    final choice = stdin.readLineSync()?.trim().toLowerCase();

    switch (choice) {
      case '1':
      case '':
        targetVersion = nextPatchVersion;
        targetBuildNumber = nextBuild;
        break;
      case '2':
        targetVersion = currentVersion;
        targetBuildNumber = nextBuild;
        break;
      case '3':
        targetVersion = '1.0.0';
        targetBuildNumber = 1;
        break;
      case '4':
        stdout.write(
          '$bold Masukkan versi target (contoh: 1.1.0 atau 1.1.0+7): $reset',
        );
        final customInput =
            stdin.readLineSync()?.replaceAll('v', '').trim() ?? '';
        if (customInput.isEmpty) {
          stderr.writeln(
            '$red Input versi tidak boleh kosong. Rilis dibatalkan.$reset',
          );
          exit(1);
        }
        if (customInput.contains('+')) {
          final parts = customInput.split('+');
          targetVersion = parts[0];
          targetBuildNumber = int.tryParse(parts[1]) ?? nextBuild;
        } else {
          targetVersion = customInput;
          targetBuildNumber = nextBuild;
        }
        break;
      case 'q':
      case 'cancel':
        stdout.writeln('$yellow Rilis dibatalkan oleh pengguna.$reset');
        exit(0);
      default:
        stderr.writeln('$red Pilihan tidak valid. Rilis dibatalkan.$reset');
        exit(1);
    }
  }

  // Ringkasan Target
  stdout.writeln('');
  stdout.writeln(
    '$cyan------------------------------------------------------$reset',
  );
  stdout.writeln(
    'Target Versi : $bold$green v$targetVersion (Build $targetBuildNumber)$reset',
  );
  stdout.writeln('Tag Git      : $bold$cyan v$targetVersion$reset');
  stdout.writeln(
    '$cyan------------------------------------------------------$reset',
  );

  stdout.write('$bold Lanjutkan kompilasi release APK? (Y/n): $reset');
  final proceed = stdin.readLineSync()?.trim().toLowerCase();
  if (proceed != null &&
      proceed.isNotEmpty &&
      proceed != 'y' &&
      proceed != 'yes') {
    stdout.writeln('$yellow Proses kompilasi dibatalkan.$reset');
    exit(0);
  }

  // 1. Perbarui pubspec.yaml
  stdout.writeln(
    '\n$cyan[1/4]$reset Memperbarui pubspec.yaml ke $targetVersion+$targetBuildNumber...',
  );
  final updatedPubspec = pubspecContent.replaceFirst(
    versionRegex,
    'version: $targetVersion+$targetBuildNumber',
  );
  pubspecFile.writeAsStringSync(updatedPubspec);
  stdout.writeln('      $green✓ pubspec.yaml berhasil diperbarui$reset');

  // 2. Jalankan kompilasi APK Release
  stdout.writeln(
    '\n$cyan[2/4]$reset Mengompilasi APK Android Release Universal Teroptimasi...',
  );
  final buildProcess = await Process.start('flutter', [
    'build',
    'apk',
    '--release',
    '--obfuscate',
    '--split-debug-info=build/app/outputs/symbols',
  ], mode: ProcessStartMode.inheritStdio);
  final buildExitCode = await buildProcess.exitCode;
  if (buildExitCode != 0) {
    stderr.writeln(
      '$red Error: Kompilasi APK gagal (exit code $buildExitCode).$reset',
    );
    exit(buildExitCode);
  }

  // 3. Verifikasi berkas APK dan hitung metadata
  stdout.writeln(
    '\n$cyan[3/4]$reset Menghitung checksum SHA-256 dan ukuran berkas APK...',
  );
  final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
  if (!apkFile.existsSync()) {
    stderr.writeln(
      '$red Error: File APK tidak ditemukan di ${apkFile.path}$reset',
    );
    exit(1);
  }

  final apkSizeBytes = apkFile.lengthSync();
  final shaProcess = await Process.run('shasum', ['-a', '256', apkFile.path]);
  final shaOutput = (shaProcess.stdout as String).trim().split(' ').first;

  stdout.writeln(
    '      $green✓ Ukuran : ${(apkSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB ($apkSizeBytes bytes)$reset',
  );
  stdout.writeln('      $green✓ SHA-256: $shaOutput$reset');

  // 4. Perbarui version.json otomatis
  stdout.writeln(
    '\n$cyan[4/4]$reset Memperbarui version.json & landing_page/version.json...',
  );
  final todayStr = DateTime.now().toIso8601String().split('T').first;
  final downloadUrl =
      'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v$targetVersion/cardly-release-v$targetVersion.apk';

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
  stdout.writeln(
    '      $green✓ version.json berhasil disinkronkan 100% otomatis$reset',
  );

  // Ringkasan Selesai
  stdout.writeln('');
  stdout.writeln(
    '$green$bold======================================================$reset',
  );
  stdout.writeln(
    '$green$bold             KOMPILASI LOKAL BERHASIL!                $reset',
  );
  stdout.writeln(
    '$green$bold======================================================$reset',
  );
  stdout.writeln('File APK siap di: $bold${apkFile.path}$reset\n');

  // 5. Prompt Opsi Auto-Publish ke GitHub
  stdout.write(
    '$bold$yellow🚀 Publikasikan langsung ke GitHub sekarang? (Y/n): $reset',
  );
  final publishChoice = stdin.readLineSync()?.trim().toLowerCase();
  final shouldPublish =
      publishChoice == null ||
      publishChoice.isEmpty ||
      publishChoice == 'y' ||
      publishChoice == 'yes';

  if (shouldPublish) {
    stdout.writeln('\n$cyan Memulai publikasi otomatis ke GitHub...$reset');

    // a. Git add
    stdout.write(
      '  -> Menambahkan berkas versi & konfigurasi rilis ke Git staging... ',
    );
    final addResult = await Process.run('git', [
      'add',
      'pubspec.yaml',
      'version.json',
      'landing_page/version.json',
      'android/app/build.gradle.kts',
      '.github/workflows/release.yml',
      'scripts/release.sh',
      'tool/release.dart',
    ]);
    if (addResult.exitCode != 0) {
      stderr.writeln('\n$red Gagal git add: ${addResult.stderr}$reset');
      exit(1);
    }
    stdout.writeln('$green✓$reset');

    // b. Git commit
    stdout.write(
      '  -> Membuat commit rilis chore(release): v$targetVersion+$targetBuildNumber... ',
    );
    final commitResult = await Process.run('git', [
      'commit',
      '-m',
      'chore(release): v$targetVersion+$targetBuildNumber',
    ]);
    if (commitResult.exitCode != 0 &&
        !(commitResult.stdout as String).contains('nothing to commit')) {
      stderr.writeln('\n$red Gagal git commit: ${commitResult.stderr}$reset');
      exit(1);
    }
    stdout.writeln('$green✓$reset');

    // c. Git tag
    stdout.write('  -> Membuat git tag v$targetVersion... ');
    final tagResult = await Process.run('git', [
      'tag',
      '-a',
      'v$targetVersion',
      '-m',
      'Release v$targetVersion',
    ]);
    if (tagResult.exitCode != 0) {
      final stderrStr = tagResult.stderr as String;
      if (stderrStr.contains('already exists')) {
        stdout.writeln('$yellow(Tag sudah ada, memperbarui tag)...$reset');
        await Process.run('git', ['tag', '-d', 'v$targetVersion']);
        await Process.run('git', [
          'tag',
          '-a',
          'v$targetVersion',
          '-m',
          'Release v$targetVersion',
        ]);
      } else {
        stderr.writeln('\n$red Gagal membuat tag git: $stderrStr$reset');
        exit(1);
      }
    } else {
      stdout.writeln('$green✓$reset');
    }

    // d. Git push origin main
    stdout.write('  -> Mendorong commit ke branch origin main... ');
    final pushMainResult = await Process.run('git', ['push', 'origin', 'main']);
    if (pushMainResult.exitCode != 0) {
      stderr.writeln(
        '\n$red Peringatan: Gagal push ke origin main: ${pushMainResult.stderr}$reset',
      );
    } else {
      stdout.writeln('$green✓$reset');
    }

    // e. Git push origin tag
    stdout.write('  -> Mendorong tag v$targetVersion ke GitHub... ');
    final pushTagResult = await Process.run('git', [
      'push',
      'origin',
      'v$targetVersion',
    ]);
    if (pushTagResult.exitCode != 0) {
      stderr.writeln(
        '\n$red Gagal push tag ke GitHub: ${pushTagResult.stderr}$reset',
      );
      stdout.writeln('\n$yellow Anda dapat mencoba push manual nanti:$reset');
      stdout.writeln('  git push origin v$targetVersion\n');
    } else {
      stdout.writeln('$green✓$reset');
      stdout.writeln('');
      stdout.writeln('$green$bold🎉 BERHASIL DIPUBLIKASIKAN KE GITHUB!$reset');
      stdout.writeln(
        'GitHub Actions sedang membangun rilis resmi dan menyinkronkan ke Supabase:',
      );
      stdout.writeln(
        '$cyan$bold https://github.com/Mrmarc-bit/cardly_apps/actions$reset',
      );
      stdout.writeln(
        '$green$bold======================================================$reset\n',
      );
    }
  } else {
    stdout.writeln(
      '\n$yellow Publikasi ke GitHub dilewati (perubahan disimpan lokal).$reset',
    );
    stdout.writeln('Jika ingin mempublikasikan secara manual nanti, jalankan:');
    stdout.writeln(
      '  git add pubspec.yaml version.json landing_page/version.json',
    );
    stdout.writeln(
      '  git commit -m "chore(release): v$targetVersion+$targetBuildNumber"',
    );
    stdout.writeln('  git tag -a v$targetVersion -m "Release v$targetVersion"');
    stdout.writeln('  git push origin main && git push origin v$targetVersion');
    stdout.writeln(
      '$cyan======================================================$reset\n',
    );
  }

  // 6. Post-Release Maintenance & Disk Optimization Hook
  await runCacheCleanupMenu(
    targetVersion: targetVersion,
    apkPath: apkFile.path,
  );
}

/// Menampilkan menu interaktif pembersihan cache dan menjalankan aksi yang dipilih
Future<void> runCacheCleanupMenu({
  String? targetVersion,
  String? apkPath,
}) async {
  stdout.writeln('');
  stdout.writeln(
    '$cyan$bold======================================================$reset',
  );
  stdout.writeln(
    '$cyan$bold    🧹 POST-RELEASE MAINTENANCE & DISK OPTIMIZATION   $reset',
  );
  stdout.writeln(
    '$cyan$bold======================================================$reset',
  );
  stdout.writeln(
    'Kompilasi Gradle dan Android SDK menghasilkan cache yang dapat memakan belasan GB.',
  );
  stdout.writeln('Pilih tingkat pembersihan disk yang diinginkan:\n');
  stdout.writeln('  $bold[1] Pembersihan Cepat (Proyek Lokal)$reset');
  stdout.writeln(
    '      $gray-> Hapus build/ & android/.gradle/ (~1 - 3 GB)$reset',
  );
  stdout.writeln('  $bold[2] Pembersihan Menyeluruh (Deep Gradle Clean)$reset');
  stdout.writeln(
    '      $gray-> Level 1 + Hapus ~/.gradle/caches/ & daemon/ (~10 - 14 GB)$reset',
  );
  stdout.writeln('  $bold[3] Lewati (Selesai tanpa pembersihan)$reset');
  stdout.writeln(
    '      $gray-> Pertahankan seluruh cache untuk mempercepat build lokal berikutnya$reset',
  );
  stdout.writeln('');
  stdout.write('$bold Masukkan pilihan [1-3] (default 3): $reset');

  final choice = stdin.readLineSync()?.trim();
  if (choice == '1') {
    await performProjectClean(targetVersion: targetVersion, apkPath: apkPath);
    stdout.writeln(
      '\n$green$bold✓ Pembersihan proyek lokal selesai! Ruang disk berhasil dirapikan.$reset\n',
    );
  } else if (choice == '2') {
    await performProjectClean(targetVersion: targetVersion, apkPath: apkPath);
    await performDeepGradleClean();
    stdout.writeln(
      '\n$green$bold🎉 Pembersihan menyeluruh selesai! Ruang disk Mac Anda kembali optimal dan lega.$reset\n',
    );
  } else {
    stdout.writeln(
      '\n$yellow Pembersihan cache dilewati. Rilis Cardly selesai dengan sempurna! ✨$reset\n',
    );
  }
}

/// Menghapus cache build lokal proyek dan menghentikan Gradle Daemon
Future<void> performProjectClean({
  String? targetVersion,
  String? apkPath,
}) async {
  stdout.writeln('\n$cyan Memulai pembersihan cache proyek lokal...$reset');

  // Jika ada berkas APK yang baru dibuat, beri opsi untuk mengamankan salinan ke folder releases/
  if (apkPath != null && File(apkPath).existsSync()) {
    stdout.write(
      '$yellow Ingin menyimpan salinan APK ke folder releases/ sebelum build/ dihapus? (Y/n): $reset',
    );
    final saveChoice = stdin.readLineSync()?.trim().toLowerCase();
    final shouldSave =
        saveChoice == null ||
        saveChoice.isEmpty ||
        saveChoice == 'y' ||
        saveChoice == 'yes';

    if (shouldSave) {
      final releasesDir = Directory('releases');
      if (!releasesDir.existsSync()) {
        releasesDir.createSync(recursive: true);
      }
      final destName = targetVersion != null
          ? 'cardly-release-v$targetVersion.apk'
          : 'cardly-release-latest.apk';
      final destFile = File('${releasesDir.path}/$destName');
      stdout.write('  -> Menyalin APK ke ${destFile.path}... ');
      File(apkPath).copySync(destFile.path);
      stdout.writeln('$green✓$reset');
    }
  }

  // 1. Hentikan Gradle Daemons agar tidak mengunci file
  stdout.write('  -> Menghentikan Gradle daemon yang berjalan... ');
  await stopGradleDaemon();
  stdout.writeln('$green✓$reset');

  // 2. Hapus android/.gradle
  stdout.write('  -> Menghapus direktori android/.gradle/... ');
  await safeDeleteDirectory(Directory('android/.gradle'));
  stdout.writeln('$green✓$reset');

  // 3. Hapus build/
  stdout.write('  -> Menghapus direktori build/... ');
  await safeDeleteDirectory(Directory('build'));
  stdout.writeln('$green✓$reset');
}

/// Menghapus tumpukan cache Gradle global (~/.gradle/caches, daemon, .tmp, kotlin-profile)
Future<void> performDeepGradleClean() async {
  stdout.writeln(
    '\n$cyan Memulai pembersihan mendalam Gradle Cache global (~/.gradle)...$reset',
  );

  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null || home.isEmpty) {
    stderr.writeln('$red Gagal mendeteksi direktori HOME pengguna.$reset');
    return;
  }

  final gradleHome = '$home/.gradle';
  final targets = [
    Directory('$gradleHome/caches'),
    Directory('$gradleHome/daemon'),
    Directory('$gradleHome/.tmp'),
    Directory('$gradleHome/kotlin-profile'),
  ];

  for (final target in targets) {
    if (target.existsSync()) {
      stdout.write('  -> Menghapus ${target.path}... ');
      await safeDeleteDirectory(target);
      stdout.writeln('$green✓$reset');
    }
  }

  stdout.writeln(
    '$gray  (Catatan: ~/.gradle/wrapper tetap dipertahankan agar tidak perlu mengunduh ulang Gradle binary)$reset',
  );
}

/// Menghentikan proses background daemon Gradle agar tidak mengunci file cache
Future<void> stopGradleDaemon() async {
  final gradlewFile = File(
    Platform.isWindows ? 'android/gradlew.bat' : 'android/gradlew',
  );
  if (gradlewFile.existsSync()) {
    try {
      await Process.run(gradlewFile.absolute.path, [
        '--stop',
      ], workingDirectory: 'android');
    } catch (_) {}
  }
}

/// Menghapus direktori secara aman (menggunakan rm -rf di macOS/Linux untuk efisiensi tinggi)
Future<void> safeDeleteDirectory(Directory dir) async {
  if (!dir.existsSync()) return;
  try {
    if (Platform.isMacOS || Platform.isLinux) {
      final res = await Process.run('rm', ['-rf', dir.path]);
      if (res.exitCode != 0 && dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } else {
      dir.deleteSync(recursive: true);
    }
  } catch (_) {
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }
}
