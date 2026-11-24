# Project 06 — Host Telemetry and Dashboard

This project documents the PC side of the FPGA system. UART carries compact
statistics, not the internal high-rate data stream. The Python parser provides
a lightweight command-line monitor and independently derives throughput and
BER. The Qt application provides a live event-driven GUI using `QSerialPort`.

## Checks

```bash
python3 host/python/monitor.py --self-test
./scripts/build_qt_monitor.sh
```

The dashboard executable is created under `build/qt-local/` and is intentionally
not required for the FPGA datapath to run.

## Interview story

This cleanly separates the high-speed synchronous datapath from a slow control
and observability channel. The UART reports snapshots and counters; it does
not pretend to carry 12.8 Gb/s of raw data.
