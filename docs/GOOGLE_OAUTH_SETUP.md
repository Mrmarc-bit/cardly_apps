# Panduan Konfigurasi Google OAuth - Cardly & Supabase

Dokumen ini memandu langkah demi langkah menghubungkan tombol **"Masuk dengan Google"** di aplikasi Cardly dengan **Google Cloud Console** dan **Supabase Dashboard**.

---

## 1. Dapatkan Kredensial di Google Cloud Console

1. Buka [Google Cloud Console](https://console.cloud.google.com/).
2. Buat proyek baru atau pilih proyek yang sudah ada (misal: `Cardly App`).
3. Buka **APIs & Services** $\rightarrow$ **OAuth consent screen**:
   - Pilih User Type: **External** $\rightarrow$ Klik **Create**.
   - **App name**: `Cardly`
   - **User support email**: Email Anda
   - **Developer contact information**: Email Anda
   - Klik **Save and Continue**.
   - Pada bagian **Scopes**, pastikan scope dasar (`userinfo.email`, `userinfo.profile`, `openid`) sudah ada $\rightarrow$ Klik **Save and Continue**.
4. Buka **APIs & Services** $\rightarrow$ **Credentials**:
   - Klik **+ CREATE CREDENTIALS** $\rightarrow$ Pilih **OAuth client ID**.
   - **Application type**: Pilih **Web application**.
   - **Name**: `Cardly Supabase Client`
   - **Authorized JavaScript origins**:
     ```text
     https://tsmdqyqftxriqgfurrae.supabase.co
     ```
   - **Authorized redirect URIs** (Sangat Penting):
     ```text
     https://tsmdqyqftxriqgfurrae.supabase.co/auth/v1/callback
     ```
   - Klik **CREATE**.
5. Simpan **Client ID** dan **Client Secret** yang muncul di layar.

---

## 2. Masukkan Kredensial ke Dashboard Supabase

1. Buka Dashboard Supabase proyek Anda:
   `https://supabase.com/dashboard/project/tsmdqyqftxriqgfurrae`
2. Di menu bilah kiri, klik menu **Authentication** (ikon gembok).
3. Pilih tab **Providers** $\rightarrow$ Cari dan klik **Google**:
   - Aktifkan toggle **Enable Google provider**.
   - **Client ID (for OAuth)**: Tempelkan Client ID dari Google Cloud Console.
   - **Client Secret**: Tempelkan Client Secret dari Google Cloud Console.
   - Klik tombol **Save**.
4. Pindah ke tab **URL Configuration** (di bawah menu Authentication):
   - **Site URL**: `io.supabase.cardly://login-callback`
   - **Redirect URLs**: Tambahkan:
     ```text
     io.supabase.cardly://login-callback
     ```
   - Klik **Save**.

---

## 3. Konfigurasi Aplikasi (Sudah Terpasang Otomatis di Kode)

Bagian aplikasi Flutter telah selesai dikonfigurasi secara lengkap oleh AI:
- ✅ **Android Deep Link** di [AndroidManifest.xml](file:///Users/macbookair/Documents/Herd/cardly/android/app/src/main/AndroidManifest.xml):
  Scheme `io.supabase.cardly` dengan host `login-callback`.
- ✅ **iOS Deep Link** di [Info.plist](file:///Users/macbookair/Documents/Herd/cardly/ios/Runner/Info.plist):
  `CFBundleURLSchemes` `io.supabase.cardly`.
- ✅ **Supabase Service Call** di [supabase_service.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/network/supabase_service.dart):
  Memanggil `signInWithOAuth(OAuthProvider.google, redirectTo: 'io.supabase.cardly://login-callback')`.
- ✅ **Auth State Stream Listener** di [app.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/app/app.dart):
  Mendeteksi callback Google OAuth, otomatis menyimpan data profil pengguna, dan mengarahkan ke dashboard utama.
- ✅ **Tombol UI Resmi Google** di [login_view.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/authentication/presentation/login_view.dart) dan [register_view.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/authentication/presentation/register_view.dart).
