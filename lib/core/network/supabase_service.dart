import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Hasil autentikasi Native Google Sign-In SDK
class NativeGoogleAuthResult {
  final GoogleSignInAccount? account;
  final bool isCancelled;
  final String? errorMessage;
  final bool isDevSha1Missing;

  const NativeGoogleAuthResult({
    this.account,
    this.isCancelled = false,
    this.errorMessage,
    this.isDevSha1Missing = false,
  });

  bool get isSuccess => account != null;
}

/// Service inti untuk koneksi, autentikasi, dan operasi client Supabase di Cardly.
class SupabaseService {
  static SupabaseService? _instance;
  static bool _initialized = false;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Inisialisasi Supabase saat app startup.
  /// Memiliki perlindungan error agar tidak crash di lingkungan testing tanpa platform channel.
  static Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        debug: kDebugMode,
      );
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('Supabase init note: $e');
      _initialized = false;
      return false;
    }
  }

  /// Memeriksa apakah Supabase SDK sudah terinisialisasi
  bool get isInitialized => _initialized;

  /// Instance SupabaseClient aktif
  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// User yang sedang login
  User? get currentUser => client?.auth.currentUser;

  /// ID User unik Supabase
  String? get currentUserId => currentUser?.id;

  /// Status apakah user sudah login di Supabase
  bool get isAuthenticated => currentUser != null;

  /// Stream perubahan status autentikasi
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  /// Masuk dengan email & kata sandi
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) {
      throw Exception('Layanan Supabase belum terinisialisasi.');
    }
    return await c.auth.signInWithPassword(email: email, password: password);
  }

  /// Mendaftar akun baru dengan email & kata sandi
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    String? emailRedirectTo,
  }) async {
    final c = client;
    if (c == null) {
      throw Exception('Layanan Supabase belum terinisialisasi.');
    }
    return await c.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo ?? SupabaseConfig.oauthCallbackUrl,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Mengirim ulang email verifikasi pendaftaran
  Future<bool> resendSignUpConfirmation(String email) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseConfig.oauthCallbackUrl,
      );
      return true;
    } catch (e) {
      debugPrint('Resend verification note: $e');
      return false;
    }
  }

  /// Mengunggah avatar ke Supabase Storage (bucket: cardly_avatars) dan memperbarui profiles
  Future<String?> uploadAvatar({
    required String filePath,
    required String userId,
  }) async {
    final c = client;
    if (c == null) return null;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final ext = filePath.split('.').last.toLowerCase();
      final storagePath = '$userId/avatar.$ext';

      // 1. Unggah ke bucket cardly_avatars dengan opsi upsert
      await c.storage.from('cardly_avatars').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Dapatkan URL Publik resmi dari Supabase CDN
      final publicUrl =
          c.storage.from('cardly_avatars').getPublicUrl(storagePath);
      final cacheBustedUrl =
          '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

      // 3. Simpan URL avatar ke tabel profiles
      await c.from('profiles').update({
        'avatar_url': cacheBustedUrl,
      }).eq('id', userId);

      return cacheBustedUrl;
    } catch (e) {
      debugPrint('Upload avatar note: $e');
      return null;
    }
  }

  /// Mengambil URL avatar profil pengguna dari cloud Supabase
  Future<String?> getProfileAvatarUrl(String userId) async {
    final c = client;
    if (c == null || userId.isEmpty) return null;
    try {
      final res = await c
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return res?['avatar_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Menghapus avatar dari cloud profiles
  Future<void> deleteAvatar(String userId) async {
    final c = client;
    if (c == null || userId.isEmpty) return;
    try {
      await c.from('profiles').update({'avatar_url': null}).eq('id', userId);
    } catch (_) {}
  }

  /// Keluar dari sesi Supabase
  Future<void> signOut() async {
    final c = client;
    if (c != null) {
      await c.auth.signOut();
    }
  }

  /// Masuk dengan Google OAuth melalui Supabase (In-App Browser Sheet / Custom Tabs)
  Future<bool> signInWithGoogle({String? redirectTo}) async {
    final c = client;
    if (c == null) {
      throw Exception('Layanan Supabase belum terinisialisasi.');
    }
    return await c.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo ?? SupabaseConfig.oauthCallbackUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: SupabaseConfig.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  /// Masuk dengan Google secara Native Mobile SDK (Google Play Services Account Picker di Android).
  /// Mengembalikan NativeGoogleAuthResult dengan informasi status detail.
  Future<NativeGoogleAuthResult> signInWithGoogleNativeAccount() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (pe) {
        final errText = '${pe.code}: ${pe.message}'.toLowerCase();
        final isSha1Missing =
            errText.contains('10') ||
            errText.contains('developer_error') ||
            errText.contains('sign_in_failed');
        return NativeGoogleAuthResult(
          isCancelled: false,
          isDevSha1Missing: isSha1Missing,
          errorMessage: isSha1Missing
              ? 'SHA-1 debug aplikasi belum didaftarkan di Firebase Console (ApiException 10).'
              : (pe.message ?? pe.code),
        );
      } catch (e) {
        return NativeGoogleAuthResult(
          isCancelled: false,
          errorMessage: e.toString(),
        );
      }

      if (googleUser == null) {
        // Pengguna membatalkan dialog pemilihan akun Google Play Services
        return const NativeGoogleAuthResult(isCancelled: true);
      }

      // Sinkronisasi ID token dengan Supabase agar sesi backend aktif
      final c = client;
      if (c != null) {
        try {
          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;
          if (idToken != null) {
            await c.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
          }
        } catch (e) {
          debugPrint('Sinkronisasi ID token Supabase: $e');
        }
      }

      return NativeGoogleAuthResult(account: googleUser);
    } catch (e) {
      return NativeGoogleAuthResult(
        isCancelled: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Memutuskan sesi Google Sign-In saat logout
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Kirim tautan reset kata sandi ke email
  Future<void> resetPasswordForEmail(String email) async {
    final c = client;
    if (c == null) {
      throw Exception('Layanan Supabase belum terinisialisasi.');
    }
    await c.auth.resetPasswordForEmail(email);
  }
}
