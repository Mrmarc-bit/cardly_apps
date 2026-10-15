#!/usr/bin/env bash
set -e

# Skrip peluncur rilis otomatis Cardly
# Penggunaan:
#   ./scripts/release.sh [versi+build]
# Contoh:
#   ./scripts/release.sh 1.0.5+6

cd "$(dirname "$0")/.."
dart run tool/release.dart "$@"
