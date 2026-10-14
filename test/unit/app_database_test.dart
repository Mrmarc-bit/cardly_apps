import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/core/storage/app_database.dart';
import 'package:cardly/features/cards/domain/card_model.dart';
import 'package:cardly/features/documents/domain/document_model.dart';
import 'package:cardly/features/reminders/domain/reminder_model.dart';

void main() {
  group('AppDatabase SQLite & Typed Persistence Unit Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase();
    });

    test('Cards CRUD operations work seamlessly', () async {
      final card = CardItem(
        id: 'test-card-1',
        nickname: 'Kartu Utama',
        issuer: 'Bank Mandiri',
        lastFourDigits: '9876',
        category: CardCategory.pembayaran,
      );

      // 1. Insert
      await db.insertCard(card);
      var cards = await db.getCards();
      expect(cards.length, 1);
      expect(cards.first.nickname, 'Kartu Utama');
      expect(cards.first.lastFourDigits, '9876');

      // 2. Update
      final updated = card.copyWith(nickname: 'Kartu Tabungan');
      await db.updateCard(updated);
      cards = await db.getCards();
      expect(cards.first.nickname, 'Kartu Tabungan');

      // 3. Toggle favorite
      await db.toggleCardFavorite('test-card-1');
      cards = await db.getCards();
      expect(cards.first.isFavorite, isTrue);

      // 4. Archive
      await db.archiveCard('test-card-1', true);
      cards = await db.getCards(includeArchived: false);
      expect(cards.isEmpty, isTrue);
      cards = await db.getCards(includeArchived: true);
      expect(cards.length, 1);

      // 5. Delete
      await db.deleteCard('test-card-1');
      cards = await db.getCards(includeArchived: true);
      expect(cards.isEmpty, isTrue);
    });

    test('Documents CRUD operations work seamlessly', () async {
      final doc = DocumentItem(
        id: 'test-doc-1',
        title: 'Paspor RI',
        category: 'Identitas',
        maskedNumber: 'X1234567',
        localFilePath: '/path/to/paspor.pdf',
        fileSizeBytes: 2048000,
        isPrivate: true,
      );

      // Insert
      await db.insertDocument(doc);
      var docs = await db.getDocuments();
      expect(docs.length, 1);
      expect(docs.first.title, 'Paspor RI');
      expect(docs.first.isPrivate, isTrue);

      // Filter private
      var privateDocs = await db.getDocuments(onlyPrivate: true);
      expect(privateDocs.length, 1);

      // Delete
      await db.deleteDocument('test-doc-1');
      docs = await db.getDocuments();
      expect(docs.isEmpty, isTrue);
    });

    test('Reminders CRUD operations work seamlessly', () async {
      final reminder = ReminderItem(
        id: 'test-rem-1',
        title: 'Perpanjang SIM',
        reminderDate: DateTime(2027, 5, 20),
        repetition: 'Tahunan',
      );

      await db.insertReminder(reminder);
      var reminders = await db.getReminders();
      expect(reminders.length, 1);
      expect(reminders.first.title, 'Perpanjang SIM');

      await db.toggleReminderCompleted('test-rem-1');
      reminders = await db.getReminders();
      expect(reminders.first.isCompleted, isTrue);

      await db.deleteReminder('test-rem-1');
      reminders = await db.getReminders();
      expect(reminders.isEmpty, isTrue);
    });

    test('Zero-Trace Wipe clears all tables completely', () async {
      await db.insertCard(
        CardItem(
          id: 'c1',
          nickname: 'C1',
          issuer: 'BCA',
          lastFourDigits: '1111',
        ),
      );
      await db.insertDocument(
        DocumentItem(
          id: 'd1',
          title: 'D1',
          category: 'Lainnya',
          localFilePath: '/tmp',
        ),
      );
      await db.insertReminder(
        ReminderItem(id: 'r1', title: 'R1', reminderDate: DateTime.now()),
      );

      expect((await db.getCards()).length, 1);
      expect((await db.getDocuments()).length, 1);
      expect((await db.getReminders()).length, 1);

      // Wipe all
      await db.wipeAllData();

      expect((await db.getCards()).isEmpty, isTrue);
      expect((await db.getDocuments()).isEmpty, isTrue);
      expect((await db.getReminders()).isEmpty, isTrue);
    });
  });
}
