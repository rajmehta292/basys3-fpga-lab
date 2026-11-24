# FPGA High-Speed Data Streaming and Integrity Validation System

This document records the architecture for the new Basys 3 project. It is
deliberately separate from the historical AM3358/GPMC project. Historical
implementation details are not inferred from the resume.

## Confirmed facts versus new decisions

Confirmed from the project context:

- The resume describes an FPGA-to-ARM communication path using GPMC, Linux,
  TCP/IP, and a Qt host.
- The processor was an AM3358 on a BeagleBone Black.
- The exact FPGA data source, register map, buffering, Linux driver interface,
  and original HDL are not verified.

New implementation decisions for this project:

- The Basys 3 is the target platform.
- The initial design is a single 100 MHz clock domain with a 128-bit internal
  streaming interface.
- The first source is a deterministic counter, not a claimed sensor or ADC
  source.
- The initial checker compares the sequence `0, 1, 2, ...` and is intentionally
  non-resynchronizing.
- UART is telemetry only. It is not the 128-bit data path and it is not a
  replacement for GPMC or TCP/IP.

## Corrected throughput interpretation

The arithmetic

```text
128 bits/transfer * 100,000,000 transfers/second = 12.8 Gbit/s
```

is the peak payload capacity of a continuously accepted internal datapath. It
is not automatically an achieved measurement, a physical 10 Gb/s interface, or
the bandwidth available through the Basys 3 USB-UART bridge.

The project will report measured throughput from accepted transfers:

```text
accepted_bits = accepted_words * DATA_WIDTH
throughput_bps = accepted_bits * clock_hz / elapsed_clock_cycles
```

The measurement must identify the measurement window and whether pipeline
fill/drain cycles were included. A 100% utilized 128-bit, 100 MHz path would
correspond to 1.6 GB/s of internal payload, but this is a design target, not a
hardware result until simulation, timing, and hardware counters support it.

## Streaming contract

Every streaming interface uses:

- `valid`: the producer presents a meaningful word.
- `ready`: the consumer can accept a word.
- `transfer = valid && ready` on the active clock edge.
- `data`: the word associated with `valid`.

If `valid=1` and `ready=0`, the producer must keep both `valid` and `data`
stable. Otherwise the consumer could see a word disappear or change before it
accepts it. The producer advances its sequence only on `transfer`.

The first source implementation in `rtl/stream_counter_generator.v` follows
this rule. It starts at zero, holds zero while stalled, and advances to one
only after zero is accepted.

The first checker in `rtl/stream_sequence_checker.v` is always ready. This is
intentional: Milestone 1 teaches the source contract and sequence accounting.
The FIFO becomes the backpressure-producing consumer in Milestones 2 and 3.

## Implemented complete simulation system

```text
100 MHz clock
     |
reset synchronizer/debouncer
     |
counter generator --valid/data--> fault injector --> synchronous FIFO
                                                         |
                                                         +--> sequence checker
                                                         |
performance counters <----------------------------------+
                                                         |
coherent telemetry snapshot --> UART transmitter --> Basys 3 UART TX
```

The implemented top-level is [`rtl/top_streaming.v`](../rtl/top_streaming.v).
The top uses the counter source for the normal board test. The PRBS generator
and checker are implemented and independently simulated, but are not selected
by the board top until a mode control is added.

The FIFO uses a registered output. It can prefetch from memory while the
consumer is stalled, reports occupancy including the output register, and
supports simultaneous output-consume/input-write boundary cases. The Vivado
build must still confirm whether the 128×256 memory inferred as block RAM on
the selected device. A generic Yosys XC7 mapping estimated two `RAMB36E1`
cells, which is encouraging but is not a substitute for Vivado's device report.

The telemetry line is fixed-width hexadecimal text:

```text
STAT W=<words> E=<word errors> C=<elapsed cycles> B=<bit errors>
     H=<FIFO high-water> F=<full cycles> M=<empty cycles> R=<running>
```

The Python host converts those fields to integers and derives throughput and
error rates. This keeps UART serialization out of the high-speed datapath.

Initial operation remains one clock domain. Clock-domain crossing logic is
added only when a separate clock is introduced and will not be hidden behind a
false timing constraint.

## Risks and controls

| Risk | Control |
|---|---|
| Treating 12.8 Gb/s arithmetic as achieved performance | Count accepted words and publish timing/resource evidence. |
| Generator increments while stalled | Self-checking hold test and explicit `valid && ready` logic. |
| FIFO read-latency mismatch | Specify standard versus FWFT behavior and test the exact interface before integration. |
| Simple checker cascades after a missing word | Document the limitation; add a sequence tag/resynchronizing checker later. |
| Mechanical button metastability/bounce | Synchronize and debounce controls before using them as state transitions. |
| UART blocks the datapath | Use snapshot registers and a separate telemetry scheduler. |
| Unconstrained or failing timing | Require a 10 ns clock constraint and clean timing reports before hardware claims. |
| Historical resume details are invented | Label every result as confirmed historical, plausible reconstruction, new decision, or verified new result. |
| Reset leaves data in flight | Define reset semantics and test reset during active streaming in the complete top. |

## Milestone gates

The project does not advance merely because RTL compiles.

1. Counter source/checker simulation passes, including stall hold. **Complete.**
2. FIFO and randomized valid/ready tests pass with a reference queue. **Complete.**
3. Counters and one-word fault-injection pipeline pass. **Complete.**
4. PRBS-31, one-bit error counting, UART framing, and telemetry tests pass.
   **Complete in simulation.**
5. Synthesis, implementation, resource review, and 100 MHz timing pass.
   **Blocked by missing full Vivado.**
6. Program the Basys 3, capture UART telemetry, and compare hardware results
   with the simulation reference. **JTAG setup complete; blocked only by the
   missing streaming bitstream/full Vivado implementation flow.**
