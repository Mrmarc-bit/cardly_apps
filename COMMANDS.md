# Operational Commands Reference — Cardly

Dokumen ini merupakan panduan perintah operasional resmi untuk pengembangan, pengujian, audit kualitas, dan pembuatan build aplikasi Cardly. Seluruh perintah di bawah ini telah disesuaikan dengan kondisi faktual repositori dan lingkungan eksekusi.

---

## 1. Status Indikator Perintah

| Status | Makna |
|---|---|
| `VERIFIED` | Perintah telah dieksekusi secara nyata pada repositori ini dan hasilnya terbukti sukses. |
| `AVAILABLE_NOT_RUN` | Perintah didukung penuh oleh konfigurasi proyek saat ini, tetapi tidak perlu dieksekusi saat audit. |
| `PLANNED` | Perintah dibutuhkan dalam alur kerja masa depan, namun dependensi/konfigurasi belum siap. |
| `BLOCKED` | Perintah tidak dapat dijalankan saat ini karena kendala lingkungan atau ketiadaan alat pendukung. |
| `NOT_APPLICABLE` | Perintah tidak relevan dengan kondisi repositori saat ini (misalnya target belum ada). |

---

## 2. Environment & Diagnostik

Perintah untuk memeriksa kesehatan sistem dan kompatibilitas SDK.

| Tujuan / Operasi | Perintah | Status | Prasyarat / Keterangan | Kapan Dijalankan |
|---|---|---|---|---|
| Cek versi Flutter SDK | `flutter --version` | `VERIFIED` | Flutter CLI terpasang. Terkonfirmasi: **Flutter 3.47.5 stable**. | Sebelum memulai sesi pengerjaan atau saat pergantian mesin. |
| Cek versi Dart SDK | `dart --version` | `VERIFIED` | Terkonfirmasi: **Dart 3.13.4**. | Verifikasi null safety dan fitur bahasa. |
| Audit status lingkungan | `flutter doctor` | `VERIFIED` | Menampilkan kesiapan Android SDK (36.0.0), Chrome, Xcode, dan konektivitas. | Saat terjadi masalah kompilasi atau setup device baru. |
| Diagnostik detail lingkungan | `flutter doctor -v` | `AVAILABLE_NOT_RUN` | Menampilkan log verbose dari `flutter doctor`. | Ketika butuh log path SDK atau lisensi yang hilang. |
| Cek daftar perangkat terhubung | `flutter devices` | `VERIFIED` | Terkonfirmasi: `macOS (desktop)` dan `Chrome (web)` tersedia. | Sebelum menjalankan perintah `flutter run`. |
| Cek emulator yang tersedia | `flutter emulators` | `VERIFIED` | Terkonfirmasi: `Pixel_10_Pro_XL (android)` tersedia. | Untuk mengetahui emulator yang siap diluncurkan. |

---

## 3. Dependency Management

Perintah untuk mengelola pustaka pihak ketiga.

> [!CAUTION]
> Jangan mengubah atau memperbarui paket tanpa persetujuan eksplisit dari pengguna sesuai aturan di [AGENTS.md](file:///Users/macbookair/Documents/Herd/cardly/AGENTS.md).

| Tujuan / Operasi | Perintah | Status | Prasyarat / Keterangan | Kapan Dijalankan |
|---|---|---|---|---|
| Unduh dependensi | `flutter pub get` | `AVAILABLE_NOT_RUN` | File [pubspec.yaml](file:///Users/macbookair/Documents/Herd/cardly/pubspec.yaml) ada di root. | Setelah clone repositori atau setelah dependensi baru disetujui. |
| Audit dependensi usang | `flutter pub outdated` | `AVAILABLE_NOT_RUN` | Koneksi internet aktif. | Audit berkala kesehatan package tanpa mengubah file. |
| Update dependensi terkunci | `flutter pub upgrade` | `AVAILABLE_NOT_RUN` | Wajib konfirmasi pengguna. | Hanya jika ada kebutuhan update versi minor yang aman. |

---

## 4. Development & Running

Perintah untuk menjalankan aplikasi dalam siklus pengembangan.

| Tujuan / Operasi | Perintah | Status | Prasyarat / Keterangan | Kapan Dijalankan |
|---|---|---|---|---|
| Jalankan ke Desktop macOS | `flutter run -d macos` | `AVAILABLE_NOT_RUN` | Device `macos` aktif. | Pengujian cepat UI dan fungsionalitas lokal. |
| Jalankan ke Web Chrome | `flutter run -d chrome` | `AVAILABLE_NOT_RUN` | Google Chrome terpasang. | Preview visual dan navigasi layar lebar. |
| Nyalakan Android Emulator | `flutter emulators --launch Pixel_10_Pro_XL` | `AVAILABLE_NOT_RUN` | Android Studio & AVD telah dibuat. | Sebelum pengujian mobile jika device fisik tidak terhubung. |
| Jalankan ke Android Emulator | `flutter run -d Pixel_10_Pro_XL` | `AVAILABLE_NOT_RUN` | Emulator Pixel 10 Pro XL sudah aktif. | Pengujian integrasi fitur mobile, kamera mock, dan SQLite. |
| Jalankan pada Device Fisik | `flutter run` | `AVAILABLE_NOT_RUN` | Perangkat Android fisik dengan USB debugging terhubung. | Pengujian performa nyata dan sensor perangkat. |
| Jalankan dalam Profile Mode | `flutter run --profile` | `AVAILABLE_NOT_RUN` | Perangkat fisik Android terhubung. | Analisis konsumsi memori dan frame rate (*jank*). |

---

## 5. Code Quality & Formatting

Perintah untuk memastikan kepatuhan standar kode dan nihil regresi sebelum commit.

| Tujuan / Operasi | Perintah | Status | Prasyarat / Keterangan | Kapan Dijalankan |
|---|---|---|---|---|
| Analisis kode statis | `flutter analyze` | `VERIFIED` | Terkonfirmasi: **0 issues found** (lulus bersih). | **Wajib** dijalankan setiap kali selesai mengedit kode. |
| Periksa format kode (CI check) | `dart format --output=none --set-exit-if-changed .` | `VERIFIED` | Terkonfirmasi: Mendeteksi 13 file perlu diformat (Exit code 1). | Verifikasi kelayakan format tanpa memodifikasi file. |
| Rapikan format seluruh kode | `dart format .` | `AVAILABLE_NOT_RUN` | Memformat seluruh 98 file Dart sesuai standar resmi Dart. | Saat pengguna menyetujui pembersihan format kode. |
| Rapikan format folder `lib/` | `dart format lib/` | `AVAILABLE_NOT_RUN` | Hanya memformat kode aplikasi. | Sebelum penyerahan fitur baru. |
| Rapikan format folder `test/` | `dart format test/` | `AVAILABLE_NOT_RUN` | Hanya memformat kode pengujian. | Setelah membuat atau memperbarui test. |

---

## 6. Testing

Perintah untuk mengeksekusi automated test suite.

| Tujuan / Operasi | Perintah | Status | Prasyarat / Keterangan | Kapan Dijalankan |
|---|---|---|---|---|
| Jalankan seluruh test | `flutter test` | `VERIFIED` | Terkonfirmasi: **51/51 tests passed** (0 kegagalan). | **Wajib** dijalankan sebelum menyelesaikan task. |
| Jalankan unit test saja | `flutter test test/unit` | `VERIFIED` | Terkonfirmasi: **16/16 unit tests passed**. | Verifikasi logika bisnis, CRUD database, dan formatters. |
| Jalankan widget test saja | `flutter test test/widget` | `VERIFIED` | Terkonfirmasi: **34/34 widget tests passed**. | Verifikasi antarmuka, form input, dan transisi layar. |
| Jalankan file test spesifik | `flutter test test/widget/auth_flow_test.dart` | `AVAILABLE_NOT_RUN` | Menjalankan tes khusus autentikasi & splash. | Saat melakukan debugging cepat pada fitur autentikasi. |
| Hitung coverage pengujian | `flutter test --coverage` | `AVAILABLE_NOT_RUN` | Menghasilkan file `coverage/lcov.info`. | Audit cakupan pengujian aplikasi. |
| Jalankan integration test | `flutter test integration_test` | `NOT_APPLICABLE` | Folder `integration_test/` belum ada di repositori. | Jika integration test telah dibuat di masa depan. |

---

## 7. Build & Packaging

Perintah kompilasi binary aplikasi.

> [!WARNING]
> Build iOS saat ini berstatus `BLOCKED` di lingkungan lokal karena instalasi Xcode belum lengkap dan CocoaPods belum terpasang.

| Target Build | Perintah | Status | Prasyarat / Keterangan | Kapan Dijalankan |
|---|---|---|---|---|
| Android APK (Debug) | `flutter build apk --debug` | `AVAILABLE_NOT_RUN` | Android SDK 36.0.0 siap. | Pembuatan paket instalasi cepat untuk uji internal. |
| Android APK (Release) | `flutter build apk --release` | `AVAILABLE_NOT_RUN` | Android toolchain siap. Menghasilkan file `.apk` mandiri. | Distribusi sideload atau release testing. |
| Android App Bundle | `flutter build appbundle --release` | `AVAILABLE_NOT_RUN` | Menghasilkan file `.aab` untuk Google Play Console. | Persiapan publikasi ke Google Play Store. |
| iOS Release | `flutter build ios --release` | `BLOCKED` | **Terhalang:** Xcode belum lengkap & CocoaPods tidak ada. | Publikasi ke App Store (butuh pemulihan toolchain). |
| macOS App | `flutter build macos` | `BLOCKED` | **Terhalang:** Xcode command line tools / full app belum siap. | Rilis desktop macOS. |
| Web Bundle | `flutter build web --release` | `AVAILABLE_NOT_RUN` | Menghasilkan aset statis di `build/web/`. | Rilis versi web aplikasi. |

---

## 8. Version Control & Setup Lingkungan

Perintah pemulihan dan inisialisasi lingkungan operasional.

| Tujuan / Operasi | Perintah | Status | Keterangan |
|---|---|---|---|
| Inisialisasi Git repositori | `git init` | `AVAILABLE_NOT_RUN` | **Rekomendasi Utama:** Aktifkan git tracking untuk mengamankan 98 file source code. |
| Cek status Git singkat | `git status -s` | `BLOCKED` | Gagal dengan kode 128 sampai `git init` dijalankan. |
| Pasang CocoaPods (macOS) | `brew install cocoapods` | `AVAILABLE_NOT_RUN` | Diperlukan untuk mengaktifkan build iOS & macOS. |
| Selesaikan setup Xcode | `sudo xcodebuild -runFirstLaunch` | `AVAILABLE_NOT_RUN` | Menyelesaikan lisensi dan komponen Xcode yang belum lengkap. |
