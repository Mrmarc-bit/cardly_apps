#!/usr/bin/env bash
set -e

# ========================================================
# Cardly Automated Release Engine & Disk Maintenance
# ========================================================
# Penggunaan:
#   ./scripts/release.sh                 -> Mode Interaktif (Versi, Auto-Publish & Cache Clean)
#   ./scripts/release.sh 1.0.5+6         -> Mode Cepat (Langsung versi spesifik)
#   ./scripts/release.sh --clean         -> Mode Pembersihan Cache Langsung (~1-14 GB)
# ========================================================

cd "$(dirname "$0")/.."
dart tool/release.dart "$@"
