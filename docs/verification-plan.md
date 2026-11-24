# Verification Plan

## Milestone 1 status

The current Milestone 1 implementation contains only functional RTL that has
an executable self-checking testbench:

- `rtl/stream_counter_generator.v`
- `rtl/stream_sequence_checker.v`
- `sim/tb_milestone1.v`
- `sim/run_iverilog.sh`

The first milestone did not claim a FIFO, PRBS source, UART, hardware
deployment, synthesis result, or measured throughput. The broader simulation
layer has now been added. Its current regression status is:

| Test | Result |
|---|---|
| `tb_milestone1` | PASS |
| `tb_stream_fifo` | PASS |
| `tb_stream_pipeline` | PASS |
| `tb_prbs` | PASS |
| `tb_uart_tx` | PASS |
| `tb_telemetry` | PASS |
| `top_streaming` elaboration | PASS |
| Python telemetry self-test | PASS |

The original Milestone 1 file list below is retained as historical progression
rather than a statement that later RTL is absent.

## Required checks

| Check | Testbench evidence |
|---|---|
| Synchronous reset | Generator/checker are held in reset, then observed after release. |
| First word | Generator presents zero after reset. |
| Backpressure | `ready=0` for four observations; valid and data must remain unchanged. |
| Accepted progression | Sixteen accepted generator transfers produce the next registered values 1 through 16. |
| Clean integration | Thirty-two accepted counter words produce zero checker errors. |
| Invalid cycles | Four valid words separated by invalid cycles produce five total words only after the final valid word. |
| Fault detection | Final word is changed to 99; exactly one word error is counted. |

## Important checker limitation

The checker compares each accepted word with its current expected value and
then increments the expected value. If a word is missing, the next word is
compared against the missing value and fails; subsequent words usually fail too
because the checker is now out of phase. This is useful for detecting a stream
problem but is not a resynchronizing diagnostic. A later version will include
sequence tags or a deliberate resynchronization policy.

## Running the test

With Icarus Verilog installed:

```bash
./sim/run_iverilog.sh
```

The wrapper compiles with Verilog-2001 mode, runs the testbench, prints its
diagnostics, and returns a failing process status unless the log contains the
explicit pass line.

If Vivado is installed, the same source files can be added to a simulation set
with `tb_milestone1` as the simulation top. The testbench uses only standard
Verilog constructs and does not require SystemVerilog.

## Vivado GUI procedure

1. Create a project in the workspace, select RTL project, and select the
   Basys 3 part `xc7a35tcpg236-1`.
2. Add `rtl/stream_counter_generator.v` and
   `rtl/stream_sequence_checker.v` as design sources.
3. Add `sim/tb_milestone1.v` as a simulation source.
4. In **Project Settings → Simulation**, select `tb_milestone1` as the top
   module and keep the simulator language in Verilog mode.
5. Run **Flow → Run Simulation → Run Behavioral Simulation**.
6. The Tcl console should print `MILESTONE1 PASS`. The waveform is useful for
   teaching, but the pass/fail checks in the testbench are the acceptance
   criterion.

If Vivado reports an elaboration error, capture the complete first error and
the source line before changing RTL. If simulation passes but synthesis later
fails, treat those as different problems: simulation validates functional
behavior, while synthesis validates whether the RTL can map to FPGA hardware.

## Additional verification layers

The following higher-level tests are now implemented and passing:

- `tb_stream_fifo` uses a reference queue for full, empty, simultaneous
  read/write, registered output, and randomized backpressure.
- `tb_stream_pipeline` checks the generator, fault injector, FIFO, checker, and
  performance counters together.
- `tb_prbs` checks the parallel PRBS-31 generator/checker and bit-error count.
- `tb_uart_tx` checks a complete 8-N-1 frame.
- `tb_telemetry` checks the fixed-width status message and coherent snapshot.

For future strengthening:

- Add randomized backpressure and a scoreboard that stores every accepted
  source word.
- Add assertions for the hold rule and for no acceptance when `valid=0`.
- Test reset at each phase of a transfer.

For hardware implementation and the next checker revision:

- Test empty read attempts, full write attempts, simultaneous read/write,
  occupancy boundaries, and the selected read-output latency.
- Compare a synthesizable FIFO against a behavioral reference queue.
- Inspect Vivado inference to confirm whether block RAM was used.
- Add sequence tags or a resynchronization policy to distinguish one lost word
  from a long cascade of expected-value mismatches.

For the complete system:

- Compare counters with an independent testbench reference model.
- Inject one-bit and multi-bit faults and count word errors separately from bit
  errors.
- Run implementation and require clean setup/hold timing at the 10 ns clock.
- Only then collect hardware UART results and label them as measured.

## Full regression

```bash
./scripts/run_simulation_local.sh
python3 host/python/monitor.py --self-test
```

The regression currently passes with Icarus Verilog 12.0 in the persistent
rootless local tool directory exposed by `scripts/run_simulation_local.sh`.
The host does not have a global simulator installation.

Yosys 0.52 also elaborated the complete `top_streaming` RTL and completed a
generic synthesis sanity pass. This is not an Artix-7 timing or utilization
result; Vivado remains required for those claims.
