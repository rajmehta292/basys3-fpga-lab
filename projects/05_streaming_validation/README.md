# Project 05 — High-Speed Streaming and Integrity Validation

This is the main engineering project. It models a 128-bit internal stream at a
100 MHz target clock and validates accepted transfers through a FIFO, sequence
checker, performance counters, fault injection, PRBS-31, UART telemetry, and
backpressure tests.

## Canonical implementation

The reusable RTL is in the repository-level `rtl/` directory and the
self-checking simulations are in `sim/`. Keeping one canonical RTL copy avoids
the documentation and implementation drifting apart.

Important files:

- `rtl/stream_counter_generator.v` — valid/ready counter producer.
- `rtl/stream_fifo.v` — synchronous 128-bit FIFO.
- `rtl/stream_sequence_checker.v` — accepted-transfer checker.
- `rtl/prbs_generator.v`, `rtl/prbs_checker.v` — parallel PRBS-31 path.
- `rtl/performance_counters.v` — transfer, stall, and error metrics.
- `rtl/fault_injector.v` — controlled corruption.
- `rtl/uart_tx.v`, `rtl/telemetry_controller.v` — statistics telemetry.
- `rtl/top_streaming.v` — Basys3-facing integration top.

## Evidence status

The complete RTL regression passes, including randomized backpressure, FIFO
boundaries, reset during traffic, PRBS errors, UART framing, and telemetry.
The openXC7 sample flow has been proven on the board, but the streaming top
still requires a dedicated full hardware bitstream and UART capture before any
hardware throughput claim is made.

```bash
./scripts/run_simulation_local.sh
python3 host/python/monitor.py --self-test
```

## Interview story

The defensible claim is an internally validated 128-bit streaming architecture,
not a physical 10 Gb/s link. The accepted-transfer handshake is the key: data
and sequence state advance only on `valid && ready`, so backpressure cannot
silently drop words.
