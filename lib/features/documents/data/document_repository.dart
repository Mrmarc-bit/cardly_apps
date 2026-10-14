import 'dart:async';

import '../../../core/storage/app_database.dart';
import '../domain/document_model.dart';

/// Repositori data dokumen dengan persistensi SQLite (AppDatabase) tanpa dummy data
class DocumentRepository {
  final AppDatabase _db;
  final List<DocumentItem> _cachedDocs = [];
  bool _isLoaded = false;

  DocumentRepository(this._db);

  Future<void> loadFromDatabase() async {
    final list = await _db.getDocuments();
    _cachedDocs.clear();
    _cachedDocs.addAll(list);
    _isLoaded = true;
  }

  List<DocumentItem> getAllDocuments({bool onlyPrivate = false}) {
    if (!_isLoaded) {
      unawaited(loadFromDatabase());
    }
    if (onlyPrivate) {
      return _cachedDocs.where((d) => d.isPrivate).toList();
    }
    return List.unmodifiable(_cachedDocs);
  }

  Future<void> addDocument(DocumentItem doc) async {
    _cachedDocs.insert(0, doc);
    await _db.insertDocument(doc);
  }

  Future<void> updateDocument(DocumentItem updatedDoc) async {
    final index = _cachedDocs.indexWhere((d) => d.id == updatedDoc.id);
    if (index != -1) {
      _cachedDocs[index] = updatedDoc;
      await _db.updateDocument(updatedDoc);
    }
  }

  Future<void> deleteDocument(String id) async {
    _cachedDocs.removeWhere((d) => d.id == id);
    await _db.deleteDocument(id);
  }

  Future<void> wipeAll() async {
    _cachedDocs.clear();
    await _db.wipeAllData();
  }
}
