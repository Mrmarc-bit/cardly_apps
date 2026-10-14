import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/cards/domain/card_model.dart';
import '../../features/documents/domain/document_model.dart';
import '../../features/reminders/domain/reminder_model.dart';

/// Database SQLite Terstruktur Cardly (ACID Transactional, Typed, On-Device Only)
class AppDatabase {
  static const String dbName = 'cardly.db';
  static const int dbVersion = 1;

  Database? _db;
  bool _useMemoryFallback = false;

  // In-memory fallback untuk lingkungan headless test tanpa native SQLite channel
  final Map<String, CardItem> _memoryCards = {};
  final Map<String, DocumentItem> _memoryDocuments = {};
  final Map<String, ReminderItem> _memoryReminders = {};
  final Map<String, Map<String, dynamic>> _memoryFolders = {};

  AppDatabase([Database? db]) : _db = db;

  static final AppDatabase instance = AppDatabase();

  Future<Database?> get database async {
    if (_useMemoryFallback) return null;
    if (_db != null && _db!.isOpen) return _db!;
    try {
      _db = await _initDatabase();
      return _db!;
    } catch (e) {
      debugPrint(
        'SQLite native channel not available. Using in-memory store: $e',
      );
      _useMemoryFallback = true;
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);

    return openDatabase(path, version: dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabel Cards
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        nickname TEXT NOT NULL,
        holder_name TEXT NOT NULL,
        issuer TEXT NOT NULL,
        network TEXT NOT NULL,
        last_four_digits TEXT NOT NULL,
        expiry_date TEXT,
        color_theme TEXT NOT NULL,
        notes TEXT,
        is_contactless INTEGER NOT NULL DEFAULT 1,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_cards_fav ON cards(is_favorite);');
    await db.execute('CREATE INDEX idx_cards_archived ON cards(is_archived);');

    // 2. Tabel Documents
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        masked_number TEXT,
        issuer TEXT,
        issue_date TEXT,
        expiry_date TEXT,
        notes TEXT,
        local_file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        is_private INTEGER NOT NULL DEFAULT 0,
        is_ocr_reviewed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_docs_private ON documents(is_private);');

    // 3. Tabel Reminders
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        document_id TEXT,
        title TEXT NOT NULL,
        reminder_date TEXT NOT NULL,
        reminder_time TEXT NOT NULL,
        repetition TEXT NOT NULL,
        notes TEXT,
        device_notification_active INTEGER NOT NULL DEFAULT 1,
        hide_title_on_lock_screen INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX idx_reminders_date ON reminders(reminder_date);',
    );

    // 4. Tabel Folders
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }

  // ==========================================
  // CARDS CRUD
  // ==========================================

  Future<List<CardItem>> getCards({bool includeArchived = false}) async {
    final db = await database;
    if (db == null) {
      final list = _memoryCards.values.toList();
      return includeArchived ? list : list.where((c) => !c.isArchived).toList();
    }

    final whereClause = includeArchived ? null : 'is_archived = 0';
    final result = await db.query(
      'cards',
      where: whereClause,
      orderBy: 'created_at DESC',
    );

    return result.map(_mapToCard).toList();
  }

  Future<void> insertCard(CardItem card) async {
    final db = await database;
    if (db == null) {
      _memoryCards[card.id] = card;
      return;
    }

    await db.insert(
      'cards',
      _cardToMap(card),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCard(CardItem card) async {
    final db = await database;
    if (db == null) {
      _memoryCards[card.id] = card;
      return;
    }

    await db.update(
      'cards',
      _cardToMap(card),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> toggleCardFavorite(String id) async {
    final db = await database;
    if (db == null) {
      final existing = _memoryCards[id];
      if (existing != null) {
        _memoryCards[id] = existing.copyWith(isFavorite: !existing.isFavorite);
      }
      return;
    }

    final existing = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      final currentFav = (existing.first['is_favorite'] as int?) == 1;
      await db.update(
        'cards',
        {'is_favorite': currentFav ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> archiveCard(String id, bool archive) async {
    final db = await database;
    if (db == null) {
      final existing = _memoryCards[id];
      if (existing != null) {
        _memoryCards[id] = existing.copyWith(isArchived: archive);
      }
      return;
    }

    await db.update(
      'cards',
      {'is_archived': archive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCard(String id) async {
    final db = await database;
    if (db == null) {
      _memoryCards.remove(id);
      return;
    }

    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // DOCUMENTS CRUD
  // ==========================================

  Future<List<DocumentItem>> getDocuments({bool onlyPrivate = false}) async {
    final db = await database;
    if (db == null) {
      final list = _memoryDocuments.values.toList();
      return onlyPrivate ? list.where((d) => d.isPrivate).toList() : list;
    }

    final whereClause = onlyPrivate ? 'is_private = 1' : null;
    final result = await db.query(
      'documents',
      where: whereClause,
      orderBy: 'created_at DESC',
    );

    return result.map(_mapToDocument).toList();
  }

  Future<void> insertDocument(DocumentItem doc) async {
    final db = await database;
    if (db == null) {
      _memoryDocuments[doc.id] = doc;
      return;
    }

    await db.insert(
      'documents',
      _documentToMap(doc),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDocument(DocumentItem doc) async {
    final db = await database;
    if (db == null) {
      _memoryDocuments[doc.id] = doc;
      return;
    }

    await db.update(
      'documents',
      _documentToMap(doc),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    if (db == null) {
      _memoryDocuments.remove(id);
      return;
    }

    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // REMINDERS CRUD
  // ==========================================

  Future<List<ReminderItem>> getReminders() async {
    final db = await database;
    if (db == null) {
      return _memoryReminders.values.toList();
    }

    final result = await db.query('reminders', orderBy: 'reminder_date ASC');

    return result.map(_mapToReminder).toList();
  }

  Future<void> insertReminder(ReminderItem reminder) async {
    final db = await database;
    if (db == null) {
      _memoryReminders[reminder.id] = reminder;
      return;
    }

    await db.insert(
      'reminders',
      _reminderToMap(reminder),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReminder(ReminderItem reminder) async {
    final db = await database;
    if (db == null) {
      _memoryReminders[reminder.id] = reminder;
      return;
    }

    await db.update(
      'reminders',
      _reminderToMap(reminder),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> toggleReminderCompleted(String id) async {
    final db = await database;
    if (db == null) {
      final existing = _memoryReminders[id];
      if (existing != null) {
        _memoryReminders[id] = existing.copyWith(
          isCompleted: !existing.isCompleted,
        );
      }
      return;
    }

    final existing = await db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty) {
      final currentCompleted = (existing.first['is_completed'] as int?) == 1;
      await db.update(
        'reminders',
        {'is_completed': currentCompleted ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    if (db == null) {
      _memoryReminders.remove(id);
      return;
    }

    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // FOLDERS CRUD
  // ==========================================

  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    if (db == null) {
      return _memoryFolders.values.toList();
    }

    return db.query('folders', orderBy: 'created_at ASC');
  }

  Future<void> insertFolder(Map<String, dynamic> folder) async {
    final db = await database;
    final id = folder['id'] as String;
    if (db == null) {
      _memoryFolders[id] = folder;
      return;
    }

    await db.insert(
      'folders',
      folder,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFolder(String id) async {
    final db = await database;
    if (db == null) {
      _memoryFolders.remove(id);
      return;
    }

    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // ZERO-TRACE WIPE (Hapus Seluruh Data Lokal)
  // ==========================================

  Future<void> wipeAllData() async {
    _memoryCards.clear();
    _memoryDocuments.clear();
    _memoryReminders.clear();
    _memoryFolders.clear();

    final db = await database;
    if (db != null) {
      await db.transaction((txn) async {
        await txn.delete('cards');
        await txn.delete('documents');
        await txn.delete('reminders');
        await txn.delete('folders');
      });
    }
  }

  // ==========================================
  // MAPPERS
  // ==========================================

  Map<String, dynamic> _cardToMap(CardItem card) {
    return {
      'id': card.id,
      'category': card.category.name,
      'nickname': card.nickname,
      'holder_name': card.holderName,
      'issuer': card.issuer,
      'network': card.network,
      'last_four_digits': card.lastFourDigits,
      'expiry_date': card.expiryDate?.toIso8601String(),
      'color_theme': card.colorTheme.name,
      'notes': card.notes,
      'is_contactless': card.isContactless ? 1 : 0,
      'is_favorite': card.isFavorite ? 1 : 0,
      'is_archived': card.isArchived ? 1 : 0,
      'created_at': card.createdAt.toIso8601String(),
      'updated_at': card.updatedAt.toIso8601String(),
    };
  }

  CardItem _mapToCard(Map<String, dynamic> map) {
    return CardItem(
      id: map['id'] as String,
      category: CardCategory.fromString(map['category'] as String),
      nickname: map['nickname'] as String,
      holderName: map['holder_name'] as String? ?? 'PEMILIK',
      issuer: map['issuer'] as String,
      network: map['network'] as String? ?? 'Visa',
      lastFourDigits: map['last_four_digits'] as String? ?? '0000',
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      colorTheme: map['color_theme'],
      notes: map['notes'] as String?,
      isContactless: (map['is_contactless'] as int?) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _documentToMap(DocumentItem doc) {
    return {
      'id': doc.id,
      'title': doc.title,
      'category': doc.rawCategory,
      'masked_number': doc.maskedNumber,
      'issuer': doc.issuer,
      'issue_date': doc.issueDate?.toIso8601String(),
      'expiry_date': doc.expiryDate?.toIso8601String(),
      'notes': doc.notes,
      'local_file_path': doc.localFilePath,
      'file_type': doc.rawFileType,
      'file_size_bytes': doc.fileSizeBytes,
      'is_private': doc.isPrivate ? 1 : 0,
      'is_ocr_reviewed': doc.isOcrReviewed ? 1 : 0,
      'created_at': doc.createdAt.toIso8601String(),
      'updated_at': doc.updatedAt.toIso8601String(),
    };
  }

  DocumentItem _mapToDocument(Map<String, dynamic> map) {
    return DocumentItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      maskedNumber: map['masked_number'] as String?,
      issuer: map['issuer'] as String?,
      issueDate: map['issue_date'] != null
          ? DateTime.tryParse(map['issue_date'] as String)
          : null,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      notes: map['notes'] as String?,
      localFilePath: map['local_file_path'] as String,
      fileType: map['file_type'] as String,
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      isPrivate: (map['is_private'] as int?) == 1,
      isOcrReviewed: (map['is_ocr_reviewed'] as int?) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> _reminderToMap(ReminderItem r) {
    return {
      'id': r.id,
      'document_id': r.documentId,
      'title': r.title,
      'reminder_date': r.reminderDate.toIso8601String(),
      'reminder_time': r.reminderTime,
      'repetition': r.repetition,
      'notes': r.notes,
      'device_notification_active': r.deviceNotificationActive ? 1 : 0,
      'hide_title_on_lock_screen': r.hideTitleOnLockScreen ? 1 : 0,
      'is_completed': r.isCompleted ? 1 : 0,
      'created_at': r.createdAt.toIso8601String(),
    };
  }

  ReminderItem _mapToReminder(Map<String, dynamic> map) {
    return ReminderItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String?,
      title: map['title'] as String,
      reminderDate: DateTime.parse(map['reminder_date'] as String),
      reminderTime: map['reminder_time'] as String? ?? '09:00',
      repetition: map['repetition'] as String? ?? 'Tidak berulang',
      notes: map['notes'] as String?,
      deviceNotificationActive:
          (map['device_notification_active'] as int?) == 1,
      hideTitleOnLockScreen: (map['hide_title_on_lock_screen'] as int?) == 1,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
