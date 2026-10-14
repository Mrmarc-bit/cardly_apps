# Design Specification Document - Cardly

## 1. Design Overview

| Atribut | Detail |
|---|---|
| **Aplikasi** | Cardly (Personal Organizer & Private Space) |
| **Versi Desain** | Design Handoff 1.0 (2026) |
| **Sumber Kebenaran Desain** | 147 file gambar PNG yang diekspor dari Figma dan tersimpan di `docs/` |
| **Bahasa Antarmuka** | Bahasa Indonesia (primer) dengan opsi English (`docs/11. Profile and Settings/70 Bahasa.png`) |
| **Ukuran Layar Desain** | **Utama:** 393 × 852 pt (iPhone 14/15/16 Pro standard ratio) |
| **Adaptasi Responsif** | **Adaptasi 360:** 360 × 852 pt (`docs/5. Home/69 Beranda • 360.png`) |
| **Hubungan dengan PRD** | Menjadi spesifikasi implementasi visual dan interaktif untuk seluruh Functional Requirements di [PRD.md](file:///Users/macbookair/Documents/Herd/cardly/PRD.md). |

---

## 2. Design Source Inventory

Seluruh folder dan file desain di `docs/` telah diperiksa secara lengkap:

| No | Folder Relatif | Jumlah File | Kategori & Karakteristik | Status Audit |
|---|---|---|---|---|
| 1 | `docs/1. Cover.png` | 1 | Cover produk, identitas visual, dan ringkasan handoff | TERVERIFIKASI (Diperiksa) |
| 2 | `docs/2. Foundations/` | 1 | Foundations visual lengkap (warna, tipe, ritme 8-pt, bentuk & radius) | TERVERIFIKASI (Diperiksa) |
| 3 | `docs/3. Components/` | 2 | `Components.png` & `Native Component Library.png` (62 varian native) | TERVERIFIKASI (Diperiksa) |
| 4 | `docs/4. Authentication/` | 30 | Alur Autentikasi lengkap (Splash, Onboarding, Login, Register, Biometric, Terang & Gelap) | TERVERIFIKASI (Diperiksa) |
| 5 | `docs/5. Home/` | 19 | Beranda, Pencarian, Global State (Empty, Loading, Error, Success), Adaptasi 360 | TERVERIFIKASI (Diperiksa) |
| 6 | `docs/6. Cards/` | 28 | Alur Kartu Saya (Katalog, Tambah 4 langkah, Detail, Edit, Hapus, Arsip, Terang & Gelap) | TERVERIFIKASI (Diperiksa) |
| 7 | `docs/7. Documents/` | 20 | Alur Dokumen (Daftar, Tambah multi-metode, Buka pribadi, Detail manual, Ganti berkas) | TERVERIFIKASI (Diperiksa) |
| 8 | `docs/8. Scan Flow/` | 14 | Alur Scan (Kamera, Izin ditolak, Potong & Putar, Tinjau OCR, Terang & Gelap) | TERVERIFIKASI (Diperiksa) |
| 9 | `docs/9. Vault and Scurity/` | 12 | Catatan nama folder di disk: `9. Vault and Scurity` (Brankas, Keamanan, Hapus data lokal/akun) | TERVERIFIKASI (Diperiksa) |
| 10 | `docs/10. Reminders/` | 10 | Modul Pengingat (Daftar, Detail hitung hari, Tambah & Edit pengingat) | TERVERIFIKASI (Diperiksa) |
| 11 | `docs/11. Profile and Settings/` | 24 | Profil, Edit profil, Tampilan tema, Ekspor data JSON, Privasi, Bantuan, Notifikasi, Bahasa, Backup, Tentang | TERVERIFIKASI (Diperiksa) |
| 12 | `docs/12. Prototype Flows/` | 2 | `Prototype Flows & Motion Spec.png` & `Motion/Splash demonstration.png` | TERVERIFIKASI (Diperiksa) |
| **TOTAL** | **12 Area Desain** | **147 File** | **Semua layar memiliki pasangan Terang dan Gelap (kecuali spesifikasi teknis)** | **100% TERINVENTARISIR** |

---

## 3. Visual Identity & Brand Philosophy

Berdasarkan `docs/1. Cover.png` dan `docs/2. Foundations/Foundations.png`:
- **Prinsip Utama:** *"Sederhana. Sengaja. Konsisten."* / *"Jelas tanpa berlebihan"*.
- **Karakter Visual:** Modern, tenang (*serene*), tanpa gradien dekoratif murahan (*"Tanpa glow. Tanpa gradient dekoratif"*), mengandalkan pemisahan level permukaan (*elevation through surface shifts*).
- **Aksen Khas:** Warna **Lime** (`#C8F45A`) digunakan secara selektif sebagai aksen status dan penegas tombol utama.
- **Aturan Tegas Warna Lime:** *"Lime hanya sebagai aksen dan permukaan fitur. Jangan gunakan teks lime di atas putih."* Teks di atas tombol Lime selalu menggunakan warna gelap Ink (`#171717`).

---

## 4. Design Foundations

### 4.1 Token Warna Merek & Status [TERVERIFIKASI]
Sumber: `docs/2. Foundations/Foundations.png`.

| Nama Token | Nilai Hex | Peran & Penggunaan | Status |
|---|---|---|---|
| **Lime** | `#C8F45A` | Brand Accent, CTA Utama, Pill Aktif, Indikator Seleksi | TERVERIFIKASI |
| **Ink** | `#171717` | Teks Primer (Terang), Background Canvas (Gelap), Tombol Destruktif Primer | TERVERIFIKASI |
| **Charcoal** | `#252525` | Background Card (Gelap), Card Varian Gelap | TERVERIFIKASI |
| **White** | `#FFFFFF` | Background Card (Terang), Teks Primer (Gelap) | TERVERIFIKASI |
| **Mist** | `#F5F5F3` | Background Canvas (Terang), Latar Belakang Input | TERVERIFIKASI |
| **Soft Gray** | `#EBEBE8` | Elevated Surface (Terang), Border Netral, Tombol Sekunder | TERVERIFIKASI |
| **Medium Gray** | `#8B8B87` | Teks Tersier, Placeholder, Divider Halus | TERVERIFIKASI |
| **Muted** | `#666666` | Teks Sekunder (Terang), Ikon Inaktif | TERVERIFIKASI |
| **Elevated Dark** | `#303030` | Elevated Surface (Gelap), Border Netral Gelap | TERVERIFIKASI |
| **Text Secondary Dark** | `#B6B6B6` | Teks Sekunder (Gelap) | TERVERIFIKASI |
| **Success** | `#367A48` | Indikator Berhasil, Tersimpan, Selesai | TERVERIFIKASI |
| **Warning** | `#9A6B18` | Indikator Perlu ditinjau, Masa berlaku mendekati | TERVERIFIKASI |
| **Error / Destructive** | `#B93838` | Validasi gagal, Hapus kartu/dokumen permanen | TERVERIFIKASI |
| **Info** | `#3B6D8C` | Konteks edukasi privasi dan keamanan | TERVERIFIKASI |

### 4.2 Semantik Terang vs Gelap [TERVERIFIKASI]
*"Gelap, bukan inversi"* - Mode gelap Cardly bukan merupakan pembalikan warna (*invert*) biner, melainkan pemetaan kedalaman yang disesuaikan secara khusus:

| Lapisan Elemen | Mode Terang (Light) | Mode Gelap (Dark) |
|---|---|---|
| **Canvas / Background Layar** | `Mist` (`#F5F5F3`) | `Ink` (`#171717`) |
| **Card / Surface Konten** | `White` (`#FFFFFF`) | `Charcoal` (`#252525`) |
| **Elevated Surface (Modal / Bar)** | `Soft Gray` (`#EBEBE8`) | `Elevated Dark` (`#303030`) |
| **Teks Primer** | `Ink` (`#171717`) | `White` (`#FFFFFF`) |
| **Teks Sekunder** | `Muted` (`#666666`) | `#B6B6B6` |
| **Teks di atas Aksen Lime** | `Ink` (`#171717`) | `Ink` (`#171717`) |
| **Border / Pemisah** | `#EBEBE8` (1 px solid) | `#303030` (1 px solid) |

### 4.3 Typography Scale (Inter Font Family) [TERVERIFIKASI]
Font resmi: **Inter**. Angka wajib menggunakan **Tabular Numerals** (*Monospaced Numbers*) pada implementasi Flutter. Line height dasar: $1.4$.

| Role Nama | Ukuran / Line Height | Font Weight | Tracking | Catatan Penggunaan |
|---|---|---|---|---|
| **Display** | 36–44 pt / 44 pt | SemiBold (600) | -1.1 px | Judul Onboarding, Headline Cover |
| **Large Heading** | 28–32 pt / 36 pt | SemiBold (600) | -0.8 px | Judul Utama Layar (Beranda, Welcome) |
| **Page** | 24–28 pt / 32 pt | SemiBold (600) | -0.5 px | Header Halaman / Modul |
| **Section** | 18–20 pt / 24 pt | SemiBold (600) | -0.2 px | Sub-judul Bagian Form / Bagian Daftar |
| **Body** | 16 pt / 22 pt | Regular (400) | 0.0 px | Teks Paragraf Utama, Isi Deskripsi |
| **Compact Body** | 14 pt / 20 pt | Regular (400) | 0.0 px | Keterangan Tambahan, Subtitle Baris |
| **Caption** | 12 pt / 16 pt | Regular (400) | +0.2 px | Label Kategori Kecil, Tanggal, Stempel |
| **Tiny Label** | 10–11 pt / 14 pt | Medium (500) | +0.4 px | Tag Status, Badge Belum Terverifikasi |

### 4.4 8-Point Rhythm & Dimensi Tata Letak [TERVERIFIKASI]
- Skala Spacing: **4 pt, 8 pt, 12 pt, 16 pt, 24 pt, 32 pt, 40 pt, 48 pt**.
- Inset Layar Default: **24 pt** (horizontal padding konten).
- Area Status Bar: **44 pt** (tinggi aman atas).
- Gesture Bar Bawah: **34 pt** (tinggi aman bawah).
- Form panjang wajib menggunakan halaman yang memanjang (*single continuous scroll*), tanpa nested scrolling terputus.

### 4.5 Bentuk, Radius, & Elevasi [TERVERIFIKASI]
- **Control / Pill Kecil:** `12 pt` (Tombol filter, chip kategori, badge).
- **Input Field:** `16 pt` (Semua textfield, dropdown, selector tanggal).
- **Card:** `24 pt` (Kartu pembayaran, kartu dokumen baris, container utama).
- **Feature Card / Modal:** `32 pt` (Card fitur utama, bottom sheet sudut atas).
- **Pill / Floating:** `999 pt` / Full Circular (Tombol aksi utama, FAB lingkaran, switch pill).
- **Modal Scrim:** Hitam transparan 50% (`Colors.black.withOpacity(0.50)`).
- **Elevation / Shadow:** Bebas glow. Menggunakan perbedaan saturasi permukaan dan border hairline netral.

---

## 5. Reusable Component Library

Berdasarkan `docs/3. Components/Components.png` dan `Native Component Library.png` (62 varian native):

### 5.1 Tombol (Buttons)
1. **Primary Button:** Latar Lime (`#C8F45A`), Teks Ink (`#171717`, 16 pt SemiBold), Radius 999/16 pt, Tinggi 52 pt.
   - States: *Default*, *Hover/Pressed* (opacity 0.88, scale 0.98), *Disabled / Tidak tersedia* (`#EBEBE8` dengan teks `#8B8B87`), *Loading / Memproses...* (spinner sirkular netral).
2. **Secondary Button:** Latar Soft Gray (`#EBEBE8`), Teks Ink (`#171717`).
3. **Quiet / Ghost Button:** Tanpa latar belakang, border transparan, teks Ink atau Lime.
4. **Destructive Button:** Latar Merah Destruktif (`#B93838`), Teks Putih (`#FFFFFF`). Digunakan khusus dialog konfirmasi hapus permanen.
5. **Icon Action Button:** Tombol sirkular (+) atau tombol kecil dengan ikon 20 pt.

### 5.2 Input Formulir (Form Controls)
- **Tinggi Input:** 56 pt dengan border radius 16 pt.
- **States:**
  - *Default:* Latar `Mist`/`White`, border 1px `#EBEBE8`.
  - *Focus:* Border 1.5px `#171717` (Terang) atau `#FFFFFF` (Gelap). Catatan desain: *"Fokus jelas, tanpa glow"*.
  - *Filled:* Teks terisi dengan label mengecil di atas (*floating label*).
  - *Error:* Border 1.5px `#B93838`, pesan error di bawah input dengan teks merah 12 pt.
  - *Disabled:* Latar `#EBEBE8`, teks `#8B8B87`.
  - *Password:* Trailing toggle icon mata (sembunyikan / tampilkan karakter).

### 5.3 Payment Cards (Kartu Representasi Visual)
- **Rasio Dimensi:** Standar kartu kredit (85.60 × 53.98 mm, rasio $\approx 1.58:1$), radius sudut 24 pt.
- **4 Preset Warna:**
  1. *Lime:* Latar `#C8F45A`, teks `#171717`.
  2. *Black:* Latar `#171717`, teks `#FFFFFF`.
  3. *White:* Latar `#FFFFFF`, border `#EBEBE8`, teks `#171717`.
  4. *Gray:* Latar `#EBEBE8`, teks `#171717`.
- **Elemen Tampilan:** Kategori badge (kiri atas), Ikon Contactless (kanan atas), Nama Panggilan (18 pt SemiBold), Penerbit (12 pt), 4 Digit Masking (`•••• 4582`), Logo Jaringan (Visa / Mastercard) di kanan bawah.

### 5.4 Documents & List Rows
- **Document List Tile:** Tinggi dinamis, radius 16 pt, ikon jenis file di kiri (PDF / Gambar / Identitas), Judul dokumen (16 pt SemiBold), Subtitle (Kategori • Ekstensi • Tanggal), Trailing chevron `>`.
- **Masked Document Preview Card:** Pratinjau dokumen tersamar dengan avatar siluet abstrak dan baris garis horizontal pengganti teks, menandakan data disamarkan sebelum diotentikasi.

### 5.5 Navigation Bar (Bottom Navigation)
- **5 Tujuan Tetap:**
  1. `Beranda` (Ikon Home)
  2. `Kartu` (Ikon Card)
  3. `Dokumen` (Ikon File/Document)
  4. `Brankas` (Ikon Lock)
  5. `Profil` (Ikon Person)
- **Spesifikasi Bar:** Tinggi 80 pt (termasuk safe area bawah), background `#FFFFFF` (Terang) / `#171717` (Gelap), border atas 1px `#EBEBE8` / `#303030`.
- **Indikator Aktif:** Chip pill latar Lime (`#C8F45A`) melingkupi ikon tab yang sedang aktif. Teks label aktif tebal 11 pt. Tab inaktif berwarna abu-abu netral tanpa pill. Area sentuh tiap tab minimal $44 \times 44$ pt.

### 5.6 Status Indicators & Banners
- **Banner Peringatan:** Kotak radius 16 pt bergaris tepi tipis dengan ikon peringatan di kiri. Teks informatif: *"Pesan dengan ikon, bukan warna saja"* (kepatuhan aksesibilitas buta warna).
- **Banner Edukasi Keamanan:** Ikon perisai centang, latar lembut, teks ramah privasi.

### 5.7 Dialogs & Bottom Sheets
- **Bottom Sheet Tindakan:** Sudut atas membulat 32 pt, bar pegangan (*drag handle*) 4 × 36 pt di tengah atas, judul tebal, deskripsi aksi, tombol primer/destruktif, dan tombol "Batal".
- **Modal Dialog Konfirmasi:** Kotak tengah layar radius 24 pt, tombol primer penuh di atas tombol batal.

### 5.8 Empty States, Skeleton, & Toast
- **Empty State:** Ikon ilustrasi dalam kotak bulat Lime (radius 24 pt), judul tegas (*"Belum ada dokumen"*, *"Tidak ada hasil"*), deskripsi instruksi, dan tombol aksi pembuat item baru.
- **Skeleton Loader:** Container abu-abu lembut radius 16/24 pt dengan animasi pulsasi tenang (*pulse opacity 0.65–1.00*), bukan shimmer berkilau tinggi yang agresif.
- **Snack/Toast Bar:** Latar hitam pekat (`#171717` / `#252525`), teks putih, dengan tombol "Urungkan" di kanan untuk aksi yang dapat dibatalkan (arsip/favorit).

---

## 6. Screen Specifications by Feature Module

### 6.1 Authentication Module (`docs/4. Authentication/`)
- **01 Splash:** Latar polos bersih, logo Cardly tengah (ikon tumpukan dua kartu hitam & hijau lime), slogan *"Your cards. Your documents. One private space."*, indikator garis lime.
- **02–04 Onboarding (Kartu, Dokumen, Privasi):** Menampilkan ilustrasi kartu bertumpuk, kartu identitas, dan gembok brankas hijau lime. Indikator 3 titik di bawah, tombol "Lanjut" (Lime), tombol "Lewati" di kanan atas bar status.
- **05 Welcome:** Pintu masuk utama aplikasi. Judul *"Ruang pribadi untuk yang penting"*. Tombol primer "Masuk", tombol sekunder "Buat Akun", serta banner penafian resmi: *"Bukan bank. Bukan alat pembayaran. Cardly membantu mengatur kartu dan dokumen. Jangan simpan CVV, PIN, atau kata sandi"*.
- **06 Masuk:** Form login ringkas: Email, Kata Sandi, Checkbox "Ingat saya", Tautan "Lupa kata sandi?", Tombol "Masuk", Tautan footer "Belum punya akun? Buat Akun".
- **07 Buat Akun:** Nama lengkap, Email, Kata sandi (min 12 karakter), Indikator kekuatan kata sandi 3 bar hijau, Konfirmasi kata sandi, Checkbox persetujuan Ketentuan & Kebijakan Privasi, Tombol "Buat Akun".
- **08 Lupa Kata Sandi & 41 Periksa Email:** Input email terdaftar $\rightarrow$ Konfirmasi pengiriman instruksi tanpa membuka status registrasi email.
- **61–62 Kunci Biometrik & Setup PIN:** Permintaan aktivasi Face ID / Fingerprint dengan jaminan privasi: *"Cardly meminta hasil autentikasi sistem, bukan menampilkan data biometrik Anda"*. Jika perangkat tidak mendukung biometrik, fallback otomatis ke layar "Biometrik tidak tersedia" dengan opsi "Atur PIN aplikasi".

### 6.2 Home Module (`docs/5. Home/`)
- **10 Beranda (Terang) & 11 Beranda (Gelap):**
  - Header: Salam dinamis (*"Selamat pagi Ma'ruf"*), ikon notifikasi lonceng (dengan dot badge jika ada jadwal), avatar inisial profil lingkaran (*"M"*).
  - Ringkasan Dompet (*Wallet Summary Card*): Angka total kartu, angka total dokumen, badge "Disamarkan".
  - Kartu Pilihan (*Featured Cards Carousel*): Slider horizontal kartu pembayaran/identitas dengan tombol "Lihat Detail" dan "Lihat semua".
  - Aksi Cepat (*Quick Action Grid*): 4 tombol pintas: `Tambah Kartu`, `Scan Dokumen`, `Buat Folder`, `Pengingat`.
  - Baru Ditambahkan: Daftar ringkas 3 berkas terakhir yang baru disimpan.
- **26–27 Pencarian Global:** Field pencarian instan dengan tag filter (*Semua, Kartu, Dokumen, Tag*). Riwayat pencarian terakhir dengan tombol hapus.
- **37–40 System Feedback Screens:**
  - *Keadaan Kosong (37):* Variasi visual saat kartu, dokumen, pengingat, atau favorit masih berjumlah nol.
  - *Memuat (38):* Tampilan skeleton lengkap Beranda.
  - *Terjadi Kesalahan (39):* Menampilkan contoh kesalahan validasi input dan peringatan kegagalan simpan.
  - *Berhasil (40):* Layar konfirmasi kesuksesan transaksi data.
- **69 Beranda • 360:** Spesifikasi tata letak untuk layar sempit (lebar 360 dp), memastikan carousel kartu mengecil proporsional tanpa ada teks terpotong (*no overflow*).

### 6.3 Cards Module (`docs/6. Cards/`)
- **12–13 Kartu Saya:** Filter kategori horizontal di bagian atas (*Semua, Pembayaran, Identitas, Pendidikan, Kesehatan, Keanggotaan, Kendaraan, Lainnya*). Grid 2 kolom kartu ringkas dengan nomor 4 digit tersamar. Floating Action Button / Tombol bawah "Tambah Kartu".
- **14–16, 44–46 Alur Tambah Kartu (4 Langkah Terpandu):**
  - *Langkah 1 (14):* Pilih kategori kartu yang ingin disimpan.
  - *Langkah 2 (15/46):* Masukkan nama panggilan, penerbit, jaringan (Visa/Mastercard/dll), 4 digit terakhir (hanya angka), dan masa berlaku opsional.
  - *Langkah 3 (16):* Pilih warna representasi kartu (Lime / Black / White / Gray).
  - *Langkah 4 (44/45):* Tinjau ringkasan kartu sebelum disimpan $\rightarrow$ Layar sukses "Harian siap ditemukan".
- **17 Detail & 18 Edit Kartu:** Tampilan kartu skala besar, tabel metadata lengkap (kategori, penerbit, tanggal ditambahkan), tombol aksi: `Edit`, `Favorit`, `Arsipkan`, `Hapus`. Di bawahnya terdapat log "Aktivitas lokal".
- **47–48 Aksi Proteksi Kartu:** Bottom sheet "Arsipkan kartu Harian?" (dengan opsi Urungkan), Modal "Hapus kartu Harian?" (aksi permanen destruktif), dan Dialog "Simpan perubahan?" jika keluar sebelum menyimpan form edit.

### 6.4 Documents Module (`docs/7. Documents/`)
- **20 Dokumen:** Banner kuning jika ada dokumen mendekati kedaluwarsa (*"1 dokumen segera kedaluwarsa"*), chip filter kategori, daftar dokumen vertikal dengan informasi tanggal dan ekstensi file.
- **21 Tambah Dokumen:** 4 pilihan input sumber berkas: (1) `Scan dengan kamera`, (2) `Impor gambar`, (3) `Impor PDF`, (4) `Isi metadata manual`.
- **24 Detail Dokumen:** Menampilkan kartu pratinjau dokumen tersamar, metadata berkas (nama, kategori, ukuran file, tanggal ditambahkan, kedaluwarsa, catatan), tombol aksi `Lihat dokumen`, `Edit metadata`, `Ganti file`, `Arsipkan`, `Hapus`.
- **25 Buka Dokumen Pribadi:** Layar gerbang keamanan verifikasi biometrik / PIN sebelum file berstatus pribadi diizinkan untuk dibuka pratinjaunya.
- **53–55 Konfirmasi & Detail Manual:** Form pengisian metadata dokumen mandiri dan konfirmasi lampiran berkas.
- **59 Ganti Berkas & 60 Hapus Dokumen:** Lembar konfirmasi penggantian lampiran file fisik tanpa merusak metadata tersimpan, serta modal konfirmasi hapus permanen.

### 6.5 Scan Flow Module (`docs/8. Scan Flow/`)
- **49 Sebelum Scan:** Layar persiapan pengambilan foto dokumen (posisikan dokumen, periksa cahaya, simpan metadata).
- **50–51 Izin Kamera:** Penjelasan perlunya akses kamera. Layar penanganan saat izin ditolak dengan tombol "Buka pengaturan" dan fallback "Impor file saja".
- **22 Scan Dokumen:** Antarmuka viewport kamera aktif dengan bingkai pemandu persegi panjang hijau lime (*bounding frame*), tombol shutter lingkaran putih besar, tombol senter/flash, dan tombol ambil dari galeri.
- **52 Potong & Putar:** Editor gambar sederhana untuk memutar berkas 90 derajat searah jarum jam (*Putar 90°*) dan mengatur batas crop sebelum diproses.
- **23 Tinjau Hasil OCR:** Layar verifikasi hasil pembacaan teks otomatis. Seluruh isian (nama, nomor tersamar, tanggal terbit, kedaluwarsa) dapat dikoreksi langsung oleh pengguna sebelum menekan tombol "Lanjut ke konfirmasi".

### 6.6 Vault and Security Module (`docs/9. Vault and Scurity/`)
*Catatan audit: Nama folder fisik pada repositori adalah `9. Vault and Scurity`.*
- **56 Brankas • Terkunci:** Keadaan saat tab Brankas terkunci. Menampilkan ilustrasi gembok hijau lime, judul *"Ruang pribadi terkunci"*, tombol "Buka Brankas", dan tombol alternatif "Gunakan PIN aplikasi".
- **57 Brankas • Terbuka:** Tampilan saat autentikasi berhasil dilewati. Menampilkan kartu aksen hijau lime *"Untuk Anda saja. 3 dokumen pribadi"*, tombol cepat "Kunci sekarang", daftar dokumen rahasia terisolasi, dan folder khusus identitas pribadi.
- **32 Pengaturan Keamanan:** Konfigurasi toggle Biometrik, Atur PIN aplikasi, Ubah PIN aplikasi, Kunci otomatis (pilihan waktu: 1 menit, 5 menit, dll.), Toggle "Sembunyikan di pengalih aplikasi" (*Privacy Shield*), dan tombol aksi "Kunci sekarang".
- **63 Hapus Data Lokal:** Dialog destruktif tingkat tinggi. Mengharuskan pengguna mengetik kata konfirmasi "HAPUS" untuk menghapus seluruh kartu, dokumen, dan metadata dari memori perangkat.
- **64 Hapus Akun:** Konfirmasi penghapusan akun dari aplikasi yang mewajibkan autentikasi ulang sebelum dieksekusi.

### 6.7 Reminders Module (`docs/10. Reminders/`)
- **28 Pengingat:** Tab filter *Mendatang*, *Selesai*, *Kustom*. Kartu sorotan utama besar berlatar Lime: *"30 hari - SIM A akan kedaluwarsa (11 Nov 2026)"*. Daftar jadwal pengingat mendatang dan tombol pintas "Pengaturan notifikasi".
- **29 Detail Pengingat:** Informasi dokumen tertaut, tanggal kedaluwarsa, jam notifikasi, status perizinan notifikasi perangkat, tombol "Edit pengingat", "Tandai selesai", dan "Hapus pengingat".
- **66–67 Buat & Edit Pengingat:** Form konfigurasi pengingat: Judul, Tautkan ke dokumen (dropdown dokumen), Tanggal pengingat, Jam (timepicker), Frekuensi pengulangan (Tidak berulang/berulang), Toggle "Notifikasi perangkat", dan Toggle "Sembunyikan nama di notifikasi".

### 6.8 Profile and Settings Module (`docs/11. Profile and Settings/`)
- **30 Profil:** Header akun (Avatar inisial, Nama, Email), Menu pengaturan vertikal: `Edit profil`, `Tampilan`, `Bahasa`, `Notifikasi`, `Privasi`, `Keamanan`, `Ekspor data`, `Cadangan`, `Tentang Cardly`, `Bantuan`, dan tombol "Keluar".
- **31 Edit Profil:** Ubah nama lengkap dan email dengan verifikasi.
- **33 Tampilan:** Pemilihan mode tema antarmuka melalui radio selector visual: *Terang*, *Gelap*, dan *Ikuti sistem*.
- **34 & 65 Ekspor Data:** Pilihan cakupan ekspor (*Kartu & metadata dokumen*), format (*JSON*), lokasi penyimpanan tujuan di perangkat, toggle sertakan file lampiran dokumen, dan bottom sheet konfirmasi autentikasi biometrik sebelum ekspor diproses.
- **35 Informasi Privasi & 72 Tentang Cardly:** Dokumentasi transparansi penanganan data dalam aplikasi dan informasi versi rilis 1.0.
- **68 Pengaturan Notifikasi:** Izin notifikasi sistem dan preferensi privasi layar kunci.
- **70 Bahasa:** Pemilihan bahasa antarmuka (Bahasa Indonesia dan English).
- **71 Pengaturan Cadangan:** Transparansi status pencadangan lokal vs cloud.

---

## 7. Interaction Specification

1. **Tap / Selection:** Umpan balik langsung pada tombol dengan perubahan opasitas ke 0.88 dan sedikit penyesuaian skala menjadi 0.98.
2. **Carousel Drag (Horizontal Scroll):** Kartu pilihan pada beranda dapat digeser horizontal dengan titik snap per kartu (*ease-out snap*).
3. **Form Submissions:** Tombol CTA form segera beralih ke keadaan memproses (*Loading state with circular progress*) untuk mencegah pengiriman ganda (*double tap/race condition*).
4. **Destructive Actions:** Semua tindakan hapus (kartu, dokumen, data lokal) diwajibkan melewati lembar konfirmasi modal atau pengetikan teks verifikasi ("HAPUS").
5. **Dismissible Undo:** Pengarsipan atau penambahan ke favorit memunculkan toast di bagian bawah layar selama 4–5 detik dengan tombol "Urungkan" sebelum perubahan dikunci permanen.

---

## 8. Motion & Animation Specification [TERVERIFIKASI]

Sumber: `docs/12. Prototype Flows/Prototype Flows & Motion Spec.png`.

| ID | Elemen / Interaksi | Trigger | Jenis Animasi | Durasi | Kurva Timing | Perilaku Saat Reduced Motion | Status |
|---|---|---|---|---|---|---|---|
| **MOT-01** | Press State | Ketukan tombol / card | Opacity & Skala mikro | 80–120 ms | Ease-out | Hanya opacity (tanpa perubahan skala) | TERVERIFIKASI |
| **MOT-02** | Carousel Snapping | Swipe kartu di Beranda | Horizontal snap 1 kartu | 200–240 ms | Ease-out | Pergantian kartu instan | TERVERIFIKASI |
| **MOT-03** | Bottom Sheet | Pemicu menu / filter | Slide up dari bawah & Scrim | 240 ms | Ease-out (Scrim 120 ms) | Fade 100 ms tanpa translasi pergeseran | TERVERIFIKASI |
| **MOT-04** | Favorite Toggle | Ketuk ikon bintang favorit | Transisi outline ke isi | 160 ms | Instant fill + Toast | Langsung terisi tanpa bounce | TERVERIFIKASI |
| **MOT-05** | Skeleton Pulse | Pemuatan data halaman | Pulse opacity 0.65 – 1.00 | 1.000 ms | Sine pulse | Bentuk abu-abu statis tanpa kedip | TERVERIFIKASI |
| **MOT-06** | Success Feedback | Sukses simpan / proses | Tampilan checkmark & copy | 160–200 ms | Ease-out | Langsung tampil tanpa animasi confetti | TERVERIFIKASI |
| **MOT-07** | Theme Switch | Ganti Terang $\leftrightarrow$ Gelap | Cross-fade palet warna | 180 ms | Linear cross-fade | Langsung berganti warna instan | TERVERIFIKASI |
| **MOT-08** | Tab Navigation | Ganti tab bar bawah | Cross-fade konten halaman | 160 ms | Linear | Konten berganti tanpa animasi | TERVERIFIKASI |
| **MOT-09** | Modal Dialog | Dialog konfirmasi hapus | Scrim muncul $\rightarrow$ Dialog fokus | 120–200 ms | Ease-out | Scrim & dialog muncul via opacity | TERVERIFIKASI |
| **MOT-10** | Scan & Privacy Reveal | Autentikasi dokumen terbuka | Unmasking konten rahasia | 0–120 ms | Instant reveal | Reveal instan | TERVERIFIKASI |

---

## 9. Design-to-Flutter Widget Mapping

| Komponen Desain | Sumber File Desain | Rekomendasi Widget Flutter | Catatan Arsitektur Flutter |
|---|---|---|---|
| Brand Button Primary | `docs/3. Components/Components.png` | `CardlyPrimaryButton` | Reusable widget dengan dukungan loading, disabled, dan haptic |
| Brand Button Destructive | `docs/3. Components/Components.png` | `CardlyDestructiveButton` | Berwarna merah `#B93838`, teks putih |
| Form Text Field | `docs/3. Components/Components.png` | `CardlyTextField` | Border radius 16 pt, floating label, error handling, eye toggle |
| Visual Card Container | `docs/6. Cards/16 Tampilan kartu.png` | `CardlyVisualCard` | Mendukung 4 palet warna, chip contactless, dan masking 4 digit |
| Masked Document Tile | `docs/7. Documents/24 Detail dokumen.png` | `CardlyDocumentTile` | Menampilkan placeholder siluet jika status dokumen adalah pribadi |
| Bottom Navigation Bar | `docs/3. Components/Components.png` | `CardlyBottomNavBar` | 5 tab tetap dengan pill background Lime pada item yang aktif |
| Notification Banner | `docs/7. Documents/20 Dokumen.png` | `CardlyNoticeBanner` | Mendukung varian Warning, Error, Info dengan ikon eksplisit |
| Action Bottom Sheet | `docs/6. Cards/47 Arsipkan kartu.png` | `CardlyActionBottomSheet` | Sudut atas 32 pt, modal barrier 50% hitam, tombol aksi tersusun rapi |
| Skeleton Loader Box | `docs/5. Home/38 Memuat.png` | `CardlySkeleton` | Menggunakan `AnimationController` pulsasi halus (durasi 1000 ms) |

---

## 10. Asset Mapping

| Aset Desain | Lokasi Sumber di Repositori | Format | Rencana Lokasi Aset Flutter | Kegunaan |
|---|---|---|---|---|
| Cardly App Logo | `docs/1. Cover.png`, `docs/4. Authentication/01 Splash.png` | PNG (vektor disarankan) | `assets/images/logo_cardly.png` & `assets/icons/app_icon.png` | Splash screen, Welcome, dan Privacy Shield |
| Ilustrasi Onboarding Kartu | `docs/4. Authentication/02 Onboarding • Kartu.png` | PNG | `assets/illustrations/onboarding_cards.png` | Layar Onboarding 1 |
| Ilustrasi Onboarding Dokumen | `docs/4. Authentication/03 Onboarding • Dokumen.png` | PNG | `assets/illustrations/onboarding_documents.png` | Layar Onboarding 2 |
| Ilustrasi Onboarding Privasi | `docs/4. Authentication/04 Onboarding • Privasi.png` | PNG | `assets/illustrations/onboarding_privacy.png` | Layar Onboarding 3 |
| Iconography Set | `docs/3. Components/Native Component Library.png` | PNG / Font Icons | `CupertinoIcons` / Material Icons disesuaikan | Seluruh ikon aplikasi (Home, Card, Document, Lock, Person, dll.) |

---

## 11. Design Quality & Fidelity Checklist

Sebelum sebuah layar Flutter disetujui sebagai representasi desain yang akurat:
- [ ] **Akurasi Spacing:** Apakah margin horizontal bernilai persis 24 pt dan elemen internal mematuhi kelipatan 8-pt?
- [ ] **Akurasi Sudut (Radius):** Apakah input field beradius 16 pt, card beradius 24 pt, dan modal sheet beradius 32 pt?
- [ ] **Akurasi Warna & Kontras:** Apakah warna Lime (`#C8F45A`) hanya digunakan untuk aksen dan tidak pernah dipakai sebagai warna teks di atas latar putih?
- [ ] **Ketahanan Layar Sempit (360 dp):** Apakah layout telah diuji pada lebar 360 dp dan bebas dari peringatan *RenderFlex overflowed*?
- [ ] **Dual-Theme Verification:** Apakah tampilan telah diperiksa dalam mode Terang dan Gelap, memastikan teks di mode gelap terbaca dengan jelas?
- [ ] **Area Sentuh Aksesibel:** Apakah semua ikon tombol memiliki padding minimal hingga mencapai area sentuh $44 \times 44$ pt?
- [ ] **Status Lengkap:** Apakah varian *empty*, *loading*, dan *error* telah dibuat sesuai desain?

---

## 12. Design Gaps & Open Questions

1. **Format Aset Ikon:** File di `docs/` diekspor dalam format PNG komposit (*rasterized*). Untuk kualitas rendering Flutter terbaik tanpa blur, disarankan menyiapkan ikon SVG atau mengekstrak aset vektor sebelum implementasi UI.
2. **Foto Dokumen Fisik:** Pada mockup desain, seluruh gambar KTP/SIM diisi dengan ilustrasi siluet tersamar (*"Pratinjau disamarkan - Data contoh"*). Perlu dipastikan bagaimana tampilan UI ketika pengguna mengunggah foto dokumen asli dengan orientasi memanjang (*portrait vs landscape*).
3. **Penyelarasan Nama Folder Disk:** Folder nomor 9 di disk tertulis `9. Vault and Scurity` (dengan salah ketik huruf 'e'). Seluruh referensi skrip dan dokumentasi wajib menghormati path aktual ini agar tidak terjadi kesalahan pemuatan file.
