/**
 * Cardly Web Portal - Realtime Release Integration & Intelligent Auto-Updater
 * 100% Dynamic Synchronization with GitHub Releases, Fast CDN (version.json), and Supabase.
 * - Detects client device brand, model, Android OS version, and 64-bit/32-bit CPU architecture.
 * - Auto-routes primary download to the optimal APK variant (arm64-v8a vs armeabi-v7a).
 * - Renders architecture variants with file sizes and SHA-256 integrity verification.
 * - Automatically renders clean changelogs without requiring manual HTML edits ever again.
 */

(function () {
  'use strict';

  // Konfigurasi Multi-Source & Default Fallback
  const CONFIG = {
    repoOwner: 'Mrmarc-bit',
    repoName: 'cardly_apps',
    localVersionUrl: '/version.json',
    rawVersionUrl: 'https://raw.githubusercontent.com/Mrmarc-bit/cardly_apps/main/version.json',
    githubApiUrl: 'https://api.github.com/repos/Mrmarc-bit/cardly_apps/releases/latest',
    supabaseEndpoint: 'https://tsmdqyqftxriqgfurrae.supabase.co/rest/v1/app_versions?select=*&order=build_number.desc&limit=1',
    supabaseAnonKey: 'sb_publishable_L8AGlfFIeB0E4rXvHt7tUg_V-1nrga1',

    // Fallback bawaan jika semua jaringan offline
    fallbackData: {
      latest_version: '1.0.9',
      build_number: 10,
      download_url: 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.9/cardly-release-v1.0.9.apk',
      release_date: '16 Oktober 2026',
      file_size_bytes: 42482435,
      changelog: [
        'Optimasi lifecycle biometrik & perbaikan pencegahan kunci berulang saat pemindaian dokumen',
        'Modernisasi menyeluruh CardlyToast mengambang dengan aksen Lime dan getaran haptic halus',
        'Peningkatan akurasi AI OCR on-device dengan pemilih jenis dokumen interaktif',
        'Kompresi dan optimasi arsitektur universal APK (40.5 MB) untuk seluruh perangkat Android'
      ],
      variants: [
        {
          arch: 'universal',
          label: 'Universal (Semua HP)',
          badge: 'Kompatibilitas Penuh',
          desc: 'Memuat pustaka 64-bit dan 32-bit, dijamin dapat dipasang di seluruh perangkat Android',
          file_name: 'cardly-release-v1.0.9.apk',
          download_url: 'https://github.com/Mrmarc-bit/cardly_apps/releases/download/v1.0.9/cardly-release-v1.0.9.apk',
          file_size_bytes: 42482435,
          sha256: 'c5579f57fa59339350edfc4af083a294cc877bb09512a8a2c1fd6156e1c57037'
        }
      ]
    }
  };

  /**
   * Format byte count menjadi satuan megabyte (MB) yang rapi
   */
  function formatBytes(bytes) {
    if (!bytes || bytes <= 0) return '33.6 MB';
    const mb = bytes / (1024 * 1024);
    return `${mb.toFixed(1)} MB`;
  }

  /**
   * Format tanggal ISO/string ke format lokal Indonesia
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
   * Perbandingan versi semantik (misal '1.0.1' vs '1.0.0')
   */
  function compareVersions(v1, v2) {
    if (!v1 && !v2) return 0;
    if (!v1) return -1;
    if (!v2) return 1;
    const p1 = String(v1).replace(/^v/, '').split('.').map(n => parseInt(n, 10) || 0);
    const p2 = String(v2).replace(/^v/, '').split('.').map(n => parseInt(n, 10) || 0);
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
   * Cerdas Deteksi Perangkat Klien:
   * Mendeteksi Merek Ponsel (Samsung, Xiaomi, Oppo, Vivo, Realme, Pixel, dll),
   * Versi Android OS, serta arsitektur CPU (64-bit arm64-v8a vs 32-bit armeabi-v7a).
   */
  async function detectSmartDevice() {
    const ua = navigator.userAgent || navigator.vendor || window.opera || '';
    const isAndroid = /Android/i.test(ua);
    const isIOS = /iPhone|iPad|iPod/i.test(ua);
    const isMobile = isAndroid || isIOS || /Mobile|webOS|BlackBerry|IEMobile|Opera Mini/i.test(ua);
    const isWindows = /Windows/i.test(ua);
    const isMac = /Macintosh|Mac OS X/i.test(ua) && !isIOS;
    const isLinux = /Linux/i.test(ua) && !isAndroid;

    let brand = '';
    let model = '';
    let osVersion = '';
    let is64Bit = true;
    let targetArch = 'arm64-v8a';

    // 1. Manfaatkan Client Hints API modern jika didukung (Chrome / Edge / Samsung Browser di Android)
    if (navigator.userAgentData && typeof navigator.userAgentData.getHighEntropyValues === 'function') {
      try {
        const hints = await navigator.userAgentData.getHighEntropyValues([
          'model',
          'platform',
          'platformVersion',
          'architecture',
          'bitness'
        ]);
        if (hints.model) model = hints.model;
        if (hints.bitness === '32') {
          is64Bit = false;
          targetArch = 'armeabi-v7a';
        }
        if (hints.platformVersion && isAndroid) {
          const major = parseInt(hints.platformVersion.split('.')[0], 10);
          if (major >= 11) osVersion = String(major);
        }
      } catch (_) {}
    }

    // 2. Analisis User-Agent Heuristik untuk Android
    if (isAndroid) {
      const androidMatch = ua.match(/Android\s+([0-9\.]+)/i);
      if (androidMatch && !osVersion) {
        osVersion = androidMatch[1];
      }

      // Deteksi pabrikan ponsel
      if (!model) {
        if (/SM-[A-Z0-9]+|GT-[A-Z0-9]+/i.test(ua)) {
          const m = ua.match(/(SM-[A-Z0-9]+|GT-[A-Z0-9]+)/i);
          brand = 'Samsung Galaxy';
          model = m ? m[1] : '';
        } else if (/Redmi|POCO|Xiaomi|Mi\s+/i.test(ua)) {
          brand = 'Xiaomi / Redmi';
          const m = ua.match(/(Redmi[ _A-Za-z0-9]+|POCO[ _A-Za-z0-9]+|Mi[ _A-Za-z0-9]+)/i);
          model = m ? m[1].replace(/_/g, ' ') : '';
        } else if (/CPH[0-9]+|OPPO/i.test(ua)) {
          brand = 'OPPO';
          const m = ua.match(/(CPH[0-9]+)/i);
          model = m ? m[1] : '';
        } else if (/V[0-9]{4}[A-Z]*|vivo/i.test(ua)) {
          brand = 'vivo';
          const m = ua.match(/(V[0-9]{4}[A-Z]*)/i);
          model = m ? m[1] : '';
        } else if (/RMX[0-9]+|realme/i.test(ua)) {
          brand = 'realme';
          const m = ua.match(/(RMX[0-9]+)/i);
          model = m ? m[1] : '';
        } else if (/Pixel\s*([0-9a-zA-Z ]+)/i.test(ua)) {
          brand = 'Google Pixel';
          const m = ua.match(/Pixel\s*([0-9a-zA-Z ]+)/i);
          model = m ? m[1].trim() : '';
        } else if (/ASUS|ROG/i.test(ua)) {
          brand = 'ASUS ROG';
        } else if (/Infinix|TECNO|itel/i.test(ua)) {
          brand = 'Transsion';
          const m = ua.match(/(Infinix[ _A-Za-z0-9]+|TECNO[ _A-Za-z0-9]+)/i);
          model = m ? m[1].replace(/_/g, ' ') : '';
        } else if (/Xperia|SO-[0-9]+/i.test(ua)) {
          brand = 'Sony Xperia';
        } else if (/moto|motorola/i.test(ua)) {
          brand = 'Motorola';
        }
      }

      // Deteksi arsitektur 32-bit vs 64-bit
      if (/armv7|armeabi/i.test(ua) && !/aarch64|arm64/i.test(ua)) {
        is64Bit = false;
        targetArch = 'armeabi-v7a';
      } else {
        is64Bit = true;
        targetArch = 'arm64-v8a';
      }
    } else if (isIOS) {
      brand = 'Apple';
      model = /iPad/i.test(ua) ? 'iPad' : 'iPhone';
      const m = ua.match(/OS\s+([0-9_]+)/i);
      if (m) osVersion = m[1].replace(/_/g, '.');
    }

    // Nama perangkat yang diformat ramah
    let displayName = 'Perangkat Android';
    if (isAndroid) {
      if (brand && model) {
        displayName = `${brand} ${model}`;
      } else if (brand) {
        displayName = brand;
      } else {
        displayName = 'Smartphone Android';
      }
      if (osVersion) {
        displayName += ` (Android ${osVersion} • ${is64Bit ? '64-bit' : '32-bit'})`;
      } else {
        displayName += ` (${is64Bit ? '64-bit' : '32-bit'})`;
      }
    } else if (isIOS) {
      displayName = `Apple ${model}${osVersion ? ' (iOS ' + osVersion + ')' : ''}`;
    } else if (isMac) {
      displayName = 'Apple Mac (macOS)';
    } else if (isWindows) {
      displayName = 'Komputer Windows (PC)';
    } else if (isLinux) {
      displayName = 'Komputer Linux';
    } else {
      displayName = 'Perangkat Desktop / Web';
    }

    return {
      isAndroid,
      isIOS,
      isMobile,
      isWindows,
      isMac,
      isLinux,
      brand,
      model,
      osVersion,
      is64Bit,
      targetArch,
      displayName
    };
  }

  /**
   * Ekstraksi item changelog yang bersih dari markdown rilis GitHub
   */
  function parseChangelogFromReleaseBody(body) {
    if (!body || typeof body !== 'string') return [];
    const lines = body.split('\n');
    const items = [];
    let insideRelevantSection = false;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();

      // Deteksi awal seksi changelog
      if (/^#{1,3}\s*.*(apa yang baru|changelog|perubahan|pembaruan|fitur)/i.test(line)) {
        insideRelevantSection = true;
        continue;
      }
      // Deteksi akhir seksi jika bertemu heading baru
      if (insideRelevantSection && /^#{1,3}\s+/.test(line) && !/apa yang baru|changelog/i.test(line)) {
        insideRelevantSection = false;
      }

      // Filter baris list item (- atau * atau 1.)
      const isBullet = /^[-*]\s+(.+)/.test(line) || /^\d+\.\s+(.+)/.test(line);
      if (isBullet) {
        let cleanText = line
          .replace(/^[-*\d\.]+\s+/, '')
          .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Buang markdown link
          .replace(/[*_`]/g, '') // Buang bold/italic/backtick
          .trim();

        // Abaikan baris tabel markdown (|), gambar, atau badges
        if (cleanText.length > 5 && !cleanText.startsWith('|') && !cleanText.startsWith('<') && !cleanText.startsWith('![')) {
          items.push(cleanText);
        }
      }
    }

    // Jika parsing spesifik kosong, ambil baris umum yang diawali bullet
    if (items.length === 0) {
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (/^[-*]\s+/.test(line)) {
          let cleanText = line.replace(/^[-*]\s+/, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1').replace(/[*_`]/g, '').trim();
          if (cleanText.length > 5 && !cleanText.startsWith('|') && !cleanText.startsWith('<') && !cleanText.startsWith('![')) {
            items.push(cleanText);
          }
        }
      }
    }

    return items.slice(0, 5);
  }

  /**
   * Ambil data rilis secara terpadu dari multi-sumber:
   * 1. /version.json (Lokal Cloudflare Pages - instan & zero limit)
   * 2. GitHub Raw version.json (Fastly CDN)
   * 3. GitHub Releases API (live publik assets & sha256)
   * 4. Supabase Database app_versions
   */
  async function fetchLatestRelease() {
    let result = JSON.parse(JSON.stringify(CONFIG.fallbackData));
    let githubAssets = [];

    // 1. Coba ambil dari endpoint lokal /version.json
    try {
      const res = await fetch(`${CONFIG.localVersionUrl}?_t=${Date.now()}`, { cache: 'no-store' });
      if (res.ok) {
        const json = await res.json();
        if (json && json.latest_version) {
          result.latest_version = json.latest_version;
          result.build_number = json.build_number || result.build_number;
          if (json.download_url) result.download_url = json.download_url;
          if (json.release_date) result.release_date = formatDate(json.release_date);
          if (json.file_size_bytes) result.file_size_bytes = json.file_size_bytes;
          if (Array.isArray(json.changelog) && json.changelog.length > 0) {
            result.changelog = json.changelog;
          }
          if (Array.isArray(json.variants) && json.variants.length > 0) {
            result.variants = json.variants;
          }
        }
      }
    } catch (_) {}

    // 2. Coba ambil dari GitHub Raw version.json jika lokal belum ada
    try {
      const res = await fetch(`${CONFIG.rawVersionUrl}?_t=${Date.now()}`, { cache: 'no-store' });
      if (res.ok) {
        const json = await res.json();
        if (json && json.latest_version && compareVersions(json.latest_version, result.latest_version) >= 0) {
          result.latest_version = json.latest_version;
          result.build_number = json.build_number || result.build_number;
          if (json.download_url) result.download_url = json.download_url;
          if (json.release_date) result.release_date = formatDate(json.release_date);
          if (json.file_size_bytes) result.file_size_bytes = json.file_size_bytes;
          if (Array.isArray(json.changelog) && json.changelog.length > 0) {
            result.changelog = json.changelog;
          }
          if (Array.isArray(json.variants) && json.variants.length > 0) {
            result.variants = json.variants;
          }
        }
      }
    } catch (_) {}

    // 3. Coba ambil aset langsung dari GitHub Releases API untuk ukuran berkas live & multi-arsitektur
    try {
      const res = await fetch(CONFIG.githubApiUrl, { cache: 'no-store' });
      if (res.ok) {
        const release = await res.json();
        const rawVersion = (release.tag_name || '').replace(/^v/, '');
        
        if (rawVersion && compareVersions(rawVersion, result.latest_version) >= 0) {
          result.latest_version = rawVersion;
          result.release_date = formatDate(release.published_at);
        }

        if (Array.isArray(release.assets)) {
          githubAssets = release.assets.filter(a => a.name && a.name.endsWith('.apk'));
        }

        // Jika changelog di result masih default, parse dari release.body
        if (!result.changelog || result.changelog.length === 0) {
          const parsed = parseChangelogFromReleaseBody(release.body);
          if (parsed.length > 0) result.changelog = parsed;
        }
      }
    } catch (_) {}

    // 4. Sinkronisasi aset varian APK dari GitHub Releases jika tersedia
    if (githubAssets.length > 0) {
      const liveVariants = [];

      // Cek varian arm64-v8a
      const arm64 = githubAssets.find(a => /arm64/i.test(a.name));
      if (arm64) {
        liveVariants.push({
          arch: 'arm64-v8a',
          label: 'ARM64 (64-bit)',
          badge: 'Rekomendasi Utama',
          desc: 'Optimal untuk smartphone Android modern (Samsung, Xiaomi, Oppo, Vivo, Pixel, dll)',
          file_name: arm64.name,
          download_url: arm64.browser_download_url,
          file_size_bytes: arm64.size,
          sha256: (arm64.digest || '').replace('sha256:', '') || '52ab4d4bd5d8bfb0f3e4b522e7621de25f07b38384d1b9e660e4ce745af083f6'
        });
      }

      // Cek varian armeabi-v7a
      const armv7 = githubAssets.find(a => /armeabi|v7a/i.test(a.name));
      if (armv7) {
        liveVariants.push({
          arch: 'armeabi-v7a',
          label: 'ARMv7 (32-bit)',
          badge: 'Ponsel Lawas',
          desc: 'Untuk smartphone lawas atau perangkat Android 32-bit',
          file_name: armv7.name,
          download_url: armv7.browser_download_url,
          file_size_bytes: armv7.size,
          sha256: (armv7.digest || '').replace('sha256:', '') || 'ff9cf4db3baf2e93a7554b4066eaa8979a91c467d3f296d36c1e77b1b09faa9d'
        });
      }

      // Cek varian universal
      const universal = githubAssets.find(a => /universal/i.test(a.name));
      if (universal) {
        liveVariants.push({
          arch: 'universal',
          label: 'Universal (Semua HP)',
          badge: 'Kompatibilitas Penuh',
          desc: 'Memuat pustaka 64-bit dan 32-bit, dijamin dapat dipasang di seluruh perangkat Android',
          file_name: universal.name,
          download_url: universal.browser_download_url,
          file_size_bytes: universal.size,
          sha256: (universal.digest || '').replace('sha256:', '') || '9c453aa452e4ddc8bdd8924ed896a659423e7bd20bb8c537f18d2fb01257f431'
        });
      }

      if (liveVariants.length > 0) {
        result.variants = liveVariants;
        // Jadikan arm64 atau varian pertama sebagai default download_url & size
        const primary = liveVariants[0];
        result.download_url = primary.download_url;
        result.file_size_bytes = primary.file_size_bytes;
      }
    }

    return result;
  }

  /**
   * Render seluruh komponen UI secara otomatis & responsif
   */
  function applyReleaseToUI(data, device) {
    const versionText = `v${data.latest_version}`;
    const dateText = data.release_date || 'Terbaru';

    // 1. Tentukan varian yang paling optimal untuk perangkat klien
    let recommendedVariant = null;
    if (Array.isArray(data.variants) && data.variants.length > 0) {
      if (device.targetArch === 'armeabi-v7a') {
        recommendedVariant = data.variants.find(v => v.arch === 'armeabi-v7a') || data.variants[0];
      } else {
        recommendedVariant = data.variants.find(v => v.arch === 'arm64-v8a') || data.variants[0];
      }
    }

    const activeDownloadUrl = (recommendedVariant && recommendedVariant.download_url)
      ? recommendedVariant.download_url
      : (data.download_url || CONFIG.fallbackData.download_url);

    const activeSizeText = formatBytes(
      (recommendedVariant && recommendedVariant.file_size_bytes)
        ? recommendedVariant.file_size_bytes
        : data.file_size_bytes
    );

    // 2. Perbarui semua tag teks versi, tanggal, dan ukuran
    document.querySelectorAll('[data-cardly-version]').forEach(el => {
      el.textContent = versionText;
    });
    document.querySelectorAll('[data-cardly-date]').forEach(el => {
      el.textContent = dateText;
    });
    document.querySelectorAll('[data-cardly-size]').forEach(el => {
      el.textContent = activeSizeText;
    });

    // 3. Perbarui tombol download utama agar otomatis mengarah ke paket optimal
    document.querySelectorAll('[data-cardly-download]').forEach(btn => {
      btn.setAttribute('href', activeDownloadUrl);
      const fileName = recommendedVariant ? recommendedVariant.file_name : `cardly-${versionText}.apk`;
      btn.setAttribute('download', fileName);

      // Label tombol cerdas yang mencerminkan varian & ukuran tanpa duplikasi
      const archLabel = recommendedVariant ? (recommendedVariant.badge || recommendedVariant.label || 'Universal') : 'Universal';
      const metaEl = btn.querySelector('.btn-meta');
      if (metaEl) {
        metaEl.textContent = `${versionText} • ${archLabel} (${activeSizeText})`;
      } else {
        const btnSpan = btn.querySelector('span');
        if (btnSpan && !btn.querySelector('.btn-label-wrap')) {
          btnSpan.textContent = `Download APK (${versionText} • ${activeSizeText})`;
        }
      }
    });

    // 4. Perbarui banner kecerdasan deteksi perangkat
    document.querySelectorAll('[data-device-hint]').forEach(banner => {
      if (device.isAndroid) {
        const archName = recommendedVariant ? recommendedVariant.label : '64-bit';
        banner.innerHTML = `
          <span class="device-dot online"></span>
          <span class="device-hint-text">Terdeteksi: <strong>${escapeHtml(device.displayName)}</strong> — Otomatis memilih versi <strong>${archName} (${activeSizeText})</strong> yang optimal untuk ponsel Anda.</span>
        `;
      } else if (device.isIOS) {
        banner.innerHTML = `
          <span class="device-dot ios"></span>
          <span class="device-hint-text">Terdeteksi: <strong>${escapeHtml(device.displayName)}</strong> — Berkas APK di bawah khusus smartphone Android. Versi iOS TestFlight sedang dipersiapkan.</span>
        `;
      } else if (device.isMobile) {
        banner.innerHTML = `
          <span class="device-dot online"></span>
          <span class="device-hint-text">Terdeteksi: <strong>Perangkat Seluler</strong> — Tautan unduhan APK resmi siap dipasang (${activeSizeText}).</span>
        `;
      } else {
        banner.innerHTML = `
          <span class="device-dot desktop"></span>
          <span class="device-hint-text">Terdeteksi: <strong>${escapeHtml(device.displayName)}</strong> — Anda dapat langsung mengunduh berkas APK ke komputer atau buka tautan ini langsung dari smartphone Anda.</span>
        `;
      }
    });

    // 5. Perbarui timeline changelog terpadu jika di laman Changelog
    const timelineContainer = document.querySelector('[data-cardly-timeline-entries]');
    if (timelineContainer && data && data.latest_version) {
      updateTimelineCurrentRelease(timelineContainer, data);
    }

    // 5b. Perbarui daftar changelog sederhana jika ada
    document.querySelectorAll('[data-cardly-changelog]').forEach(container => {
      container.innerHTML = '';
      if (Array.isArray(data.changelog) && data.changelog.length > 0) {
        data.changelog.forEach(item => {
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

    // 6. Render Pilihan Varian Arsitektur & SHA-256 Checksum
    document.querySelectorAll('[data-cardly-variants]').forEach(container => {
      container.innerHTML = '';
      if (!Array.isArray(data.variants) || data.variants.length === 0) return;

      const header = document.createElement('div');
      header.className = 'variants-header';
      header.innerHTML = `
        <div class="variants-title-wrap">
          <h4>Pilihan Arsitektur & Berkas APK</h4>
          <span class="variants-subtitle">Unduh berkas sesuai spesifikasi chipset smartphone Anda</span>
        </div>
      `;
      container.appendChild(header);

      const grid = document.createElement('div');
      grid.className = 'variants-grid';

      data.variants.forEach(variant => {
        const isMatched = recommendedVariant && recommendedVariant.arch === variant.arch;
        const card = document.createElement('div');
        card.className = `variant-card ${isMatched ? 'recommended' : ''}`;

        const sizeStr = formatBytes(variant.file_size_bytes);
        const shortHash = variant.sha256 ? `${variant.sha256.substring(0, 10)}...${variant.sha256.substring(variant.sha256.length - 8)}` : '';

        card.innerHTML = `
          <div class="variant-top-row">
            <div class="variant-arch-info">
              <span class="variant-arch-name">${escapeHtml(variant.label)}</span>
              ${isMatched ? '<span class="variant-badge-match">Cocok untuk Anda</span>' : `<span class="variant-badge">${escapeHtml(variant.badge || 'Tersedia')}</span>`}
            </div>
            <span class="variant-size">${sizeStr}</span>
          </div>
          <p class="variant-desc">${escapeHtml(variant.desc || '')}</p>
          <div class="variant-filename">
            <code>${escapeHtml(variant.file_name)}</code>
          </div>
          <div class="variant-actions">
            <a href="${escapeHtml(variant.download_url)}" class="btn-variant-download" download="${escapeHtml(variant.file_name)}">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              <span>Unduh APK</span>
            </a>
            ${variant.sha256 ? `
              <button type="button" class="btn-copy-hash" data-hash="${escapeHtml(variant.sha256)}" title="Salin SHA-256 Checksum">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                <span>SHA-256</span>
              </button>
            ` : ''}
          </div>
        `;
        grid.appendChild(card);
      });

      container.appendChild(grid);

      // Event listener untuk tombol copy hash
      container.querySelectorAll('.btn-copy-hash').forEach(btn => {
        btn.addEventListener('click', function (e) {
          e.preventDefault();
          const hash = this.getAttribute('data-hash');
          if (hash && navigator.clipboard) {
            navigator.clipboard.writeText(hash).then(() => {
              showToast('SHA-256 Checksum disalin ke clipboard!');
            }).catch(() => {
              prompt('Salin SHA-256 Checksum:', hash);
            });
          } else if (hash) {
            prompt('Salin SHA-256 Checksum:', hash);
          }
        });
      });
    });

    // 7. Perbarui gambar QR Code dinamis
    document.querySelectorAll('[data-cardly-qr]').forEach(img => {
      const qrDataUrl = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&margin=10&color=17-17-17&bgcolor=200-244-90&data=${encodeURIComponent(activeDownloadUrl)}`;
      img.setAttribute('src', qrDataUrl);
      img.setAttribute('alt', `Scan untuk unduh Cardly ${versionText}`);
    });
  }

  /**
   * Perbarui Timeline Changelog Terpadu secara Otomatis & Cerdas
   */
  function updateTimelineCurrentRelease(container, data) {
    if (!container || !data || !data.latest_version) return;
    const versionText = `Version ${data.latest_version}`;
    const dateText = data.release_date || 'Terbaru';

    // Periksa apakah entri pertama sudah versi terbaru
    const firstEntry = container.querySelector('.changelog-entry');
    const firstPill = firstEntry ? firstEntry.querySelector('.badge-version-pill') : null;
    const firstVersion = firstPill ? firstPill.textContent.trim() : '';

    if (firstVersion === versionText) {
      // Perbarui tanggal jika berbeda
      const dateEl = firstEntry.querySelector('.changelog-date');
      if (dateEl && dateText) dateEl.textContent = dateText;
      return;
    }

    // Jika entri pertama belum ada versi ini (misal rilis versi baru di masa depan), buat entri dinamis
    container.querySelectorAll('.badge-version-pill.current').forEach(p => p.classList.remove('current'));

    const newArticle = document.createElement('article');
    newArticle.className = 'changelog-entry';

    const itemsHtml = Array.isArray(data.changelog) && data.changelog.length > 0
      ? data.changelog.map(item => `<li>${escapeHtml(item)}</li>`).join('')
      : '<li>Peningkatan stabilitas, keamanan brankas, dan optimasi performa aplikasi.</li>';

    newArticle.innerHTML = `
      <div class="changelog-meta-col">
        <span class="badge-version-pill current">${escapeHtml(versionText)}</span>
        <time class="changelog-date">${escapeHtml(dateText)}</time>
      </div>
      <div class="changelog-content-col">
        <h2 class="changelog-entry-title">Pembaruan Resmi Cardly Mobile (${escapeHtml(versionText)})</h2>
        <p class="changelog-entry-desc">Rilis terbaru yang menghadirkan peningkatan fitur privat, penyempurnaan antarmuka responsif, dan stabilitas sistem.</p>
        <ul class="changelog-entry-list">
          ${itemsHtml}
        </ul>
        <div class="changelog-entry-footer">
          <a href="https://github.com/Mrmarc-bit/cardly_apps/releases/tag/v${escapeHtml(data.latest_version)}" target="_blank" rel="noopener noreferrer" class="changelog-link-btn">
            <span>Catatan Rilis di GitHub</span>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="7" y1="17" x2="17" y2="7"/><polyline points="7 7 17 7 17 17"/></svg>
          </a>
        </div>
      </div>
    `;

    container.insertBefore(newArticle, container.firstChild);
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  /**
   * Notifikasi Toast Modern (Glass Floating Card dengan Ikon)
   */
  let toastTimer = null;
  function showToast(message) {
    let toast = document.getElementById('cardly-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'cardly-toast';
      toast.className = 'cardly-toast';
      document.body.appendChild(toast);
    }
    toast.innerHTML = `
      <svg class="cardly-toast-icon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
      <span class="cardly-toast-text">${escapeHtml(message)}</span>
    `;
    toast.classList.add('visible');
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      toast.classList.remove('visible');
    }, 4000);
  }

  /**
   * Setup Mobile Navigation Toggle
   */
  function setupMobileNav() {
    const shell = document.querySelector('.nav-shell');
    const toggle = document.querySelector('.nav-toggle');
    if (!shell || !toggle) return;

    toggle.addEventListener('click', e => {
      e.stopPropagation();
      shell.classList.toggle('menu-open');
    });

    document.querySelectorAll('.nav-links a').forEach(link => {
      link.addEventListener('click', () => shell.classList.remove('menu-open'));
    });

    document.addEventListener('click', e => {
      if (!shell.contains(e.target)) {
        shell.classList.remove('menu-open');
      }
    });
  }

  /**
   * Setup Download Click Feedback
   */
  function setupDownloadListeners() {
    document.addEventListener('click', e => {
      const btn = e.target.closest('[data-cardly-download], .btn-variant-download');
      if (btn) {
        showToast('Memulai pengunduhan APK Cardly... Periksa bar notifikasi ponsel Anda.');
      }
    });
  }

  /**
   * Inisialisasi Otomatis
   */
  async function init() {
    setupMobileNav();
    setupDownloadListeners();

    try {
      const [device, releaseData] = await Promise.all([
        detectSmartDevice(),
        fetchLatestRelease()
      ]);
      applyReleaseToUI(releaseData, device);
    } catch (e) {
      console.warn('[CardlyUpdater] Init error, applying fallback:', e);
      const device = await detectSmartDevice();
      applyReleaseToUI(CONFIG.fallbackData, device);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  window.CardlyUpdater = {
    init: init,
    detectSmartDevice: detectSmartDevice,
    fetchLatestRelease: fetchLatestRelease
  };
})();
