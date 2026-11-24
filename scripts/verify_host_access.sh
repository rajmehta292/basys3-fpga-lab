#!/usr/bin/env bash
set -u

# Verify that the current user can access the Basys 3's UART and raw JTAG
# device, and optionally perform a read-only hw_server/XSDB cable probe.
# This script never asks for a password and never uses sudo.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XILINX_ROOT="${XILINX_ROOT:-/home/dmehta/xilinux-petalinux/components/xsct}"
PROBE=0
if [ "${1:-}" = "--probe-jtag" ]; then
    PROBE=1
fi

failures=0
pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; failures=$((failures + 1)); }

echo "Basys 3 host-access verification"
echo "workspace: $ROOT_DIR"
echo "user: $(id -un) (uid=$(id -u))"

groups=" $(id -nG) "
case "$groups" in
    *" dialout "*) pass "user is in dialout; serial access does not require root" ;;
    *) fail "user is not in dialout; UART access will require a group change and re-login" ;;
esac

case "$groups" in
    *" plugdev "*) pass "user is in plugdev; raw USB rule can grant JTAG access" ;;
    *) warn "user is not in plugdev; the installed rule's uaccess tag may still work on a desktop session" ;;
esac

serial_found=0
for port in /dev/ttyUSB* /dev/ttyACM*; do
    [ -e "$port" ] || continue
    serial_found=1
    if [ -r "$port" ] && [ -w "$port" ]; then
        pass "serial node is readable and writable: $port ($(stat -c '%A %U:%G' "$port"))"
    else
        fail "serial node is not usable by this user: $port ($(stat -c '%A %U:%G' "$port"))"
    fi
done
[ "$serial_found" -eq 1 ] || warn "no /dev/ttyUSB* or /dev/ttyACM* node is currently present"

basys_found=0
for dev in /sys/bus/usb/devices/*; do
    [ -f "$dev/idVendor" ] || continue
    [ "$(cat "$dev/idVendor")" = "0403" ] || continue
    [ "$(cat "$dev/idProduct" 2>/dev/null)" = "6010" ] || continue
    basys_found=1
    bus="$(cat "$dev/busnum")"
    number="$(cat "$dev/devnum")"
    raw="$(printf '/dev/bus/usb/%03d/%03d' "$bus" "$number")"
    echo "USB device: $raw serial=$(cat "$dev/serial" 2>/dev/null || echo unknown)"
    if [ -r "$raw" ] && [ -w "$raw" ]; then
        pass "raw USB node is readable and writable: $raw ($(stat -c '%A %U:%G' "$raw"))"
    else
        fail "raw USB node is not writable by this user: $raw ($(stat -c '%A %U:%G' "$raw"))"
        echo "      Install the rule once with: sudo $ROOT_DIR/scripts/install_udev_rules.sh"
    fi
    jtag_name="$(basename "$dev"):1.0"
    uart_name="$(basename "$dev"):1.1"
    for iface in "$dev":1.0 "$dev":1.1; do
        [ -e "$iface" ] || continue
        name="$(basename "$iface")"
        driver="$(basename "$(readlink "$iface/driver" 2>/dev/null || echo unbound)")"
        if [ "$name" = "$jtag_name" ]; then
            if [ "$driver" = "unbound" ] || [ "$driver" = "usbfs" ]; then
                pass "JTAG interface $name is available for raw JTAG access ($driver)"
            else
                warn "JTAG interface $name is still claimed by $driver"
            fi
        elif [ "$name" = "$uart_name" ]; then
            if [ "$driver" = "ftdi_sio" ]; then
                pass "UART interface $name remains bound to ftdi_sio"
            else
                warn "UART interface $name is not bound to ftdi_sio ($driver)"
            fi
        fi
    done
done
[ "$basys_found" -eq 1 ] || warn "Digilent FT2232 device 0403:6010 is not currently connected"

if [ "$PROBE" -eq 1 ]; then
    hw="$XILINX_ROOT/bin/hw_server"
    xsdb="$XILINX_ROOT/bin/xsdb"
    if [ ! -x "$hw" ] || [ ! -x "$xsdb" ]; then
        fail "--probe-jtag requested, but bundled hw_server/xsdb are missing under $XILINX_ROOT/bin"
    else
        log="$(mktemp /tmp/basys3-hw-server.XXXXXX)"
        port=3121
        (env -u XILINX_PATH "$hw" -s tcp::${port} -L- >"$log" 2>&1) &
        server_pid=$!
        connected=0
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            if (echo >/dev/tcp/127.0.0.1/$port) >/dev/null 2>&1; then
                connected=1
                break
            fi
            sleep 0.2
        done
        if [ "$connected" -eq 0 ]; then
            fail "hw_server did not listen on tcp:localhost:$port; log retained at $log"
        else
            probe="$(env -u XILINX_PATH "$xsdb" -eval 'connect -url tcp:localhost:3121; set js [jtag servers]; set jt [jtag targets]; puts "JTAG_SERVERS=$js"; puts "JTAG_TARGETS=$jt"; disconnect' 2>&1)"
            printf '%s\n' "$probe"
            case "$probe" in
                *"digilent-ftdi cables 1"*) pass "hw_server can see a Digilent JTAG cable" ;;
                *) fail "hw_server cannot see a Digilent JTAG cable; inspect the probe output above and $log" ;;
            esac
        fi
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "ACCESS RESULT: PASS"
    exit 0
else
    echo "ACCESS RESULT: $failures check(s) need attention"
    exit 1
fi
