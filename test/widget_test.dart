import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cardly/app/app.dart';
import 'package:cardly/app/providers.dart';

void main() {
  testWidgets('CardlyApp launches successfully and displays splash screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const CardlyApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Cardly title / branding appears
    expect(find.text('Cardly'), findsWidgets);
  });
}
