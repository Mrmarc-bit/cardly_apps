import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cardly/core/network/supabase_service.dart';
import 'package:cardly/core/storage/app_database.dart';
import 'package:cardly/core/sync/cloud_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;
  late CloudSyncService syncService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase();
    syncService = CloudSyncService(
      database: db,
      supabase: SupabaseService.instance,
      prefs: prefs,
    );
  });

  group('CloudSyncService Unit Tests', () {
    test('initial status is idle and lastSyncTime is null', () {
      expect(syncService.currentStatus, SyncStatus.idle);
      expect(syncService.lastSyncTime, isNull);
    });

    test('syncAll reports unauthenticated or offline gracefully when no user is logged in', () async {
      final report = await syncService.syncAll();
      expect(report.isSuccess, isFalse);
      expect(report.errorMessage, isNotNull);
      expect(
        syncService.currentStatus == SyncStatus.unauthenticated ||
            syncService.currentStatus == SyncStatus.offline,
        isTrue,
      );
    });

    test('SyncReport calculates totalItems correctly', () {
      final report = SyncReport(
        cardsPushed: 2,
        cardsPulled: 3,
        documentsPushed: 1,
        documentsPulled: 0,
        remindersPushed: 4,
        remindersPulled: 1,
        timestamp: DateTime.now(),
      );

      expect(report.totalItems, 11);
      expect(report.isSuccess, isTrue);
    });
  });
}
