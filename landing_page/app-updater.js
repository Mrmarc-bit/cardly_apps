/**
 * Cardly Web Portal - Realtime Release Integration & Dynamic Downloader
 * Automatically fetches the latest version, changelog, and direct APK download URL
 * from GitHub raw (version.json) or GitHub Releases API with seamless fallback.
 */

(function () {
  'use strict';

  // Konfigurasi Default & Sumber Data
  const CONFIG = {
    // Supabase Centralized Hub (Sumber Utama)
    supabaseUrl: 'https://tsmdqyqftxriqgfurrae.supabase.co',
    supabaseAnonKey: 'sb_publishable_L8AGlfFIeB0E4rXvHt7tUg_V-1nrga1',
    supabaseEndpoint: 'https://tsmdqyqftxriqgfurrae.supabase.co/rest/v1/app_versions?select=*&order=build_number.desc&limit=1',

    // Sumber Data Rilis
    repoOwner: 'Mrmarc-bit',
    repoName: 'cardly_apps',
    rawVersionUrl: 'https://raw.githubusercontent.com/Mrmarc-bit/cardly_apps/main/version.json',
    githubApiUrl: 'https://api.github.com/repos/Mrmarc-bit/cardly_apps/releases/latest',
    defaultDownloadUrl: 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.1/cardly-release-v1.0.1.apk',
    fallbackData: {
      latest_version: '1.0.1',
      build_number: 2,
      download_url: 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.1/cardly-release-v1.0.1.apk',
      release_date: '14 Oktober 2026',
      file_size_bytes: 35203072,
      changelog: [
        'Fitur unggah dan ganti foto profil avatar (kamera, galeri, dan hapus foto)',
        'Anonimitas total penyimpanan cloud (perlindungan data privat tanpa ekspos vendor)',
        'Optimasi antarmuka responsif mobile portal web',
        'Perbaikan kestabilan performa dan keamanan data lokal'
      ]
    }
  };

  /**
   * Format bytes ke ukuran yang mudah dibaca (MB)
   */
  function formatBytes(bytes) {
    if (!bytes || bytes <= 0) return '33.6 MB';
    const mb = bytes / (1024 * 1024);
    return `${mb.toFixed(1)} MB`;
  }

  /**
   * Format tanggal rilis ke bahasa Indonesia
   */
  function formatDate(dateStr) {
    if (!dateStr) return 'Terbaru';
    try {
      const d = new Date(dateStr);
      if (isNaN(d.getTime())) return dateStr;
      return d.toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      });
    } catch (_) {
      return dateStr;
    }
  }

  /**
   * Membandingkan dua string semantik versi (contoh: '1.0.1' > '1.0.0')
   */
  function compareVersions(v1, v2) {
    if (!v1 && !v2) return 0;
    if (!v1) return -1;
    if (!v2) return 1;
    const p1 = String(v1).replace(/^v/, '').split('.').map(function (n) { return parseInt(n, 10) || 0; });
    const p2 = String(v2).replace(/^v/, '').split('.').map(function (n) { return parseInt(n, 10) || 0; });
    const len = Math.max(p1.length, p2.length);
    for (let i = 0; i < len; i++) {
      const a = p1[i] || 0;
      const b = p2[i] || 0;
      if (a > b) return 1;
      if (a < b) return -1;
    }
    return 0;
  }

  /**
   * Menentukan apakah kandidat rilis lebih baru daripada rilis saat ini
   */
  function isBetterCandidate(candidate, current) {
    if (!candidate || !candidate.latest_version) return false;
    if (!current || !current.latest_version) return true;
    const vCmp = compareVersions(candidate.latest_version, current.latest_version);
    if (vCmp > 0) return true;
    if (vCmp < 0) return false;
    return (candidate.build_number || 0) > (current.build_number || 0);
  }

  /**
   * Deteksi platform perangkat pengguna secara akurat
   */
  function getDeviceInfo() {
    const ua = navigator.userAgent || navigator.vendor || window.opera || '';
    const isAndroid = /Android/i.test(ua);
    const isIOS = /iPhone|iPad|iPod/i.test(ua);
    const isMobile = isAndroid || isIOS || /Mobile|webOS|BlackBerry|IEMobile|Opera Mini/i.test(ua);
    return { isAndroid, isIOS, isMobile };
  }

  /**
   * Ambil data versi terbaru secara otomatis dari multi-sumber:
   * 1. GitHub Releases API (live rilis publik yang baru diunggah)
   * 2. GitHub Raw version.json (CDN Fastly tanpa limit)
   * 3. Supabase Database app_versions
   * Mengambil versi/build number tertinggi secara otomatis.
   */
  async function fetchLatestRelease() {
    let bestRelease = null;

    // 1. Coba ambil dari GitHub Releases API publik (sumber rilis utama)
    try {
      const res = await fetch(CONFIG.githubApiUrl, { cache: 'no-store' });
      if (res.ok) {
        const json = await res.json();
        const apkAsset = (json.assets || []).find(function (a) {
          return a.name && a.name.endsWith('.apk');
        });
        const rawVersion = (json.tag_name || '1.0.0').replace(/^v/, '');

        let changelogList = [];
        if (json.body) {
          changelogList = json.body
            .split('\n')
            .map(function (line) {
              return line.replace(/^[\*\-\d\.\s#]+/, '').trim();
            })
            .filter(function (line) {
              return line.length > 3 && !line.startsWith('![') && !line.startsWith('<');
            });
        }

        const candidate = {
          latest_version: rawVersion,
          build_number: 2, // Tag v1.0.1 bersesuaian dengan build 2
          download_url: apkAsset ? apkAsset.browser_download_url : (CONFIG.defaultDownloadUrl),
          release_date: formatDate(json.published_at),
          file_size_bytes: apkAsset ? apkAsset.size : (CONFIG.fallbackData.file_size_bytes),
          changelog: changelogList.length > 0 ? changelogList.slice(0, 5) : CONFIG.fallbackData.changelog
        };

        if (isBetterCandidate(candidate, bestRelease)) {
          bestRelease = candidate;
        }
      }
    } catch (e) {
      console.warn('[CardlyUpdater] GitHub Releases API fetch skipped:', e);
    }

    // 2. Coba ambil dari version.json di repo GitHub (cepat & tanpa limit API)
    try {
      const res = await fetch(`${CONFIG.rawVersionUrl}?_t=${Date.now()}`, {
        cache: 'no-store'
      });
      if (res.ok) {
        const json = await res.json();
        if (json && json.latest_version) {
          const candidate = {
            latest_version: json.latest_version,
            build_number: json.build_number || 1,
            download_url: json.download_url || CONFIG.defaultDownloadUrl,
            release_date: formatDate(json.release_date),
            file_size_bytes: json.file_size_bytes || CONFIG.fallbackData.file_size_bytes,
            changelog: Array.isArray(json.changelog) && json.changelog.length > 0
              ? json.changelog
              : CONFIG.fallbackData.changelog
          };

          if (isBetterCandidate(candidate, bestRelease)) {
            bestRelease = candidate;
          }
        }
      }
    } catch (e) {
      console.warn('[CardlyUpdater] Fetch from version.json skipped:', e);
    }

    // 3. Fallback / Alternatif: Coba ambil dari Supabase Database (Tabel app_versions)
    try {
      const res = await fetch(CONFIG.supabaseEndpoint, {
        headers: {
          'apikey': CONFIG.supabaseAnonKey,
          'Authorization': `Bearer ${CONFIG.supabaseAnonKey}`
        },
        cache: 'no-store'
      });
      if (res.ok) {
        const rows = await res.json();
        if (Array.isArray(rows) && rows.length > 0) {
          const row = rows[0];
          const candidate = {
            latest_version: row.latest_version,
            build_number: row.build_number || 1,
            download_url: row.download_url || CONFIG.defaultDownloadUrl,
            release_date: formatDate(row.release_date),
            file_size_bytes: row.file_size_bytes || CONFIG.fallbackData.file_size_bytes,
            changelog: Array.isArray(row.changelog) && row.changelog.length > 0
              ? row.changelog
              : CONFIG.fallbackData.changelog
          };

          if (isBetterCandidate(candidate, bestRelease)) {
            bestRelease = candidate;
          }
        }
      }
    } catch (e) {
      console.warn('[CardlyUpdater] Fetch from Supabase skipped:', e);
    }

    // 4. Fallback final: gunakan fallback bawaan (v1.0.1)
    return bestRelease || CONFIG.fallbackData;
  }

  /**
   * Perbarui seluruh elemen UI secara dinamis
   */
  function applyReleaseToUI(data) {
    const versionText = `v${data.latest_version}`;
    const sizeText = formatBytes(data.file_size_bytes);
    const dateText = data.release_date || '14 Oktober 2026';
    const downloadUrl = data.download_url || CONFIG.defaultDownloadUrl;

    // Perbarui teks versi
    document.querySelectorAll('[data-cardly-version]').forEach(function (el) {
      el.textContent = versionText;
    });

    // Perbarui tanggal rilis
    document.querySelectorAll('[data-cardly-date]').forEach(function (el) {
      el.textContent = dateText;
    });

    // Perbarui ukuran berkas
    document.querySelectorAll('[data-cardly-size]').forEach(function (el) {
      el.textContent = sizeText;
    });

    // Perbarui tautan tombol unduh
    document.querySelectorAll('[data-cardly-download]').forEach(function (el) {
      el.setAttribute('href', downloadUrl);
      el.setAttribute('download', `cardly-v${data.latest_version}.apk`);
    });

    // Perbarui daftar changelog
    const changelogContainers = document.querySelectorAll('[data-cardly-changelog]');
    changelogContainers.forEach(function (container) {
      container.innerHTML = '';
      if (Array.isArray(data.changelog)) {
        data.changelog.forEach(function (item) {
          const li = document.createElement('li');
          li.className = 'changelog-item';
          li.innerHTML = `
            <svg class="changelog-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            <span>${escapeHtml(item)}</span>
          `;
          container.appendChild(li);
        });
      }
    });

    // Perbarui QR Code URL
    const qrImgs = document.querySelectorAll('[data-cardly-qr]');
    qrImgs.forEach(function (img) {
      const qrDataUrl = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&margin=10&color=17-17-17&bgcolor=200-244-90&data=${encodeURIComponent(downloadUrl)}`;
      img.setAttribute('src', qrDataUrl);
      img.setAttribute('alt', `Scan untuk unduh Cardly ${versionText}`);
    });

    // Sesuaikan teks instruksi sesuai platform
    const device = getDeviceInfo();
    const platformBadges = document.querySelectorAll('[data-device-hint]');
    platformBadges.forEach(function (badge) {
      if (device.isAndroid) {
        badge.innerHTML = `
          <span class="device-dot online"></span>
          Terdeteksi: <strong>Perangkat Android</strong> — Siap unduh & pasang langsung
        `;
      } else if (device.isIOS) {
        badge.innerHTML = `
          <span class="device-dot ios"></span>
          Terdeteksi: <strong>Perangkat iOS (iPhone)</strong> — Berkas instalasi APK khusus Android
        `;
      } else if (device.isMobile) {
        badge.innerHTML = `
          <span class="device-dot online"></span>
          Terdeteksi: <strong>Perangkat Seluler</strong> — Tautan unduhan APK siap
        `;
      } else {
        badge.innerHTML = `
          <span class="device-dot desktop"></span>
          Terdeteksi: <strong>Komputer / Desktop</strong> — Scan QR Code untuk unduh di ponsel Anda
        `;
      }
    });
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
  }

  /**
   * Pengatur interaksi menu navigasi mobile
   */
  function setupMobileNav() {
    const shell = document.querySelector('.nav-shell');
    const toggle = document.querySelector('.nav-toggle');
    if (!shell) return;

    if (toggle) {
      toggle.addEventListener('click', function (e) {
        e.stopPropagation();
        shell.classList.toggle('menu-open');
      });
    }

    document.querySelectorAll('.nav-links a').forEach(function (link) {
      link.addEventListener('click', function () {
        shell.classList.remove('menu-open');
      });
    });

    document.addEventListener('click', function (e) {
      if (!shell.contains(e.target)) {
        shell.classList.remove('menu-open');
      }
    });
  }

  /**
   * Notifikasi toast kecil saat unduhan diklik
   */
  function setupDownloadToasts() {
    document.querySelectorAll('[data-cardly-download]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        showToast('Memulai pengunduhan APK Cardly... Buka berkas unduhan di notifikasi ponsel Anda.');
      });
    });
  }

  function showToast(message) {
    let toast = document.getElementById('cardly-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'cardly-toast';
      toast.className = 'cardly-toast';
      document.body.appendChild(toast);
    }
    toast.textContent = message;
    toast.classList.add('visible');
    setTimeout(function () {
      toast.classList.remove('visible');
    }, 4500);
  }

  // Inisialisasi saat DOM siap
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  async function init() {
    setupMobileNav();
    setupDownloadToasts();
    try {
      const releaseData = await fetchLatestRelease();
      applyReleaseToUI(releaseData);
    } catch (e) {
      console.warn('[CardlyUpdater] Init error, using fallback:', e);
      applyReleaseToUI(CONFIG.fallbackData);
    }
  }

  // Ekspor helper ke window jika dibutuhkan secara global
  window.CardlyUpdater = {
    fetchLatestRelease: fetchLatestRelease,
    refreshUI: init
  };
})();
