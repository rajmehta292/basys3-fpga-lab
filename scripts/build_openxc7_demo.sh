#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENXC7_ROOT="${OPENXC7_ROOT:-/home/dmehta/openxc7/toolchain}"
YOSYS_ROOT="${YOSYS_ROOT:-/home/dmehta/openxc7/yosys-root}"
OUT_DIR="$ROOT_DIR/build/openxc7"
PART="xc7a35tcpg236-1"
TOP="basys3_demo"

source "$ROOT_DIR/scripts/openxc7_env.sh" >/dev/null
mkdir -p "$OUT_DIR"

for tool in yosys nextpnr-xilinx fasm2frames xc7frames2bit; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Required tool not found: $tool" >&2
        exit 2
    }
done

SRC="$ROOT_DIR/src/basys3_demo.sv"
XDC="$ROOT_DIR/constraints/basys3_demo_openxc7.xdc"
JSON="$OUT_DIR/$TOP.json"
FASM="$OUT_DIR/$TOP.fasm"
FRAMES="$OUT_DIR/$TOP.frames"
BIT="$OUT_DIR/$TOP.bit"
REPORT="$OUT_DIR/$TOP.report.json"
LOG="$OUT_DIR/build.log"
DB="$OPENXC7_ROOT/share/nextpnr/external/prjxray-db/artix7"

echo "[1/4] Yosys synthesis"
yosys -p "read_verilog -sv $SRC; synth_xilinx -arch xc7 -top $TOP; write_json $JSON" >"$OUT_DIR/yosys.log" 2>&1

echo "[2/4] nextpnr-Xilinx placement and routing"
nextpnr-xilinx --device "$PART" --json "$JSON" --report "$REPORT" --freq 100 \
    -o xdc="$XDC" -o fasm="$FASM" >"$OUT_DIR/nextpnr.log" 2>&1

echo "[3/4] FASM to configuration frames"
fasm2frames --part "$PART" --db-root "$DB" "$FASM" >"$FRAMES"

echo "[4/4] Frames to Xilinx bitstream"
xc7frames2bit --part_file "$DB/$PART/part.yaml" --part_name "$PART" \
    --frm_file "$FRAMES" --output_file "$BIT"

{
    echo "part=$PART"
    echo "top=$TOP"
    echo "bitstream=$BIT"
    sha256sum "$BIT"
    rg "Max frequency|warnings, 0 errors|Program finished normally" "$OUT_DIR/nextpnr.log" || true
} | tee "$LOG"

echo "Build complete: $BIT"
