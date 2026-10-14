import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cardly/app/providers.dart';
import 'package:cardly/features/home/presentation/main_shell_screen.dart';

void main() {
  testWidgets(
    'MainShellScreen renders bottom nav bar with 5 items and switches tabs',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 5 tab labels are visible on screen
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Kartu'), findsOneWidget);
      expect(find.text('Dokumen'), findsOneWidget);
      expect(find.text('Brankas'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap 'Kartu' tab
      await tester.tap(find.text('Kartu'));
      await tester.pumpAndSettle();

      // Tap 'Dokumen' tab
      await tester.tap(find.text('Dokumen'));
      await tester.pumpAndSettle();

      // Tap 'Brankas' tab
      await tester.tap(find.text('Brankas'));
      await tester.pumpAndSettle();

      // Tap 'Profil' tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
    },
  );
}
