import 'dart:async';

import '../../../core/storage/app_database.dart';
import '../domain/reminder_model.dart';

/// Repositori data pengingat dengan persistensi SQLite (AppDatabase) tanpa dummy data
class ReminderRepository {
  final AppDatabase _db;
  final List<ReminderItem> _cachedReminders = [];
  bool _isLoaded = false;

  ReminderRepository(this._db);

  Future<void> loadFromDatabase() async {
    final list = await _db.getReminders();
    _cachedReminders.clear();
    _cachedReminders.addAll(list);
    _isLoaded = true;
  }

  List<ReminderItem> getAllReminders() {
    if (!_isLoaded) {
      unawaited(loadFromDatabase());
    }
    return List.unmodifiable(_cachedReminders);
  }

  Future<void> addReminder(ReminderItem reminder) async {
    _cachedReminders.insert(0, reminder);
    await _db.insertReminder(reminder);
  }

  Future<void> updateReminder(ReminderItem updated) async {
    final index = _cachedReminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _cachedReminders[index] = updated;
      await _db.updateReminder(updated);
    }
  }

  Future<void> toggleCompleted(String id) async {
    final index = _cachedReminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updated = _cachedReminders[index].copyWith(
        isCompleted: !_cachedReminders[index].isCompleted,
      );
      _cachedReminders[index] = updated;
      await _db.updateReminder(updated);
    }
  }

  Future<void> deleteReminder(String id) async {
    _cachedReminders.removeWhere((r) => r.id == id);
    await _db.deleteReminder(id);
  }

  Future<void> wipeAll() async {
    _cachedReminders.clear();
    await _db.wipeAllData();
  }
}
