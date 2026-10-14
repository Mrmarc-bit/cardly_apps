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
import '../features/documents/domain/document_model.dart';
import '../features/reminders/data/reminder_repository.dart';
import '../features/reminders/domain/reminder_model.dart';

// --- Global Storage & Repository Providers ---

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
    state = state.copyWith(fullName: name, email: email, avatarPath: avatarPath);
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

// --- Reactive Card List Notifier ---

final cardListProvider =
    StateNotifierProvider<CardListNotifier, List<CardItem>>((ref) {
      final repo = ref.watch(cardRepositoryProvider);
      return CardListNotifier(repo);
    });

class CardListNotifier extends StateNotifier<List<CardItem>> {
  final CardRepository _repo;

  CardListNotifier(this._repo) : super(_repo.getAllCards());

  void refresh() {
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

  DocumentListNotifier(this._repo) : super(_repo.getAllDocuments());

  void refresh() {
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

  ReminderListNotifier(this._repo) : super(_repo.getAllReminders());

  void refresh() {
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
