import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardly/core/storage/local_storage_service.dart';

void main() {
  group('LocalStorageService & App Version Tracking Tests', () {
    test('lastAppVersion and lastBuildNumber default to empty and 0', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      expect(storage.lastAppVersion, '');
      expect(storage.lastBuildNumber, 0);
    });

    test(
      'lastAppVersion and lastBuildNumber correctly persist and update',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = LocalStorageService(prefs);

        await storage.setLastAppVersion('1.0.9');
        await storage.setLastBuildNumber(10);

        expect(storage.lastAppVersion, '1.0.9');
        expect(storage.lastBuildNumber, 10);

        // Simulasi update ke versi 1.1.0
        await storage.setLastAppVersion('1.1.0');
        await storage.setLastBuildNumber(11);

        expect(storage.lastAppVersion, '1.1.0');
        expect(storage.lastBuildNumber, 11);
      },
    );
  });
}
