import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardly/app/providers.dart';
import 'package:cardly/features/scan/presentation/camera_scan_flow_view.dart';
import 'package:cardly/features/scan/presentation/widgets/camera_permission_view.dart';
import 'package:cardly/features/scan/presentation/widgets/crop_rotate_editor.dart';
import 'package:cardly/features/scan/presentation/widgets/pre_scan_sheet.dart';
import 'package:cardly/features/scan/presentation/widgets/scan_laser_overlay.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Camera Scan & OCR Flow Tests', () {
    testWidgets(
      'PreScanSheet renders title, document type selectors, and action buttons',
      (tester) async {
        ScanDocumentType selectedType = ScanDocumentType.idCard;
        bool startedScan = false;
        bool pickedGallery = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PreScanSheet(
                selectedType: selectedType,
                onTypeChanged: (type) => selectedType = type,
                onStartScan: () => startedScan = true,
                onPickFromGallery: () => pickedGallery = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Panduan Memindai Dokumen'), findsOneWidget);
        expect(find.text('Kartu Identitas'), findsOneWidget);
        expect(find.text('Dokumen Fisik'), findsOneWidget);
        expect(find.text('100% On-Device'), findsOneWidget);
        expect(find.text('Buka Kamera Pindai'), findsOneWidget);
        expect(find.text('Pilih dari Galeri Foto'), findsOneWidget);

        await tester.ensureVisible(find.text('Buka Kamera Pindai'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Buka Kamera Pindai'));
        expect(startedScan, isTrue);

        await tester.ensureVisible(find.text('Pilih dari Galeri Foto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pilih dari Galeri Foto'));
        expect(pickedGallery, isTrue);
      },
    );

    testWidgets('ScanLaserOverlay renders laser bar and detected badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScanLaserOverlay(
              isScanning: true,
              detectedBadge: 'KTP RI Terdeteksi',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('KTP RI Terdeteksi'), findsOneWidget);
      expect(find.text('Posisikan dokumen dalam bingkai'), findsOneWidget);
    });

    testWidgets(
      'CameraPermissionView renders required explanation and fallback button',
      (tester) async {
        bool openedSettings = false;
        bool imported = false;

        await tester.pumpWidget(
          MaterialApp(
            home: CameraPermissionView(
              onOpenSettings: () => openedSettings = true,
              onImportFallback: () => imported = true,
              onClose: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Akses Kamera Diperlukan'), findsOneWidget);
        expect(find.text('Buka Pengaturan Perangkat'), findsOneWidget);
        expect(find.text('Impor File Saja (Tanpa Kamera)'), findsOneWidget);

        await tester.tap(find.text('Buka Pengaturan Perangkat'));
        expect(openedSettings, isTrue);

        await tester.tap(find.text('Impor File Saja (Tanpa Kamera)'));
        expect(imported, isTrue);
      },
    );

    testWidgets('CropRotateEditor allows rotating 90 degrees and confirming', (
      tester,
    ) async {
      int confirmedTurns = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: CropRotateEditor(
            initialQuarterTurns: 0,
            onRetake: () {},
            onConfirmCrop: (turns) => confirmedTurns = turns,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Potong & putar'), findsOneWidget);
      expect(find.text('Putar 90°'), findsOneWidget);
      expect(find.text('Atur ulang'), findsOneWidget);

      // Tap Putar 90°
      await tester.ensureVisible(find.text('Putar 90°'));
      await tester.tap(find.text('Putar 90°'));
      await tester.pumpAndSettle();

      // Tap Gunakan hasil scan
      await tester.ensureVisible(find.text('Gunakan hasil scan'));
      await tester.tap(find.text('Gunakan hasil scan'));
      await tester.pumpAndSettle();

      expect(confirmedTurns, 1);
    });

    testWidgets(
      'CameraScanFlowView transitions through complete scan -> crop -> OCR workflow',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MaterialApp(home: CameraScanFlowView()),
          ),
        );
        await tester.pumpAndSettle();

        // Step 1: Pre-Scan
        expect(find.text('Panduan Memindai Dokumen'), findsOneWidget);
        await tester.ensureVisible(find.text('Buka Kamera Pindai'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Buka Kamera Pindai'));
        await tester.pump();

        // Step 2: Camera Capture
        expect(find.byType(ScanLaserOverlay), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

        // Tap Shutter
        await tester.tap(find.byIcon(Icons.camera_alt_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        // Step 3: Express Flow -> Langsung ke OCR Review Form (Auto-Cropped)
        expect(find.text('Tinjau Hasil OCR'), findsOneWidget);
        expect(find.text('Auto-crop aktif'), findsOneWidget);
        expect(find.text('Sesuaikan'), findsOneWidget);

        // Buka editor Potong & Putar melalui tombol Sesuaikan
        await tester.ensureVisible(find.text('Sesuaikan'));
        await tester.tap(find.text('Sesuaikan'));
        await tester.pumpAndSettle();

        expect(find.text('Potong & putar'), findsOneWidget);
        await tester.ensureVisible(find.text('Putar 90°'));
        await tester.tap(find.text('Putar 90°'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Gunakan hasil scan'));
        await tester.tap(find.text('Gunakan hasil scan'));
        await tester.pumpAndSettle();

        // Kembali ke OCR Review Form
        expect(find.text('Tinjau Hasil OCR'), findsOneWidget);
        expect(find.text('KTP Digital RI'), findsNWidgets(2));
        expect(find.text('Simpan ke Dokumen Penting'), findsOneWidget);
        expect(find.text('Simpan ke Dompet Kartu'), findsOneWidget);

        // Save document
        await tester.ensureVisible(find.text('Simpan ke Dokumen Penting'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simpan ke Dokumen Penting'));
        await tester.pumpAndSettle();
      },
    );
  });
}
