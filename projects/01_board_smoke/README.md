# Project 01 — Basys3 Board Smoke Test

This is the first hardware acceptance test. It proves the clock, input pins,
LED outputs, seven-segment multiplexing, active-low display polarity, and
center-button reset before more ambitious logic is attempted.

## Behavior

- `SW[15:0]` appears on `LED[15:0]`.
- The four seven-segment digits show the switch bank as hexadecimal.
- The decimal point blinks as a heartbeat.
- Center resets the scanner and heartbeat divider.

## Build and program

The canonical source is also retained at `src/basys3_demo.sv` for compatibility
with the original Vivado scripts. The project-local copy and constraints are
provided for catalog browsing.

```bash
./scripts/build_openxc7_demo.sh
./scripts/program_openxc7_demo.sh
```

The verified artifact is also copied to `artifacts/bitstreams/basys3_demo.bit`.

## Interview story

This project is intentionally simple. It separates board bring-up from
algorithm development: if this fails, debugging should focus on power, clock,
constraints, I/O polarity, or programming—not on FIFO or protocol logic.
