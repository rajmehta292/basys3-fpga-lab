#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YOSYS_BIN="${YOSYS:-yosys}"
RESULT_DIR="$ROOT_DIR/results/synthesis"
mkdir -p "$RESULT_DIR"

command -v "$YOSYS_BIN" >/dev/null 2>&1 || {
    echo "yosys is not installed or not on PATH" >&2
    exit 2
}

"$YOSYS_BIN" -p 'read_verilog rtl/*.v; synth_xilinx -family xc7 -top top_streaming -flatten; stat' \
    | tee "$RESULT_DIR/yosys_xc7_estimate.log"
