import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service penyimpanan data kredensial terenkripsi hardware (Keychain / Keystore)
class SecureStorageService {
  static const String _keyAppPinHash = 'cardly_app_pin_hash';
  static const String _keyBiometricEnabled = 'cardly_biometric_enabled';
  static const String _keyVaultPasscode = 'cardly_vault_passcode';

  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  Future<void> saveAppPin(String pin) async {
    try {
      await _storage.write(key: _keyAppPinHash, value: pin);
    } catch (_) {}
  }

  Future<String?> getAppPin() async {
    try {
      return await _storage.read(key: _keyAppPinHash);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasAppPin() async {
    final pin = await getAppPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<bool> verifyAppPin(String pin) async {
    final saved = await getAppPin();
    return saved != null && saved == pin;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _keyBiometricEnabled,
        value: enabled ? 'true' : 'false',
      );
    } catch (_) {}
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final val = await _storage.read(key: _keyBiometricEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveVaultPasscode(String code) async {
    try {
      await _storage.write(key: _keyVaultPasscode, value: code);
    } catch (_) {}
  }

  Future<String?> getVaultPasscode() async {
    try {
      return await _storage.read(key: _keyVaultPasscode);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
