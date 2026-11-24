# Qt dashboard

This is a Qt 6 Widgets dashboard for the fixed-width UART telemetry emitted by
the FPGA. It uses `QSerialPort` signals for event-driven input, keeps parsing on
the GUI thread because messages are tiny, and limits the history plot to the
most recent 120 samples.

Build on a machine with Qt6 Widgets and Qt6 SerialPort development packages:

```bash
cmake -S host/qt -B build/qt
cmake --build build/qt
./build/qt/basys3_monitor
```

On the prepared Basys3 host, use the reproducible rootless wrapper:

```bash
./scripts/build_qt_monitor.sh
./build/qt-local/basys3_monitor
```

The wrapper uses the unpacked Qt SerialPort development files under
`/home/dmehta/openqt` and the system Qt 6 runtime. It does not require root.

The application does not assume that `/dev/ttyUSB0` or `/dev/ttyUSB1` is the
UART channel; it enumerates ports and lets the user select one. UART remains a
statistics channel, not the internal data stream.
