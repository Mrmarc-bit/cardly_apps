import 'dart:async';

import '../../../core/storage/app_database.dart';
import '../domain/card_model.dart';

/// Repositori data kartu dengan persistensi SQLite (AppDatabase) tanpa dummy data
class CardRepository {
  final AppDatabase _db;
  final List<CardItem> _cachedCards = [];
  bool _isLoaded = false;

  CardRepository(this._db);

  Future<void> loadFromDatabase() async {
    final list = await _db.getCards(includeArchived: true);
    _cachedCards.clear();
    _cachedCards.addAll(list);
    _isLoaded = true;
  }

  List<CardItem> getAllCards({bool includeArchived = false}) {
    if (!_isLoaded) {
      unawaited(loadFromDatabase());
    }
    if (!includeArchived) {
      return _cachedCards.where((c) => !c.isArchived).toList();
    }
    return List.unmodifiable(_cachedCards);
  }

  Future<void> addCard(CardItem card) async {
    _cachedCards.insert(0, card);
    await _db.insertCard(card);
  }

  Future<void> updateCard(CardItem updatedCard) async {
    final index = _cachedCards.indexWhere((c) => c.id == updatedCard.id);
    if (index != -1) {
      _cachedCards[index] = updatedCard;
      await _db.updateCard(updatedCard);
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = _cachedCards.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _cachedCards[index].copyWith(
        isFavorite: !_cachedCards[index].isFavorite,
      );
      _cachedCards[index] = updated;
      await _db.updateCard(updated);
    }
  }

  Future<void> archiveCard(String id, bool archive) async {
    final index = _cachedCards.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _cachedCards[index].copyWith(isArchived: archive);
      _cachedCards[index] = updated;
      await _db.updateCard(updated);
    }
  }

  Future<void> deleteCard(String id) async {
    _cachedCards.removeWhere((c) => c.id == id);
    await _db.deleteCard(id);
  }

  Future<void> wipeAll() async {
    _cachedCards.clear();
    await _db.wipeAllData();
  }
}
