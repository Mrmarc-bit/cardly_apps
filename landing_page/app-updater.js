/**
 * Cardly Web Portal - Realtime Release Integration & Dynamic Downloader
 * Automatically fetches the latest version, changelog, and direct APK download URL
 * from GitHub raw (version.json) or GitHub Releases API with seamless fallback.
 */

(function () {
  'use strict';

  // Konfigurasi Default & Sumber Data
  const CONFIG = {
    repoOwner: 'Mrmarc-bit',
    repoName: 'cardly_apps',
    rawVersionUrl: 'https://raw.githubusercontent.com/Mrmarc-bit/cardly_apps/main/version.json',
    githubApiUrl: 'https://api.github.com/repos/Mrmarc-bit/cardly_apps/releases/latest',
    defaultDownloadUrl: 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.0/cardly-release-v1.0.0.apk',
    fallbackData: {
      latest_version: '1.0.0',
      build_number: 1,
      download_url: 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.0/cardly-release-v1.0.0.apk',
      release_date: '14 Oktober 2026',
      file_size_bytes: 97517568,
      changelog: [
        'Pemindai kartu & dokumen otomatis berstandar ISO ID-1 (rounded corners)',
        'Ekstraksi teks OCR e-KTP dan kartu bank on-device otomatis & presisi',
        'Pencegahan kebocoran data sensitif (Zero Full-Card Retention)',
        'Pembaruan otomatis in-app tanpa Google Play Store',
        'Penandatanganan rilis Keystore resmi konsisten'
      ]
    }
  };

  /**
   * Format bytes ke ukuran yang mudah dibaca (MB)
   */
  function formatBytes(bytes) {
    if (!bytes || bytes <= 0) return '93 MB';
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
   * Deteksi apakah pengguna membuka dari perangkat Android
   */
  function isAndroidDevice() {
    return /Android/i.test(navigator.userAgent || navigator.vendor || window.opera);
  }

  /**
   * Ambil data versi terbaru secara otomatis
   */
  async function fetchLatestRelease() {
    let release = null;

    // 1. Coba ambil dari version.json di repo GitHub (paling cepat & real-time)
    try {
      const res = await fetch(`${CONFIG.rawVersionUrl}?_t=${Date.now()}`, {
        cache: 'no-store'
      });
      if (res.ok) {
        const json = await res.json();
        if (json && json.latest_version) {
          release = {
            latest_version: json.latest_version,
            build_number: json.build_number || 1,
            download_url: json.download_url || CONFIG.defaultDownloadUrl,
            release_date: formatDate(json.release_date),
            file_size_bytes: json.file_size_bytes || 97517568,
            changelog: Array.isArray(json.changelog) && json.changelog.length > 0
              ? json.changelog
              : CONFIG.fallbackData.changelog
          };
        }
      }
    } catch (e) {
      console.warn('[CardlyUpdater] Fetch from version.json skipped:', e);
    }

    // 2. Fallback: Coba ambil dari GitHub Releases API publik
    if (!release) {
      try {
        const res = await fetch(CONFIG.githubApiUrl);
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
                return line.length > 3;
              });
          }

          release = {
            latest_version: rawVersion,
            build_number: 1,
            download_url: apkAsset ? apkAsset.browser_download_url : json.html_url,
            release_date: formatDate(json.published_at),
            file_size_bytes: apkAsset ? apkAsset.size : 97517568,
            changelog: changelogList.length > 0 ? changelogList : CONFIG.fallbackData.changelog
          };
        }
      } catch (e) {
        console.warn('[CardlyUpdater] Fetch from GitHub Releases API skipped:', e);
      }
    }

    // 3. Fallback terakhir: gunakan data bawaan resmi
    return release || CONFIG.fallbackData;
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
    const isAndroid = isAndroidDevice();
    const platformBadges = document.querySelectorAll('[data-device-hint]');
    platformBadges.forEach(function (badge) {
      if (isAndroid) {
        badge.innerHTML = `
          <span class="device-dot online"></span>
          Terdeteksi: <strong>Perangkat Android</strong> — Unduhan langsung siap dipasang
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
