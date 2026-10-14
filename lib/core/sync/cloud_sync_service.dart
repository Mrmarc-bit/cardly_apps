import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../network/supabase_service.dart';
import '../storage/app_database.dart';
import '../../features/cards/domain/card_model.dart';
import '../../features/documents/domain/document_model.dart';
import '../../features/reminders/domain/reminder_model.dart';

enum SyncStatus { idle, syncing, success, offline, unauthenticated, error }

class SyncReport {
  final int cardsPushed;
  final int cardsPulled;
  final int documentsPushed;
  final int documentsPulled;
  final int remindersPushed;
  final int remindersPulled;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncReport({
    this.cardsPushed = 0,
    this.cardsPulled = 0,
    this.documentsPushed = 0,
    this.documentsPulled = 0,
    this.remindersPushed = 0,
    this.remindersPulled = 0,
    this.errorMessage,
    required this.timestamp,
  });

  bool get isSuccess => errorMessage == null;

  int get totalItems =>
      cardsPushed +
      cardsPulled +
      documentsPushed +
      documentsPulled +
      remindersPushed +
      remindersPulled;
}

/// Service sinkronisasi awan dua arah (Bi-directional Cloud Sync) antara SQLite lokal dan Supabase.
class CloudSyncService {
  final AppDatabase database;
  final SupabaseService supabase;
  final SharedPreferences? prefs;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.idle;

  static const String _keyLastSync = 'cardly_last_sync_timestamp';

  CloudSyncService({
    required this.database,
    required this.supabase,
    this.prefs,
  });

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get currentStatus => _currentStatus;

  DateTime? get lastSyncTime {
    final str = prefs?.getString(_keyLastSync);
    return str != null ? DateTime.tryParse(str) : null;
  }

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Menjalankan sinkronisasi penuh untuk Kartu, Dokumen, dan Pengingat.
  Future<SyncReport> syncAll() async {
    final now = DateTime.now();

    if (!supabase.isInitialized) {
      _setStatus(SyncStatus.offline);
      return SyncReport(
        timestamp: now,
        errorMessage:
            'Layanan Supabase belum terhubung atau perangkat offline.',
      );
    }

    final userId = supabase.currentUserId;
    if (userId == null) {
      _setStatus(SyncStatus.unauthenticated);
      return SyncReport(
        timestamp: now,
        errorMessage: 'Silakan masuk ke akun Cardly untuk mengaktifkan sinkronisasi cloud.',
      );
    }

    final client = supabase.client;
    if (client == null) {
      _setStatus(SyncStatus.offline);
      return SyncReport(
        timestamp: now,
        errorMessage: 'Klien Supabase tidak tersedia.',
      );
    }

    _setStatus(SyncStatus.syncing);

    int cardsPushed = 0;
    int cardsPulled = 0;
    int docsPushed = 0;
    int docsPulled = 0;
    int remPushed = 0;
    int remPulled = 0;

    try {
      // 1. Sync Cards
      final localCards = await database.getCards(includeArchived: true);
      for (final card in localCards) {
        final cardPayload = {
          'id': card.id,
          'user_id': userId,
          'category': card.category.name,
          'nickname': card.nickname,
          'holder_name': card.holderName,
          'issuer': card.issuer,
          'network': card.network,
          'last_four_digits': card.lastFourDigits,
          'expiry_date': card.expiryDate?.toIso8601String(),
          'color_theme': card.colorTheme.name,
          'notes': card.notes,
          'is_contactless': card.isContactless,
          'is_favorite': card.isFavorite,
          'is_archived': card.isArchived,
          'created_at': card.createdAt.toIso8601String(),
          'updated_at': card.updatedAt.toIso8601String(),
        };
        await client.from('cards').upsert(cardPayload);
        cardsPushed++;
      }

      final cloudCardsRes = await client
          .from('cards')
          .select()
          .eq('user_id', userId);
      for (final raw in (cloudCardsRes as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final cloudCard = CardItem(
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
          isContactless: map['is_contactless'] as bool? ?? true,
          isFavorite: map['is_favorite'] as bool? ?? false,
          isArchived: map['is_archived'] as bool? ?? false,
          createdAt:
              DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(map['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
        await database.insertCard(cloudCard);
        cardsPulled++;
      }

      // 2. Sync Documents
      final localDocs = await database.getDocuments();
      for (final doc in localDocs) {
        String? cloudStoragePath;
        // Opsional: Unggah file fisik jika tersedia secara lokal
        if (doc.localFilePath != null && doc.localFilePath!.isNotEmpty) {
          final file = File(doc.localFilePath!);
          if (file.existsSync()) {
            final fileName =
                '${doc.id}_${doc.title.replaceAll(' ', '_')}.${doc.rawFileType}';
            final path = '$userId/$fileName';
            try {
              await client.storage
                  .from(SupabaseConfig.documentsBucket)
                  .upload(path, file);
              cloudStoragePath = path;
            } catch (_) {
              // Jika file sudah ada, abaikan error upload
            }
          }
        }

        final docPayload = {
          'id': doc.id,
          'user_id': userId,
          'title': doc.title,
          'category': doc.rawCategory,
          'masked_number': doc.maskedNumber,
          'issuer': doc.issuer,
          'issue_date': doc.issueDate?.toIso8601String(),
          'expiry_date': doc.expiryDate?.toIso8601String(),
          'notes': doc.notes,
          'local_file_path': doc.localFilePath,
          'storage_path': cloudStoragePath,
          'file_type': doc.rawFileType,
          'file_size_bytes': doc.fileSizeBytes,
          'is_private': doc.isPrivate,
          'is_ocr_reviewed': doc.isOcrReviewed,
          'created_at': doc.createdAt.toIso8601String(),
          'updated_at': doc.updatedAt.toIso8601String(),
        };
        await client.from('documents').upsert(docPayload);
        docsPushed++;
      }

      final cloudDocsRes = await client
          .from('documents')
          .select()
          .eq('user_id', userId);
      for (final raw in (cloudDocsRes as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final cloudDoc = DocumentItem(
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
          localFilePath: map['local_file_path'] as String? ?? '',
          fileType: map['file_type'] as String,
          fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
          isPrivate: map['is_private'] as bool? ?? false,
          isOcrReviewed: map['is_ocr_reviewed'] as bool? ?? false,
          createdAt:
              DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(map['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
        await database.insertDocument(cloudDoc);
        docsPulled++;
      }

      // 3. Sync Reminders
      final localReminders = await database.getReminders();
      for (final r in localReminders) {
        final remPayload = {
          'id': r.id,
          'user_id': userId,
          'document_id': r.documentId,
          'title': r.title,
          'reminder_date': r.reminderDate.toIso8601String(),
          'reminder_time': r.reminderTime,
          'repetition': r.repetition,
          'notes': r.notes,
          'device_notification_active': r.deviceNotificationActive,
          'hide_title_on_lock_screen': r.hideTitleOnLockScreen,
          'is_completed': r.isCompleted,
          'created_at': r.createdAt.toIso8601String(),
        };
        await client.from('reminders').upsert(remPayload);
        remPushed++;
      }

      final cloudRemRes = await client
          .from('reminders')
          .select()
          .eq('user_id', userId);
      for (final raw in (cloudRemRes as List)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final cloudRem = ReminderItem(
          id: map['id'] as String,
          documentId: map['document_id'] as String?,
          title: map['title'] as String,
          reminderDate: DateTime.parse(map['reminder_date'] as String),
          reminderTime: map['reminder_time'] as String? ?? '09:00',
          repetition: map['repetition'] as String? ?? 'Tidak berulang',
          notes: map['notes'] as String?,
          deviceNotificationActive:
              map['device_notification_active'] as bool? ?? true,
          hideTitleOnLockScreen:
              map['hide_title_on_lock_screen'] as bool? ?? false,
          isCompleted: map['is_completed'] as bool? ?? false,
          createdAt:
              DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
        await database.insertReminder(cloudRem);
        remPulled++;
      }

      await prefs?.setString(_keyLastSync, now.toIso8601String());
      _setStatus(SyncStatus.success);

      return SyncReport(
        cardsPushed: cardsPushed,
        cardsPulled: cardsPulled,
        documentsPushed: docsPushed,
        documentsPulled: docsPulled,
        remindersPushed: remPushed,
        remindersPulled: remPulled,
        timestamp: now,
      );
    } catch (e) {
      debugPrint('Cloud sync error: $e');
      _setStatus(SyncStatus.error);
      return SyncReport(
        timestamp: now,
        errorMessage: 'Gagal melakukan sinkronisasi: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _statusController.close();
  }
}
