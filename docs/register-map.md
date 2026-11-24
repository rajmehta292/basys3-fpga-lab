# Register Map Status

There is no implemented memory-mapped register interface in Milestone 1. The
current design is a self-contained streaming source and checker; it has no ARM,
GPMC, AXI, or processor bus attached to it.

This distinction matters: the Basys 3 UART telemetry planned for a later
milestone is a serialized status channel, not a GPMC register map and not a
replacement for the historical AM3358 Linux interface.

## Planned telemetry snapshot fields

These names are a design plan, not implemented addresses or measured values:

| Field | Meaning |
|---|---|
| `TEST_RUNNING` | Snapshot of the test state machine. |
| `CLOCK_HZ` | Clock rate used for the measurement window. |
| `DATA_WIDTH` | Streaming payload width, initially 128. |
| `WORDS_WRITTEN` | Accepted source-to-FIFO transfers. |
| `WORDS_READ` | Accepted FIFO-to-checker transfers. |
| `WORDS_CHECKED` | Checker transfers actually compared. |
| `WORD_ERRORS` | Mismatching accepted words. |
| `BIT_ERRORS` | Differing bits, when the PRBS/bit-counting checker exists. |
| `FIFO_HIGH_WATER` | Maximum observed occupancy. |
| `FULL_CYCLES` | Clock cycles the FIFO was full. |
| `EMPTY_CYCLES` | Clock cycles the FIFO was empty. |
| `ELAPSED_CYCLES` | Measurement-window duration. |

The current UART telemetry implementation serializes the implemented subset as
one fixed-width line rather than memory-mapped addresses:

```text
STAT W=<16 hex> E=<16 hex> C=<16 hex> B=<16 hex> H=<4 hex> F=<16 hex> M=<16 hex> R=<1 hex> I=<16 hex> O=<16 hex> P=<16 hex> Q=<16 hex> X=<16 hex> Y=<16 hex>\r\n
```

The Python and Qt hosts parse this exact format. `W` is words checked, `E` is
word errors, `C` is elapsed cycles, `B` is bit errors, `H` is FIFO high-water,
`F` is full cycles, `M` is empty cycles, `R` is the running state, `I` and `O`
are accepted writes and reads, `P` and `Q` are producer and consumer stalls,
and `X` and `Y` are overflow and underflow attempts.

When this becomes RTL, counters will be snapshotted coherently before UART
formatting so that a multi-field report cannot mix values from different clock
cycles. Widths and addresses will be frozen only after the telemetry controller
exists and has a self-checking testbench.

## Future ARM/GPMC compatibility

If the project is later moved to an FPGA/AM3358 platform, a separate bus-facing
register block would define chip-select, address, data, read/write timing,
status, and buffer access. That future interface will be documented separately
and will not be described as part of the Basys 3 implementation.
