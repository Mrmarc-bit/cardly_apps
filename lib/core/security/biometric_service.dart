import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Hasil detail proses autentikasi biometrik
class BiometricAuthResult {
  final bool success;
  final bool isNotEnrolled;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.isNotEnrolled = false,
    this.errorMessage,
  });
}

/// Layanan autentikasi biometrik native hardware (Fingerprint, Face Unlock, TouchID, FaceID)
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  /// Memeriksa apakah perangkat memiliki sensor biometrik hardware
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa jenis biometrik yang tersedia di perangkat
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Autentikasi dengan informasi status detail (untuk umpan balik UI yang jelas)
  Future<BiometricAuthResult> authenticateDetailed({
    String localizedReason = 'Pindai sidik jari atau Face ID Anda untuk mengakses ruang pribadi Cardly.',
    bool biometricOnly = false,
  }) async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Sensor biometrik tidak tersedia di perangkat ini.',
        );
      }

      final success = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      return BiometricAuthResult(success: success);
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult(
          success: false,
          isNotEnrolled: true,
          errorMessage: 'Sidik jari atau Face ID belum didaftarkan di Pengaturan HP Anda. Silakan daftarkan di Pengaturan perangkat terlebih dahulu.',
        );
      }
      if (e.code == 'auth_in_progress') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Pemindaian sedang berjalan, silakan sentuh sensor.',
        );
      }
      if (e.code == 'LockedOut') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Sensor biometrik terkunci sementara karena terlalu banyak percobaan gagal. Silakan gunakan PIN.',
        );
      }
      if (e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult(
          success: false,
          errorMessage: 'Sensor biometrik terkunci permanen. Silakan gunakan PIN atau buka kunci perangkat Anda.',
        );
      }
      return BiometricAuthResult(
        success: false,
        errorMessage: e.message ?? 'Verifikasi biometrik gagal.',
      );
    } catch (e) {
      return const BiometricAuthResult(
        success: false,
        errorMessage: 'Terjadi kendala sistem pada sensor.',
      );
    }
  }

  /// Menjalankan dialog autentikasi native sistem operasi
  Future<bool> authenticate({
    String localizedReason = 'Pindai sidik jari atau Face ID Anda untuk mengakses ruang pribadi Cardly.',
  }) async {
    final res = await authenticateDetailed(localizedReason: localizedReason);
    return res.success;
  }

  /// Membatalkan proses autentikasi yang sedang aktif
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
