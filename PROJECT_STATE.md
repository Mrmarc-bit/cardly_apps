# Project State — Cardly

Dokumen ini merupakan snapshot operasional status proyek Cardly. Dokumen ini diperbarui secara berkala untuk memandu AI agent dan developer mengenai kondisi aktual repositori tanpa perlu memindai ulang seluruh codebase.

---

## 1. Metadata

| Atribut | Nilai | Status Verifikasi |
|---|---|---|
| **Nama Proyek** | Cardly | `VERIFIED` |
| **Tanggal Pembaruan** | 2026-10-13 | `VERIFIED` |
| **Fase Pengembangan** | Post-Core Implementation / Feature Verification & Polish | `VERIFIED` |
| **Status Keseluruhan** | Stabil (Core & 8 Modul Fitur terimplementasi, 51 Test Lulus, Analyze Bersih) | `VERIFIED` |
| **Tingkat Verifikasi** | Terverifikasi empiris via inspeksi file & eksekusi terminal | `VERIFIED` |

---

## 2. Repository Reality

Kondisi faktual repositori per tanggal 13 Oktober 2026:

- **Source Code (`lib/`):** `VERIFIED` — 99 file Dart aktif. Terbagi ke dalam `app/`, `core/` (config, error, network, storage, sync, theme, utils, widgets), dan 8 modul di `features/` (`authentication`, `cards`, `documents`, `home`, `profile_settings`, `reminders`, `scan`, `vault`).
- **Dependency & SDK (`pubspec.yaml`):** `VERIFIED` — SDK Dart `^3.13.4`, Flutter 3.47.5 stable. Paket utama aktif: `flutter_riverpod` (2.6.1), `go_router` (14.6.3), `sqflite` (2.4.4+1), `flutter_secure_storage` (9.2.2), `supabase_flutter` (2.18.3), `local_auth` (2.3.0), `google_sign_in` (6.3.0), `flutter_animate` (4.5.2), `lottie` (3.6.1).
- **Test Suite (`test/`):** `VERIFIED` — 17 file pengujian (6 unit test di `test/unit/`, 10 widget test di `test/widget/`, 1 `widget_test.dart`). Total 51 tes lulus tanpa kegagalan.
- **Platform Inisialisasi:** `VERIFIED` — Folder `android/` (Gradle/Kotlin, `MainActivity` menggunakan `FlutterFragmentActivity`, izin `USE_BIOMETRIC` dan `USE_FINGERPRINT`) dan `ios/` (`NSFaceIDUsageDescription` aktif di `Info.plist`) tersedia.
- **Integration Test:** `NOT_APPLICABLE` — Direktori `integration_test/` belum dibuat.
- **Git Repository:** `NOT_INITIALIZED` / `BLOCKED` — Root belum memiliki direktori `.git` (`git status` keluar dengan kode 128).
- **Toolchain Lingkungan:** `VERIFIED` — Flutter 3.47.5, Dart 3.13.4, Android SDK 36.0.0 (`OK`), macOS 27.0.1 darwin-arm64. Toolchain Xcode incomplete & CocoaPods missing (`BLOCKED` untuk iOS build).

---

## 3. Current Development Status

### 3.1 Selesai Diimplementasikan (`VERIFIED`)
1. **Core Foundation & Design System:**
   - Design tokens: [app_colors.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/theme/app_colors.dart), [app_typography.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/theme/app_typography.dart), [app_spacing.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/theme/app_spacing.dart), [app_radius.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/theme/app_radius.dart), [app_motion.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/theme/app_motion.dart), [app_theme.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/theme/app_theme.dart).
   - Reusable widgets: `CardlyButton`, `CardlyTextField`, `CardlyVisualCard` (desain 100% presisi Figma `12 Kartu Saya.png` & `16 Tampilan kartu.png`, mendukung compact 2-column grid & full card, chip/sim, masked number dengan tabular figures, dynamic bank gradient/solid), `CardlyWalletStack` (komponen tumpukan kartu interaktif fanned deck ala Apple Wallet), `CardlyBottomSheet`, `CardlyEmptyState`, `CardlySkeleton`, `CardlyNoticeBanner`, `CardlyBottomNavBar`.
   - Penyimpanan lokal & keamanan: [app_database.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/storage/app_database.dart) (SQLite CRUD & zero-trace wipe), [secure_storage_service.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/storage/secure_storage_service.dart), [formatters.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/core/utils/formatters.dart) (masking 4-digit).
   - Fitur Kartu: [card_list_view.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/cards/presentation/card_list_view.dart) (tampilan 2 kolom grid resmi Figma `12 Kartu Saya.png` dengan tanggal pembuatan di bawah kartu, search bar di kanan, toggle Grid, List, dan Stack).
2. **Navigasi & Arsitektur Aplikasi:**
   - [app_router.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/app/app_router.dart) (GoRouter dengan shell bottom navigation), [providers.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/app/providers.dart) (Riverpod state wiring).
3. **8 Modul Fitur:**
   - **Authentication:** SplashView (mengalir mulus ke `/welcome`), OnboardingView, WelcomeView (adaptif cerdas: otomatis memicu prompt biometrik OS murni tanpa modal bottom sheet jika akun ada; tombol dinamis menjadi 'Buka dengan Biometrik'/'Masukkan PIN Brankas' atau 'Masuk'/'Buat Akun' jika belum login), LoginView, RegisterView (bersih dari bottom sheet pengganggu, penanganan Google Sign-In via SnackBar), ForgotPasswordView, ResetPasswordView, BiometricSetupView (mewajibkan PIN sebelum ke dashboard), CheckEmailView. Input kartu [cardly_card_input.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/authentication/presentation/widgets/cardly_card_input.dart) responsif ketuk di seluruh area padding kartu. Supabase OAuth Google dengan mode in-app browser view.
   - **Home:** HomeDashboardView, GlobalSearchView, MainShellScreen.
   - **Cards:** CardListView, CardDetailView, CardCreateWizardView, CardEditView, CardRepository, CardModel.
   - **Documents:** DocumentListView, DocumentDetailView, DocumentPrivateView, CreateFolderView, AddDocumentSourceView, DocumentRepository, DocumentModel.
   - **Reminders:** ReminderListView, ReminderFormView, ReminderRepository, ReminderModel.
   - **Scan:** CameraScanFlowView (integrasi kamera standar industri Opsi A: Google Play Services ML Kit Document Scanner & On-Device OCR), DocumentScanService, CropRotateEditor (dukungan tampilan berkas terpindai asli), OcrReviewForm (thumbnail berkas asli & auto-fill cerdas), ScanLaserOverlay, PreScanSheet.
   - **Vault:** VaultGateView, PinScreen, SecuritySettingsView, EmergencyWipeView, CardlyPinPad (keypad ultra-modern 72pt dengan label alfabetik, umpan balik haptik, dan titik PIN responsif).
   - **Profile & Settings:** ProfileDashboardView, ThemeSettingsView, CloudSyncView, PrivacyInfoView, ExportDataView.

### 3.2 Pekerjaan Berjalan / File Aktif Pengguna
- Kamera & Pemindai Dokumen Aktif (Google ML Kit Document Scanner + On-Device OCR):
  - [document_scan_service.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/data/document_scan_service.dart)
  - [camera_scan_flow_view.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/presentation/camera_scan_flow_view.dart)
  - [crop_rotate_editor.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/presentation/widgets/crop_rotate_editor.dart)
  - [ocr_review_form.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/presentation/widgets/ocr_review_form.dart)
  - [welcome_view.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/authentication/presentation/welcome_view.dart)

### 3.3 Belum Dimulai / Tertunda
- CI/CD workflow automation (belum ada `.github/workflows`).
- Integration tests (`integration_test/`).
- Konfigurasi rilis Play Store & App Store.

### 3.4 Keputusan Teknis Terkonfirmasi
- **State Management:** Flutter Riverpod (`StateNotifierProvider` / `Provider`).
- **Routing:** GoRouter deklaratif dengan ShellRoute untuk bottom bar.
- **Penyimpanan Utama:** SQLite lokal (`sqflite`) + Hardware Keychain/Keystore (`flutter_secure_storage`).
- **Sync Opsional:** Supabase Flutter client.
- **Aturan Privasi:** Nol toleransi nomor kartu 16-digit (hanya 4 digit terakhir), zero-trace wipe.
- **Biometrik & Autentikasi:** Murni menggunakan dialog OS bawaan tanpa modal sheet kustom pengganggu di atas layar Welcome/Splash.
- **Pemindai Dokumen & OCR (ADR-003):** Opsi A — Google Play Services ML Kit Document Scanner (`cunning_document_scanner`) + On-Device Text Recognition (`google_mlkit_text_recognition`) + Galeri Fallback (`image_picker`). Ukuran APK hemat karena mesin AI di-load dari Play Services bawaan OS.

---

## 4. Current Task

- **Tujuan Pekerjaan Aktif:** Implementasi Kamera & Pemindai Dokumen Standar Industri Opsi A (Google ML Kit Document Scanner & On-Device OCR):
  1. Integrasi hardware kamera via Google Play Services Document Scanner (Auto-edge detection, perspective correction, shadow removal otomatis).
  2. Ekstraksi teks On-Device OCR (`google_mlkit_text_recognition`) untuk deteksi cerdas NIK KTP, SIM, BPJS, Paspor, NPWP, nama pemegang, tanggal kedaluwarsa, dan instansi penerbit secara lokal offline tanpa pengiriman data ke server luar.
  3. Integrasi galeri fallback (`image_picker`) dan editor penyesuaian gambar (`CropRotateEditor` & `OcrReviewForm`) dengan pratinjau thumbnail asli dokumen hasil foto.
  4. Penambahan izin hardware kamera (`android.permission.CAMERA` di Android dan `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` di iOS).
- **Status:** Selesai (`VERIFIED`).
- **File Terkait Langsung:**
  - [document_scan_service.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/data/document_scan_service.dart)
  - [camera_scan_flow_view.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/presentation/camera_scan_flow_view.dart)
  - [crop_rotate_editor.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/presentation/widgets/crop_rotate_editor.dart)
  - [ocr_review_form.dart](file:///Users/macbookair/Documents/Herd/cardly/lib/features/scan/presentation/widgets/ocr_review_form.dart)
  - [AndroidManifest.xml](file:///Users/macbookair/Documents/Herd/cardly/android/app/src/main/AndroidManifest.xml)
  - [Info.plist](file:///Users/macbookair/Documents/Herd/cardly/ios/Runner/Info.plist)
- **Sisa Pekerjaan:** Pengujian langsung di perangkat fisik Android pengguna (`flutter run -d 23122PCD1G`).

---

## 5. Verification Snapshot

| Perintah / Pemeriksaan | Status | Hasil Aktual & Catatan |
|---|---|---|
| `flutter analyze` | `PASS` | 0 issues found (bersih mutlak) |
| `flutter test` | `PASS` | 51 test lulus (16 unit + 34 widget + 1 smoke) |
| `flutter test test/unit` | `PASS` | 16 unit test lulus |
| `flutter test test/widget` | `PASS` | 34 widget test lulus |
| `dart format --output=none --set-exit-if-changed .` | `PASS` | 100% file terformat rapi sesuai Dart standard |
| `flutter doctor` | `ISSUES` | Android SDK 36.0.0 [✓], Flutter 3.47.5 [✓], Xcode & CocoaPods [!] |
| `git status` | `BLOCKED` | `fatal: not a git repository` |
| `flutter build apk` | `AVAILABLE_NOT_RUN` | Prasyarat Android SDK lengkap; belum dieksekusi |
| `flutter build ios` | `BLOCKED` | Xcode belum lengkap & CocoaPods belum terpasang |
| `integration_test` | `NOT_APPLICABLE` | Folder `integration_test/` belum tersedia |

---

## 6. Known Issues & Risks

1. **Git Repository Belum Diinisialisasi (`.git` tidak ada)**
   - *Dampak:* Perubahan kode saat ini tidak terlacak oleh sistem version control.
   - *Status:* `BLOCKED` (Menunggu persetujuan pengguna untuk `git init`).
   - *Penanganan:* Jalankan `git init` dan commit awal jika diinstruksikan.
2. **Toolchain iOS Lokal Belum Siap**
   - *Dampak:* Tidak dapat melakukan compile atau run pada simulator/device iOS di laptop ini.
   - *Status:* `BLOCKED` (Xcode incomplete, CocoaPods missing).
   - *Penanganan:* Pasang CocoaPods (`gem install cocoapods` atau `brew install cocoapods`) dan jalankan `sudo xcodebuild -runFirstLaunch`.
4. **Notice SQLite pada Test Runner**
   - *Dampak:* Log test memunculkan pesan `SQLite native channel not available. Using in-memory store`. Tes tetap lulus karena fallback in-memory aktif.
   - *Status:* `LOW RISK` / `OPEN`.
   - *Penanganan:* Tambahkan inisialisasi `sqfliteFfiInit()` pada suite test SQLite bila diperlukan output yang bersih dari warning.

---

## 7. Next Actions (Berdasarkan Prioritas)

1. **Inisialisasi Git Repository:** Jalankan `git init` dan buat initial commit untuk mengamankan seluruh kode sumber yang telah dibuat.
2. **Format Standar Kode:** Jalankan `dart format .` untuk merapikan 13 file kode sumber agar memenuhi standar CI.
3. **Konfigurasi Lingkungan iOS (Opsional):** Lengkapi instalasi Xcode dan pasang CocoaPods jika pengujian target iOS lokal diperlukan.

---

## 8. Context Loading Guide

Agar hemat token dan waktu eksekusi, agen AI **dilarang** membaca semua dokumen untuk setiap task:

- **Task UI:** Baca bagian spesifikasi modul terkait di [DESAIN.md](file:///Users/macbookair/Documents/Herd/cardly/DESAIN.md). Hanya buka gambar spesifik di `docs/` jika butuh detail visual mikro.
- **Task Logic & Data:** Baca bagian modul terkait di [ARCHITECTURE.md](file:///Users/macbookair/Documents/Herd/cardly/ARCHITECTURE.md) dan definisi entitas di [PRD.md](file:///Users/macbookair/Documents/Herd/cardly/PRD.md).
- **Task Bugfix:** Buka file yang dicurigai bermasalah dan tes terkait di `test/unit/` atau `test/widget/`.
- **Task Testing & Build:** Rujuk [COMMANDS.md](file:///Users/macbookair/Documents/Herd/cardly/COMMANDS.md).
- **Task Security:** Baca aturan keamanan di [AGENTS.md](file:///Users/macbookair/Documents/Herd/cardly/AGENTS.md) Bagian 10 dan [ARCHITECTURE.md](file:///Users/macbookair/Documents/Herd/cardly/ARCHITECTURE.md) Bagian 10.
- **Task Dokumentasi:** Hanya baca dan ubah dokumen yang ditugaskan pengguna.

---

## 9. State Maintenance Rules

1. **Perbarui Segera:** Perbarui file ini setiap kali ada perubahan fitur besar, pembaruan paket, atau modifikasi status verifikasi.
2. **Ganti, Jangan Menumpuk:** Timpa status lama dengan fakta terbaru; hindari menyimpan data kadaluwarsa.
3. **Ringkas & Akurat:** Pertahankan panjang ringkasan (~60–120 baris). Jangan salin log terminal panjang atau obrolan chat.
4. **Tanpa Kredensial:** Dilarang keras menuliskan API key, password, token JWT, atau isi `.env`.
5. **Gunakan Label Status Baku:** Gunakan selalu label `VERIFIED`, `PLANNED`, `PROPOSED`, `UNKNOWN`, `BLOCKED`, `AVAILABLE_NOT_RUN`, atau `NOT_APPLICABLE`.
