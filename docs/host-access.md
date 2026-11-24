# Basys 3 host-access and privilege boundary

## The short answer

The current Linux account is already configured for normal serial use:

```text
groups: dialout, plugdev
/dev/ttyUSB0: root:dialout, user-readable and user-writable
/dev/ttyUSB1: root:dialout, user-readable and user-writable
```

There is one remaining privileged operation: installing a udev rule under
`/etc/udev/rules.d` and releasing the board's JTAG FT2232 interface from the
kernel `ftdi_sio` driver. That action changes system device policy and writes a
protected sysfs control, so Linux requires the user to authenticate with sudo.
An agent or a project script must not bypass that boundary or receive the
password.

Run exactly once from the repository root:

```bash
./scripts/enable_basys3_usb.sh
```

This wrapper asks for administrator authentication locally through sudo, then
calls the root installer and runs the non-root verifier. The script is
idempotent. It installs
`/etc/udev/rules.d/60-basys3-xilinx.rules`, reloads udev, releases the current
JTAG interface if necessary, and leaves the UART interface attached. On later
board reconnects the rule repeats the JTAG-channel action automatically.

After that command, all verification and normal project work can run as the
ordinary user:

```bash
./scripts/verify_host_access.sh --probe-jtag
```

A successful result includes:

```text
PASS  user is in dialout; serial access does not require root
PASS  raw USB node is readable and writable
PASS  JTAG interface ...:1.0 is unbound from ftdi_sio
PASS  UART interface ...:1.1 remains bound to ftdi_sio
...
PASS  hw_server can see a Digilent JTAG cable
ACCESS RESULT: PASS
```

The final board-specific proof is an XSDB probe that reports a Digilent cable
and an Artix-7 target. This is stronger than merely seeing `/dev/ttyUSB*`:
serial visibility proves UART access, while cable enumeration proves the raw
JTAG path.

## Why root is involved

Linux protects two different interfaces here:

1. The UART is exposed as character devices owned by group `dialout`. The
   account already belongs to that group, so no root is needed.
2. JTAG is accessed through the raw USB device node and the FT2232 interface
   driver. The raw node currently defaults to `root:root` and the kernel
   `ftdi_sio` driver claims the JTAG interface. A udev rule changes the node's
   group/mode and unbinds only interface `00` so `hw_server` can claim it.

The rule intentionally does not unbind interface `01`, because that is the
USB-UART channel used by the telemetry monitor. This avoids the older failure
mode where making JTAG work accidentally removed the serial console.

## If verification still fails

Capture the complete output of:

```bash
./scripts/verify_host_access.sh --probe-jtag
```

Then check the specific evidence:

- `raw USB node is not writable`: reconnect the board after the installer and
  confirm the installed rule with `ls -l /etc/udev/rules.d/60-basys3-xilinx.rules`.
- `JTAG interface ...:1.0 is still claimed`: rerun the installer once with
  sudo while the board is connected, then reconnect it.
- `hw_server` cable count is zero after both checks pass: ensure no other
  `hw_server` owns port 3121, keep JP1 in JTAG, use a data-capable Micro-USB
  cable, and inspect the retained `/tmp/basys3-hw-server.*` log.
- UART disappears: do not unbind interface `01`; the repository rule should
  only touch interface `00`. Reconnect the board to restore normal udev
  enumeration.

Do not solve a permission problem with `chmod 666` on every USB device, broad
recursive permissions, or a password embedded in a script. The project rule is
narrowly matched to Digilent VID `0403`, PID `6010`, and manufacturer
`Digilent`.

## What the agent can and cannot do

The agent can inspect the board, write and test project files, run simulations,
start read-only hardware probes, build host tools, and produce exact commands.
It cannot legitimately self-authorize a protected system change or receive a
password. Once the wrapper's local sudo prompt is authenticated, the remaining
setup is designed to run without elevated privileges and the verifier makes
the result observable.
