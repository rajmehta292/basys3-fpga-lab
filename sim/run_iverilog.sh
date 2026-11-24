#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/sim/build"
IVERILOG_BIN="${IVERILOG:-iverilog}"
VVP_BIN="${VVP:-vvp}"

mkdir -p "$BUILD_DIR"

if [[ "$IVERILOG_BIN" == */* ]]; then
    [[ -x "$IVERILOG_BIN" ]] || { echo "iverilog executable not found: $IVERILOG_BIN" >&2; exit 2; }
else
    command -v "$IVERILOG_BIN" >/dev/null 2>&1 || {
        echo "iverilog is not installed. Set IVERILOG=/path/to/iverilog." >&2
        exit 2
    }
fi

if [[ "$VVP_BIN" == */* ]]; then
    [[ -x "$VVP_BIN" ]] || { echo "vvp executable not found: $VVP_BIN" >&2; exit 2; }
else
    command -v "$VVP_BIN" >/dev/null 2>&1 || {
        echo "vvp is not installed. Set VVP=/path/to/vvp." >&2
        exit 2
    }
fi

"$IVERILOG_BIN" -g2001 -Wall -s tb_milestone1 \
    -o "$BUILD_DIR/tb_milestone1.vvp" \
    "$ROOT_DIR/rtl/stream_counter_generator.v" \
    "$ROOT_DIR/rtl/stream_sequence_checker.v" \
    "$ROOT_DIR/sim/tb_milestone1.v"

SIM_OUTPUT="$("$VVP_BIN" "$BUILD_DIR/tb_milestone1.vvp")"
printf '%s\n' "$SIM_OUTPUT"

grep -q "MILESTONE1 PASS" <<< "$SIM_OUTPUT" || {
    echo "Simulation did not report a pass." >&2
    exit 1
}
