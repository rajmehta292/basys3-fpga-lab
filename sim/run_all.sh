#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/sim/build"
IVERILOG_BIN="${IVERILOG:-iverilog}"
VVP_BIN="${VVP:-vvp}"

mkdir -p "$BUILD_DIR"

run_case() {
    local name="$1"
    shift
    echo "=== $name ==="
    "$IVERILOG_BIN" -g2001 -Wall -s "$name" -o "$BUILD_DIR/$name.vvp" "$@"
    "$VVP_BIN" "$BUILD_DIR/$name.vvp"
}

run_case tb_milestone1 \
    "$ROOT_DIR/rtl/stream_counter_generator.v" \
    "$ROOT_DIR/rtl/stream_sequence_checker.v" \
    "$ROOT_DIR/sim/tb_milestone1.v"

run_case tb_stream_fifo \
    "$ROOT_DIR/rtl/stream_fifo.v" \
    "$ROOT_DIR/sim/tb_stream_fifo.v"

run_case tb_stream_pipeline \
    "$ROOT_DIR/rtl/stream_counter_generator.v" \
    "$ROOT_DIR/rtl/fault_injector.v" \
    "$ROOT_DIR/rtl/stream_fifo.v" \
    "$ROOT_DIR/rtl/stream_sequence_checker.v" \
    "$ROOT_DIR/rtl/performance_counters.v" \
    "$ROOT_DIR/sim/tb_stream_pipeline.v"

run_case tb_prbs \
    "$ROOT_DIR/rtl/prbs_generator.v" \
    "$ROOT_DIR/rtl/prbs_checker.v" \
    "$ROOT_DIR/sim/tb_prbs.v"

run_case tb_uart_tx \
    "$ROOT_DIR/rtl/uart_tx.v" \
    "$ROOT_DIR/sim/tb_uart_tx.v"

run_case tb_telemetry \
    "$ROOT_DIR/rtl/telemetry_controller.v" \
    "$ROOT_DIR/sim/tb_telemetry.v"

echo "=== top_streaming elaboration ==="
"$IVERILOG_BIN" -g2001 -Wall -s top_streaming -tnull \
    "$ROOT_DIR/rtl/reset_sync.v" \
    "$ROOT_DIR/rtl/button_conditioner.v" \
    "$ROOT_DIR/rtl/stream_counter_generator_controlled.v" \
    "$ROOT_DIR/rtl/stream_fifo.v" \
    "$ROOT_DIR/rtl/fault_injector.v" \
    "$ROOT_DIR/rtl/stream_sequence_checker.v" \
    "$ROOT_DIR/rtl/performance_counters.v" \
    "$ROOT_DIR/rtl/uart_tx.v" \
    "$ROOT_DIR/rtl/telemetry_controller.v" \
    "$ROOT_DIR/rtl/top_streaming.v"

echo "ALL RTL SIMULATIONS PASS"
