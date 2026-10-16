import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/supabase_service.dart';
import '../core/security/biometric_service.dart';
import '../core/storage/app_database.dart';
import '../core/storage/local_storage_service.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/sync/cloud_sync_service.dart';
import '../features/cards/data/card_repository.dart';
import '../features/cards/domain/card_model.dart';
import '../features/documents/data/document_repository.dart';
import '../features/documents/data/folder_repository.dart';
import '../features/documents/domain/document_model.dart';
import '../features/documents/domain/folder_model.dart';
import '../features/reminders/data/reminder_repository.dart';
import '../features/reminders/domain/reminder_model.dart';

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

// --- Global Storage & Repository Providers ---

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return PackageInfo(
      appName: 'Cardly',
      packageName: 'com.cardly.cardly',
      version: '1.0.0',
      buildNumber: '1',
    );
  }
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialized before runApp',
  );
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CardRepository(db);
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DocumentRepository(db);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReminderRepository(db);
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FolderRepository(db);
});

// --- Theme Mode State Notifier ---

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(localStorageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorageService _storage;

  ThemeModeNotifier(this._storage) : super(_parseThemeMode(_storage.themeMode));

  static ThemeMode _parseThemeMode(String val) {
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    String str = 'system';
    if (mode == ThemeMode.light) str = 'light';
    if (mode == ThemeMode.dark) str = 'dark';
    await _storage.setThemeMode(str);
  }
}

// --- Auth & User State Notifier ---

class UserProfile {
  final String fullName;
  final String email;
  final String avatarPath;
  final bool isLoggedIn;
  final bool hasBiometrics;
  final bool isBiometricActive;
  final bool hasPin;

  const UserProfile({
    this.fullName = '',
    this.email = '',
    this.avatarPath = '',
    this.isLoggedIn = false,
    this.hasBiometrics = true,
    this.isBiometricActive = false,
    this.hasPin = false,
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? avatarPath,
    bool? isLoggedIn,
    bool? hasBiometrics,
    bool? isBiometricActive,
    bool? hasPin,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasBiometrics: hasBiometrics ?? this.hasBiometrics,
      isBiometricActive: isBiometricActive ?? this.isBiometricActive,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      final storage = ref.watch(localStorageServiceProvider);
      return UserProfileNotifier(storage);
    });

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final LocalStorageService _storage;

  UserProfileNotifier(this._storage)
    : super(
        UserProfile(
          fullName: _storage.userName,
          email: _storage.userEmail,
          avatarPath: _storage.userAvatarPath,
          isLoggedIn: _storage.isLoggedIn,
        ),
      );

  void updateProfile({String? name, String? email, String? avatarPath}) {
    state = state.copyWith(
      fullName: name,
      email: email,
      avatarPath: avatarPath,
    );
    if (name != null) _storage.setUserName(name);
    if (email != null) _storage.setUserEmail(email);
    if (avatarPath != null) _storage.setUserAvatarPath(avatarPath);
  }

  void updateAvatar(String path) {
    state = state.copyWith(avatarPath: path);
    _storage.setUserAvatarPath(path);
  }

  void removeAvatar() {
    state = state.copyWith(avatarPath: '');
    _storage.setUserAvatarPath('');
  }

  void setBiometricActive(bool active) {
    state = state.copyWith(isBiometricActive: active);
  }

  void setHasPin(bool hasPin) {
    state = state.copyWith(hasPin: hasPin);
  }

  void logout() {
    state = state.copyWith(isLoggedIn: false);
    _storage.setIsLoggedIn(false);
  }

  void login(String name, String email) {
    state = state.copyWith(fullName: name, email: email, isLoggedIn: true);
    _storage.setUserName(name);
    _storage.setUserEmail(email);
    _storage.setIsLoggedIn(true);
  }
}

// --- Vault Lock State Notifier ---

final vaultLockedProvider = StateNotifierProvider<VaultLockNotifier, bool>((
  ref,
) {
  return VaultLockNotifier();
});

class VaultLockNotifier extends StateNotifier<bool> {
  VaultLockNotifier() : super(true); // Default: Terkunci demi keamanan

  void unlock() => state = false;
  void lock() => state = true;
  void toggle() => state = !state;
}

// --- Global App Session Lock State Notifier ---

final appLockedProvider = StateNotifierProvider<AppLockNotifier, bool>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AppLockNotifier(storage);
});

class AppLockNotifier extends StateNotifier<bool> {
  final LocalStorageService _storage;

  AppLockNotifier(this._storage) : super(_storage.isLoggedIn);

  void lock() {
    if (_storage.isLoggedIn) {
      state = true;
    }
  }

  void unlock() {
    state = false;
  }
}

/// Menandakan apakah operasi eksternal (Kamera / Google Doc Scanner / Image Picker) sedang berjalan
/// agar event lifecycle onResume tidak memicu penguncian otomatis sesi secara keliru.
final isExternalOperationInProgressProvider = StateProvider<bool>(
  (ref) => false,
);

/// Menandakan apakah alur Splash screen telah selesai agar otentikasi biometrik
/// tidak memotong animasi splash di depan.
final isSplashCompletedProvider = StateProvider<bool>((ref) => false);

// --- Reactive Card List Notifier ---

final cardListProvider =
    StateNotifierProvider<CardListNotifier, List<CardItem>>((ref) {
      final repo = ref.watch(cardRepositoryProvider);
      return CardListNotifier(repo);
    });

class CardListNotifier extends StateNotifier<List<CardItem>> {
  final CardRepository _repo;

  CardListNotifier(this._repo) : super(_repo.getAllCards()) {
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _repo.loadFromDatabase();
    state = _repo.getAllCards();
  }

  Future<void> refresh() async {
    await _repo.loadFromDatabase();
    state = _repo.getAllCards();
  }

  Future<void> addCard(CardItem card) async {
    await _repo.addCard(card);
    refresh();
  }

  Future<void> updateCard(CardItem card) async {
    await _repo.updateCard(card);
    refresh();
  }

  Future<void> toggleFavorite(String id) async {
    await _repo.toggleFavorite(id);
    refresh();
  }

  Future<void> archiveCard(String id, bool archive) async {
    await _repo.archiveCard(id, archive);
    refresh();
  }

  Future<void> deleteCard(String id) async {
    await _repo.deleteCard(id);
    refresh();
  }
}

// --- Reactive Document List Notifier ---

final documentListProvider =
    StateNotifierProvider<DocumentListNotifier, List<DocumentItem>>((ref) {
      final repo = ref.watch(documentRepositoryProvider);
      return DocumentListNotifier(repo);
    });

class DocumentListNotifier extends StateNotifier<List<DocumentItem>> {
  final DocumentRepository _repo;

  DocumentListNotifier(this._repo) : super(_repo.getAllDocuments()) {
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _repo.loadFromDatabase();
    state = _repo.getAllDocuments();
  }

  Future<void> refresh() async {
    await _repo.loadFromDatabase();
    state = _repo.getAllDocuments();
  }

  Future<void> addDocument(DocumentItem doc) async {
    await _repo.addDocument(doc);
    refresh();
  }

  Future<void> updateDocument(DocumentItem doc) async {
    await _repo.updateDocument(doc);
    refresh();
  }

  Future<void> deleteDocument(String id) async {
    await _repo.deleteDocument(id);
    refresh();
  }
}

// --- Reactive Reminder List Notifier ---

final reminderListProvider =
    StateNotifierProvider<ReminderListNotifier, List<ReminderItem>>((ref) {
      final repo = ref.watch(reminderRepositoryProvider);
      return ReminderListNotifier(repo);
    });

class ReminderListNotifier extends StateNotifier<List<ReminderItem>> {
  final ReminderRepository _repo;

  ReminderListNotifier(this._repo) : super(_repo.getAllReminders()) {
    _initLoad();
  }

  Future<void> _initLoad() async {
    await _repo.loadFromDatabase();
    state = _repo.getAllReminders();
  }

  Future<void> refresh() async {
    await _repo.loadFromDatabase();
    state = _repo.getAllReminders();
  }

  Future<void> addReminder(ReminderItem reminder) async {
    await _repo.addReminder(reminder);
    refresh();
  }

  Future<void> updateReminder(ReminderItem reminder) async {
    await _repo.updateReminder(reminder);
    refresh();
  }

  Future<void> toggleCompleted(String id) async {
    await _repo.toggleCompleted(id);
    refresh();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    refresh();
  }
}

// --- Supabase & Cloud Sync Providers ---

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // Abaikan jika SharedPreferences belum di-override di environment test
  }
  return CloudSyncService(database: db, supabase: supabase, prefs: prefs);
});

// --- Folder List Provider ---

final folderListProvider =
    StateNotifierProvider<FolderListNotifier, List<FolderItem>>((ref) {
      final repo = ref.watch(folderRepositoryProvider);
      return FolderListNotifier(repo);
    });

class FolderListNotifier extends StateNotifier<List<FolderItem>> {
  final FolderRepository _repo;

  FolderListNotifier(this._repo) : super(_repo.getAllFolders()) {
    _initLoad();
  }

  Future<void> _initLoad() async {
    final list = await _repo.loadFolders();
    state = list;
  }

  Future<void> refresh() async {
    final list = await _repo.loadFolders();
    state = list;
  }

  Future<void> createFolder(FolderItem folder) async {
    await _repo.addFolder(folder);
    state = _repo.getAllFolders();
  }

  Future<void> deleteFolder(String id) async {
    await _repo.deleteFolder(id);
    state = _repo.getAllFolders();
  }
}

// --- Security Settings Provider (Auto-Lock & App Switcher Shield) ---

class SecuritySettingsState {
  final String
  autoLockOption; // 'Segera', '30 Detik', '1 Menit', '5 Menit', 'Tidak Pernah'
  final bool hideInAppSwitcher;

  const SecuritySettingsState({
    this.autoLockOption = 'Segera',
    this.hideInAppSwitcher = false,
  });

  SecuritySettingsState copyWith({
    String? autoLockOption,
    bool? hideInAppSwitcher,
  }) {
    return SecuritySettingsState(
      autoLockOption: autoLockOption ?? this.autoLockOption,
      hideInAppSwitcher: hideInAppSwitcher ?? this.hideInAppSwitcher,
    );
  }
}

final securitySettingsProvider =
    StateNotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>((
      ref,
    ) {
      SharedPreferences? prefs;
      try {
        prefs = ref.watch(sharedPreferencesProvider);
      } catch (_) {}
      return SecuritySettingsNotifier(prefs);
    });

class SecuritySettingsNotifier extends StateNotifier<SecuritySettingsState> {
  final SharedPreferences? _prefs;
  static const _channel = MethodChannel('com.cardly.app/security');

  SecuritySettingsNotifier(this._prefs)
    : super(
        SecuritySettingsState(
          autoLockOption:
              _prefs?.getString('cardly_auto_lock_option') ?? 'Segera',
          hideInAppSwitcher:
              _prefs?.getBool('cardly_hide_in_app_switcher') ?? false,
        ),
      ) {
    if (state.hideInAppSwitcher) {
      _applySecureFlag(true);
    }
  }

  Future<void> setAutoLockOption(String option) async {
    state = state.copyWith(autoLockOption: option);
    await _prefs?.setString('cardly_auto_lock_option', option);
  }

  Future<void> setHideInAppSwitcher(bool value) async {
    state = state.copyWith(hideInAppSwitcher: value);
    await _prefs?.setBool('cardly_hide_in_app_switcher', value);
    await _applySecureFlag(value);
  }

  Future<void> _applySecureFlag(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecureFlag', {'enabled': enabled});
    } catch (_) {}
  }
}
