# Performance and Evidence Ledger

This file is intentionally conservative. A result is recorded only when the
corresponding experiment has actually run.

## Current evidence

| Item | Status | Evidence |
|---|---|---|
| 128-bit counter/checker simulation | PASS | `sim/run_iverilog.sh`; output includes `MILESTONE1 PASS`. |
| Generator holds data during `ready=0` | PASS | Four-cycle self-checking stall test. |
| Clean accepted-transfer checker path | PASS | Thirty-two accepted words, zero word errors in simulation. |
| Deliberate final-word corruption | PASS | One injected word mismatch counted. |
| 256-word FIFO boundary and randomized traffic | PASS | `tb_stream_fifo` reference-queue regression. |
| End-to-end backpressure pipeline | PASS | `tb_stream_pipeline`; FIFO reaches high-water mark and producer stalls. |
| Reset during active pipeline traffic | PASS | `tb_stream_pipeline`; reset restarts source, FIFO, checker, and counters cleanly. |
| Parallel PRBS-31 | PASS | `tb_prbs`; clean sequence and one-bit fault. |
| UART framing | PASS | `tb_uart_tx`; 8-N-1 frame verified at a reduced simulation divider. |
| UART telemetry serialization | PASS | `tb_telemetry`; 245-byte structured status line with transfer/stall/FIFO-attempt counters. |
| Python telemetry derivation | PASS | `host/python/monitor.py --self-test`. |
| Generic RTL synthesis/elaboration | PASS | Yosys 0.52 `read_verilog`, hierarchy, process, memory collection, check, and stat. |
| Generic XC7 resource estimate | INFORMATIONAL | Yosys `synth_xilinx -family xc7` estimated 2 `RAMB36E1` cells, 2,005 `FDRE` cells, and 967 LUT cells; not a Vivado result. |
| Fresh RTL regression on 2026-11-24 | PASS | Icarus Verilog 12.0 via `scripts/run_simulation_local.sh`; all six testbenches and `top_streaming` elaboration passed. |
| Fresh Python monitor check on 2026-11-24 | PASS | `host/python/monitor.py --self-test`. |
| Fresh Qt dashboard build on 2026-11-24 | PASS | Rootless Qt 6 SerialPort development files under `/home/dmehta/openqt`; `build/qt-live-20261123/basys3_monitor` built and has no missing runtime libraries. |
| OpenXC7 sample synthesis/place/route/bitstream | PASS | `build/openxc7/basys3_demo.bit`; nextpnr reported 372.58 MHz maximum estimate at a 100 MHz target; bitstream SHA-256 is recorded in `docs/openxc7-bringup.md` and `build/openxc7/build.log`. |
| Sample bitstream JTAG programming | PASS | `scripts/program_openxc7_demo.sh`; XSDB reported `Programming command completed.` |
| Reaction timer simulation | PASS | `projects/02_reaction_timer/sim/tb_reaction_timer.sv`; reset, valid reaction, and early press. |
| PWM breathing simulation | PASS | `projects/03_pwm_breathing/sim/tb_pwm_breathing.sv`; envelope movement and switch mask. |
| Stopwatch simulation | PASS | `projects/04_stopwatch/sim/tb_stopwatch.sv`; start, elapsed time, pause, and clear. |
| Reaction timer openXC7 implementation | PASS | `build/projects/reaction_timer`; 261.37 MHz openXC7 estimate at 100 MHz target. |
| PWM breathing openXC7 implementation | PASS | `build/projects/pwm_breathing`; 365.63 MHz openXC7 estimate at 100 MHz target. |
| Stopwatch openXC7 implementation | PASS | `build/projects/stopwatch`; 281.77 MHz openXC7 estimate at 100 MHz target. |
| USB/JTAG permissions | PASS | Raw USB node is `root:plugdev` mode `0660`; JTAG interface is unbound and UART remains on `/dev/ttyUSB1`. |
| Hardware JTAG enumeration | PASS | Direct XSDB probe found one Digilent Basys3 and `xc7a35t`, IDCODE `0362d093`, IR length 6. |
| Vivado synthesis | NOT RUN | Full Vivado is not currently on the host PATH. |
| 100 MHz timing closure | NOT RUN | No implementation report exists for this streaming RTL. |
| Basys 3 bitstream | NOT RUN | The current bitstream is the separate demo path, not this streaming design. |
| Hardware accepted-word throughput | NOT RUN | Counters and UART exist in RTL, but no bitstream has been programmed. |
| Physical 10 Gb/s link | NOT APPLICABLE TO BASELINE | The Basys 3 baseline is an internal datapath, not a 10 Gb/s transceiver link. |

## Measurement rules

When counters are added, record at minimum:

- device part and speed grade;
- Vivado version;
- RTL source snapshot;
- clock constraint and measured clock frequency;
- elapsed measurement cycles;
- accepted words and accepted bits;
- FIFO depth and high-water mark;
- producer/consumer stall cycles;
- setup WNS/TNS, hold WNS/TNS, and unconstrained-path count;
- LUT, flip-flop, block RAM, DSP, and clock-resource utilization;
- exact UART capture or host log for the reported run.

The headline throughput must be derived from the accepted-transfer count and
the measurement window. The 12.8 Gb/s figure remains a theoretical 128-bit ×
100 MHz peak until those fields are populated by a verified implementation.

The generic Yosys result is a syntax/elaboration sanity check only. It does not
replace Vivado's Artix-7 synthesis, RAM inference decision, placement, routing,
static timing, or device resource report. Its log is retained at
`results/synthesis/yosys_generic_top.log`.

The live XC7 estimate is retained at
`results/synthesis/yosys_xc7_estimate-live.log`. Yosys reported four
address-width resize warnings while mapping the inferred RAM. They are not
treated as timing or correctness proof; Vivado must review the actual
implementation and warnings.
