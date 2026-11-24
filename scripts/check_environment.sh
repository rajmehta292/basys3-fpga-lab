#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XILINX_ROOT="${XILINX_ROOT:-/home/dmehta/xilinux-petalinux/components/xsct}"

echo "Basys 3 environment check"
echo "workspace: $ROOT_DIR"
echo
echo "USB devices:"
if command -v lsusb >/dev/null 2>&1; then
    lsusb -d 0403:6010 || echo "  no Digilent FT2232 USB device found"
else
    echo "  lsusb is not installed"
fi

echo
echo "Serial nodes:"
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null || echo "  none"

echo
echo "Raw USB node permissions:"
for dev in /sys/bus/usb/devices/*; do
    [ -f "$dev/idVendor" ] || continue
    [ "$(cat "$dev/idVendor")" = "0403" ] || continue
    [ "$(cat "$dev/idProduct" 2>/dev/null)" = "6010" ] || continue
    bus="$(cat "$dev/busnum")"
    number="$(cat "$dev/devnum")"
    node=$(printf '/dev/bus/usb/%03d/%03d' "$bus" "$number")
    ls -l "$node"
done

echo
echo "Kernel driver bindings:"
for iface in /sys/bus/usb/devices/*:1.0 /sys/bus/usb/devices/*:1.1; do
    [ -e "$iface" ] || continue
    case "$(cat "$iface/../idVendor" 2>/dev/null):$(cat "$iface/../idProduct" 2>/dev/null)" in
        0403:6010)
            printf '%s -> ' "$iface"
            readlink "$iface/driver" 2>/dev/null || echo "unbound"
            ;;
    esac
done

echo
echo "Tool paths:"
for tool in vivado vivado_lab hw_server xsdb iverilog verilator yosys nextpnr-xilinx; do
    printf '  %-16s' "$tool"
    command -v "$tool" 2>/dev/null || echo "not on PATH"
done

echo
echo "Bundled Xilinx hardware tools:"
for tool in vivado_lab hw_server xsdb; do
    if [ -x "$XILINX_ROOT/bin/$tool" ]; then
        echo "  $XILINX_ROOT/bin/$tool"
    else
        echo "  missing: $XILINX_ROOT/bin/$tool"
    fi
done

echo
echo "Interpretation: a usable Xilinx JTAG session should show a Digilent cable and an XC7A35T device."
echo "If the cable count is zero, install host/udev/60-basys3-xilinx.rules as root and replug the board."
