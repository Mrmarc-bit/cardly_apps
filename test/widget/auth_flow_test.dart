import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardly/app/providers.dart';
import 'package:cardly/features/authentication/presentation/splash_view.dart';
import 'package:cardly/features/authentication/presentation/onboarding_view.dart';
import 'package:cardly/features/authentication/presentation/welcome_view.dart';
import 'package:cardly/features/authentication/presentation/login_view.dart';
import 'package:cardly/features/authentication/presentation/register_view.dart';
import 'package:cardly/features/authentication/presentation/check_email_view.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('SplashView displays brand lockup, slogan and bottom caption', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(const SplashView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cardly'), findsOneWidget);
    expect(
      find.text('Your cards. Your documents. One private space.'),
      findsOneWidget,
    );
    expect(
      find.text('Semua kartu dan dokumen penting, dalam satu tempat.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'OnboardingView renders initial slide with card stack and Lewati button',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget(const OnboardingView()));
      await tester.pumpAndSettle();

      expect(find.text('Cardly'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.text('KENALI CARDLY / 01'), findsOneWidget);
      expect(find.text('Semua kartu, satu tempat.'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    },
  );

  testWidgets(
    'WelcomeView renders hero cards, title, Masuk and Buat Akun buttons without Bukan bank banner',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget(const WelcomeView()));
      await tester.pumpAndSettle();

      expect(find.text('Cardly'), findsOneWidget);
      expect(find.text('Ruang pribadi\nuntuk yang\npenting.'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Buat Akun'), findsOneWidget);
      expect(find.text('Bukan bank. Bukan alat pembayaran.'), findsNothing);
    },
  );

  testWidgets(
    'LoginView renders enclosed card inputs, Ingat saya, and Lupa kata sandi',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginView()));
      await tester.pumpAndSettle();

      expect(find.text('Selamat datang kembali.'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata sandi'), findsOneWidget);
      expect(find.text('Ingat saya'), findsOneWidget);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
    },
  );

  testWidgets(
    'RegisterView renders full form, 4-bar indicator, and terms checkbox',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget(const RegisterView()));
      await tester.pumpAndSettle();

      expect(find.text('Buat ruang pribadi Anda.'), findsOneWidget);
      expect(find.text('Nama lengkap'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata sandi'), findsOneWidget);
      expect(find.text('Buat Akun'), findsNWidgets(2));
    },
  );

  testWidgets(
    'CheckEmailView renders email, countdown timer and action buttons',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const CheckEmailView(email: 'user@test.com')),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tautan sudah diminta.'), findsOneWidget);
      expect(find.textContaining('user@test.com'), findsOneWidget);
      expect(find.text('Kembali ke Masuk'), findsOneWidget);
      expect(find.textContaining('Kirim ulang dalam'), findsOneWidget);
    },
  );
}
