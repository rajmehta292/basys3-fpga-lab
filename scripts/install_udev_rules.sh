#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULE_SRC="$ROOT_DIR/host/udev/60-basys3-xilinx.rules"
RULE_DST="/etc/udev/rules.d/60-basys3-xilinx.rules"

if [ "$(id -u)" -ne 0 ]; then
    echo "This is the one operation that needs administrator authentication." >&2
    echo "Run: sudo $0" >&2
    exit 1
fi

install -D -m 0644 "$RULE_SRC" "$RULE_DST"
udevadm control --reload-rules

# Apply the rule immediately to the currently connected board. On future
# reconnects the ACTION=="bind" rule in the installed file performs the same
# JTAG-channel unbind automatically.
found=0
for iface in /sys/bus/usb/devices/*:1.0; do
    [ -e "$iface" ] || continue
    vendor_file="$iface/../idVendor"
    product_file="$iface/../idProduct"
    manufacturer_file="$iface/../manufacturer"
    [ -f "$vendor_file" ] || continue
    [ "$(cat "$vendor_file")" = "0403" ] || continue
    [ "$(cat "$product_file" 2>/dev/null)" = "6010" ] || continue
    [ "$(cat "$manufacturer_file" 2>/dev/null)" = "Digilent" ] || continue
    driver="$(basename "$(readlink "$iface/driver" 2>/dev/null || echo none)")"
    if [ "$driver" = "ftdi_sio" ]; then
        printf '%s' "$(basename "$iface")" > /sys/bus/usb/drivers/ftdi_sio/unbind
        found=1
        echo "Released JTAG interface $(basename "$iface") from ftdi_sio."
    fi
done

# Re-evaluate device-node permissions without touching unrelated USB devices.
udevadm trigger --action=change --subsystem-match=usb --attr-match=idVendor=0403 --attr-match=idProduct=6010 || true

echo "Installed $RULE_DST"
if [ "$found" -eq 0 ]; then
    echo "No currently bound Basys 3 JTAG interface was found; reconnect the board once."
fi
echo "Now run: ./scripts/verify_host_access.sh --probe-jtag"
