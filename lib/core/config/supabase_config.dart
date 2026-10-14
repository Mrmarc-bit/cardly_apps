/// Konfigurasi resmi Supabase untuk Cardly.
/// PERHATIAN: Sesuai panduan keamanan AGENTS.md, hanya publishable (anon) key
/// yang boleh disimpan pada aplikasi client Flutter. Secret key tidak boleh disertakan.
class SupabaseConfig {
  SupabaseConfig._();

  /// URL Proyek Supabase Cardly
  static const String url = 'https://tsmdqyqftxriqgfurrae.supabase.co';

  /// Publishable (Anon) Key resmi untuk komunikasi client aman dengan Row Level Security (RLS)
  static const String publishableKey =
      'sb_publishable_L8AGlfFIeB0E4rXvHt7tUg_V-1nrga1';
  static const String anonKey = publishableKey;

  /// Nama storage bucket untuk dokumen terenkripsi Cardly
  static const String documentsBucket = 'cardly_documents';

  /// URL Redirect Deep Link untuk OAuth (Google, dll.)
  static const String oauthCallbackUrl = 'io.supabase.cardly://login-callback';

  /// Google OAuth Web Client ID (untuk backend verification & Supabase Auth)
  static const String googleWebClientId =
      '95629750679-f2q3h8hrqk76ld7ru9steia2j3qdqrq7.apps.googleusercontent.com';

  /// Google OAuth Android Client ID (untuk verifikasi aplikasi mobile di Google Cloud)
  static const String googleAndroidClientId =
      '95629750679-1sll7cho8rsrl4np1osueg09r53rsofr.apps.googleusercontent.com';
}
