# Cara Update & Deploy Website Cardly ke Cloudflare Pages

## Ringkasan Perbaikan:
Sebelumnya Google bot mendeteksi URL `https://cardly.suntree.my.id/privacy` **tidak responsif** karena terjadi **Infinite 307 Redirect Loop** (aturan rewrite di `_redirects` bertabrakan dengan fitur bawaan Clean URLs Cloudflare Pages).

File `_redirects` yang bentrok telah **dihapus**, dan struktur direktori resmi telah disempurnakan:
```text
landing_page/
├── index.html            (Beranda Resmi)
├── style.css             (CSS Desain Mewah & Responsif)
├── app_icon_120.png      (Logo Aplikasi 120x120)
├── privacy/
│   └── index.html        (Langsung terbuka di https://cardly.suntree.my.id/privacy)
├── privacy.html          (Fallback langsung)
├── terms/
│   └── index.html        (Langsung terbuka di https://cardly.suntree.my.id/terms)
└── terms.html            (Fallback langsung)
```

---

## Langkah Update ke Cloudflare Pages (30 Detik)

1. Buka [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Di bilah menu kiri, pilih **Workers & Pages** (atau **Compute**).
3. Klik proyek Pages Anda (misal: `cardly`).
4. Klik tab **Deployments** $\rightarrow$ klik tombol **Create a new deployment** (atau **Upload assets**).
5. Tarik / Unggah folder `landing_page/` yang ada di laptop Anda.
6. Klik **Save and Deploy**.

---

## Langkah Penting: Bersihkan Cache Cloudflare (Purge Cache)

Agar Cloudflare tidak lagi menyimpan status redirect 307 lama:
1. Di Dashboard Cloudflare, klik menu **Websites** $\rightarrow$ pilih domain **suntree.my.id**.
2. Di bilah kiri, klik menu **Caching** $\rightarrow$ pilih **Configuration**.
3. Pada kartu **Purge Cache**, klik tombol **Purge Everything** $\rightarrow$ Konfirmasi **Purge Everything**.

---

## Hasil Akhir untuk Google Cloud Console

Setelah deploy dan purge cache, buka URL berikut di browser atau curl untuk memastikan responsnya **200 OK**:
- **Application home page**: `https://cardly.suntree.my.id`
- **Application privacy policy link**: `https://cardly.suntree.my.id/privacy`
- **Application terms of service link**: `https://cardly.suntree.my.id/terms`

Di Google Cloud Console $\rightarrow$ **Branding**, masukkan URL di atas dan klik **SAVE** / **Kirim Verifikasi**. Google akan langsung memvalidasinya!
