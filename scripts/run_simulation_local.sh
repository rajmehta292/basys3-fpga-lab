#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="$ROOT_DIR/scripts/iverilog_local.sh" \
VVP="$ROOT_DIR/scripts/vvp_local.sh" \
    "$ROOT_DIR/sim/run_all.sh"
