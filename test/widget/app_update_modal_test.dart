import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cardly/features/app_update/domain/app_update_info.dart';
import 'package:cardly/features/app_update/presentation/app_update_modal.dart';

void main() {
  group('AppUpdateModal Widget Tests', () {
    testWidgets('AppUpdateModal renders version info, changelog, and buttons', (
      tester,
    ) async {
      const updateInfo = AppUpdateInfo(
        latestVersion: '1.0.5',
        buildNumber: 5,
        downloadUrl: 'https://mock.url/cardly.apk',
        changelog: [
          'Fitur OCR otomatis presisi tinggi',
          'Perbaikan navigasi tombol kembali',
        ],
        isForceUpdate: false,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: AppUpdateModal(updateInfo: updateInfo)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Versi Tersedia'), findsOneWidget);
      expect(find.text('v1.0.5'), findsOneWidget);
      expect(find.text('APA YANG BARU:'), findsOneWidget);
      expect(find.text('Fitur OCR otomatis presisi tinggi'), findsOneWidget);
      expect(find.text('Perbaikan navigasi tombol kembali'), findsOneWidget);
      expect(find.text('Perbarui Sekarang'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
    });

    testWidgets(
      'AppUpdateModal hides Nanti Saja button when force update is required',
      (tester) async {
        const forceUpdateInfo = AppUpdateInfo(
          latestVersion: '2.0.0',
          buildNumber: 10,
          downloadUrl: 'https://mock.url/cardly.apk',
          changelog: ['Pembaruan keamanan kritis'],
          isForceUpdate: true,
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: AppUpdateModal(updateInfo: forceUpdateInfo)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Wajib'), findsOneWidget);
        expect(find.text('Perbarui Sekarang'), findsOneWidget);
        expect(find.text('Nanti Saja'), findsNothing);
      },
    );
  });
}
