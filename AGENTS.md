# AI Agent Operational Playbook - Cardly Project

Dokumen ini merupakan panduan instruksi operasional permanen bagi setiap AI coding agent (termasuk Antigravity / Claude / Gemini / subagent) yang bekerja di repositori Cardly. Dokumen ini dirancang untuk menjaga konsistensi, efisiensi token, kepatuhan arsitektur, dan fidelitas desain yang mutlak tanpa regresi.

---

## 1. Project Identity

| Atribut | Nilai |
|---|---|
| **Nama Proyek** | Cardly |
| **Deskripsi** | Personal Organizer & Private Space untuk kartu, dokumen penting, dan pengingat masa berlaku. |
| **Framework Utama** | Flutter (Dart 3.x, Null Safety) |
| **Target Platform** | iOS & Android (Mobile) |
| **Sumber Kebenaran Desain** | 147 file artefak desain Figma di `docs/` |
| **Sumber Kebenaran Produk** | [PRD.md](file:///Users/macbookair/Documents/Herd/cardly/PRD.md) |
| **Sumber Kebenaran Arsitektur**| [ARCHITECTURE.md](file:///Users/macbookair/Documents/Herd/cardly/ARCHITECTURE.md) |
| **Sumber Kebenaran Visual**    | [DESAIN.md](file:///Users/macbookair/Documents/Herd/cardly/DESAIN.md) |

---

## 2. Instruction Hierarchy (Hierarki Sumber Kebenaran)

Jika terjadi pertentangan informasi selama pengerjaan, AI agent wajib menyelesaikan berdasarkan urutan prioritas berikut:

1. **Instruksi Eksplisit Pengguna yang Terbaru:** Arahan langsung dari sesi chat aktif pengguna saat ini (selama tidak melanggar batasan keselamatan sistem).
2. **`AGENTS.md` (Dokumen ini):** Aturan kerja, batasan operasional, dan protokol efisiensi agent.
3. **`PRD.md`:** Ruang lingkup fitur, batasan bisnis, dan kriteria penerimaan fungsional.
4. **`DESAIN.md`:** Spesifikasi visual, design tokens, kurva animasi, dan komponen UI.
5. **`ARCHITECTURE.md`:** Pola arsitektur, struktur folder modular, dan strategi data lokal.
6. **Source Code & Konfigurasi Aktual:** Kondisi nyata di repositori saat ini.
7. **Inferensi atau Catatan AI:** Hipotesis agen yang belum diverifikasi (tidak mengikat).

> [!IMPORTANT]
> **Aturan Resolusi Konflik:** Jika dua sumber bertentangan (misal: desain menunjukkan suatu tombol namun PRD melarangnya), **JANGAN diam-diam memilih salah satu**. Identifikasi perbedaannya secara eksplisit, jelaskan dampaknya kepada pengguna, dan minta konfirmasi sebelum melanjutkan.

---

## 3. Mandatory Preflight (Prosedur Wajib Sebelum Mulai Task)

Sebelum menulis kode atau menjalankan tool perombakan:
1. **Pahami Kategori Task:** Tentukan klasifikasi task sesuai Bagian 4.
2. **Baca Bagian Dokumentasi yang Relevan Saja:**
   - Jika mengerjakan UI: Baca bagian modul terkait di `DESAIN.md` dan buka gambar terkait di `docs/`.
   - Jika mengerjakan Logic/Data: Baca bagian terkait di `ARCHITECTURE.md` dan entitas di `PRD.md`.
   - *Jangan membaca ulang seluruh isi 4 dokumen untuk task kecil.*
3. **Cek Status Repositori:** Jalankan pemeriksaan git status singkat untuk mengetahui file yang sedang dimodifikasi pengguna.
4. **Gunakan Reusable Components yang Sudah Ada:** Cari implementasi widget di `lib/core/widgets/` sebelum membuat komponen baru.
5. **Hindari Menambah Package Tanpa Izin:** Periksa apakah kemampuan sudah disediakan oleh Flutter core atau package yang telah disetujui di `ARCHITECTURE.md`.

---

## 4. Task Classification

Setiap permintaan kerja wajib diklasifikasikan ke dalam salah satu kategori berikut:

| Kategori | Batasan Operasional | Risiko | Tindakan Verifikasi |
|---|---|---|---|
| `analysis` | Hanya membaca file dan memberikan laporan. **Dilarang keras mengubah file apapun.** | Nol | Verifikasi kelengkapan temuan |
| `documentation`| Hanya membuat/memperbarui file dokumentasi (`.md`). **Dilarang mengubah kode aplikasi.** | Sangat Rendah | Validasi link markdown & konsistensi istilah |
| `ui` | Mengimplementasikan widget / tampilan sesuai `DESAIN.md`. Gunakan design tokens. | Rendah | Widget test, verifikasi mode terang & gelap, cek ukuran 360 dp |
| `feature` | Membangun fungsionalitas end-to-end (UI, logic, model, repo). | Sedang | Unit test logika, widget test, verifikasi alur state |
| `bugfix` | Memperbaiki cacat kode yang ada. Perubahan sespesifik mungkin. | Sedang | Reproduksi bug $\rightarrow$ perbaikan $\rightarrow$ test kelulusan |
| `refactor` | Mengubah struktur tanpa mengubah perilaku eksternal. Minta konfirmasi jika skala besar. | Tinggi | Seluruh automated test harus tetap lulus |
| `security` | Audit atau implementasi keamanan (Brankas, biometric, wiping). | Kritis | Verifikasi zero-leakage pada logging & storage |
| `architecture` | Mengubah struktur dasar framework / router / DB. Wajib persetujuan tertulis. | Kritis | Analisis trade-off menyeluruh sebelum eksekusi |

---

## 5. Change Management & Code Hygiene

1. **Prinsip Perubahan Terkecil (*Minimal Viable Change*):** Jangan merombak file secara menyeluruh (*mass rewrite*) jika hanya memperbaiki atau menambahkan sebagian kecil kode.
2. **Pertahankan Kode Pengguna:** Jangan menghapus komentar, struktur, atau fitur eksperimental yang sengaja dibuat oleh pengguna kecuali diinstruksikan eksplisit.
3. **Dilarang Merusak Kontrak Publik:** Jangan mengubah nama method, parameter, atau interface repository publik yang sedang digunakan modul lain tanpa memperbarui modul terkait secara terpadu.
4. **Preservasi Dokumentasi:** Jangan menghapus atau menimpa dokumen dasar (`PRD.md`, `DESAIN.md`, `ARCHITECTURE.md`, `AGENTS.md`) tanpa alasan substantif.

---

## 6. Coding Standards (Dart & Flutter)

1. **Dart Idiomatis & Null Safety:**
   - Gunakan tipe data eksplisit jika menambah kejelasan kode.
   - Hindari penggunaan operator *bang* (`!`) tanpa pengecekan null yang pasti. Gunakan *null-aware operators* (`?.`, `??`).
2. **Kerapian Widget Tree:**
   - Utamakan widget kecil dengan tanggung jawab tunggal.
   - Pecah widget yang panjangnya melebihi 100 baris menjadi sub-widget terpisah atau private helper classes.
   - Gunakan `const` constructor di mana pun memungkinkan untuk mengoptimalkan memori dan mencegah rebuild sia-sia.
3. **Pemisahan UI dan Logika Bisnis:**
   - Dilarang keras menempatkan kalkulasi rumit, pembacaan database, atau request IO di dalam method `build()`.
   - Gunakan controller / state notifier untuk memegang status layar.
4. **Penanganan Error Eksplisit:**
   - Tangani setiap `try-catch` secara bermakna. Jangan menelan error diam-diam dengan blok catch kosong (`catch (e) {}`).
   - Ubah exception menjadi kegagalan yang memiliki representasi UI bersahabat.

---

## 7. Design Fidelity Rules (Kepatuhan Desain)

Saat mengimplementasikan antarmuka dari `docs/`:

1. **Wajib Rujukan Gambar Desain:** Sebelum membuat tampilan, periksa file PNG terkait di folder `docs/`.
2. **Gunakan Nilai Terverifikasi dari `DESAIN.md`:**
   - Gunakan token warna resmi (Lime `#C8F45A`, Ink `#171717`, Charcoal `#252525`, White `#FFFFFF`, Mist `#F5F5F3`, Soft Gray `#EBEBE8`).
   - Terapkan ritme 8-point (4, 8, 12, 16, 24, 32, 40, 48 pt). Inset layar standar adalah 24 pt.
   - Terapkan radius baku: Control = 12 pt, Input = 16 pt, Card = 24 pt, Modal Sheet = 32 pt, Pill = 999 pt.
3. **Aturan Tegas Warna Lime:** Jangan pernah merender teks berwarna lime di atas latar belakang putih/terang. Teks di atas latar Lime wajib menggunakan warna gelap Ink (`#171717`).
4. **Dukungan Dual-Theme Seimbang:** Selalu sediakan dan uji tampilan untuk Mode Terang dan Mode Gelap (*Gelap, bukan sekadar inversi*).
5. **Dukungan Layar Sempit (360 dp):** Pastikan komponen tidak menyebabkan *overflow* pada lebar 360 pt (`docs/5. Home/69 Beranda • 360.png`).
6. **Status Lengkap Antarmuka:** Setiap layar form atau daftar wajib menangani:
   - Keadaan memuat (*Skeleton Pulse 1.000 ms*).
   - Keadaan kosong (*Empty State* dengan ilustrasi ikonik dan tombol aksi).
   - Keadaan terjadi kesalahan (*Error feedback banner*).

---

## 8. Flutter-Specific Best Practices

1. **Async & BuildContext Safety:**
   - Jangan gunakan `BuildContext` setelah *asynchronous gap* (`await`) tanpa memeriksa `if (!mounted) return;` terlebih dahulu.
2. **Resource Management:**
   - Selalu `dispose()` objek berat seperti `TextEditingController`, `AnimationController`, `StreamSubscription`, dan `CameraController`.
3. **Tabular Numerals pada Angka:**
   - Terapkan fitur font tabular numerals (`FontFeature.tabularFigures()`) pada teks nomor kartu tersamar dan tanggal kedaluwarsa agar perataan visual tidak goyang saat angka berubah.
4. **Aksesibilitas (A11y):**
   - Pastikan area sentuh tombol dan elemen interaktif minimal $44 \times 44$ pt.
   - Sertakan teks `semanticsLabel` pada ikon aksi penting.

---

## 9. Dependency & Package Policy

1. **Kebijakan Default:** Jangan menambahkan package pihak ketiga baru sebelum memeriksa apakah fungsionalitas tersebut dapat dicapai menggunakan framework bawaan Flutter/Dart.
2. **Daftar Package yang Diizinkan:** Hanya package yang tercantum dengan status `USULAN` pada Bagian 14 di `ARCHITECTURE.md` yang boleh dipertimbangkan.
3. **Prosedur Pengajuan:** Jika agent merasa membutuhkan package baru di luar daftar:
   - Jelaskan alasan mengapa solusi lokal tidak mencukupi.
   - Jelaskan ukuran binary tambahan dan rekam jejak pemeliharaan package.
   - Dapatkan konfirmasi pengguna sebelum menambahkan baris ke `pubspec.yaml`.

---

## 10. Security & Privacy Rules (Nol-Toleransi Pelanggaran)

1. **Larangan Kredensial Perbankan:**
   - Dilarang membuat form input atau properti model data untuk: Nomor kartu 16 digit lengkap, CVV/CVC, PIN perbankan, atau kode OTP kartu kredit.
   - Field kartu pembayaran hanya boleh menampung 4 digit angka terakhir.
2. **Larangan Logging Data Sensitif:**
   - Dilarang memanggil `print()`, `debugPrint()`, atau logger yang mencetak nama dokumen pribadi, isi OCR, nomor kartu, atau email pengguna ke console.
3. **Kerahasian Kunci & PIN:**
   - Jangan pernah melakukan *hardcode* kata sandi, kunci enkripsi, atau token rahasia di dalam kode Dart.
   - Simpan kredensial aplikasi di Secure Storage berbasis hardware.
4. **Privasi Layar (App Switcher Shield):**
   - Pastikan permukaan sensitif disamarkan saat aplikasi berpindah ke latar belakang.

---

## 11. Token Efficiency Protocol (Efisiensi Konteks AI)

Agar sesi percakapan tetap cepat, hemat token, dan tidak melampaui batas konteks:

1. **Fokus dan Ringkas:**
   - Jangan mencetak seluruh isi file yang baru dibuat atau diubah ke dalam pesan chat. Cukup laporkan ringkasan perubahan dan file link yang dapat diklik.
2. **Pencarian Terarah:**
   - Gunakan `grep_search` atau `list_dir` spesifik daripada memindai pohon folder secara rekursif tanpa filter.
   - Jangan memindai folder `.dart_tool`, `.git`, `build/`, `.gradle`, atau cache dependency pihak ketiga.
3. **Jangan Melakukan Audit Berulang:**
   - Hasil audit 147 file desain dan repositori telah terekam secara permanen di `PRD.md`, `DESAIN.md`, dan `ARCHITECTURE.md`. Gunakan ketiga file tersebut sebagai sumber acuan cepat daripada memindai ulang seluruh gambar di `docs/`.
4. **Rencana Singkat Sebelum Eksekusi:**
   - Untuk tugas sederhana, langsung kerjakan tanpa membuat proposal bertele-tele.
   - Untuk tugas arsitektur kompleks, berikan 3–5 poin rencana kerja ringkas sebelum memulai.

---

## 12. Verification & Quality Assurance Rules

Setelah menyelesaikan pekerjaan implementasi:

1. **Static Analysis:** Jalankan `flutter analyze` untuk memastikan tidak ada error kompilasi, tipe data salah, atau *unused imports*.
2. **Format Standar:** Pastikan kode diformat rapi dengan `dart format .`.
3. **Automated Tests:** Jalankan test terkait dengan `flutter test`. Laporkan jika ada test yang gagal dan segera perbaiki.
4. **Validasi Markdown (untuk task dokumentasi):**
   - Pastikan seluruh link menggunakan path relatif yang valid.
   - Pastikan tidak ada karakter syntax yang merusak rendering markdown.
   - Pastikan tabel terformat simetris.

---

## 13. Definition of Done (DoD)

Sebuah task dinyatakan **SELESAI** jika memenuhi seluruh kriteria berikut:
- [ ] Kebutuhan fungsional task terpenuhi sesuai acceptance criteria di `PRD.md`.
- [ ] Antarmuka mematuhi design tokens dan kurva gerak di `DESAIN.md`.
- [ ] Kode terstruktur rapi mengikuti modul di `ARCHITECTURE.md`.
- [ ] Tidak ada pelanggaran privasi atau pembocoran data sensitif.
- [ ] `flutter analyze` bersih dari warning dan error fatal.
- [ ] Automated tests terkait lulus tanpa regresi.
- [ ] Dokumentasi terkait diperbarui jika ada keputusan yang berubah.

---

## 14. Standard Final Response Format

Setiap kali agent menyelesaikan task, format laporan akhir wajib ringkas dan mengikuti struktur berikut:

1. **Status:** `Selesai` | `Sebagian` | `Terblokir`
2. **Ringkasan Perubahan:** File apa saja yang dibuat/dimodifikasi beserta tujuannya (gunakan file markdown link).
3. **Verifikasi yang Dilakukan:** Hasil pemeriksaan static analysis, test runner, atau audit dokumen yang benar-benar dijalankan.
4. **Risiko / Catatan Khusus:** Hal penting atau keterbatasan yang perlu diketahui pengguna.
5. **Next Step:** 1–2 rekomendasi aksi paling relevan untuk sesi berikutnya.
