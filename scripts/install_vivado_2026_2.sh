#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="${AMD_VIVADO_INSTALLER:-/home/dmehta/Downloads/FPGAs_AdaptiveSoCs_Unified_SDI_2026.2_1109_1430_Lin64.bin}"
CONFIG="${AMD_VIVADO_CONFIG:-$ROOT_DIR/installer/vivado_artix7_config.txt}"

if [[ ! -x "$INSTALLER" ]]; then
    echo "AMD installer not found or not executable: $INSTALLER" >&2
    exit 2
fi
if [[ ! -f "$CONFIG" ]]; then
    echo "Vivado install configuration not found: $CONFIG" >&2
    exit 2
fi

echo "Installing Vivado 2026.2 to /home/dmehta/AMD_FPGA/2026.2"
echo "If AMD requests an authentication token, run AuthTokenGen as documented in docs/installation-vivado.md."
exec "$INSTALLER" --nox11 -- \
    --agree XilinxEULA,3rdPartyEULA \
    --batch Install --config "$CONFIG"
