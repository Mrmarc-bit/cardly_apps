import 'package:flutter_test/flutter_test.dart';

import 'package:cardly/features/documents/domain/document_model.dart';
import 'package:cardly/features/scan/data/card_crop_helper.dart';
import 'package:cardly/features/scan/data/document_scan_service.dart';
import 'package:cardly/features/scan/presentation/widgets/pre_scan_sheet.dart';

void main() {
  group('DocumentScanService & Heuristic OCR Parser Tests', () {
    late DocumentScanService scanService;

    setUp(() {
      scanService = DocumentScanService();
    });

    test(
      'Parses full Indonesian KTP text into structured fields accurately',
      () {
        const ktpRawText = '''
PROVINSI DKI JAKARTA
KOTA JAKARTA PUSAT
NIK : 3171010190001882
Nama : BUDI SANTOSO
Tempat/Tgl Lahir : JAKARTA, 01-01-1990
Jenis Kelamin : LAKI-LAKI    Gol. Darah : O
Alamat : JL. MERDEKA BARAT NO. 10
RT/RW : 001/002
Kel/Desa : GAMBIR
Kecamatan : GAMBIR
Agama : ISLAM
Status Perkawinan : BELUM KAWIN
Pekerjaan : KARYAWAN SWASTA
Kewarganegaraan : WNI
Berlaku Hingga : SEUMUR HIDUP
''';

        final result = scanService.parseRecognizedText(
          ktpRawText,
          documentType: ScanDocumentType.idCard,
        );

        expect(result.recognizedType, RecognizedDocumentType.ktp);
        expect(result.title, 'KTP Republik Indonesia');
        expect(result.documentNumber, '3171010190001882');
        expect(result.fullName, 'BUDI SANTOSO');
        expect(result.birthPlaceDate, 'JAKARTA, 01-01-1990');
        expect(result.gender, 'LAKI-LAKI');
        expect(result.bloodType, 'O');
        expect(result.address, 'JL. MERDEKA BARAT NO. 10');
        expect(result.rtRw, '001/002');
        expect(result.kelDesa, 'GAMBIR');
        expect(result.kecamatan, 'GAMBIR');
        expect(result.religion, 'ISLAM');
        expect(result.maritalStatus, 'BELUM KAWIN');
        expect(result.occupation, 'KARYAWAN SWASTA');
        expect(result.nationality, 'WNI');
        expect(result.expiryDate, 'SEUMUR HIDUP');
        expect(result.isLifetimeExpiry, isTrue);
        expect(result.issuer, contains('Disdukcapil'));
        expect(result.category, DocumentCategory.identity);
      },
    );

    test(
      'Parses Bank Card text with masked number, issuer, and expiry safely',
      () {
        const bankCardRawText = '''
BCA
Platinum Debit
5200 1234 5678 9012
08/29
MA'RUF AMIN
MASTERCARD
''';

        final result = scanService.parseRecognizedText(
          bankCardRawText,
          documentType: ScanDocumentType.paymentCard,
        );

        expect(result.recognizedType, RecognizedDocumentType.bankCard);
        expect(result.bankName, contains('BCA'));
        expect(result.cardNetwork, 'Mastercard');
        expect(result.last4Digits, '9012');
        expect(result.documentNumber, '•••• •••• •••• 9012');
        expect(result.expiryDate, '08/29');
        expect(result.isLifetimeExpiry, isFalse);
        expect(result.category, DocumentCategory.financial);
      },
    );

    test('Parses SIM (Surat Izin Mengemudi) into vehicle category', () {
      const simRawText = '''
SURAT IZIN MENGEMUDI
DRIVING LICENSE
KORLANTAS POLRI
NO: 920311240091
NAMA: AHMAD FAUZI
ALAMAT: JL. ASIA AFRIKA NO. 12
PEKERJAAN: KARYAWAN SWASTA
BERLAKU HINGGA: 11-11-2029
''';

      final result = scanService.parseRecognizedText(
        simRawText,
        documentType: ScanDocumentType.idCard,
      );

      expect(result.recognizedType, RecognizedDocumentType.sim);
      expect(result.title, 'Surat Izin Mengemudi (SIM)');
      expect(result.issuer, 'Korlantas Polri');
      expect(result.category, DocumentCategory.vehicle);
      expect(result.documentNumber, '920311240091');
      expect(result.fullName, 'AHMAD FAUZI');
    });

    test('CardCropHelper handles headless test environment safely', () async {
      final cropped = await CardCropHelper.autoCropCard(
        imagePath: '/mock/path/card.png',
        roundedCorners: true,
      );
      expect(cropped, '/mock/path/card.png');

      final rounded = await CardCropHelper.roundCardCorners(
        imagePath: '/mock/path/card.png',
      );
      expect(rounded, '/mock/path/card.png');
    });
  });
}
