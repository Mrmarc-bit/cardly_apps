import 'dart:convert';
import 'dart:io';

/// Cardly Multi-Repo Synchronizer CLI
/// -------------------------------------------------------------
/// Tool otomatisasi dan manajemen sinkronisasi multi-remote Git:
/// - Repositori Kampus / Organisasi (UNUGHA-Informatika-26)
/// - Repositori Personal (Mrmarc-bit)
/// - Dual Sync (Mendorong ke kedua repositori sekaligus)
///
/// Penggunaan:
///   dart run tool/sync_repo.dart                  (Mode interaktif)
///   ./scripts/sync.sh                             (Shortcut bash)
///   dart run tool/sync_repo.dart --unugha --full  (Sync lengkap ke UNUGHA langsung)
///   dart run tool/sync_repo.dart --origin         (Sync branch aktif ke personal)
///   dart run tool/sync_repo.dart --both --full    (Sync lengkap ke kedua remote)

// ANSI Colors
const reset = '\x1B[0m';
const bold = '\x1B[1m';
const green = '\x1B[32m';
const cyan = '\x1B[36m';
const yellow = '\x1B[33m';
const red = '\x1B[31m';
const gray = '\x1B[90m';
const magenta = '\x1B[35m';

// Default Remote URLs (SSH disarankan untuk keamanan & keandalan)
const unughaSshUrl = 'git@github.com:UNUGHA-Informatika-26/cardly_apps.git';
const originDefaultName = 'origin';
const unughaDefaultName = 'unugha';

void main(List<String> args) async {
  // 1. Handle Help Flag
  if (args.contains('--help') || args.contains('-h')) {
    printHelp();
    exit(0);
  }

  // Handle Direct Upload APK Mode
  if (args.contains('--upload-apk')) {
    await handleDirectApkUpload(args);
    exit(0);
  }

  stdout.writeln('');
  stdout.writeln('$cyan$bold======================================================$reset');
  stdout.writeln('$cyan$bold        🚀 CARDLY MULTI-REPO SYNCHRONIZER CLI         $reset');
  stdout.writeln('$cyan$bold======================================================$reset');

  // 2. Preflight Check: Memastikan direktori adalah Git repository
  if (!await Directory('.git').exists()) {
    stderr.writeln('$red$bold Error:$reset Direktori ini bukan repositori Git!');
    exit(1);
  }

  // 3. Inspeksi Remote Aktif
  final remotes = await getGitRemotes();
  await ensureRemoteConfigured(remotes);

  // 4. Deteksi Branch Lokal
  final branches = await getLocalBranches();
  final currentBranch = await getCurrentBranch();
  final featureBranches = branches.where((b) => b.startsWith('feature/')).toList()..sort();

  // 5. Cek Perubahan yang Belum di-Commit (Uncommitted Changes)
  final dirtyFiles = await getDirtyWorkingTreeFiles();
  if (dirtyFiles.isNotEmpty) {
    stdout.writeln('\n$yellow⚠️  Pemberitahuan Working Tree:$reset');
    stdout.writeln('$gray   Ada ${dirtyFiles.length} berkas lokal dengan perubahan belum di-commit.$reset');
    if (args.isEmpty) {
      stdout.write('   Tetap lanjutkan proses sinkronisasi branch yang sudah ada? (Y/n): ');
      final cont = stdin.readLineSync()?.trim().toLowerCase();
      if (cont == 'n' || cont == 'no') {
        stdout.writeln('$yellow Sinkronisasi dibatalkan.$reset');
        exit(0);
      }
    }
  }

  // 6. Tentukan Target Remote (UNUGHA, Personal/Origin, atau Keduanya)
  final targetRemote = await determineTargetRemote(args, remotes);

  // 7. Tentukan Mode Sinkronisasi
  final syncPlan = await determineSyncPlan(
    args: args,
    target: targetRemote,
    branches: branches,
    currentBranch: currentBranch,
    featureBranches: featureBranches,
  );

  // 8. Tampilkan Ringkasan Rencana Sinkronisasi
  printSyncPlanSummary(targetRemote, syncPlan);

  // 9. Konfirmasi Eksekusi (jika interaktif)
  final isDryRun = args.contains('--dry-run') || args.contains('-n');
  if (isDryRun) {
    stdout.writeln('$yellow[DRY-RUN]$reset Mode simulasi aktif. Tidak ada perintah push yang dijalankan.');
    exit(0);
  }

  if (args.isEmpty) {
    stdout.write('\n$bold Jalankan sinkronisasi sekarang? (Y/n): $reset');
    final confirm = stdin.readLineSync()?.trim().toLowerCase();
    if (confirm == 'n' || confirm == 'no') {
      stdout.writeln('$yellow Sinkronisasi dibatalkan.$reset\n');
      exit(0);
    }
  }

  // 10. Uji Koneksi SSH ke GitHub
  stdout.write('\n  -> Memeriksa koneksi SSH ke GitHub... ');
  final sshOk = await testSshConnection();
  if (sshOk) {
    stdout.writeln('$green✓ Terhubung$reset');
  } else {
    stdout.writeln('$yellow⚠️ Gagal tes SSH (akan mencoba push langsung)$reset');
  }

  // 11. Eksekusi Push Berdasarkan Target
  final startTime = DateTime.now();
  var totalSuccess = 0;
  var totalFailed = 0;

  final targets = targetRemote == SyncTarget.both
      ? [SyncTarget.unugha, SyncTarget.personal]
      : [targetRemote];

  for (final target in targets) {
    final remoteName = target == SyncTarget.unugha ? unughaDefaultName : originDefaultName;
    stdout.writeln('\n$cyan$bold▶ Memulai sinkronisasi ke remote [$remoteName]...$reset');

    for (final item in syncPlan.items) {
      final source = item.sourceBranch;
      final dest = (target == SyncTarget.unugha && item.unughaDestBranch != null)
          ? item.unughaDestBranch!
          : item.destBranch;

      stdout.write('  -> Mendorong $source:$dest ... ');
      final result = await executeGitPush(remoteName, '$source:$dest');
      if (result.success) {
        stdout.writeln('$green✓ Berhasil$reset');
        totalSuccess++;
      } else {
        stdout.writeln('$red✗ Gagal$reset');
        stderr.writeln('$gray     Detail: ${result.error.trim()}$reset');
        totalFailed++;
      }
    }

    if (syncPlan.pushTags) {
      stdout.write('  -> Mendorong tags ke [$remoteName]... ');
      final tagResult = await executeGitPush(remoteName, '--tags');
      if (tagResult.success) {
        stdout.writeln('$green✓ Berhasil$reset');
      } else {
        stdout.writeln('$yellow⚠️ Beberapa tag dilewati (email privacy atau sudah ada)$reset');
      }
    }
  }

  final duration = DateTime.now().difference(startTime);
  stdout.writeln('');
  stdout.writeln('$green$bold======================================================$reset');
  if (totalFailed == 0) {
    stdout.writeln('$green$bold  🎉 SINKRONISASI SELESAI DENGAN SUKSES! ($totalSuccess operasi)$reset');
  } else {
    stdout.writeln('$yellow$bold  ⚠️  SINKRONISASI SELESAI DENGAN CATATAN$reset');
    stdout.writeln('  Berhasil: $totalSuccess | Gagal: $totalFailed');
  }
  stdout.writeln('$gray  Waktu eksekusi: ${duration.inSeconds} detik$reset');
  stdout.writeln('$green$bold======================================================$reset\n');
}

// -------------------------------------------------------------
// Model & Enums
// -------------------------------------------------------------

enum SyncTarget { unugha, personal, both }

enum SyncScope { full, current, custom }

class SyncItem {
  final String sourceBranch;
  final String destBranch;
  final String? unughaDestBranch;

  SyncItem({
    required this.sourceBranch,
    required this.destBranch,
    this.unughaDestBranch,
  });
}

class SyncPlan {
  final SyncScope scope;
  final List<SyncItem> items;
  final bool pushTags;

  SyncPlan({
    required this.scope,
    required this.items,
    required this.pushTags,
  });
}

class PushResult {
  final bool success;
  final String output;
  final String error;

  PushResult({
    required this.success,
    required this.output,
    required this.error,
  });
}

// -------------------------------------------------------------
// Git Operations Helpers
// -------------------------------------------------------------

Future<Map<String, String>> getGitRemotes() async {
  final res = await Process.run('git', ['remote', '-v']);
  if (res.exitCode != 0) return {};
  final map = <String, String>{};
  final lines = LineSplitter.split(res.stdout.toString());
  for (final line in lines) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      map[parts[0]] = parts[1];
    }
  }
  return map;
}

Future<void> ensureRemoteConfigured(Map<String, String> remotes) async {
  // Jika remote unugha belum ada, otomatis tambahkan menggunakan SSH
  if (!remotes.containsKey(unughaDefaultName)) {
    stdout.write('  -> Remote "$unughaDefaultName" belum terdaftar. Menambahkan otomatis... ');
    final addRes = await Process.run('git', ['remote', 'add', unughaDefaultName, unughaSshUrl]);
    if (addRes.exitCode == 0) {
      stdout.writeln('$green✓$reset');
    } else {
      stdout.writeln('$red✗$reset');
    }
  } else {
    // Jika masih HTTPS, sarankan ganti atau otomatis rapikan ke SSH
    final currentUrl = remotes[unughaDefaultName] ?? '';
    if (currentUrl.startsWith('https://')) {
      await Process.run('git', ['remote', 'set-url', unughaDefaultName, unughaSshUrl]);
    }
  }
}

Future<List<String>> getLocalBranches() async {
  final res = await Process.run('git', ['branch', '--format=%(refname:short)']);
  if (res.exitCode != 0) return [];
  return LineSplitter.split(res.stdout.toString()).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

Future<String> getCurrentBranch() async {
  final res = await Process.run('git', ['branch', '--show-current']);
  return res.stdout.toString().trim();
}

Future<List<String>> getDirtyWorkingTreeFiles() async {
  final res = await Process.run('git', ['status', '--porcelain']);
  if (res.exitCode != 0) return [];
  return LineSplitter.split(res.stdout.toString()).where((l) => l.trim().isNotEmpty).toList();
}

Future<bool> testSshConnection() async {
  try {
    final res = await Process.run('ssh', ['-T', '-o', 'ConnectTimeout=5', 'git@github.com']);
    // exit code 1 dengan pesan "Hi username!" adalah tanda sukses dari GitHub
    final out = '${res.stdout} ${res.stderr}';
    return out.contains("You've successfully authenticated") || res.exitCode == 1;
  } catch (_) {
    return false;
  }
}

Future<PushResult> executeGitPush(String remote, String refspec) async {
  final res = await Process.run('git', ['push', '-u', remote, refspec]);
  return PushResult(
    success: res.exitCode == 0,
    output: res.stdout.toString(),
    error: res.stderr.toString(),
  );
}

// -------------------------------------------------------------
// Interactive Selection & Planning
// -------------------------------------------------------------

Future<SyncTarget> determineTargetRemote(List<String> args, Map<String, String> remotes) async {
  if (args.contains('--unugha') || args.contains('-u') || args.contains('--target=unugha')) {
    return SyncTarget.unugha;
  }
  if (args.contains('--origin') || args.contains('-p') || args.contains('--target=origin')) {
    return SyncTarget.personal;
  }
  if (args.contains('--both') || args.contains('--all') || args.contains('--target=both')) {
    return SyncTarget.both;
  }

  stdout.writeln('\n[1/2] Pilih Target Repositori:');
  stdout.writeln('  [1] UNUGHA Kampus (UNUGHA-Informatika-26/cardly_apps)');
  stdout.writeln('  [2] Personal GitHub (Mrmarc-bit/cardly_apps)');
  stdout.writeln('  [3] Dual Sync (UNUGHA & Personal Sekaligus)');
  stdout.write('\nMasukkan pilihan [1-3] (default 1): ');

  final input = stdin.readLineSync()?.trim();
  switch (input) {
    case '2':
      return SyncTarget.personal;
    case '3':
      return SyncTarget.both;
    case '1':
    default:
      return SyncTarget.unugha;
  }
}

Future<SyncPlan> determineSyncPlan({
  required List<String> args,
  required SyncTarget target,
  required List<String> branches,
  required String currentBranch,
  required List<String> featureBranches,
}) async {
  var scope = SyncScope.full;

  if (args.contains('--full') || args.contains('-f') || args.contains('--mode=full')) {
    scope = SyncScope.full;
  } else if (args.contains('--current') || args.contains('-c') || args.contains('--mode=current')) {
    scope = SyncScope.current;
  } else if (args.isEmpty) {
    stdout.writeln('\n[2/2] Pilih Mode Sinkronisasi:');
    stdout.writeln('  [1] Full Academic Sync (main, develop, 8 modul feature/* & tags)');
    stdout.writeln('  [2] Branch Aktif Saja (hanya branch saat ini: "$currentBranch")');
    stdout.writeln('  [3] Pilih Branch Spesifik (Custom)');
    stdout.write('\nMasukkan pilihan [1-3] (default 1): ');

    final input = stdin.readLineSync()?.trim();
    if (input == '2') {
      scope = SyncScope.current;
    } else if (input == '3') {
      scope = SyncScope.custom;
    } else {
      scope = SyncScope.full;
    }
  }

  final items = <SyncItem>[];
  var pushTags = true;

  if (scope == SyncScope.full) {
    // 1. Main branch handling
    if (branches.contains('unugha-main')) {
      items.add(SyncItem(
        sourceBranch: 'unugha-main',
        destBranch: 'unugha-main',
        unughaDestBranch: 'main',
      ));
    } else if (branches.contains('main')) {
      items.add(SyncItem(
        sourceBranch: 'main',
        destBranch: 'main',
      ));
    }

    // 2. Develop branch handling
    if (branches.contains('develop')) {
      items.add(SyncItem(sourceBranch: 'develop', destBranch: 'develop'));
    }

    // 3. Semua Feature Branches
    for (final fb in featureBranches) {
      items.add(SyncItem(sourceBranch: fb, destBranch: fb));
    }

    pushTags = true;
  } else if (scope == SyncScope.current) {
    // Hanya branch aktif saat ini
    final isUnughaMain = currentBranch == 'unugha-main';
    items.add(SyncItem(
      sourceBranch: currentBranch,
      destBranch: currentBranch,
      unughaDestBranch: isUnughaMain ? 'main' : currentBranch,
    ));
    pushTags = false;
  } else {
    // Custom selection
    stdout.writeln('\nDaftar Branch Lokal:');
    for (var i = 0; i < branches.length; i++) {
      stdout.writeln('  [${i + 1}] ${branches[i]}');
    }
    stdout.write('\nPilih nomor branch (pisahkan dengan koma, contoh: 1,3): ');
    final selection = stdin.readLineSync() ?? '';
    final indices = selection
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((i) => i >= 1 && i <= branches.length)
        .map((i) => i - 1)
        .toList();

    for (final idx in indices) {
      final b = branches[idx];
      items.add(SyncItem(
        sourceBranch: b,
        destBranch: b,
        unughaDestBranch: b == 'unugha-main' ? 'main' : b,
      ));
    }

    stdout.write('Sertakan push tags juga? (y/N): ');
    final tagChoice = stdin.readLineSync()?.trim().toLowerCase();
    pushTags = tagChoice == 'y' || tagChoice == 'yes';
  }

  return SyncPlan(scope: scope, items: items, pushTags: pushTags);
}

void printSyncPlanSummary(SyncTarget target, SyncPlan plan) {
  final targetLabel = target == SyncTarget.unugha
      ? 'UNUGHA Kampus ($unughaSshUrl)'
      : target == SyncTarget.personal
          ? 'Personal GitHub (origin)'
          : 'Dual Sync (UNUGHA & Personal Sekaligus)';

  stdout.writeln('');
  stdout.writeln('$cyan$bold------------------------------------------------------$reset');
  stdout.writeln('$bold Rencana Sinkronisasi:$reset');
  stdout.writeln('  Target : $bold$targetLabel$reset');
  stdout.writeln('  Scope  : ${plan.scope.name.toUpperCase()} (${plan.items.length} branch)');
  stdout.writeln('  Tags   : ${plan.pushTags ? "$green Ya$reset" : "$gray Tidak$reset"}');
  stdout.writeln('  Daftar Branch yang akan didorong:');
  for (final item in plan.items) {
    final dest = target == SyncTarget.unugha && item.unughaDestBranch != null
        ? item.unughaDestBranch!
        : item.destBranch;
    stdout.writeln('    • ${item.sourceBranch} $gray->$reset $dest');
  }
  stdout.writeln('$cyan$bold------------------------------------------------------$reset');
}

void printHelp() {
  stdout.writeln('');
  stdout.writeln('$cyan$bold Cardly Multi-Repo Synchronizer$reset');
  stdout.writeln('Alat otomatisasi sinkronisasi Git untuk multi-repositori (Kampus & Personal).\n');
  stdout.writeln('Penggunaan:');
  stdout.writeln('  dart run tool/sync_repo.dart [options]\n');
  stdout.writeln('Opsi Target:');
  stdout.writeln('  -u, --unugha          Target ke repositori UNUGHA Kampus');
  stdout.writeln('  -p, --origin          Target ke repositori Personal (origin)');
  stdout.writeln('  -a, --both, --all     Target ke kedua repositori sekaligus (Dual Sync)\n');
  stdout.writeln('Opsi Mode:');
  stdout.writeln('  -f, --full            Mode lengkap (main, develop, seluruh feature/* & tags)');
  stdout.writeln('  -c, --current         Mode cepat (hanya branch yang aktif saat ini)\n');
  stdout.writeln('Opsi Lain:');
  stdout.writeln('  --upload-apk [file]   Unggah berkas APK lokal langsung ke GitHub Releases');
  stdout.writeln('  -n, --dry-run         Simulasi tanpa menjalankan push git');
  stdout.writeln('  -h, --help            Menampilkan bantuan ini\n');
  stdout.writeln('Contoh Cepat:');
  stdout.writeln('  ./scripts/sync.sh                     Mode interaktif dengan dialog menu');
  stdout.writeln('  ./scripts/sync.sh -u -f               Langsung push semua tugas ke UNUGHA');
  stdout.writeln('  ./scripts/sync.sh -a -f               Dual-sync semua branch ke UNUGHA & Personal');
  stdout.writeln('  ./scripts/sync.sh --upload-apk        Pilih dan unggah berkas APK ke GitHub Releases');
  stdout.writeln('');
}

/// Menangani unggah APK lokal langsung ke GitHub Releases via REST API
Future<void> handleDirectApkUpload(List<String> args) async {
  stdout.writeln('');
  stdout.writeln('$cyan$bold======================================================$reset');
  stdout.writeln('$cyan$bold       📦 GITHUB RELEASE DIRECT APK UPLOADER          $reset');
  stdout.writeln('$cyan$bold======================================================$reset');

  // 1. Cari File APK
  File? chosenFile;
  final flagIdx = args.indexOf('--upload-apk');
  if (flagIdx != -1 && flagIdx + 1 < args.length && !args[flagIdx + 1].startsWith('-')) {
    final candidate = File(args[flagIdx + 1]);
    if (candidate.existsSync()) {
      chosenFile = candidate;
    }
  }

  if (chosenFile == null) {
    final releasesDir = Directory('releases');
    final buildApkDir = Directory('build/app/outputs/flutter-apk');
    final apkCandidates = <File>[];

    if (releasesDir.existsSync()) {
      apkCandidates.addAll(
        releasesDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.apk')),
      );
    }
    if (buildApkDir.existsSync()) {
      apkCandidates.addAll(
        buildApkDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.apk')),
      );
    }

    if (apkCandidates.isEmpty) {
      stderr.writeln('$red Error: Tidak ditemukan berkas APK di releases/ atau build/.$reset');
      stdout.writeln('Silakan build terlebih dahulu dengan ./scripts/release.sh');
      return;
    }

    stdout.writeln('\nPilih berkas APK yang ingin diunggah:');
    for (var i = 0; i < apkCandidates.length; i++) {
      final f = apkCandidates[i];
      final mb = (f.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
      stdout.writeln('  [${i + 1}] ${f.path} ($mb MB)');
    }
    stdout.write('\nMasukkan pilihan [1-${apkCandidates.length}]: ');
    final selStr = stdin.readLineSync()?.trim();
    final selIdx = (int.tryParse(selStr ?? '1') ?? 1) - 1;
    if (selIdx >= 0 && selIdx < apkCandidates.length) {
      chosenFile = apkCandidates[selIdx];
    } else {
      chosenFile = apkCandidates.first;
    }
  }

  stdout.writeln('\nBerkas terpilih: $bold$green${chosenFile.path}$reset');

  // 2. Deteksi Versi / Tag
  final tagRegex = RegExp(r'v?([0-9]+\.[0-9]+\.[0-9]+)');
  final tagMatch = tagRegex.firstMatch(chosenFile.path);
  var targetTag = tagMatch != null ? 'v${tagMatch.group(1)}' : 'v1.0.10';

  stdout.write('Tag Rilis Target [$targetTag]: ');
  final customTag = stdin.readLineSync()?.trim();
  if (customTag != null && customTag.isNotEmpty) {
    targetTag = customTag.startsWith('v') ? customTag : 'v$customTag';
  }

  // 3. Tentukan Target Repo
  stdout.writeln('\nPilih Target Repositori GitHub:');
  stdout.writeln('  [1] UNUGHA Kampus (UNUGHA-Informatika-26/cardly_apps)');
  stdout.writeln('  [2] Personal (Mrmarc-bit/cardly_apps)');
  stdout.writeln('  [3] Keduanya (Dual Release)');
  stdout.write('Masukkan pilihan [1-3] (default 1): ');
  final targetChoice = stdin.readLineSync()?.trim();

  final owners = <String>[];
  if (targetChoice == '2') {
    owners.add('Mrmarc-bit');
  } else if (targetChoice == '3') {
    owners.addAll(['UNUGHA-Informatika-26', 'Mrmarc-bit']);
  } else {
    owners.add('UNUGHA-Informatika-26');
  }

  // 4. Token Autentikasi
  var token = Platform.environment['GITHUB_TOKEN'];
  if (token == null || token.isEmpty) {
    stdout.write('\nMasukkan Personal Access Token GitHub (Classic dengan scope "repo"): ');
    token = stdin.readLineSync()?.trim();
    if (token == null || token.isEmpty) {
      stderr.writeln('$red Token tidak boleh kosong untuk direct upload API.$reset');
      stdout.writeln('Alternatif: Dorong git tag (git push unugha $targetTag) agar GitHub Actions yang merilis.');
      return;
    }
  }

  // 5. Eksekusi Upload ke GitHub Release Assets
  final client = HttpClient();
  for (final owner in owners) {
    stdout.writeln('\n$cyan Mengunggah ke GitHub Releases [$owner/cardly_apps]...$reset');
    try {
      // Dapatkan Release Id
      final getReq = await client.getUrl(
        Uri.parse('https://api.github.com/repos/$owner/cardly_apps/releases/tags/$targetTag'),
      );
      getReq.headers.set('Authorization', 'Bearer $token');
      getReq.headers.set('User-Agent', 'Cardly-Sync-CLI');
      final getRes = await getReq.close();

      int? releaseId;
      if (getRes.statusCode == 200) {
        final body = await getRes.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        releaseId = json['id'] as int?;
      } else if (getRes.statusCode == 404) {
        stdout.write('  -> Release $targetTag belum ada di GitHub. Membuat otomatis... ');
        final postReq = await client.postUrl(
          Uri.parse('https://api.github.com/repos/$owner/cardly_apps/releases'),
        );
        postReq.headers.set('Authorization', 'Bearer $token');
        postReq.headers.set('User-Agent', 'Cardly-Sync-CLI');
        postReq.headers.set('Content-Type', 'application/json');
        postReq.write(jsonEncode({
          'tag_name': targetTag,
          'name': 'Cardly Release $targetTag',
          'draft': false,
          'prerelease': false,
        }));
        final postRes = await postReq.close();
        if (postRes.statusCode >= 200 && postRes.statusCode < 300) {
          final body = await postRes.transform(utf8.decoder).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          releaseId = json['id'] as int?;
          stdout.writeln('$green✓$reset');
        } else {
          stdout.writeln('$red✗ Gagal membuat release (${postRes.statusCode})$reset');
        }
      }

      if (releaseId != null) {
        final fileName = 'cardly-release-$targetTag.apk';
        stdout.write('  -> Mengunggah file aset $fileName (${(chosenFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB)... ');
        final uploadUri = Uri.parse(
          'https://uploads.github.com/repos/$owner/cardly_apps/releases/$releaseId/assets?name=$fileName',
        );
        final uploadReq = await client.postUrl(uploadUri);
        uploadReq.headers.set('Authorization', 'Bearer $token');
        uploadReq.headers.set('User-Agent', 'Cardly-Sync-CLI');
        uploadReq.headers.set('Content-Type', 'application/vnd.android.package-archive');
        uploadReq.headers.set('Content-Length', chosenFile.lengthSync().toString());

        await uploadReq.addStream(chosenFile.openRead());
        final uploadRes = await uploadReq.close();
        if (uploadRes.statusCode >= 200 && uploadRes.statusCode < 300) {
          stdout.writeln('$green✓ BERHASIL!$reset');
          stdout.writeln('  URL Release: https://github.com/$owner/cardly_apps/releases/tag/$targetTag');
        } else {
          final errBody = await uploadRes.transform(utf8.decoder).join();
          stdout.writeln('$red✗ Gagal (${uploadRes.statusCode})$reset');
          stderr.writeln('$gray     Detail: $errBody$reset');
        }
      }
    } catch (e) {
      stderr.writeln('$red Terjadi kesalahan: $e$reset');
    }
  }
  client.close();
  stdout.writeln('');
}

