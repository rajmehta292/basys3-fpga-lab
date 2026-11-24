#!/usr/bin/env bash
set -euo pipefail

IVERILOG_ROOT="${IVERILOG_ROOT:-/home/dmehta/openxc7/iverilog-root}"
exec "$IVERILOG_ROOT/usr/bin/vvp" "$@"
