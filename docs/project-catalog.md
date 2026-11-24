# Project Catalog

| ID | Project | Main concepts | Status |
|---|---|---|---|
| 01 | Board smoke test | clock, XDC, LEDs, seven-segment scan | Board verified |
| 02 | Reaction timer | synchronizer, debounce, FSM, LFSR, event timing | Simulation and routed bitstream pass |
| 03 | PWM breathing LEDs | PWM, duty cycle, slow envelope, masking | Simulation and routed bitstream pass |
| 04 | Decimal stopwatch | BCD carry, pause/resume, timebase | Simulation and routed bitstream pass |
| 05 | Streaming validation | valid/ready, FIFO, PRBS, telemetry, backpressure | RTL regression pass; streaming hardware gate remains |
| 06 | Host telemetry | UART parsing, throughput/BER derivation, Qt | Python self-test and Qt build pass |

## How to present the portfolio

Lead with the problem, then name the invariant, then give evidence:

- **Board smoke:** “I isolated board and constraints risk first; switch/LED
  and display behavior worked on the physical Basys3.”
- **Reaction timer:** “I treated buttons as asynchronous mechanical inputs and
  converted them into synchronized one-cycle events driving a four-state FSM.”
- **PWM:** “I separated the 8-bit carrier from the slow brightness envelope so
  duty cycle changes without changing output frequency.”
- **Stopwatch:** “I used explicit BCD digits and carry logic so the displayed
  decimal time is always legal.”
- **Streaming:** “I measured accepted transfers, not asserted valid cycles;
  the verification suite includes stalls, FIFO edges, reset, faults, and PRBS.”
- **Host:** “I kept telemetry separate from the datapath and derived
  throughput from counters rather than trusting a headline number.”

## What not to claim

Do not claim that the Basys3 transmitted a physical 10 Gb/s link. Do not claim
the old GPMC project used this exact FIFO, PRBS, register map, or Linux driver;
those are new reconstruction decisions unless historical evidence is found.
