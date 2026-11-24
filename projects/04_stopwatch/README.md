# Project 04 — Decimal Stopwatch

## What it demonstrates

This project is a board-only decimal stopwatch with start/pause, clear, a
10-Hz timebase, BCD digit rollover, and a multiplexed four-digit display.

## Board controls

- Center: reset unconditionally.
- Up: toggle running/paused.
- Down: clear the time while paused.
- Switches: copied to LEDs except LED0, which indicates running.

The display format is `M:SSt`: one minute digit, two seconds digits, and a
tenths digit. It rolls over after 9:59.9 to 0:00.0.

## Build

```bash
cd /home/dmehta/Basys3
./scripts/build_openxc7_project.sh \
  projects/04_stopwatch/rtl/stopwatch.sv stopwatch \
  constraints/basys3_project_openxc7.xdc build/projects/stopwatch \
  projects/common/basys3_reset_sync.sv projects/common/button_onepulse.sv \
  projects/common/basys3_display.sv
```

The resulting bitstream is `build/projects/stopwatch/stopwatch.bit`.

## Verification

The self-checking simulation verifies reset, start, elapsed tenths, pause, and
clear using a reduced clock divider. Expected result: `STOPWATCH PASS`.

## Interview story

The stopwatch illustrates why a binary counter is not automatically a decimal
display value. The RTL keeps each BCD digit legal and explicitly handles the
carry chain from tenths to seconds and minutes. It also demonstrates that
button actions should be events, while elapsed time should be generated from
the board clock.
