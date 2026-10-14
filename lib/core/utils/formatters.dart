import 'package:intl/intl.dart';

/// Formatter dan utilitas data untuk Cardly
abstract final class Formatters {
  static final DateFormat _displayDateFormat = DateFormat(
    'd MMM yyyy',
    'id_ID',
  );
  static final DateFormat _fallbackDateFormat = DateFormat('d MMM yyyy');
  static final DateFormat _expiryDateFormat = DateFormat('MM/yy');

  /// Memformat nomor kartu atau identitas tersamar (maksimal 4 digit terlihat)
  /// Contoh: "4582" -> "•••• 4582"
  static String maskCardNumber(String? lastFourDigits) {
    if (lastFourDigits == null || lastFourDigits.isEmpty) {
      return '•••• ----';
    }
    final clean = lastFourDigits.replaceAll(RegExp(r'\D'), '');
    final suffix = clean.length > 4 ? clean.substring(clean.length - 4) : clean;
    return '•••• $suffix';
  }

  /// Memformat objek DateTime ke string bersahabat bahasa Indonesia
  static String formatDate(DateTime? date) {
    if (date == null) return 'Tidak diisi';
    try {
      return _displayDateFormat.format(date);
    } catch (_) {
      return _fallbackDateFormat.format(date);
    }
  }

  /// Memformat tanggal dan waktu untuk riwayat sinkronisasi (misal: "13 Okt 2026, 23:05")
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'Belum pernah disinkronkan';
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy, HH:mm').format(date);
      } catch (_) {
        final d = date.day.toString().padLeft(2, '0');
        final m = date.month.toString().padLeft(2, '0');
        final y = date.year.toString();
        final h = date.hour.toString().padLeft(2, '0');
        final min = date.minute.toString().padLeft(2, '0');
        return '$d/$m/$y, $h:$min';
      }
    }
  }

  /// Memformat tanggal masa berlaku kartu (MM/YY)
  static String formatExpiry(DateTime date) {
    try {
      return _expiryDateFormat.format(date);
    } catch (_) {
      return '${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
    }
  }

  /// Memformat ukuran berkas byte menjadi string bersahabat (KB, MB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Menghitung selisih hari menuju kedaluwarsa
  static int daysUntil(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  /// Format deskripsi kedaluwarsa (misal: "30 hari lagi" atau "Kedaluwarsa")
  static String formatExpiryStatus(DateTime? expiryDate) {
    if (expiryDate == null) return 'Tidak kedaluwarsa';
    final days = daysUntil(expiryDate);
    if (days < 0) {
      return 'Telah kedaluwarsa (${formatDate(expiryDate)})';
    } else if (days == 0) {
      return 'Kedaluwarsa hari ini';
    } else {
      return '$days hari lagi (${formatDate(expiryDate)})';
    }
  }
}

/// Alias untuk kemudahan penamaan di seluruh modul Cardly
typedef CardlyFormatters = Formatters;
