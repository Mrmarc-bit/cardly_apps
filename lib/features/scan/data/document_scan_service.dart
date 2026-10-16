import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../documents/domain/document_model.dart';
import '../presentation/widgets/pre_scan_sheet.dart';
import '../../../app/providers.dart';

/// Klasifikasi tipe berkas resmi yang berhasil diidentifikasi oleh On-Device OCR
enum RecognizedDocumentType {
  ktp('KTP Republik Indonesia', 'KTP'),
  sim('Surat Izin Mengemudi', 'SIM'),
  bpjs('BPJS Kesehatan', 'BPJS'),
  passport('Paspor Republik Indonesia', 'PASPOR'),
  bankCard('Kartu Bank / Finansial', 'BANK'),
  generalDocument('Dokumen Fisik A4', 'DOKUMEN');

  final String label;
  final String shortCode;
  const RecognizedDocumentType(this.label, this.shortCode);
}

/// Hasil ekstraksi On-Device OCR untuk kartu dan dokumen penting
class OcrScanResult {
  final String imagePath;
  final String title;
  final String documentNumber;
  final String fullName;
  final String expiryDate;
  final bool isLifetimeExpiry;
  final String issuer;
  final DocumentCategory category;
  final String rawText;
  final RecognizedDocumentType recognizedType;

  // Detail Lengkap Kartu Identitas (KTP, SIM, dsb.)
  final String birthPlaceDate;
  final String gender;
  final String bloodType;
  final String address;
  final String rtRw;
  final String kelDesa;
  final String kecamatan;
  final String religion;
  final String maritalStatus;
  final String occupation;
  final String nationality;

  // Detail Kartu Bank / Pembayaran
  final String bankName;
  final String cardNetwork;
  final String last4Digits;

  const OcrScanResult({
    required this.imagePath,
    required this.title,
    required this.documentNumber,
    required this.fullName,
    required this.expiryDate,
    required this.isLifetimeExpiry,
    required this.issuer,
    required this.category,
    required this.rawText,
    this.recognizedType = RecognizedDocumentType.generalDocument,
    this.birthPlaceDate = '',
    this.gender = '',
    this.bloodType = '',
    this.address = '',
    this.rtRw = '',
    this.kelDesa = '',
    this.kecamatan = '',
    this.religion = '',
    this.maritalStatus = '',
    this.occupation = '',
    this.nationality = 'WNI',
    this.bankName = '',
    this.cardNetwork = '',
    this.last4Digits = '',
  });
}

/// Provider resmi untuk DocumentScanService
final documentScanServiceProvider = Provider<DocumentScanService>((ref) {
  return DocumentScanService(ref);
});

/// Layanan Pemindai Dokumen Standar Industri (Google Play Services ML Kit Document Scanner & On-Device OCR)
class DocumentScanService {
  final Ref? _ref;
  final ImagePicker _imagePicker = ImagePicker();

  DocumentScanService([this._ref]);

  /// Membuka pemindai dokumen native Google Play Services (Auto Edge Detection & Crop persis Google Wallet)
  /// dengan parameter dinamis berdasarkan jenis berkas yang dipilih pengguna di Panduan Memindai.
  Future<List<String>?> scanDocument({
    ScanDocumentType documentType = ScanDocumentType.idCard,
    int? pageLimit,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    _ref?.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      // Jika dokumen fisik A4: dukung pemindaian multi-halaman (hingga 10 halaman)
      // Jika kartu identitas atau kartu bank: fokus 1 halaman tunggal berbingkai presisi
      final pages =
          pageLimit ?? (documentType == ScanDocumentType.document ? 10 : 1);
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: pages,
      );
      if (pictures != null && pictures.isNotEmpty) {
        return pictures;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _ref?.read(isExternalOperationInProgressProvider.notifier).state = false;
    }
  }

  /// Memilih gambar dokumen dari galeri foto perangkat
  Future<String?> pickFromGallery() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    _ref?.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      return xFile?.path;
    } catch (_) {
      return null;
    } finally {
      _ref?.read(isExternalOperationInProgressProvider.notifier).state = false;
    }
  }

  /// Mengambil foto langsung dengan kamera sistem sebagai alternatif
  Future<String?> capturePhoto() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    _ref?.read(isExternalOperationInProgressProvider.notifier).state = true;
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      return xFile?.path;
    } catch (_) {
      return null;
    } finally {
      _ref?.read(isExternalOperationInProgressProvider.notifier).state = false;
    }
  }

  /// Melakukan ekstraksi teks On-Device OCR menggunakan Google ML Kit
  Future<OcrScanResult> processOcr(
    String imagePath, {
    ScanDocumentType documentType = ScanDocumentType.idCard,
  }) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      return _parseRecognizedText(
        imagePath,
        rawText,
        documentType: documentType,
      );
    } catch (_) {
      // Fallback jika pemrosesan OCR bermasalah
      final fileName = File(imagePath).uri.pathSegments.last;
      return OcrScanResult(
        imagePath: imagePath,
        title: 'Dokumen Terpindai (${fileName.split('.').first})',
        documentNumber: '',
        fullName: '',
        expiryDate: 'SEUMUR HIDUP',
        isLifetimeExpiry: true,
        issuer: 'Pemerintah RI',
        category: DocumentCategory.identity,
        rawText: '',
        recognizedType: RecognizedDocumentType.generalDocument,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  /// Mengurai teks hasil pengenalan karakter secara heuristik (untuk OCR & pengujian)
  OcrScanResult parseRecognizedText(
    String rawText, {
    String imagePath = '',
    ScanDocumentType documentType = ScanDocumentType.idCard,
  }) {
    return _parseRecognizedText(imagePath, rawText, documentType: documentType);
  }

  /// Pengurai heuristik cerdas untuk KTP, SIM, BPJS, Paspor, NPWP, dan Kartu Pembayaran
  OcrScanResult _parseRecognizedText(
    String imagePath,
    String rawText, {
    ScanDocumentType documentType = ScanDocumentType.idCard,
  }) {
    final upperText = rawText.toUpperCase();
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    RecognizedDocumentType recognizedType =
        RecognizedDocumentType.generalDocument;
    DocumentCategory category = DocumentCategory.identity;
    String title = 'Dokumen Baru';
    String documentNumber = '';
    String fullName = '';
    String expiryDate = '';
    bool isLifetimeExpiry = true;
    String issuer = 'Pemerintah RI';

    // Detail KTP & Identitas
    String birthPlaceDate = '';
    String gender = '';
    String bloodType = '';
    String address = '';
    String rtRw = '';
    String kelDesa = '';
    String kecamatan = '';
    String religion = '';
    String maritalStatus = '';
    String occupation = '';
    String nationality = 'WNI';

    // Detail Kartu Bank
    String bankName = '';
    String cardNetwork = '';
    String last4Digits = '';

    // 1. Identifikasi Jenis Dokumen Cerdas & Toleran OCR Noise
    final hasKtpClues =
        upperText.contains('KARTU TANDA PENDUDUK') ||
        upperText.contains('REPUBLIK INDONESIA') ||
        upperText.contains('PENDUDUK') ||
        upperText.contains('NIK') ||
        upperText.contains('N1K') ||
        upperText.contains('PROVINSI') ||
        upperText.contains('PROVINS1') ||
        upperText.contains('KABUPATEN') ||
        upperText.contains('KECAMATAN') ||
        upperText.contains('GOL. DARAH') ||
        upperText.contains('GOL DARAH') ||
        upperText.contains('TEMPAT/TGL') ||
        upperText.contains('TGL LAHIR') ||
        upperText.contains('JENIS KELAMIN') ||
        upperText.contains('ALAMAT') ||
        upperText.contains('RT/RW') ||
        upperText.contains('KEL/DESA') ||
        upperText.contains('STATUS PERKAWINAN') ||
        upperText.contains('SEUMUR HIDUP') ||
        RegExp(r'\b[1-9]\d{15}\b').hasMatch(rawText) ||
        lines.any(
          (l) =>
              _cleanDigits(l).length == 16 && !_cleanDigits(l).startsWith('0'),
        );

    final hasSimClues =
        upperText.contains('SURAT IZIN MENGEMUDI') ||
        upperText.contains('DRIVING LICENSE') ||
        upperText.contains('KORLANTAS') ||
        upperText.contains('POLRI') ||
        upperText.contains('SIM A') ||
        upperText.contains('SIM C');

    final hasBpjsClues =
        upperText.contains('BPJS') ||
        upperText.contains('INDONESIA SEHAT') ||
        upperText.contains('BADAN PENYELENGGARA JAMINAN SOSIAL');

    final hasPassportClues =
        upperText.contains('PASPOR') || upperText.contains('PASSPORT');

    final hasBankClues =
        documentType == ScanDocumentType.paymentCard ||
        upperText.contains('DEBIT') ||
        upperText.contains('CREDIT') ||
        upperText.contains('VISA') ||
        upperText.contains('MASTERCARD') ||
        upperText.contains('PASPOR') == false &&
            (upperText.contains('BCA') ||
                upperText.contains('MANDIRI') ||
                upperText.contains('BANK BRI') ||
                upperText.contains('BANK BNI') ||
                upperText.contains('CIMB') ||
                upperText.contains('DANAMON') ||
                upperText.contains('PERMATA') ||
                upperText.contains('JAGO') ||
                upperText.contains('JENIUS') ||
                upperText.contains('SEABANK'));

    if (hasSimClues && documentType != ScanDocumentType.paymentCard) {
      recognizedType = RecognizedDocumentType.sim;
      title = 'Surat Izin Mengemudi (SIM)';
      issuer = 'Korlantas Polri';
      category = DocumentCategory.vehicle;
    } else if (hasKtpClues && documentType != ScanDocumentType.paymentCard) {
      recognizedType = RecognizedDocumentType.ktp;
      title = 'KTP Republik Indonesia';
      issuer = _extractKtpIssuer(lines);
      category = DocumentCategory.identity;
    } else if (hasBpjsClues) {
      recognizedType = RecognizedDocumentType.bpjs;
      title = 'Kartu BPJS Kesehatan';
      issuer = 'BPJS Kesehatan RI';
      category = DocumentCategory.medical;
    } else if (hasPassportClues) {
      recognizedType = RecognizedDocumentType.passport;
      title = 'Paspor Republik Indonesia';
      issuer = 'Direktorat Jenderal Imigrasi';
      category = DocumentCategory.identity;
    } else if (hasBankClues) {
      recognizedType = RecognizedDocumentType.bankCard;
      bankName = _extractBankName(upperText);
      cardNetwork = _extractCardNetwork(upperText);
      title = bankName.isNotEmpty
          ? '$bankName $cardNetwork'.trim()
          : 'Kartu Perbankan / Debit';
      issuer = bankName.isNotEmpty ? bankName : 'Penerbit Kartu';
      category = DocumentCategory.financial;
    } else if (documentType == ScanDocumentType.document) {
      recognizedType = RecognizedDocumentType.generalDocument;
      title = _extractGeneralDocumentTitle(lines);
      issuer = _extractGeneralIssuer(lines);
      category = DocumentCategory.identity;
    }

    // 2. Ekstraksi Nomor Dokumen & Masking Berdaya Tahan Tinggi
    if (recognizedType == RecognizedDocumentType.ktp) {
      // Prioritas 1: NIK dengan awalan label NIK/N1K/Nomor
      final nikWithLabelMatch = RegExp(
        r'(?:NIK|N1K|NlK|Nomor|NO)?[\s:.]*([1-9][0-9OIlDbB\s\.\-]{15,22})',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (nikWithLabelMatch != null) {
        final cleaned = _cleanDigits(nikWithLabelMatch.group(1)!);
        if (cleaned.length >= 16) {
          documentNumber = cleaned.substring(0, 16);
        }
      }

      // Prioritas 2: Cari baris berisikan 16 digit angka bersih
      if (documentNumber.isEmpty) {
        for (final line in lines) {
          final cleaned = _cleanDigits(line);
          if (cleaned.length == 16 && !cleaned.startsWith('0')) {
            documentNumber = cleaned;
            break;
          }
        }
      }

      // Prioritas 3: Pola 16 digit murni di mana pun
      if (documentNumber.isEmpty) {
        final standAloneMatch = RegExp(r'\b([1-9]\d{15})\b')
            .firstMatch(rawText);
        if (standAloneMatch != null) {
          documentNumber = standAloneMatch.group(1)!;
        }
      }
    } else if (recognizedType == RecognizedDocumentType.bankCard) {
      // Cari 4 digit terakhir kartu (PRD & AGENTS.md Bagian 10: Dilarang keras simpan 16 digit penuh)
      final cardMatch =
          RegExp(r'\b(?:\d{4}[\s-]?){3}(\d{4})\b').firstMatch(rawText) ??
          RegExp(r'(?:CARD|NO|NUM)[\s:.]*(?:[*•Xx\s]*(\d{4}))')
              .firstMatch(rawText);
      if (cardMatch != null) {
        last4Digits = cardMatch.group(1)!;
        documentNumber = '•••• •••• •••• $last4Digits';
      } else {
        final fourDigitMatch = RegExp(r'\b(\d{4})\b').firstMatch(rawText);
        if (fourDigitMatch != null) {
          last4Digits = fourDigitMatch.group(1)!;
          documentNumber = '•••• •••• •••• $last4Digits';
        }
      }
    } else {
      // Pola nomor umum: 8-20 digit
      final generalMatch = RegExp(r'\b[0-9]{8,20}\b').firstMatch(rawText);
      if (generalMatch != null) {
        documentNumber = generalMatch.group(0)!;
      }
    }

    // 3. Ekstraksi Nama Pemilik (Multi-line Lookahead & Pemisahan Kolom Spasial)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineUpper = line.toUpperCase();

      if (lineUpper.contains('NAMA') || lineUpper.contains('NAME')) {
        // Cek teks setelah titik dua pada baris yang sama
        if (line.contains(':')) {
          final parts = line.split(':');
          final afterColon = parts.sublist(1).join(':').trim();
          final sanitized = _sanitizeName(afterColon);
          if (sanitized.length >= 3 && !_isStopWord(sanitized)) {
            fullName = sanitized;
            break;
          }
        } else {
          final stripped = lineUpper
              .replaceFirst(RegExp(r'^NAMA\s*'), '')
              .trim();
          final sanitized = _sanitizeName(stripped);
          if (sanitized.length >= 3 && !_isStopWord(sanitized)) {
            fullName = sanitized;
            break;
          }
        }

        // Jika baris kosong/hanya label, cari di baris berikutnya
        for (int j = i + 1; j < lines.length && j <= i + 3; j++) {
          final candidate = lines[j].trim();
          final sanitized = _sanitizeName(candidate);
          if (sanitized.length >= 3 &&
              !_isStopWord(candidate) &&
              !candidate.contains(':') &&
              !RegExp(r'\d{4,}').hasMatch(candidate)) {
            fullName = sanitized;
            break;
          }
        }
        if (fullName.isNotEmpty) break;
      }
    }

    // Fallback: Cari baris teks huruf kapital yang menyerupai nama orang
    if (fullName.isEmpty) {
      for (final line in lines) {
        final clean = _sanitizeName(line);
        final upper = clean.toUpperCase();
        if (clean.length >= 4 &&
            clean.length <= 35 &&
            !_isStopWord(upper) &&
            !upper.contains('PROVINSI') &&
            !upper.contains('KABUPATEN') &&
            !upper.contains('KOTA') &&
            !upper.contains('KECAMATAN') &&
            !upper.contains('DESA') &&
            RegExp(r'^[A-Z\s\.\,]+$').hasMatch(upper)) {
          fullName = clean;
          break;
        }
      }
    }

    // 4. Ekstraksi Spesifik KTP
    if (recognizedType == RecognizedDocumentType.ktp) {
      // Tempat/Tgl Lahir
      final birthMatch = RegExp(
        r'(?:TEMPAT|TMPT)[/\s]*(?:TGL|TANGGAL)?[/\s]*(?:LAHIR)?[\s:.]+([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (birthMatch != null &&
          birthMatch.group(1)!.trim().isNotEmpty &&
          !_isStopWord(birthMatch.group(1)!.trim())) {
        birthPlaceDate = _cleanLabel(birthMatch.group(1)!);
      } else {
        // Fallback pola KOTA, DD-MM-YYYY
        final cityDateMatch = RegExp(
          r'([A-Za-z\s]{3,20})[,\s]+([0-3]?[0-9][\s\-\/\.][0-1]?[0-9][\s\-\/\.](?:19|20)\d{2})',
        ).firstMatch(rawText);
        if (cityDateMatch != null) {
          birthPlaceDate =
              '${cityDateMatch.group(1)!.trim()}, ${cityDateMatch.group(2)!.trim()}';
        }
      }

      // Jenis Kelamin
      if (upperText.contains('LAKI-LAKI') ||
          upperText.contains('LAKI - LAKI') ||
          upperText.contains('LAKI')) {
        gender = 'LAKI-LAKI';
      } else if (upperText.contains('PEREMPUAN') ||
          upperText.contains('WANITA')) {
        gender = 'PEREMPUAN';
      }

      // Golongan Darah
      final bloodMatch = RegExp(
        r'(?:GOL|DARAH|GOL\.)[\s:.]*([ABO\-\+]{1,2})\b',
        caseSensitive: false,
      ).firstMatch(upperText);
      if (bloodMatch != null) {
        bloodType = bloodMatch.group(1)!.toUpperCase();
      }

      // Alamat Lengkap
      final addrMatch = RegExp(
        r'ALAMAT[\s:.]+([^\n\r]+)',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (addrMatch != null && addrMatch.group(1)!.trim().isNotEmpty) {
        final cand = addrMatch.group(1)!.trim();
        if (!_isStopWord(cand)) {
          address = cand;
        }
      }
      if (address.isEmpty) {
        for (int i = 0; i < lines.length; i++) {
          final l = lines[i].toUpperCase();
          if (l == 'ALAMAT' || l == 'ALAMAT:' || l.startsWith('ALAMAT')) {
            if (i + 1 < lines.length) {
              final next = lines[i + 1].trim();
              if (!_isStopWord(next)) {
                address = next;
                break;
              }
            }
          }
        }
      }

      // RT/RW
      final rtRwMatch = RegExp(
        r'RT[/\s]*RW[\s:.]*([0-9OIl]{1,3}\s*[/-]\s*[0-9OIl]{1,3})',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (rtRwMatch != null) {
        final parts = rtRwMatch.group(1)!.split(RegExp(r'[/\\-]'));
        if (parts.length >= 2) {
          rtRw = '${_cleanDigits(parts[0])}/${_cleanDigits(parts[1])}';
        }
      }

      // Kelurahan / Desa
      final kelMatch = RegExp(
        r'(?:KEL[/\s]*DESA|KELURAHAN|DESA)[\s:.]+([^\r\n]+)',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (kelMatch != null && !_isStopWord(kelMatch.group(1)!.trim())) {
        kelDesa = _cleanLabel(kelMatch.group(1)!);
      }

      // Kecamatan
      final kecMatch = RegExp(
        r'KECAMATAN[\s:.]+([^\r\n]+)',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (kecMatch != null && !_isStopWord(kecMatch.group(1)!.trim())) {
        kecamatan = _cleanLabel(kecMatch.group(1)!);
      }

      // Agama
      final relMatch = RegExp(
        r'\b(ISLAM|KRISTEN|KATHOLIK|KATOLIK|HINDU|BUDDHA|BUDHA|KHONGHUCU)\b',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (relMatch != null) {
        religion = relMatch.group(1)!.toUpperCase();
      }

      // Status Perkawinan
      final maritalMatch = RegExp(
        r'\b(BELUM KAWIN|KAWIN|CERAI HIDUP|CERAI MATI)\b',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (maritalMatch != null) {
        maritalStatus = maritalMatch.group(1)!.toUpperCase();
      }

      // Pekerjaan
      final occMatch = RegExp(
        r'PEKERJAAN[\s:.]+([^\r\n]+)',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (occMatch != null && !_isStopWord(occMatch.group(1)!.trim())) {
        occupation = _cleanLabel(occMatch.group(1)!);
      } else {
        for (final occ in [
          'KARYAWAN SWASTA',
          'PEGAWAI NEGERI SIPIL',
          'PNS',
          'WIRASWASTA',
          'PELAJAR/MAHASISWA',
          'PELAJAR',
          'MAHASISWA',
          'BURUH',
          'IBU RUMAH TANGGA',
          'TIDAK/BELUM BEKERJA',
          'TNI',
          'POLRI',
          'GURU',
          'DOKTER',
          'PEDAGANG',
        ]) {
          if (upperText.contains(occ)) {
            occupation = occ;
            break;
          }
        }
      }

      // Kewarganegaraan
      final natMatch = RegExp(
        r'\b(WNI|WNA)\b',
        caseSensitive: false,
      ).firstMatch(rawText);
      if (natMatch != null) {
        nationality = natMatch.group(1)!.toUpperCase();
      } else {
        nationality = 'WNI';
      }
    }

    // 5. Ekstraksi Masa Berlaku / Expired Date
    if (upperText.contains('SEUMUR HIDUP') || upperText.contains('LIFETIME')) {
      expiryDate = 'SEUMUR HIDUP';
      isLifetimeExpiry = true;
    } else if (recognizedType == RecognizedDocumentType.bankCard) {
      // Format MM/YY pada kartu bank
      final expMatch = RegExp(r'\b(0[1-9]|1[0-2])[\s/]+([2-3][0-9])\b')
          .firstMatch(rawText);
      if (expMatch != null) {
        expiryDate = '${expMatch.group(1)}/${expMatch.group(2)}';
        isLifetimeExpiry = false;
      } else {
        expiryDate = '12/28';
        isLifetimeExpiry = false;
      }
    } else {
      // Format tanggal DD-MM-YYYY atau DD/MM/YYYY
      final dateMatch = RegExp(r'\b(\d{2}[-/\.]\d{2}[-/\.]\d{4})\b')
          .firstMatch(rawText);
      if (dateMatch != null) {
        expiryDate = dateMatch
            .group(1)!
            .replaceAll('-', '/')
            .replaceAll('.', '/');
        isLifetimeExpiry = false;
      } else {
        expiryDate = 'SEUMUR HIDUP';
        isLifetimeExpiry = true;
      }
    }

    return OcrScanResult(
      imagePath: imagePath,
      title: title,
      documentNumber: documentNumber,
      fullName: fullName,
      expiryDate: expiryDate,
      isLifetimeExpiry: isLifetimeExpiry,
      issuer: issuer,
      category: category,
      rawText: rawText,
      recognizedType: recognizedType,
      birthPlaceDate: birthPlaceDate,
      gender: gender,
      bloodType: bloodType,
      address: address,
      rtRw: rtRw,
      kelDesa: kelDesa,
      kecamatan: kecamatan,
      religion: religion,
      maritalStatus: maritalStatus,
      occupation: occupation,
      nationality: nationality,
      bankName: bankName,
      cardNetwork: cardNetwork,
      last4Digits: last4Digits,
    );
  }

  String _cleanDigits(String raw) {
    return raw
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('|', '1')
        .replaceAll('B', '8')
        .replaceAll(RegExp(r'\D'), '');
  }

  String _cleanLabel(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9\s\.\,\-]'), '').trim();
  }

  String _extractKtpIssuer(List<String> lines) {
    String prov = '';
    String kota = '';
    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i].toUpperCase();
      if (line.contains('PROVINSI')) {
        prov = line.replaceAll('PROVINSI', '').trim();
      } else if (line.contains('KABUPATEN') || line.contains('KOTA')) {
        kota = line.replaceAll('KABUPATEN', '').replaceAll('KOTA', '').trim();
      }
    }
    if (kota.isNotEmpty) {
      return 'Disdukcapil $kota';
    }
    if (prov.isNotEmpty) {
      return 'Disdukcapil $prov';
    }
    return 'Disdukcapil RI';
  }

  String _extractBankName(String text) {
    if (text.contains('BCA') || text.contains('CENTRAL ASIA')) {
      return 'Bank Central Asia (BCA)';
    }
    if (text.contains('MANDIRI')) {
      return 'Bank Mandiri';
    }
    if (text.contains('BRI') || text.contains('RAKYAT INDONESIA')) {
      return 'Bank BRI';
    }
    if (text.contains('BNI') || text.contains('NEGARA INDONESIA')) {
      return 'Bank BNI';
    }
    if (text.contains('CIMB')) {
      return 'CIMB Niaga';
    }
    if (text.contains('PERMATA')) {
      return 'Permata Bank';
    }
    if (text.contains('DANAMON')) {
      return 'Bank Danamon';
    }
    if (text.contains('JAGO')) {
      return 'Bank Jago';
    }
    if (text.contains('JENIUS') || text.contains('BTPN')) {
      return 'Jenius BTPN';
    }
    if (text.contains('SEABANK')) {
      return 'SeaBank Indonesia';
    }
    return 'Bank Penerbit';
  }

  String _extractCardNetwork(String text) {
    if (text.contains('VISA')) return 'Visa';
    if (text.contains('MASTERCARD')) return 'Mastercard';
    if (text.contains('GPN')) return 'GPN';
    if (text.contains('JCB')) return 'JCB';
    return 'Debit';
  }

  String _extractGeneralDocumentTitle(List<String> lines) {
    if (lines.isEmpty) return 'Dokumen Fisik';
    // Gunakan baris pertama yang bermakna sebagai judul
    for (final line in lines) {
      if (line.length > 4 && !_isStopWord(line.toUpperCase())) {
        return line.trim();
      }
    }
    return 'Dokumen Fisik';
  }

  String _extractGeneralIssuer(List<String> lines) {
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('KEMENTERIAN') ||
          upper.contains('UNIVERSITAS') ||
          upper.contains('DINAS') ||
          upper.contains('PT ') ||
          upper.contains('REPUBLIK')) {
        return line.trim();
      }
    }
    return 'Instansi Terkait';
  }

  String _sanitizeName(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z\s\.\,\-]'), '').trim();
  }

  bool _isStopWord(String text) {
    final clean = text.toUpperCase().trim();
    const stopWords = {
      'PROVINSI',
      'KABUPATEN',
      'KOTA',
      'REPUBLIK',
      'INDONESIA',
      'KARTU',
      'TANDA',
      'PENDUDUK',
      'SURAT',
      'IZIN',
      'MENGEMUDI',
      'NIK',
      'N1K',
      'NLK',
      'NAMA',
      'NAME',
      'TEMPAT/TGL LAHIR',
      'TEMPAT/TGL',
      'TGL LAHIR',
      'JENIS KELAMIN',
      'GOL. DARAH',
      'GOL DARAH',
      'GOL',
      'DARAH',
      'ALAMAT',
      'RT/RW',
      'RT',
      'RW',
      'KEL/DESA',
      'KELURAHAN',
      'DESA',
      'KECAMATAN',
      'AGAMA',
      'STATUS PERKAWINAN',
      'STATUS',
      'PERKAWINAN',
      'PEKERJAAN',
      'KEWARGANEGARAAN',
      'BERLAKU HINGGA',
      'BERLAKU',
      'HINGGA',
      'SEUMUR HIDUP',
      'DISDUKCAPIL',
    };
    return stopWords.contains(clean);
  }
}
