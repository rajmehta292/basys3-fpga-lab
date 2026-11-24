# Basys 3 bring-up log

Date: 2026-11-24

This is the machine-specific record of what was tested in `/home/dmehta/Basys3`.

## Board discovery

The connected USB device is:

```text
ID 0403:6010 Future Technology Devices International, Ltd FT2232C/D/H Dual UART/FIFO IC
Manufacturer: Digilent
Product:     Digilent USB Device
USB speed:   High Speed (480 Mbps)
Interfaces:  2 vendor-specific interfaces
Serial:      210183AB3C2F
```

Linux currently exposes `/dev/ttyUSB1` for the UART interface; the JTAG
interface is intentionally released from `ftdi_sio`. The Basys 3 manual
identifies the same FT2232HQ as the independent USB-JTAG and USB-UART bridge.
The raw USB node is user-accessible through `plugdev`, and the exact FPGA JTAG
chain has been read successfully.

## Host tools found

The workspace host has:

- Xilinx `hw_server`, `xsdb`, and `vivado_lab` under
  `/home/dmehta/xilinux-petalinux/components/xsct/bin`.
- Artix-7 `xc7a35t` part data and Digilent cable data in that installation.
- No full `vivado` synthesis executable on `PATH`.
- The reproducible local wrappers now provide Icarus Verilog 12.0, Yosys 0.52,
  and openXC7 under `/home/dmehta/openxc7`; they do not modify system packages.

`hw_server` starts successfully and listens on TCP port 3121. The live XSDB
probe reports one Digilent cable and the expected FPGA:

```text
digilent-ftdi cables 1
xilinx-ftdi cables 0
amd-uniflashpod cables 0
xilinx-pcusb cables 0
bscan-jtag cables 0
```

```text
1  Digilent Basys3 210183AB3C2FA
   2  xc7a35t (idcode 0362d093 irlen 6 fpga)
```

The persistent udev rule at `host/udev/60-basys3-xilinx.rules` is installed at
`/etc/udev/rules.d/60-basys3-xilinx.rules`. The current raw node is
`/dev/bus/usb/001/002`, mode `0660`, group `plugdev`; JTAG interface `1-1:1.0`
is unbound and UART interface `1-1:1.1` remains bound to `ftdi_sio`.

The first real build attempt was also recorded:

```text
make build
make: vivado: No such file or directory
```

The extracted installation cannot synthesize RTL with Vivado, but the separate
openXC7/Yosys toolchain under `/home/dmehta/openxc7` now provides a working
Artix-7 synthesis, placement, routing, and bitstream-generation path.

## Streaming software validation

The missing global tools were supplied in isolated temporary directories for
reproducible local checks without modifying the host package installation:

- Icarus Verilog 12.0 ran the complete RTL regression successfully.
- Yosys 0.52 completed generic and XC7 resource-estimate passes.
- Qt 6 SerialPort development files are available rootlessly under
  `/home/dmehta/openqt`, and the Qt dashboard compiles with
  `./scripts/build_qt_monitor.sh`.
- Python telemetry parsing and throughput derivation passed its self-test.
- The Qt dashboard was freshly rebuilt at
  `build/qt-live-20261123/basys3_monitor` with no unresolved shared libraries.

These are software and generic synthesis checks. They do not replace Vivado
placement/routing, static timing, or programming the physical FPGA.

## Hardware verification completed

```bash
./scripts/verify_host_access.sh --probe-jtag
```

The command returned `ACCESS RESULT: PASS`. The direct probe was also run:

```bash
env -u XILINX_PATH \
  /home/dmehta/xilinux-petalinux/components/xsct/bin/xsdb \
  -quiet scripts/probe_hardware.tcl tcp:localhost:3121
```

The expected chain contains a Digilent cable and an Artix-7 XC7A35T device.
Keep JP1 in the JTAG position for PC programming.

## What is not yet verified

- FPGA IDCODE and JTAG chain enumeration: PASS; `xc7a35t`, IDCODE `0362d093`.
- Synthesis, implementation, and bitstream generation: the installed package
  is Vivado Lab/XSCT hardware tooling, not the full Vivado design suite. The
  openXC7 path generated the sample `.bit` successfully.
- Sample bitstream JTAG programming: PASS; XSDB reported `Programming command
  completed.`
- Physical LED/display behavior for the original board smoke-test design:
  PASS — user verified the programmed design on the physical Basys3 on
  2026-11-24. JTAG programming alone would not have been sufficient evidence;
  this entry is explicitly based on that direct observation.
- UART telemetry on the physical board: the streaming top now includes UART TX
  and constraints, but no bitstream has been generated or programmed yet.

## Catalog expansion on 2026-11-24

Three additional board-only projects now have self-checking simulations and
openXC7-generated bitstreams:

```text
projects/02_reaction_timer  261.37 MHz estimate at 100 MHz target
projects/03_pwm_breathing   365.63 MHz estimate at 100 MHz target
projects/04_stopwatch       281.77 MHz estimate at 100 MHz target
```

The reaction-timer bitstream was programmed successfully through JTAG after
the original smoke-test verification. Physical visual confirmation of its
button/display behavior remains a separate human observation step.

The AMD 2026.2 installer was verified, but the installation stopped before
copying Vivado because the installer requires an AMD authentication token.
The exact recovery procedure is documented in
[`docs/installation-vivado.md`](installation-vivado.md).
