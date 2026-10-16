import 'package:shared_preferences/shared_preferences.dart';

/// Service persistensi lokal key-value untuk Cardly
class LocalStorageService {
  static const String _keyOnboardingDone = 'cardly_onboarding_done';
  static const String _keyThemeMode =
      'cardly_theme_mode'; // 'light', 'dark', 'system'
  static const String _keyLanguage = 'cardly_language'; // 'id', 'en'
  static const String _keyAutoLockSeconds = 'cardly_auto_lock_seconds';
  static const String _keyHideInAppSwitcher = 'cardly_hide_in_app_switcher';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<bool> setOnboardingDone(bool done) =>
      _prefs.setBool(_keyOnboardingDone, done);

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(_keyThemeMode, mode);

  String get language => _prefs.getString(_keyLanguage) ?? 'id';
  Future<bool> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  int get autoLockSeconds => _prefs.getInt(_keyAutoLockSeconds) ?? 60;
  Future<bool> setAutoLockSeconds(int seconds) =>
      _prefs.setInt(_keyAutoLockSeconds, seconds);

  bool get hideInAppSwitcher => _prefs.getBool(_keyHideInAppSwitcher) ?? true;
  Future<bool> setHideInAppSwitcher(bool hide) =>
      _prefs.setBool(_keyHideInAppSwitcher, hide);

  static const String _keyIsLoggedIn = 'cardly_is_logged_in';

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  Future<bool> setIsLoggedIn(bool val) => _prefs.setBool(_keyIsLoggedIn, val);

  String get userName => _prefs.getString('cardly_user_name') ?? '';
  Future<bool> setUserName(String name) =>
      _prefs.setString('cardly_user_name', name);

  String get userEmail => _prefs.getString('cardly_user_email') ?? '';
  Future<bool> setUserEmail(String email) =>
      _prefs.setString('cardly_user_email', email);

  String get userAvatarPath =>
      _prefs.getString('cardly_user_avatar_path') ?? '';
  Future<bool> setUserAvatarPath(String path) =>
      _prefs.setString('cardly_user_avatar_path', path);

  static const String _keyLastAppVersion = 'cardly_last_app_version';
  static const String _keyLastBuildNumber = 'cardly_last_build_number';

  String get lastAppVersion => _prefs.getString(_keyLastAppVersion) ?? '';
  Future<bool> setLastAppVersion(String v) =>
      _prefs.setString(_keyLastAppVersion, v);

  int get lastBuildNumber => _prefs.getInt(_keyLastBuildNumber) ?? 0;
  Future<bool> setLastBuildNumber(int b) =>
      _prefs.setInt(_keyLastBuildNumber, b);

  /// Menghapus seluruh preferensi tersimpan (digunakan saat Hapus Data Lokal)
  Future<bool> clearAll() => _prefs.clear();
}
