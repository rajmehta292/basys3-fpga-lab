#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 4 ]]; then
    echo "usage: $0 <source.sv> <top> <constraints.xdc> <output-dir> [additional-source.sv ...]" >&2
    exit 2
fi

SOURCE="$1"
TOP="$2"
XDC="$3"
OUT="$4"
shift 4
SOURCES=("$SOURCE" "$@")
PART="xc7a35tcpg236-1"

source "$ROOT_DIR/scripts/openxc7_env.sh" >/dev/null
mkdir -p "$ROOT_DIR/$OUT"
OUT_ABS="$ROOT_DIR/$OUT"

YOSYS_BIN="${YOSYS_BIN:-$ROOT_DIR/../openxc7/yosys-root/usr/bin/yosys}"
NEXT_PNR_BIN="${NEXTPNR_XILINX_BIN:-nextpnr-xilinx}"
FASM2FRAMES_BIN="${FASM2FRAMES_BIN:-fasm2frames}"
FRAMES2BIT_BIN="${FRAMES2BIT_BIN:-xc7frames2bit}"
DB="$OPENXC7_ROOT/share/nextpnr/external/prjxray-db/artix7"

[[ "$SOURCE" = /* ]] || SOURCE="$ROOT_DIR/$SOURCE"
[[ "$XDC" = /* ]] || XDC="$ROOT_DIR/$XDC"
for index in "${!SOURCES[@]}"; do
    [[ "${SOURCES[$index]}" = /* ]] || SOURCES[$index]="$ROOT_DIR/${SOURCES[$index]}"
done

for required in "$YOSYS_BIN" "$XDC" "${SOURCES[@]}"; do
    if [[ ! -e "$required" ]]; then
        echo "missing required input: $required" >&2
        exit 1
    fi
done

JSON="$OUT_ABS/$TOP.json"
FASM="$OUT_ABS/$TOP.fasm"
FRAMES="$OUT_ABS/$TOP.frames"
BIT="$OUT_ABS/$TOP.bit"

SOURCE_LIST="${SOURCES[*]}"
"$YOSYS_BIN" -Q -T -l "$OUT_ABS/yosys.log" \
    -p "read_verilog -sv $SOURCE_LIST; hierarchy -top $TOP; synth_xilinx -top $TOP -family xc7 -json $JSON"

"$NEXT_PNR_BIN" --json "$JSON" \
    --device "$PART" --freq 100 --report "$OUT_ABS/$TOP.report.json" \
    -o xdc="$XDC" -o fasm="$FASM" 2>&1 | tee "$OUT_ABS/nextpnr.log"

"$FASM2FRAMES_BIN" --part "$PART" --db-root "$DB" "$FASM" > "$FRAMES"
"$FRAMES2BIT_BIN" --part_file "$DB/$PART/part.yaml" --part_name "$PART" \
    --frm_file "$FRAMES" --output_file "$BIT"

sha256sum "$BIT" > "$OUT_ABS/build.log"
printf 'part=%s\ntop=%s\nsource=%s\nconstraints=%s\nbitstream=%s\n' \
    "$PART" "$TOP" "$SOURCE" "$XDC" "$BIT" >> "$OUT_ABS/build.log"
echo "built $BIT"
