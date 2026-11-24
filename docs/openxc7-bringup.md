# Basys3 sample design bring-up

## Installed toolchain

The machine does not contain the full AMD Vivado Design Suite or its
installer. The working openXC7 path is installed at:

```text
/home/dmehta/openxc7/toolchain
/home/dmehta/openxc7/yosys-root
```

The openXC7 release supplies the Artix-7 place-and-route engine, device
database, FASM tools, and frame-to-bitstream converter. Yosys supplies RTL
synthesis. This is a real Verilog-to-bitstream flow, but it is not Vivado and
its timing/resource reports must be labeled as openXC7/nextpnr results.

The downloaded openXC7 archive was SHA-256 verified before extraction. The
device database contains the exact Basys3 part `xc7a35tcpg236-1`.

## Sample design

Source:

```text
src/basys3_demo.sv
constraints/basys3_demo_openxc7.xdc

The repository also retains `constraints/basys3_demo.xdc` for the full Vivado
flow. The openXC7 XDC intentionally omits Vivado-only configuration properties.
```

Expected behavior after programming:

- `LED[15:0]` mirrors `SW[15:0]`.
- The four-digit seven-segment display shows the switch value in hexadecimal.
- The decimal point blinks as a heartbeat.
- The center button resets the heartbeat/display scanner counter.

The board uses the 100 MHz oscillator on `W5`, the Basys3
`xc7a35tcpg236-1` part, active-low seven-segment signals, and the official
Basys3 package pins.

## Repeatable build

From `/home/dmehta/Basys3`:

```bash
./scripts/build_openxc7_demo.sh
```

Outputs are written to `build/openxc7/`:

```text
basys3_demo.json          synthesized netlist
basys3_demo.fasm         placed/routed configuration description
basys3_demo.frames       configuration frames
basys3_demo.bit          JTAG-programmable bitstream
basys3_demo.report.json  nextpnr timing/utilization report
build.log                checksum and build summary
```

The observed build completed successfully with nextpnr reporting a maximum
frequency of 372.58 MHz against the 100 MHz target. This is an openXC7 timing
estimate, not a Vivado static-timing result.

## Program the board

The persistent USB rule is installed and verified. Run:

```bash
./scripts/program_openxc7_demo.sh
```

The script starts the existing `hw_server` tools, uses XSDB over JTAG, programs
the bitstream, and shuts down only the server it started. A successful run
reports `Programming command completed.`

Keep JP1 in the JTAG position for volatile programming. The design disappears
after power removal unless a configuration-memory image is separately created.

## Physical verification

After programming:

1. Move the sixteen switches and confirm the corresponding LEDs follow them.
2. Read the four-digit display as a hexadecimal copy of the switch bank.
3. Confirm the decimal point blinks.
4. Press the center button and confirm the heartbeat/display scan restarts.

JTAG can prove configuration transfer, but it cannot prove what the LEDs look
like. The physical observation step is therefore part of the hardware
acceptance test.

## Vivado status

Vivado still requires an AMD account-authenticated installer. If the installer
is later placed on disk, use the existing Vivado scripts:

```bash
vivado -mode batch -source scripts/build_bitstream.tcl
vivado_lab -mode batch -source scripts/program_vivado_lab.tcl \
  -tclargs build/basys3_demo.bit
```

The openXC7 bitstream already provides a working Basys3 sample without waiting
for that proprietary installation.
