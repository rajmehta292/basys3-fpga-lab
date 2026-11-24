#!/usr/bin/env bash

# Source this file to make the locally installed openXC7 + rootless Yosys
# toolchain available in the current shell.

OPENXC7_ROOT="${OPENXC7_ROOT:-/home/dmehta/openxc7/toolchain}"
YOSYS_ROOT="${YOSYS_ROOT:-/home/dmehta/openxc7/yosys-root}"

if [ ! -f "$OPENXC7_ROOT/environment" ]; then
    echo "openXC7 environment not found: $OPENXC7_ROOT/environment" >&2
    return 1 2>/dev/null || exit 1
fi

# The openXC7 release supplies place/route and bitstream tools; synthesis is
# supplied separately by Yosys.
source "$OPENXC7_ROOT/environment"
export PATH="$YOSYS_ROOT/usr/bin:$PATH"
export YOSYS_DATDIR="$YOSYS_ROOT/usr/share/yosys"
export OPENXC7_ROOT YOSYS_ROOT

echo "openXC7 environment enabled"
echo "  nextpnr: $(command -v nextpnr-xilinx)"
echo "  yosys:   $(command -v yosys)"
