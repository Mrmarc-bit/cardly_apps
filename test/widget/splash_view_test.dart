import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cardly/app/providers.dart';
import 'package:cardly/features/authentication/presentation/splash_view.dart';
import 'package:cardly/features/authentication/presentation/widgets/cardly_animated_logo.dart';

void main() {
  group('CardlyAnimatedLogo & SplashView Widget Tests', () {
    testWidgets('CardlyAnimatedLogo selects screen_gelap.json for light mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.light,
          home: Scaffold(body: CardlyAnimatedLogo(isDark: false)),
        ),
      );

      final lottieFinder = find.byType(LottieBuilder);
      expect(lottieFinder, findsOneWidget);

      final lottieWidget = tester.widget<LottieBuilder>(lottieFinder);
      expect(lottieWidget.lottie, isA<AssetLottie>());
      final assetLottie = lottieWidget.lottie as AssetLottie;
      expect(assetLottie.assetName, 'assets/animations/screen_gelap.json');
    });

    testWidgets('CardlyAnimatedLogo selects screen_terang.json for dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: CardlyAnimatedLogo(isDark: true)),
        ),
      );

      final lottieFinder = find.byType(LottieBuilder);
      expect(lottieFinder, findsOneWidget);

      final lottieWidget = tester.widget<LottieBuilder>(lottieFinder);
      expect(lottieWidget.lottie, isA<AssetLottie>());
      final assetLottie = lottieWidget.lottie as AssetLottie;
      expect(assetLottie.assetName, 'assets/animations/screen_terang.json');
    });

    testWidgets(
      'SplashView renders slogan, indicator, and footer correctly in light mode',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const SplashView(),
            ),
          ),
        );

        // Verify slogan and footer
        expect(
          find.text('Your cards. Your documents. One private space.'),
          findsOneWidget,
        );
        expect(
          find.text('Semua kartu dan dokumen penting, dalam satu tempat.'),
          findsOneWidget,
        );
        expect(find.byType(CardlyAnimatedLogo), findsOneWidget);
      },
    );

    testWidgets('SplashView renders without overflow on narrow 360dp screen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(theme: ThemeData.dark(), home: const SplashView()),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CardlyAnimatedLogo), findsOneWidget);
      expect(
        find.text('Your cards. Your documents. One private space.'),
        findsOneWidget,
      );
    });
  });
}
