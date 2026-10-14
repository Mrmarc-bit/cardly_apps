import '../../../core/storage/app_database.dart';
import '../domain/folder_model.dart';

class FolderRepository {
  final AppDatabase _db;
  final List<FolderItem> _cachedFolders = [];

  FolderRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<List<FolderItem>> loadFolders() async {
    final rawList = await _db.getFolders();
    _cachedFolders.clear();
    _cachedFolders.addAll(rawList.map(FolderItem.fromMap));
    return List.unmodifiable(_cachedFolders);
  }

  List<FolderItem> getAllFolders() {
    return List.unmodifiable(_cachedFolders);
  }

  Future<void> addFolder(FolderItem folder) async {
    await _db.insertFolder(folder.toMap());
    _cachedFolders.add(folder);
  }

  Future<void> deleteFolder(String id) async {
    await _db.deleteFolder(id);
    _cachedFolders.removeWhere((f) => f.id == id);
  }
}
