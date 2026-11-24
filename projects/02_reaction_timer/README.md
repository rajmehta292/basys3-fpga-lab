# Project 02 — Reaction Timer

## What it demonstrates

This is a complete board-only reaction game. It teaches synchronized button
inputs, debouncing, finite-state machines, a small LFSR, time measurement,
and display/LED output control.

## Board controls

- Center button: reset.
- Up button: start a round from `IDLE` or `RESULT`.
- Down button: stop the timer after `GO` appears.
- Switches 15:8: XOR into the state LEDs for an easy visual I/O experiment.

## Display and LED meanings

| State | Display | LEDs |
|---|---|---|
| Idle | `0000` | `0001` |
| Random wait | `CAFE` | `00F0` plus switch experiment |
| React now | `600D` | all on |
| Valid result | hexadecimal tenths | `0F00` |
| Early press | `E001` | `F000` |

The result is deliberately hexadecimal tenths of a second, not a falsely
precise decimal measurement. A future version can convert the result to BCD.

## Build and program

```bash
cd /home/dmehta/Basys3
./scripts/build_openxc7_project.sh \
  projects/02_reaction_timer/rtl/reaction_timer.sv reaction_timer \
  constraints/basys3_project_openxc7.xdc build/projects/reaction_timer \
  projects/common/basys3_reset_sync.sv \
  projects/common/button_onepulse.sv \
  projects/common/basys3_display.sv
```

To program this project, point `scripts/program_openxc7_demo.sh` at the
generated `build/projects/reaction_timer/reaction_timer.bit`, or use the
generic XSDB command documented in `docs/openxc7-bringup.md`.

## Verification

The self-checking testbench exercises reset, a valid reaction, an early press,
and the state transitions using reduced simulation parameters:

```bash
./scripts/iverilog_local.sh -g2012 -s tb_reaction_timer -o /tmp/tb_reaction_timer \
  projects/02_reaction_timer/sim/tb_reaction_timer.sv \
  projects/02_reaction_timer/rtl/reaction_timer.sv \
  projects/common/basys3_reset_sync.sv projects/common/button_onepulse.sv \
  projects/common/basys3_display.sv
./scripts/vvp_local.sh /tmp/tb_reaction_timer
```

Expected result: `REACTION TIMER PASS`.

## Interview story

The interesting engineering choice is that button presses are not used as
clocks. They are synchronized into the 100 MHz domain, debounced, and reduced
to one-cycle events. The game itself is an explicit FSM, so every state and
transition is explainable and easy to verify.
