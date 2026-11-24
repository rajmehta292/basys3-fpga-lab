#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BITFILE="${1:-$ROOT_DIR/build/openxc7/basys3_demo.bit}"
XILINX_ROOT="${XILINX_ROOT:-/home/dmehta/xilinux-petalinux/components/xsct}"
HW_SERVER="$XILINX_ROOT/bin/hw_server"
XSDB="$XILINX_ROOT/bin/xsdb"
PORT="${HW_SERVER_PORT:-3121}"

[ -f "$BITFILE" ] || { echo "Bitstream not found: $BITFILE" >&2; exit 2; }
[ -x "$HW_SERVER" ] || { echo "hw_server not found: $HW_SERVER" >&2; exit 2; }
[ -x "$XSDB" ] || { echo "xsdb not found: $XSDB" >&2; exit 2; }

server_started=0
server_pid=""
if ! (echo >/dev/tcp/127.0.0.1/"$PORT") >/dev/null 2>&1; then
    log="$(mktemp /tmp/basys3-hw-server.XXXXXX)"
    (env -u XILINX_PATH "$HW_SERVER" -s "tcp::$PORT" -L- >"$log" 2>&1) &
    server_pid=$!
    server_started=1
    ready=0
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        if (echo >/dev/tcp/127.0.0.1/"$PORT") >/dev/null 2>&1; then
            ready=1
            break
        fi
        sleep 0.2
    done
    if [ "$ready" -ne 1 ]; then
        echo "hw_server did not start; log: $log" >&2
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
        exit 1
    fi
fi

cleanup() {
    if [ "$server_started" -eq 1 ]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "Programming $BITFILE"
env -u XILINX_PATH "$XSDB" -quiet "$ROOT_DIR/scripts/program_xsdb.tcl" \
    "$BITFILE" "tcp:localhost:$PORT"
echo "Programming completed. Keep JP1 in JTAG while testing."
