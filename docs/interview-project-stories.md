# Interview-Ready Project Stories

## Thirty-second overview

“I built a Basys3 FPGA learning and validation catalog. I started with a
constraint and I/O smoke test, then built a reaction timer, PWM LED controller,
and decimal stopwatch to practice synchronous RTL. The main project is a
128-bit internal streaming path with valid/ready flow control, a 256-word FIFO,
sequence checking, PRBS, fault injection, counters, UART telemetry, and
self-checking simulations. I separate openXC7 evidence from Vivado evidence and
do not report theoretical bandwidth as measured hardware throughput.”

## Why the smaller projects matter

They are not toy distractions. Each isolates a class of failure:

- smoke test isolates pins and clocking;
- reaction timer isolates input conditioning and FSM control;
- PWM isolates rate generation and duty-cycle reasoning;
- stopwatch isolates decimal state and rollover;
- streaming combines those foundations with buffering and verification.

## Strong follow-ups

**What would you improve?** Add a clock-enable-based debouncer shared by all
projects, formal properties for FIFO invariants, Vivado timing reports, and a
UART snapshot protocol with sequence numbers and CRC.

**Why not call 12.8 Gb/s achieved?** Because 128 bits × 100 MHz is only the
internal peak expression. Achieved throughput requires accepted-word counters,
an elapsed measurement window, timing closure, and evidence that no stalls or
errors occurred.

**How does this relate to your old GPMC project?** The new project rebuilds
transfer, buffering, integrity, and host-observability knowledge. It does not
retroactively prove the undocumented details of the AM3358/GPMC implementation.
