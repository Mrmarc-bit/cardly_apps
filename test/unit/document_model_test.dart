import 'package:flutter_test/flutter_test.dart';
import 'package:cardly/features/documents/domain/document_model.dart';

void main() {
  group('DocumentItem Domain Model Tests', () {
    test('DocumentItem creation and serialization roundtrip', () {
      final doc = DocumentItem(
        id: 'doc-001',
        title: 'KTP Digital.pdf',
        category: DocumentCategory.identity,
        fileType: DocumentFileType.pdf,
        documentNumber: '3171010190001',
        issuer: 'Disdukcapil DKI Jakarta',
        fileSizeBytes: 1450000,
        isVaultProtected: true,
      );

      final map = doc.toMap();
      final deserialized = DocumentItem.fromMap(map);

      expect(deserialized.id, equals('doc-001'));
      expect(deserialized.title, equals('KTP Digital.pdf'));
      expect(deserialized.category, equals(DocumentCategory.identity));
      expect(deserialized.fileType, equals(DocumentFileType.pdf));
      expect(deserialized.isVaultProtected, isTrue);
      expect(deserialized.documentNumber, equals('3171010190001'));
    });
  });
}
