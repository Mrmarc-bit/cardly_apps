import 'package:flutter_test/flutter_test.dart';

import 'package:cardly/features/app_update/data/app_update_service.dart';
import 'package:cardly/features/app_update/domain/app_update_info.dart';

void main() {
  group('AppUpdateService & Version Comparison Tests', () {
    late AppUpdateService updateService;

    setUp(() {
      updateService = AppUpdateService();
    });

    test('isNewerVersion correctly compares semantic version strings', () {
      expect(updateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(updateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(updateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
      expect(updateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('0.9.5', '1.0.0'), isFalse);
      expect(updateService.isNewerVersion('invalid', '1.0.0'), isFalse);
    });

    test('AppUpdateInfo correctly parses standard version.json payload', () {
      final jsonPayload = {
        'latest_version': '1.0.2',
        'build_number': 3,
        'download_url': 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.2/cardly-release.apk',
        'changelog': [
          'Pemindai rounded card ISO/IEC 7810 ID-1',
          'Ekstraksi e-KTP otomatis',
        ],
        'is_force_update': true,
        'release_date': '2026-10-14',
        'file_size_bytes': 28500000,
      };

      final info = AppUpdateInfo.fromJson(jsonPayload);

      expect(info.latestVersion, '1.0.2');
      expect(info.buildNumber, 3);
      expect(info.downloadUrl, contains('v1.0.2/cardly-release.apk'));
      expect(info.changelog.length, 2);
      expect(info.changelog.first, 'Pemindai rounded card ISO/IEC 7810 ID-1');
      expect(info.isForceUpdate, isTrue);
      expect(info.fileSizeBytes, 28500000);
    });

    test('DownloadProgress formats Megabytes and percentage properly', () {
      const progress = DownloadProgress(
        downloadedBytes: 14680064, // ~14.0 MB
        totalBytes: 29360128, // ~28.0 MB
        progress: 0.5,
      );

      expect(progress.percentage, 50);
      expect(progress.formattedDownloaded, '14.0');
      expect(progress.formattedTotal, '28.0');
    });

    test('Headless test environment skips network call safely', () async {
      final update = await updateService.checkForUpdate();
      expect(update, isNull);
    });
  });
}
