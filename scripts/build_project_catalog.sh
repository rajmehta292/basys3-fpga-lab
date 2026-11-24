#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT_DIR/scripts/build_openxc7_project.sh"
XDC="constraints/basys3_project_openxc7.xdc"
COMMON=(projects/common/basys3_reset_sync.sv projects/common/basys3_display.sv)

"$BUILD" projects/02_reaction_timer/rtl/reaction_timer.sv reaction_timer "$XDC" \
    build/projects/reaction_timer "${COMMON[@]}" projects/common/button_onepulse.sv
"$BUILD" projects/03_pwm_breathing/rtl/pwm_breathing.sv pwm_breathing "$XDC" \
    build/projects/pwm_breathing "${COMMON[@]}"
"$BUILD" projects/04_stopwatch/rtl/stopwatch.sv stopwatch "$XDC" \
    build/projects/stopwatch "${COMMON[@]}" projects/common/button_onepulse.sv

echo "PROJECT CATALOG BUILD PASS"
