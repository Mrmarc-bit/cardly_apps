import 'dart:convert';

import '../../../core/widgets/cardly_visual_card.dart';

typedef CardVisualTheme = CardColorTheme;

/// 7 Kategori kartu resmi Cardly sesuai PRD.md dan DESAIN.md
enum CardCategory {
  pembayaran('Pembayaran'),
  identitas('Identitas'),
  pendidikan('Pendidikan'),
  kesehatan('Kesehatan'),
  keanggotaan('Keanggotaan'),
  kendaraan('Kendaraan'),
  lainnya('Lainnya');

  final String label;
  const CardCategory(this.label);

  String get displayName => label;

  static const CardCategory payment = CardCategory.pembayaran;
  static const CardCategory identity = CardCategory.identitas;
  static const CardCategory education = CardCategory.pendidikan;
  static const CardCategory health = CardCategory.kesehatan;
  static const CardCategory membership = CardCategory.keanggotaan;
  static const CardCategory vehicle = CardCategory.kendaraan;
  static const CardCategory other = CardCategory.lainnya;

  static CardCategory fromString(String val) {
    for (final e in values) {
      if (e.name.toLowerCase() == val.toLowerCase() ||
          e.label.toLowerCase() == val.toLowerCase()) {
        return e;
      }
    }
    return CardCategory.lainnya;
  }
}

/// Model data entitas kartu Cardly
class CardItem {
  final String id;
  final CardCategory category;
  final String nickname;
  final String holderName;
  final String issuer;
  final String network; // Visa, Mastercard, atau custom
  final String lastFourDigits; // Maksimal 4 digit terakhir (Aturan Keamanan)
  final DateTime? expiryDate;
  final CardColorTheme colorTheme;
  final String? notes;
  final bool isContactless;
  final bool isFavorite;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  CardItem({
    required this.id,
    dynamic category,
    String? nickname,
    String? title,
    this.holderName = 'PEMILIK',
    required this.issuer,
    this.network = 'Visa',
    required this.lastFourDigits,
    this.expiryDate,
    dynamic colorTheme,
    dynamic theme,
    this.notes,
    this.isContactless = true,
    this.isFavorite = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : nickname = nickname ?? title ?? 'Kartu',
       category = category is CardCategory
           ? category
           : (category is String
                 ? CardCategory.fromString(category)
                 : CardCategory.lainnya),
       colorTheme = colorTheme is CardColorTheme
           ? colorTheme
           : (theme is CardColorTheme
                 ? theme
                 : (colorTheme is String
                       ? CardColorTheme.values.firstWhere(
                           (c) => c.name == colorTheme,
                           orElse: () => CardColorTheme.lime,
                         )
                       : CardColorTheme.lime)),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get title => nickname;
  CardVisualTheme get theme => colorTheme;

  CardItem copyWith({
    String? id,
    CardCategory? category,
    String? nickname,
    String? title,
    String? holderName,
    String? issuer,
    String? network,
    String? lastFourDigits,
    DateTime? expiryDate,
    CardColorTheme? colorTheme,
    CardVisualTheme? theme,
    String? notes,
    bool? isContactless,
    bool? isFavorite,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return CardItem(
      id: id ?? this.id,
      category: category ?? this.category,
      nickname: nickname ?? title ?? this.nickname,
      holderName: holderName ?? this.holderName,
      issuer: issuer ?? this.issuer,
      network: network ?? this.network,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryDate: expiryDate ?? this.expiryDate,
      colorTheme: colorTheme ?? theme ?? this.colorTheme,
      notes: notes ?? this.notes,
      isContactless: isContactless ?? this.isContactless,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.name,
      'nickname': nickname,
      'holderName': holderName,
      'issuer': issuer,
      'network': network,
      'lastFourDigits': lastFourDigits,
      'expiryDate': expiryDate?.toIso8601String(),
      'colorTheme': colorTheme.name,
      'notes': notes,
      'isContactless': isContactless,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CardItem.fromMap(Map<String, dynamic> map) {
    return CardItem(
      id: map['id'] as String,
      category: CardCategory.fromString(map['category'] as String),
      nickname: map['nickname'] as String? ?? 'Kartu',
      holderName: map['holderName'] as String? ?? 'PEMILIK',
      issuer: map['issuer'] as String,
      network: map['network'] as String? ?? 'Visa',
      lastFourDigits: map['lastFourDigits'] as String? ?? '----',
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'] as String)
          : null,
      colorTheme: CardColorTheme.values.firstWhere(
        (c) => c.name == map['colorTheme'],
        orElse: () => CardColorTheme.lime,
      ),
      notes: map['notes'] as String?,
      isContactless: map['isContactless'] as bool? ?? true,
      isFavorite: map['isFavorite'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory CardItem.fromJson(String source) =>
      CardItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
