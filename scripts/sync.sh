#!/usr/bin/env bash
set -e

# ========================================================
# Cardly Multi-Repo Synchronizer Shell Runner
# ========================================================
# Penggunaan:
#   ./scripts/sync.sh            -> Mode Interaktif
#   ./scripts/sync.sh -u -f      -> Sync Full ke UNUGHA Kampus
#   ./scripts/sync.sh -a -f      -> Dual-Sync ke UNUGHA & Personal
#   ./scripts/sync.sh --dry-run  -> Simulasi tanpa eksekusi push
# ========================================================

cd "$(dirname "$0")/.."
dart tool/sync_repo.dart "$@"
