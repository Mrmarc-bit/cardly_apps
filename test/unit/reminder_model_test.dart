import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/features/reminders/domain/reminder_model.dart';

void main() {
  group('ReminderItem Domain Model Tests', () {
    test('ReminderItem creation and serialization roundtrip', () {
      final dueDate = DateTime(2027, 8, 15, 9, 0);
      final reminder = ReminderItem(
        id: 'rem-001',
        title: 'Perpanjangan SIM A',
        dueDate: dueDate,
        linkedItemId: 'doc-sim-01',
        notes: 'Bawa surat keterangan kesehatan',
      );

      final map = reminder.toMap();
      final deserialized = ReminderItem.fromMap(map);

      expect(deserialized.id, equals('rem-001'));
      expect(deserialized.title, equals('Perpanjangan SIM A'));
      expect(deserialized.dueDate, equals(dueDate));
      expect(deserialized.linkedItemId, equals('doc-sim-01'));
      expect(deserialized.isCompleted, isFalse);
    });
  });
}
