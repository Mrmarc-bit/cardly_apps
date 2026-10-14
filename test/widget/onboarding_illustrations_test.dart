import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/features/authentication/presentation/widgets/auth_illustrations.dart';

void main() {
  group('Onboarding & Welcome Continuous Animations Widget Tests', () {
    testWidgets(
      'OnboardingCardsIllustration renders with floating cards in light & dark mode',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: OnboardingCardsIllustration(height: 280)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('KARTU UTAMA'), findsOneWidget);
        expect(find.text('Harian'), findsOneWidget);
        expect(find.text('Bank Central Asia'), findsOneWidget);
        expect(find.text('Visa'), findsOneWidget);
        expect(find.text('PRIORITAS'), findsOneWidget);
      },
    );

    testWidgets(
      'OnboardingDocumentIllustration renders with levitating doc & floating folder badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: OnboardingDocumentIllustration(height: 280),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Identitas'), findsOneWidget);
        expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
        expect(
          find.text('KTP Republik Indonesia • DKI Jakarta'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OnboardingPrivacyIllustration renders with security scanner beam & lock badge',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: OnboardingPrivacyIllustration(height: 280)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dokumen pribadi'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);
        expect(
          find.text('Enkripsi AES-256 • Tersimpan di Perangkat'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Illustrations adapt without overflow on narrow 360dp mobile viewports',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    OnboardingCardsIllustration(height: 240),
                    OnboardingDocumentIllustration(height: 240),
                    OnboardingPrivacyIllustration(height: 240),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('KARTU UTAMA'), findsOneWidget);
        expect(find.text('Identitas'), findsOneWidget);
        expect(find.text('Dokumen pribadi'), findsOneWidget);
      },
    );
  });
}
