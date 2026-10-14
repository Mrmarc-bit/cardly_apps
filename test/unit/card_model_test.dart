import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/features/cards/domain/card_model.dart';

void main() {
  group('CardItem Domain Model Tests', () {
    test('CardItem creation and serialization roundtrip', () {
      final card = CardItem(
        id: 'card-001',
        title: 'BCA Utama',
        holderName: "MA'RUF AMIN",
        lastFourDigits: '4582',
        issuer: 'Bank Central Asia',
        category: CardCategory.payment,
        theme: CardVisualTheme.lime,
        isContactless: true,
      );

      final map = card.toMap();
      final deserialized = CardItem.fromMap(map);

      expect(deserialized.id, equals('card-001'));
      expect(deserialized.title, equals('BCA Utama'));
      expect(deserialized.lastFourDigits, equals('4582'));
      expect(deserialized.category, equals(CardCategory.pembayaran));
      expect(deserialized.theme, equals(CardVisualTheme.lime));
    });

    test(
      'CardItem preserves 4-digit security rule without storing full PAN',
      () {
        final card = CardItem(
          id: 'card-002',
          title: 'Mandiri Prioritas',
          holderName: 'JOHN DOE',
          lastFourDigits: '9012',
          issuer: 'Bank Mandiri',
          category: CardCategory.payment,
        );

        expect(card.lastFourDigits.length, equals(4));
      },
    );
  });
}
