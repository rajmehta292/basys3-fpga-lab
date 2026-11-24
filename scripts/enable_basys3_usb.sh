#!/usr/bin/env bash
set -euo pipefail

# One-time convenience entry point. It asks sudo to authenticate locally,
# installs the persistent narrowly-scoped udev rule, and then verifies access
# as the original user. No password is read, stored, or passed to the script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/install_udev_rules.sh"
VERIFY="$SCRIPT_DIR/verify_host_access.sh"

if [ "$(id -u)" -ne 0 ]; then
    echo "One-time administrator authentication is required to install the persistent USB rule."
    echo "The rule is limited to Digilent VID 0403 / PID 6010 and preserves the UART channel."
    exec sudo "$0" "$@"
fi

"$INSTALLER" "$@"

# The installer runs as root, but the verification must run as the invoking
# desktop user so that it proves the user's actual device permissions.
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    exec sudo -u "$SUDO_USER" -- "$VERIFY" --probe-jtag
fi

echo "Root setup completed. Run $VERIFY --probe-jtag as the normal user."
