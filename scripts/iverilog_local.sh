#!/usr/bin/env bash
set -euo pipefail

IVERILOG_ROOT="${IVERILOG_ROOT:-/home/dmehta/openxc7/iverilog-root}"
exec "$IVERILOG_ROOT/usr/bin/iverilog" \
    -B "$IVERILOG_ROOT/usr/lib/x86_64-linux-gnu/ivl" "$@"
