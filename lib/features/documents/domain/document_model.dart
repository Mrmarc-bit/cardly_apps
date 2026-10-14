import 'dart:convert';

enum DocumentCategory {
  identity('Identitas'),
  financial('Finansial'),
  medical('Medis'),
  vehicle('Kendaraan'),
  work('Pekerjaan'),
  other('Lainnya');

  final String displayName;
  const DocumentCategory(this.displayName);

  static DocumentCategory fromString(String val) {
    for (final c in values) {
      if (c.displayName.toLowerCase() == val.toLowerCase() ||
          c.name.toLowerCase() == val.toLowerCase()) {
        return c;
      }
    }
    return other;
  }
}

enum DocumentFileType {
  pdf('PDF'),
  jpg('JPG'),
  png('PNG');

  final String displayName;
  const DocumentFileType(this.displayName);

  static DocumentFileType fromString(String val) {
    for (final t in values) {
      if (t.name.toLowerCase() == val.toLowerCase() ||
          t.displayName.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return pdf;
  }
}

/// Model data dokumen Cardly
class DocumentItem {
  final String id;
  final String title;
  final String rawCategory;
  final String? maskedNumber;
  final String? issuer;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? notes;
  final String? localFilePath;
  final String rawFileType; // PDF, JPG, PNG
  final int fileSizeBytes;
  final bool isPrivate; // true = Brankas
  final bool isOcrReviewed;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentItem({
    required this.id,
    required this.title,
    dynamic category,
    String? documentNumber,
    String? maskedNumber,
    this.issuer,
    this.issueDate,
    this.expiryDate,
    this.notes,
    String? filePath,
    String? localFilePath,
    dynamic fileType = 'PDF',
    this.fileSizeBytes = 1200000,
    bool isVaultProtected = false,
    bool isPrivate = false,
    this.isOcrReviewed = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : rawCategory = category is DocumentCategory
           ? category.displayName
           : (category is String ? category : 'Lainnya'),
       rawFileType = fileType is DocumentFileType
           ? fileType.name.toUpperCase()
           : (fileType is String ? fileType : 'PDF'),
       localFilePath = localFilePath ?? filePath,
       maskedNumber = maskedNumber ?? documentNumber,
       isPrivate = isPrivate || isVaultProtected,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Semantic getters for convenient type-safe access
  DocumentCategory get category => DocumentCategory.fromString(rawCategory);
  DocumentFileType get fileType => DocumentFileType.fromString(rawFileType);
  bool get isVaultProtected => isPrivate;
  String? get documentNumber => maskedNumber;
  String? get filePath => localFilePath;

  DocumentItem copyWith({
    String? id,
    String? title,
    dynamic category,
    String? documentNumber,
    String? maskedNumber,
    String? issuer,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
    String? filePath,
    String? localFilePath,
    dynamic fileType,
    int? fileSizeBytes,
    bool? isVaultProtected,
    bool? isPrivate,
    bool? isOcrReviewed,
    DateTime? updatedAt,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? rawCategory,
      maskedNumber: maskedNumber ?? documentNumber ?? this.maskedNumber,
      issuer: issuer ?? this.issuer,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      localFilePath: localFilePath ?? filePath ?? this.localFilePath,
      fileType: fileType ?? rawFileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      isPrivate: isPrivate ?? isVaultProtected ?? this.isPrivate,
      isOcrReviewed: isOcrReviewed ?? this.isOcrReviewed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': rawCategory,
      'maskedNumber': maskedNumber,
      'issuer': issuer,
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'notes': notes,
      'localFilePath': localFilePath,
      'fileType': rawFileType,
      'fileSizeBytes': fileSizeBytes,
      'isPrivate': isPrivate,
      'isOcrReviewed': isOcrReviewed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DocumentItem.fromMap(Map<String, dynamic> map) {
    return DocumentItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'Lainnya',
      maskedNumber: map['maskedNumber'] as String?,
      issuer: map['issuer'] as String?,
      issueDate: map['issueDate'] != null
          ? DateTime.tryParse(map['issueDate'] as String)
          : null,
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'] as String)
          : null,
      notes: map['notes'] as String?,
      localFilePath: map['localFilePath'] as String?,
      fileType: map['fileType'] as String? ?? 'PDF',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      isPrivate: map['isPrivate'] as bool? ?? false,
      isOcrReviewed: map['isOcrReviewed'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory DocumentItem.fromJson(String source) =>
      DocumentItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
