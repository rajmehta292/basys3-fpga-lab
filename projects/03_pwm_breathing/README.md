# Project 03 — PWM Breathing LEDs

## What it demonstrates

This project creates a visible breathing effect with no external hardware. It
uses a free-running PWM counter, a slow triangular brightness envelope, a
switch-selectable LED mask, and the seven-segment display as an instrument
panel.

## Board behavior

- With all switches off, all sixteen LEDs breathe together.
- If any switch is on, only the selected LED channels breathe.
- The seven-segment display shows the current 8-bit brightness in hexadecimal.
- Center resets the brightness ramp.

The PWM carrier is derived from the 100 MHz clock. The slow brightness update
is intentionally separated from the carrier so the LED duty cycle changes
smoothly without changing the PWM frequency.

## Build

```bash
cd /home/dmehta/Basys3
./scripts/build_openxc7_project.sh \
  projects/03_pwm_breathing/rtl/pwm_breathing.sv pwm_breathing \
  constraints/basys3_project_openxc7.xdc build/projects/pwm_breathing \
  projects/common/basys3_reset_sync.sv projects/common/basys3_display.sv
```

The resulting bitstream is `build/projects/pwm_breathing/pwm_breathing.bit`.

## Verification

The reduced-clock self-checking simulation verifies reset, brightness movement,
PWM activity, and switch masking. Expected result: `PWM BREATHING PASS`.

## Interview story

PWM is not analog voltage generation. The FPGA output is still digital; the
LED appears dimmer because the output is rapidly switched and the eye averages
the duty cycle. The design separates the fast carrier from the slow envelope,
which is a useful example of multiple time scales in synchronous RTL.
