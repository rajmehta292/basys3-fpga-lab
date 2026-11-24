#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d /tmp/basys3-catalog-tests.XXXXXX)"
if [[ -x "$ROOT_DIR/scripts/iverilog_local.sh" && -x "$ROOT_DIR/scripts/vvp_local.sh" ]]; then
    IVERILOG="$ROOT_DIR/scripts/iverilog_local.sh"
    VVP="$ROOT_DIR/scripts/vvp_local.sh"
    STREAM_IVERILOG="$IVERILOG"
    STREAM_VVP="$VVP"
else
    IVERILOG="$(command -v iverilog)"
    VVP="$(command -v vvp)"
    STREAM_IVERILOG="$IVERILOG"
    STREAM_VVP="$VVP"
fi

run_tb() {
    local name="$1"
    shift
    "$IVERILOG" -g2012 -s "$name" -o "$TEST_DIR/$name" "$@"
    "$VVP" "$TEST_DIR/$name"
}

run_tb tb_reaction_timer \
    "$ROOT_DIR/projects/02_reaction_timer/sim/tb_reaction_timer.sv" \
    "$ROOT_DIR/projects/02_reaction_timer/rtl/reaction_timer.sv" \
    "$ROOT_DIR/projects/common/basys3_reset_sync.sv" \
    "$ROOT_DIR/projects/common/button_onepulse.sv" \
    "$ROOT_DIR/projects/common/basys3_display.sv"

run_tb tb_pwm_breathing \
    "$ROOT_DIR/projects/03_pwm_breathing/sim/tb_pwm_breathing.sv" \
    "$ROOT_DIR/projects/03_pwm_breathing/rtl/pwm_breathing.sv" \
    "$ROOT_DIR/projects/common/basys3_reset_sync.sv" \
    "$ROOT_DIR/projects/common/basys3_display.sv"

run_tb tb_stopwatch \
    "$ROOT_DIR/projects/04_stopwatch/sim/tb_stopwatch.sv" \
    "$ROOT_DIR/projects/04_stopwatch/rtl/stopwatch.sv" \
    "$ROOT_DIR/projects/common/basys3_reset_sync.sv" \
    "$ROOT_DIR/projects/common/button_onepulse.sv" \
    "$ROOT_DIR/projects/common/basys3_display.sv"

IVERILOG="$STREAM_IVERILOG" VVP="$STREAM_VVP" "$ROOT_DIR/sim/run_all.sh"
python3 "$ROOT_DIR/host/python/monitor.py" --self-test
echo "PROJECT CATALOG CHECKS PASS"
