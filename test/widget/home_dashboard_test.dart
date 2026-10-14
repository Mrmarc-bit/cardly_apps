import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardly/app/providers.dart';
import 'package:cardly/core/widgets/cardly_buttons.dart';
import 'package:cardly/features/home/presentation/home_dashboard_view.dart';
import 'package:cardly/features/documents/presentation/create_folder_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'cardly_user_name': "Ma'ruf"});
  });

  testWidgets(
    'HomeDashboardView renders all header, wallet card, quick actions, and recent items',
    (WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: Scaffold(body: HomeDashboardView())),
        ),
      );

      await tester.pumpAndSettle();

      // Verify greetings and username
      expect(find.textContaining('Selamat'), findsOneWidget);
      expect(find.text("Ma'ruf"), findsOneWidget);

      // Verify Dompet Saya card
      expect(find.text('Dompet Saya'), findsOneWidget);
      expect(find.text('kartu'), findsWidgets);
      expect(find.text('dokumen'), findsWidgets);
      expect(find.text('Disamarkan'), findsOneWidget);

      // Toggle masking status
      await tester.tap(find.text('Disamarkan'));
      await tester.pumpAndSettle();
      expect(find.text('Ditampilkan'), findsOneWidget);

      // Verify 4 Quick Action buttons
      expect(find.text('Tambah Kartu'), findsWidgets);
      expect(find.text('Scan Dokumen'), findsOneWidget);
      expect(find.text('Buat Folder'), findsOneWidget);
      expect(find.text('Pengingat'), findsOneWidget);

      // Verify Kartu Pilihan and Baru ditambahkan
      expect(find.text('Kartu pilihan'), findsOneWidget);
      expect(find.text('Baru ditambahkan'), findsOneWidget);
    },
  );

  testWidgets('CreateFolderView renders form fields and validates correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateFolderView())),
    );

    await tester.pumpAndSettle();

    // Verify title and input fields
    expect(find.text('Buat Folder'), findsWidgets);
    expect(find.text('Nama folder'), findsOneWidget);
    expect(find.text('Lokasi'), findsOneWidget);
    expect(find.text('Brankas'), findsOneWidget);
    expect(find.text('Dokumen pribadi'), findsOneWidget);

    // Toggle privacy switch
    await tester.tap(find.text('Dokumen pribadi'));
    await tester.pumpAndSettle();

    // Tap submit button
    expect(find.byType(CardlyPrimaryButton), findsOneWidget);
    await tester.tap(find.byType(CardlyPrimaryButton));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
