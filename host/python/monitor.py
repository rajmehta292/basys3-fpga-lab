#!/usr/bin/env python3
"""Basys 3 streaming telemetry monitor.

The FPGA sends fixed-width hexadecimal counters. This program converts them to
integers and derives throughput from accepted/checker words and elapsed cycles.
It can parse a saved UART log without pyserial, or read a live serial port when
pyserial is installed.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from typing import Iterable, Optional


STAT_RE = re.compile(
    r"^STAT W=(?P<words>[0-9A-Fa-f]{16})"
    r" E=(?P<errors>[0-9A-Fa-f]{16})"
    r" C=(?P<cycles>[0-9A-Fa-f]{16})"
    r" B=(?P<bits>[0-9A-Fa-f]{16})"
    r" H=(?P<high>[0-9A-Fa-f]{4})"
    r" F=(?P<full>[0-9A-Fa-f]{16})"
    r" M=(?P<empty>[0-9A-Fa-f]{16})"
    r" R=(?P<running>[01])"
    r" I=(?P<writes>[0-9A-Fa-f]{16})"
    r" O=(?P<reads>[0-9A-Fa-f]{16})"
    r" P=(?P<producer_stalls>[0-9A-Fa-f]{16})"
    r" Q=(?P<consumer_stalls>[0-9A-Fa-f]{16})"
    r" X=(?P<overflows>[0-9A-Fa-f]{16})"
    r" Y=(?P<underflows>[0-9A-Fa-f]{16})$"
)


def parse_status_line(line: str, clock_hz: int = 100_000_000, data_width: int = 128) -> Optional[dict]:
    """Parse one telemetry line and derive human-readable metrics."""

    match = STAT_RE.match(line.strip())
    if not match:
        return None

    values = {key: int(value, 16) for key, value in match.groupdict().items()}
    values["running"] = bool(values["running"])
    cycles = values["cycles"]
    words = values["words"]
    values["clock_hz"] = clock_hz
    values["data_width"] = data_width
    values["total_bits"] = words * data_width
    values["throughput_bps"] = (values["total_bits"] * clock_hz // cycles) if cycles else 0
    values["word_error_rate"] = (values["errors"] / words) if words else 0.0
    values["bit_error_rate"] = (values["bits"] / values["total_bits"]) if values["total_bits"] else 0.0
    return values


def emit_line(line: str, clock_hz: int, data_width: int) -> bool:
    parsed = parse_status_line(line, clock_hz, data_width)
    if parsed is None:
        return False
    print(json.dumps(parsed, sort_keys=True), flush=True)
    return True


def read_lines(lines: Iterable[str], clock_hz: int, data_width: int) -> int:
    parsed_count = 0
    for line in lines:
        if emit_line(line, clock_hz, data_width):
            parsed_count += 1
    return parsed_count


def self_test() -> int:
    line = "STAT W=0000000000000064 E=0000000000000001 C=00000000000003E8 B=0000000000000002 H=00FF F=000000000000000A M=0000000000000003 R=0 I=0000000000000064 O=0000000000000064 P=0000000000000002 Q=0000000000000003 X=0000000000000004 Y=0000000000000005"
    result = parse_status_line(line)
    assert result is not None
    assert result["words"] == 100
    assert result["throughput_bps"] == 1_280_000_000
    assert result["total_bits"] == 12_800
    assert result["word_error_rate"] == 0.01
    print("MONITOR PASS: telemetry parsing and throughput derivation passed")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", help="live serial port, for example /dev/ttyUSB1")
    parser.add_argument("--input", help="read telemetry lines from a saved text log")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--clock-hz", type=int, default=100_000_000)
    parser.add_argument("--data-width", type=int, default=128)
    parser.add_argument("--duration", type=float, default=0.0, help="live capture duration; zero means until Ctrl-C")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        return self_test()

    if args.input:
        with open(args.input, "r", encoding="utf-8") as handle:
            return 0 if read_lines(handle, args.clock_hz, args.data_width) else 1

    if not args.port:
        parser.error("choose --input, --port, or --self-test")

    try:
        import serial  # type: ignore
    except ImportError:
        print("pyserial is required for live monitoring; use --self-test or --input without it.", file=sys.stderr)
        return 2

    start_time = time.monotonic()
    try:
        with serial.Serial(args.port, args.baud, timeout=0.2) as device:
            while True:
                raw = device.readline()
                if raw:
                    emit_line(raw.decode("ascii", errors="replace"), args.clock_hz, args.data_width)
                if args.duration and time.monotonic() - start_time >= args.duration:
                    break
    except KeyboardInterrupt:
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
