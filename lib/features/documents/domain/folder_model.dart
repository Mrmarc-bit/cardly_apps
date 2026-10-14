/// Model Domain Folder Dokumen Cardly
class FolderItem {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final String location;
  final bool isPrivate;
  final DateTime createdAt;

  const FolderItem({
    required this.id,
    required this.name,
    this.iconName = 'folder',
    this.colorHex = '#C8F45A',
    this.location = 'Dokumen Utama',
    this.isPrivate = false,
    required this.createdAt,
  });

  FolderItem copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    String? location,
    bool? isPrivate,
    DateTime? createdAt,
  }) {
    return FolderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      location: location ?? this.location,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FolderItem.fromMap(Map<String, dynamic> map) {
    return FolderItem(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: map['icon_name'] as String? ?? 'folder',
      colorHex: map['color_hex'] as String? ?? '#C8F45A',
      location: map['location'] as String? ?? 'Dokumen Utama',
      isPrivate: (map['is_private'] as int? ?? 0) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
