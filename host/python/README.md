# Python telemetry monitor

The FPGA telemetry controller emits lines in this form:

```text
STAT W=0000000000000064 E=0000000000000001 C=00000000000003E8 B=0000000000000002 H=00FF F=000000000000000A M=0000000000000003 R=0 I=0000000000000064 O=0000000000000064 P=0000000000000002 Q=0000000000000003 X=0000000000000004 Y=0000000000000005
```

The fields are hexadecimal so the FPGA can serialize fixed-width values
without a large decimal-conversion datapath. `monitor.py` converts them to
integers and calculates:

```text
total_bits      = words_checked * data_width
throughput_bps  = total_bits * clock_hz / elapsed_cycles
word_error_rate = word_errors / words_checked
bit_error_rate  = bit_errors / total_bits
```

`I` and `O` are accepted writes and reads, `P` and `Q` are producer and
consumer stall cycles, and `X` and `Y` are FIFO overflow and underflow
attempts.

Run the parser self-test:

```bash
python3 host/python/monitor.py --self-test
```

Parse a saved UART capture:

```bash
python3 host/python/monitor.py --input results/hardware/telemetry.log
```

Read a live port after the board and UART permissions are configured:

```bash
python3 host/python/monitor.py --port /dev/ttyUSB1 --baud 115200
```

The correct FT2232 channel must be confirmed empirically on the host. UART is
statistics telemetry only; it is not the internal 128-bit stream.
