import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/core/utils/formatters.dart';

void main() {
  group('CardlyFormatters (Formatters) Unit Tests', () {
    test('maskCardNumber formats 4 digits with bullet prefix', () {
      expect(CardlyFormatters.maskCardNumber('4582'), equals('•••• 4582'));
      expect(CardlyFormatters.maskCardNumber('1234'), equals('•••• 1234'));
    });

    test('maskCardNumber handles null or empty safely', () {
      expect(CardlyFormatters.maskCardNumber(null), equals('•••• ----'));
      expect(CardlyFormatters.maskCardNumber(''), equals('•••• ----'));
    });

    test(
      'maskCardNumber strips non-digit characters and takes only last 4 digits',
      () {
        expect(
          CardlyFormatters.maskCardNumber('4000 1234 5678 9010'),
          equals('•••• 9010'),
        );
      },
    );

    test('formatFileSize formats byte quantities into KB and MB', () {
      expect(CardlyFormatters.formatFileSize(500), equals('500 B'));
      expect(CardlyFormatters.formatFileSize(1024), equals('1.0 KB'));
      expect(CardlyFormatters.formatFileSize(1500000), equals('1.4 MB'));
    });

    test('formatExpiry formats dates as MM/yy', () {
      final date = DateTime(2028, 5, 1);
      expect(CardlyFormatters.formatExpiry(date), equals('05/28'));
    });
  });
}
