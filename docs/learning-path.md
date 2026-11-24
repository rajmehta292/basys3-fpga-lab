# Student Learning Path

## Stage 0 — Hardware mental model

An FPGA is a configurable digital circuit. Verilog describes relationships
between signals and state; it is not a sequential program executed by a CPU.
Synthesis maps those relationships into LUTs, flip-flops, RAM blocks, clock
resources, I/O cells, and routing.

## Stage 1 — Synchronous RTL

Start with `projects/01_board_smoke`. Learn the 100 MHz clock, rising-edge
state updates, nonblocking assignments, active-low display outputs, and why a
clock divider changes an observation rate without creating a new clock domain.

## Stage 2 — Inputs and finite-state machines

Study `projects/02_reaction_timer`. A button is an asynchronous, mechanical
input. The design synchronizes it, filters bounce, and creates a one-cycle
event. The game is then an explicit FSM: IDLE → WAITING → GO → RESULT.

## Stage 3 — Time and PWM

Study `projects/03_pwm_breathing` and `projects/04_stopwatch`. Compare a binary
PWM counter with a decimal BCD counter. Both are synchronous counters, but
they solve different measurement and presentation problems.

## Stage 4 — Handshake and buffering

Study the streaming RTL. A transfer happens only when `valid && ready`. A
producer must hold data and valid stable while stalled. A FIFO absorbs a rate
mismatch but does not create bandwidth; overflow and underflow remain design
errors to measure and report.

## Stage 5 — Verification

Read the scoreboards and randomized backpressure tests. A testbench drives
inputs, models expected behavior, and fails automatically. Waveforms explain a
failure; assertions and scoreboards decide whether the test passed.

## Stage 6 — Implementation and timing

Run synthesis, placement, routing, and static timing. For the 100 MHz target,
the required period is 10 ns. Positive setup and hold slack, zero unconstrained
paths, and a reviewed utilization report are required before claiming a
hardware operating point.

## Stage 7 — Host integration

Read the Python and Qt host code, then relate it to the old architecture:
FPGA registers or buffers → ARM memory-mapped interface → Linux → TCP → Qt.
The Basys3 UART path is an observability channel, not a replacement for GPMC,
DMA, Linux drivers, or TCP framing.
