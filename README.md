# Basys3 Mastery Lab

Basys3 Mastery Lab is a local, guided learning environment for learning Verilog, Vivado, FPGA timing, constraints, simulation, and board-level debugging with the Digilent Basys3.

It is designed around a simple loop:

> predict → describe in HDL → simulate → build → program → observe → explain

The repository is organized as a student-to-interview portfolio. Start with
[`docs/README.md`](docs/README.md) for the learning sequence and
[`docs/project-catalog.md`](docs/project-catalog.md) for the project index.
Each project has its own README under [`projects/`](projects/).

Public portfolio mirror: <https://github.com/rajmehta292/basys3-fpga-lab>

## Start it

From this directory:

```bash
python3 run.py
```

Then open <http://127.0.0.1:8765>.

The server uses only the Python standard library. It checks the local machine for Vivado/Vivado Lab, `xsdb`, `iverilog`, Verilator, USB visibility, and serial devices. The browser sandbox works without any of those tools; the real compiler and board programming paths become available when the corresponding tools are installed and working.

## What is included

- Ten progressive missions from FPGA mental models through a capstone instrument.
- Persistent local progress, quizzes, code fragments, and “do this with your hands” experiments.
- A live signal sandbox for switches, LEDs, combinational logic, muxes, replication, and inversion.
- A Verilog playground with guided checks, a build journal, and an optional real `iverilog` compile.
- A Basys3 board explorer covering the clock, switches, LEDs, 7-segment display, buttons, PMODs, and VGA.
- Toolchain and USB diagnostics based on the actual local machine.
- Starter project generation under `generated/` with RTL, XDC constraints, and a short README.
- An explicit Vivado Lab JTAG programming path through `scripts/program.tcl`.

## Important boundary

The browser sandbox is a teaching model, not a replacement for synthesis, timing analysis, or physical observation. The lab makes that boundary visible on purpose: you should learn to predict in software, then verify the real result on the board.

The programming action never chooses a bitstream for you. You provide a `.bit` file inside this workspace and click the explicit program button.

## Companion lab assets

The `src/`, `constraints/`, `scripts/`, `host/`, and `docs/` folders are reserved for the executable Basys3 hardware lab being built alongside this learning layer. The learning app does not overwrite those files.

## Hardware guide

### Board identity and capabilities

The Basys 3 uses the Xilinx/AMD Artix-7 `XC7A35T-1CPG236C` FPGA. Its important
resources are 33,280 logic cells in 5,200 slices, 1,800 Kbits of block RAM, 90
DSP slices, five clock-management tiles, and an on-chip XADC. The board also
has a 100 MHz oscillator, 16 switches, 16 LEDs, five pushbuttons, a four-digit
seven-segment display, 12-bit VGA, three digital Pmod ports, an XADC Pmod,
USB HID host, USB-UART, USB-JTAG, and a 32-Mbit quad-SPI flash.

Authoritative references:

- [Digilent Basys 3 Reference Manual](https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys3_rm.pdf)
- [Digilent official master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Basys-3-Master.xdc)
- [AMD 7 Series FPGA Data Sheet, DS180](https://docs.amd.com/api/khub/documents/2LByHkO~nSZXcei2D55fTg/content)
- [AMD Artix-7 family page](https://www.amd.com/en/products/adaptive-socs-and-fpgas/fpga/artix-7.html)

An FPGA is configured hardware, not a CPU running Verilog line-by-line.
Synthesis maps RTL to LUTs, flip-flops, RAM, DSPs, clock resources, I/O, and
routing. Implementation places and routes those resources. The bitstream then
loads the FPGA's SRAM configuration cells.

### Hardware status on this machine

The connected board was detected as:

```text
USB VID:PID       0403:6010
Manufacturer      Digilent
Product           Digilent USB Device
USB speed         High Speed (480 Mbps)
Interfaces        2 vendor-specific FT2232 interfaces
Serial            210183AB3C2F
Linux nodes       /dev/ttyUSB1 (UART; JTAG uses raw USB)
```

This is the Basys 3's FT2232HQ bridge: one channel is JTAG and the other is
UART. The persistent udev setup now grants raw USB access, releases only the
JTAG interface, and preserves `/dev/ttyUSB1`. A live XSDB probe reports one
Digilent cable and the `xc7a35t` target with IDCODE `0362d093`. The evidence is
kept in [`docs/bringup-log.md`](docs/bringup-log.md).

The host has bundled `hw_server`, `xsdb`, and `vivado_lab` under
`/home/dmehta/xilinux-petalinux/components/xsct/bin`, plus Artix-7 part and
Digilent cable data. It does not have full `vivado` synthesis on `PATH`, and
the extracted `vivado_lab` lacks its bundled JRE. A persistent rootless
openXC7/Yosys toolchain is now installed under `/home/dmehta/openxc7` and is
the working Artix-7 build path for the sample design.

### Host setup and JTAG probe

Start with:

```bash
./scripts/check_environment.sh
```

For this installation, make the hardware tools visible in the current shell:

```bash
export BASYS3_XILINX_ROOT=/home/dmehta/xilinux-petalinux/components/xsct
unset XILINX_PATH
export XILINX_VITIS="$BASYS3_XILINX_ROOT"
export XILINX_SDK="$BASYS3_XILINX_ROOT"
export PATH="$BASYS3_XILINX_ROOT/bin:$PATH"
```

Install the narrowed udev rule once as root:

```bash
./scripts/enable_basys3_usb.sh
```

This single command requests local administrator authentication once, installs
the persistent rule, and runs the JTAG/UART verifier. No password is stored in
the project. The rule survives unplug/replug and reboot.

The rule grants the current desktop user raw USB access and releases only the
FT2232 JTAG interface from `ftdi_sio`; the USB-UART interface remains available
as `/dev/ttyUSB*`. Verify the result without sudo:

```bash
./scripts/verify_host_access.sh --probe-jtag
```

The one-time administrator boundary and expected evidence are documented in
[`docs/host-access.md`](docs/host-access.md). Do not give a password to a
script or to an agent; Linux intentionally requires the logged-in user to
authenticate this system rule installation.

Then run the server in one terminal and probe from another:

```bash
hw_server -q -s tcp::3121
xsdb -quiet scripts/probe_hardware.tcl
```

The expected chain contains a Digilent cable and an XC7A35T device. If it does
not, check board power, a data-capable Micro-USB cable, JP1, udev permissions,
and stale `hw_server` processes.

### First design and build flow

### Working openXC7 sample flow

The sample design can be built and programmed without the proprietary Vivado
Design Suite:

```bash
./scripts/run_simulation_local.sh
./scripts/build_openxc7_demo.sh
./scripts/program_openxc7_demo.sh
```

This produces and programs `build/openxc7/basys3_demo.bit`. The design mirrors
the switches to the LEDs, displays the switch value on the seven-segment
display, and blinks the decimal point. Details and measured output are in
[`docs/openxc7-bringup.md`](docs/openxc7-bringup.md).

`src/basys3_demo.sv` is the smoke-test design. It mirrors `SW[15:0]` to
`LED[15:0]`, displays the switch value as four hexadecimal digits, blinks the
decimal point, and clears the divider with `BTN_C`. The display scanner uses
the 100 MHz clock and the board's active-low anodes/cathodes.

The working constraints are in `constraints/basys3_demo.xdc`; the pin reference
is in `constraints/Basys-3-Master.xdc`. Full Vivado is required:

```bash
vivado -mode batch -source scripts/build_bitstream.tcl
```

This should produce `build/basys3_demo.bit`, `build/utilization.rpt`, and
`build/timing_summary.rpt`. The current machine's equivalent attempt fails
honestly with `vivado: No such file or directory`; no bitstream is claimed as
generated here.

Program a generated bitstream with a running `hw_server`:

```bash
xsdb -quiet scripts/program_xsdb.tcl build/basys3_demo.bit
```

Or use Vivado Lab Hardware Manager:

```bash
vivado_lab -mode batch \
  -source scripts/program_vivado_lab.tcl \
  -tclargs build/basys3_demo.bit
```

The existing app's Board Lab also exposes explicit starter-project generation
and bitstream programming. It never chooses a bitstream implicitly.

### Pin and electrical map

The top-level HDL names are logical names; XDC maps them to package pins and
sets electrical standards. Regular board I/O is 3.3 V `LVCMOS33`. Never connect
a 5 V signal directly to an FPGA I/O.

| Function | FPGA pins |
|---|---|
| 100 MHz clock | W5 |
| Switches 0..15 | V17 V16 W16 W17 W15 V15 W14 W13 V2 T3 T2 R3 W2 U1 T1 R2 |
| LEDs 0..15 | U16 E19 U19 V19 W18 U15 U14 V14 V13 V3 W3 U3 P3 N3 P1 L1 |
| Buttons C/U/L/R/D | U18 T18 W19 T17 U17 |
| 7-seg A..G | W7 W6 U8 V8 U5 V5 U7 |
| 7-seg DP | V7 |
| Anodes 0..3 | U2 U4 V4 W4 |
| UART FPGA RX/TX | B18 / A18 |
| VGA red | G19 H19 J19 N19 |
| VGA blue | N18 L18 K18 J18 |
| VGA green | J17 H17 G17 D17 |
| VGA H/V sync | P19 / R19 |
| Pmod JA | J1 L2 J2 G2 H1 K2 H2 G3 |
| Pmod JB | A14 A16 B15 B16 A15 A17 C15 C16 |
| Pmod JC | K17 M18 N17 P18 L17 M19 P17 R18 |
| XADC Pmod | J3 L3 M2 N2 K3 M3 M1 N1 |
| Quad-SPI DQ0..DQ3 / CS | D18 D19 G18 F18 / K19 |

The Pmod ports are 8-bit 3.3 V expansion interfaces with VCC and ground pins.
Check a peripheral's voltage, current, direction, and timing before attaching
it. The JXADC connector routes four differential-capable analog pairs to the
Artix-7 XADC, subject to the device's analog configuration and noise limits.

### Programming modes and memory

JP1 selects the configuration source:

- **JTAG:** PC/Vivado or XSDB; fast iteration; volatile.
- **SPI:** onboard 32-Mbit flash; automatic power-on boot.
- **USB:** a `.bit` file on a FAT32 USB stick through the board's USB host path.

JTAG configuration disappears after PROG or power removal. To boot without a
PC, generate a configuration-memory image, program the onboard flash with
Vivado, and set JP1 to SPI. A 35T configuration uses a little over 2 MB, so the
flash can also retain user data depending on the image and layout.

### Display, UART, VGA, and HID patterns

The four seven-segment digits share the CA..CG/DP cathode bus. Drive exactly
one active-low anode at a time, select that digit's cathode pattern, and scan
quickly enough to avoid flicker. Ghosting usually means wrong polarity, too
slow a scan, or overlapping enables.

The FT2232 UART is independent of JTAG. B18 is FPGA receive and A18 is FPGA
transmit from the PC's point of view. A UART bridge does not create a UART in
the FPGA: instantiate one, choose a baud rate such as 115200 8-N-1, and derive
its divider from the actual clock.

VGA has four binary-weighted bits per color plus Hsync/Vsync. A standard first
mode is 640×480 at 60 Hz with a 25 MHz pixel clock. Generate that clock with a
proper divider/MMCM/PLL and constrain it. A VGA controller normally uses
horizontal and vertical counters, visible-area tests, and either a framebuffer
or a procedural pixel generator.

The USB HID controller can present a keyboard or mouse to the FPGA through a
PS/2-like interface on C17/B17. The raw signals are idle-high and require
appropriate pull-ups and protocol timing; synchronize them before using them
in system logic.

### Clock, reset, and input discipline

Use the 100 MHz oscillator as the main synchronous clock. A button or switch is
not a clock: synchronize asynchronous inputs, debounce mechanical buttons, and
edge-detect control events. Prefer one main clock and a deliberate synchronous
reset. Reset state machines, counters, valid flags, FIFOs, and outputs to
known values.

Every clock needs a timing constraint. The demo's `create_clock -period 10`
means a 100 MHz source. Generated clocks and clock-domain crossings need their
own design and constraints; do not hide timing failures with broad false-path
exceptions.

### The professional FPGA loop

1. Specify ports, clocks, resets, protocols, and timing.
2. Write RTL and a testbench; avoid accidental latches and width mismatches.
3. Constrain every external port, clock, and intentional timing exception.
4. Synthesize and inspect inferred hardware and critical warnings.
5. Place and route; review DRC and setup/hold slack.
6. Generate a bitstream only after timing is clean.
7. Program by JTAG, observe with LEDs/UART, and use ILA for internal signals.
8. Move to SPI flash only after the JTAG version is repeatable.

The verification ladder is lint/static checks → simulation → synthesis/resource
review → timing → hardware smoke test → ILA/protocol debug. A design that
works once but has unconstrained paths is not finished.

### Troubleshooting checklist

**USB visible, zero JTAG cables:** install the udev rule, replug, restart
`hw_server`, and check that `ftdi_sio` is no longer bound.

**Vivado Lab does not start:** the current extracted package is missing its
bundled JRE; install a complete Vivado Lab/Vivado distribution.

**Powered board, no device:** verify the cable carries data, JP1 is JTAG,
press PROG, and ensure the bitstream targets `xc7a35tcpg236-1`.

**Blank or wrong LEDs/display:** verify top-level port names, XDC bit ordering,
active-low anodes/cathodes, the 100 MHz clock constraint, and that no external
module drives the same pins.

**Timing failure:** pipeline long paths, use the right clock resources, handle
CDC explicitly, and fix the underlying path rather than suppressing warnings.

### Repository map

```text
src/basys3_demo.sv             first RTL smoke test
constraints/basys3_demo.xdc    active demo constraints
constraints/Basys-3-Master.xdc compact pin reference
scripts/check_environment.sh   USB/tool diagnostics
scripts/enable_basys3_usb.sh   one-time persistent USB setup wrapper
scripts/install_udev_rules.sh  root-level JTAG access implementation
scripts/verify_host_access.sh  non-root UART/JTAG access verifier
scripts/openxc7_env.sh         openXC7/Yosys environment setup
scripts/build_openxc7_demo.sh  openXC7 Basys3 bitstream build
scripts/program_openxc7_demo.sh openXC7 Basys3 JTAG programming
scripts/run_simulation_local.sh persistent local RTL regression
scripts/build_qt_monitor.sh    rootless Qt telemetry-dashboard build
scripts/run_catalog_checks.sh  all-project simulation and host regression
scripts/build_project_catalog.sh all-project openXC7 builds
scripts/build_bitstream.tcl    non-project Vivado build
scripts/create_project.tcl     managed Vivado project creation
scripts/probe_hardware.tcl     read-only XSDB probe
scripts/program_xsdb.tcl       XSDB programming
scripts/program_vivado_lab.tcl Vivado Lab programming
host/udev/                      narrowed Digilent FT2232 rule
docs/bringup-log.md             dated evidence and blockers
docs/architecture.md            corrected streaming architecture and risks
docs/verification-plan.md       milestone gates and test criteria
docs/learning-notes.md          first-principles RTL walkthrough
docs/performance-results.md     conservative evidence ledger
docs/interview-prep.md          milestone-based interview preparation
docs/register-map.md            planned telemetry fields; no bus yet
rtl/                            synthesizable streaming RTL by milestone
sim/                            self-checking simulations and runners
host/python/                    telemetry parser and throughput derivation
run.py + lab_app/               interactive teaching surface
Makefile                        command aliases
```

## Current completion status

### Streaming project: verified RTL and simulation

The high-speed streaming project is being built incrementally beside the board
smoke test. The corrected architecture, evidence rules, and milestone gates
are in [`docs/architecture.md`](docs/architecture.md). The first executable
implementation is now a complete simulation-capable internal validation path
using a proper valid/ready contract:

```text
counter generator --valid/data--> sequence checker
        accepted only when valid && ready
```

Complete Milestone 1 files:

```text
rtl/stream_counter_generator.v
rtl/stream_sequence_checker.v
rtl/stream_fifo.v
rtl/performance_counters.v
rtl/fault_injector.v
rtl/prbs_generator.v
rtl/prbs_checker.v
rtl/uart_tx.v
rtl/telemetry_controller.v
rtl/top_streaming.v
constraints/basys3_streaming.xdc
sim/tb_milestone1.v
sim/tb_stream_fifo.v
sim/tb_stream_pipeline.v
sim/tb_prbs.v
sim/tb_uart_tx.v
sim/tb_telemetry.v
sim/run_iverilog.sh
sim/run_all.sh
```

Run it with:

```bash
./sim/run_iverilog.sh
```

Run the complete regression with:

```bash
make sim-all IVERILOG=/path/to/iverilog VVP=/path/to/vvp
```

When full Vivado is installed:

```bash
make build-streaming
```

This creates `results/hardware/basys3_streaming.bit`, utilization reports, and
setup/hold timing reports only if synthesis and implementation complete
successfully. The default streaming top uses the center button for reset, the
up button to start, the down button to stop, SW0 for bit-0 fault injection,
LED0..LED3 for running/error/full/completed, and the FPGA UART TX pin for
telemetry. The exact mappings are in `constraints/basys3_streaming.xdc`.

The verification criteria and limitations are documented in
[`docs/verification-plan.md`](docs/verification-plan.md), and the teaching
notes are in [`docs/learning-notes.md`](docs/learning-notes.md). The RTL,
simulation, and host-parser results are verified; synthesis, timing closure,
bitstream programming, and measured hardware throughput remain external
hardware/toolchain gates.

Completed and verified:

- USB discovery of the connected Digilent FT2232 bridge.
- A full starter RTL design and matching active constraints.
- Complete simulation-capable streaming RTL: FIFO, counters, fault injection,
  PRBS-31, UART telemetry, and Basys 3 top level.
- Self-checking regression for reset, handshake stability, FIFO boundaries,
  randomized backpressure, fault detection, PRBS bit errors, UART framing, and
  telemetry serialization.
- Python telemetry parser with independently derived throughput and BER.
- Read-only hardware probe path through XSDB/hw_server.
- Build/program Tcl and Makefile automation.
- Host-access rule and exact instructions for the root-only step.
- Ten-lesson teaching app, signal sandbox, health API, and repaired frontend.
- Documented board architecture, pins, electrical rules, toolflow, and debug
  practices.

Still blocked by external prerequisites, not by missing documentation:

- Vivado-specific synthesis/implementation reports until the AMD Vivado
  installer is obtained and installed.
- Physical observation of the full streaming top until its separate streaming
  bitstream is generated and programmed. The Basys3 sample design itself has
  already been programmed successfully through JTAG.
