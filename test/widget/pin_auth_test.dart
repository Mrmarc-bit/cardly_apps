import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardly/app/providers.dart';
import 'package:cardly/core/storage/secure_storage_service.dart';
import 'package:cardly/features/vault/presentation/pin_screen.dart';
import 'package:cardly/features/vault/presentation/widgets/cardly_pin_pad.dart';

class FakeSecureStorageService extends SecureStorageService {
  String? _pin;
  bool _biometric = false;
  String? _vaultPass;

  @override
  Future<void> saveAppPin(String pin) async => _pin = pin;

  @override
  Future<String?> getAppPin() async => _pin;

  @override
  Future<bool> hasAppPin() async => _pin != null && _pin!.isNotEmpty;

  @override
  Future<bool> verifyAppPin(String pin) async => _pin == pin;

  @override
  Future<void> setBiometricEnabled(bool enabled) async => _biometric = enabled;

  @override
  Future<bool> isBiometricEnabled() async => _biometric;

  @override
  Future<void> saveVaultPasscode(String code) async => _vaultPass = code;

  @override
  Future<String?> getVaultPasscode() async => _vaultPass;

  @override
  Future<void> clearAll() async {
    _pin = null;
    _biometric = false;
    _vaultPass = null;
  }
}

void main() {
  late SharedPreferences prefs;
  late FakeSecureStorageService fakeSecureStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeSecureStorage = FakeSecureStorageService();
  });

  group('PIN Pad & Security Authentication Tests', () {
    testWidgets('CardlyPinPad renders 6 dots and numeric keypad buttons', (
      tester,
    ) async {
      String pin = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardlyPinPad(
              currentPin: pin,
              onPinChanged: (val) => pin = val,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets(
      'CardlyPinPad typing numbers calls onPinChanged and backspace',
      (tester) async {
        String pin = '';

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: CardlyPinPad(
                    currentPin: pin,
                    onPinChanged: (val) {
                      setState(() => pin = val);
                    },
                  ),
                ),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tap 1, 2, 3
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();
        expect(pin, '1');

        await tester.tap(find.text('2'));
        await tester.pumpAndSettle();
        expect(pin, '12');

        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();
        expect(pin, '123');

        // Tap backspace
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pumpAndSettle();
        expect(pin, '12');
      },
    );

    testWidgets('PinScreen renders create flow and switches to confirmation', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(fakeSecureStorage),
          ],
          child: const MaterialApp(home: PinScreen(mode: PinScreenMode.create)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buat PIN 6-Digit'), findsOneWidget);

      // Enter 1, 2, 3, 4, 5, 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }

      // Should now advance to confirmation step
      expect(find.text('Konfirmasi PIN Anda'), findsOneWidget);

      // Re-enter 1, 2, 3, 4, 5, 6 to confirm
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }

      // PIN saved in storage
      expect(await fakeSecureStorage.getAppPin(), '123456');
    });

    testWidgets('PinScreen verify mode with matching PIN succeeds', (
      tester,
    ) async {
      await fakeSecureStorage.saveAppPin('654321');

      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(fakeSecureStorage),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await PinScreen.showAsBottomSheet(
                      context,
                      mode: PinScreenMode.verify,
                    );
                  },
                  child: const Text('Open PIN'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Open PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Masukkan PIN Brankas'), findsOneWidget);

      // Enter 6, 5, 4, 3, 2, 1
      for (final digit in ['6', '5', '4', '3', '2', '1']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }

      // Should verify and close bottom sheet returning true
      expect(result, isTrue);
    });

    testWidgets('PinScreen verify mode with wrong PIN shows error message', (
      tester,
    ) async {
      await fakeSecureStorage.saveAppPin('999999');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            secureStorageServiceProvider.overrideWithValue(fakeSecureStorage),
          ],
          child: const MaterialApp(home: PinScreen(mode: PinScreenMode.verify)),
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN: 1, 2, 3, 4, 5, 6
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
        await tester.pumpAndSettle();
      }

      // Should show error text
      expect(find.textContaining('PIN salah'), findsOneWidget);
    });
  });
}
