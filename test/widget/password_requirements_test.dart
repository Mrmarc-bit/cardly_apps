import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/features/authentication/presentation/widgets/password_requirements_checklist.dart';
import 'package:cardly/features/authentication/presentation/widgets/google_sign_in_button.dart';

void main() {
  group('PasswordRequirementsChecklist & GoogleSignInButton Widget Tests', () {
    testWidgets(
      'PasswordRequirementsChecklist verifies enterprise criteria progressively',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PasswordRequirementsChecklist(password: 'Simple1'),
            ),
          ),
        );

        expect(find.text('Standar Keamanan Kata Sandi'), findsOneWidget);
        expect(find.text('Minimal 12 karakter'), findsOneWidget);
        expect(
          find.text('Kombinasi huruf besar (A-Z) & kecil (a-z)'),
          findsOneWidget,
        );
        expect(find.text('Minimal satu angka (0-9)'), findsOneWidget);
        expect(
          find.text('Minimal satu karakter simbol khusus (!@#\$%...)'),
          findsOneWidget,
        );

        // 'Simple1' has upper, lower, digit, but length < 12 and no special char
        final widgetState = tester.widget<PasswordRequirementsChecklist>(
          find.byType(PasswordRequirementsChecklist),
        );
        expect(widgetState.hasMinLength, isFalse);
        expect(widgetState.hasUpperAndLower, isTrue);
        expect(widgetState.hasDigit, isTrue);
        expect(widgetState.hasSpecialChar, isFalse);
        expect(widgetState.isAllSatisfied, isFalse);
      },
    );

    testWidgets(
      'PasswordRequirementsChecklist passes all criteria with strong enterprise password',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PasswordRequirementsChecklist(
                password: 'Cardly#2026Secure!',
              ),
            ),
          ),
        );

        final widgetState = tester.widget<PasswordRequirementsChecklist>(
          find.byType(PasswordRequirementsChecklist),
        );
        expect(widgetState.hasMinLength, isTrue);
        expect(widgetState.hasUpperAndLower, isTrue);
        expect(widgetState.hasDigit, isTrue);
        expect(widgetState.hasSpecialChar, isTrue);
        expect(widgetState.isAllSatisfied, isTrue);
      },
    );

    testWidgets(
      'GoogleSignInButton triggers callback and displays loading state',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GoogleSignInButton(
                onPressed: () => tapped = true,
                text: 'Lanjutkan dengan Google',
              ),
            ),
          ),
        );

        expect(find.text('Lanjutkan dengan Google'), findsOneWidget);
        await tester.tap(find.byType(GoogleSignInButton));
        expect(tapped, isTrue);

        // Verify loading indicator
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GoogleSignInButton(onPressed: null, isLoading: true),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
