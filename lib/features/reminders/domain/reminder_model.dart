import 'dart:convert';

class ReminderItem {
  final String id;
  final String? documentId;
  final String title;
  final DateTime reminderDate;
  final String reminderTime; // "09:00"
  final String repetition; // "Tidak berulang", "Harian", dll.
  final String? notes;
  final bool deviceNotificationActive;
  final bool hideTitleOnLockScreen;
  final bool isCompleted;
  final DateTime createdAt;

  ReminderItem({
    required this.id,
    String? linkedItemId,
    String? documentId,
    required this.title,
    DateTime? dueDate,
    DateTime? reminderDate,
    this.reminderTime = '09:00',
    this.repetition = 'Tidak berulang',
    this.notes,
    this.deviceNotificationActive = true,
    this.hideTitleOnLockScreen = false,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : reminderDate = reminderDate ?? dueDate ?? DateTime.now(),
       documentId = documentId ?? linkedItemId,
       createdAt = createdAt ?? DateTime.now();

  DateTime get dueDate => reminderDate;
  String? get linkedItemId => documentId;

  ReminderItem copyWith({
    String? id,
    String? linkedItemId,
    String? documentId,
    String? title,
    DateTime? dueDate,
    DateTime? reminderDate,
    String? reminderTime,
    String? repetition,
    String? notes,
    bool? deviceNotificationActive,
    bool? hideTitleOnLockScreen,
    bool? isCompleted,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      documentId: documentId ?? linkedItemId ?? this.documentId,
      title: title ?? this.title,
      reminderDate: reminderDate ?? dueDate ?? this.reminderDate,
      reminderTime: reminderTime ?? this.reminderTime,
      repetition: repetition ?? this.repetition,
      notes: notes ?? this.notes,
      deviceNotificationActive:
          deviceNotificationActive ?? this.deviceNotificationActive,
      hideTitleOnLockScreen:
          hideTitleOnLockScreen ?? this.hideTitleOnLockScreen,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'reminderDate': reminderDate.toIso8601String(),
      'reminderTime': reminderTime,
      'repetition': repetition,
      'notes': notes,
      'deviceNotificationActive': deviceNotificationActive,
      'hideTitleOnLockScreen': hideTitleOnLockScreen,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReminderItem.fromMap(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'] as String,
      documentId: map['documentId'] as String?,
      title: map['title'] as String,
      reminderDate: DateTime.parse(map['reminderDate'] as String),
      reminderTime: map['reminderTime'] as String? ?? '09:00',
      repetition: map['repetition'] as String? ?? 'Tidak berulang',
      notes: map['notes'] as String?,
      deviceNotificationActive:
          map['deviceNotificationActive'] as bool? ?? true,
      hideTitleOnLockScreen: map['hideTitleOnLockScreen'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory ReminderItem.fromJson(String source) =>
      ReminderItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
