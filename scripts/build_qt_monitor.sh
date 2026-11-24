#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${QT_BUILD_DIR:-$ROOT_DIR/build/qt-local}"
QT_PREFIX="${QT6_PREFIX:-/home/dmehta/openqt/usr}"
SERIALPORT_DIR="${QT6_SERIALPORT_DIR:-$QT_PREFIX/lib/x86_64-linux-gnu/cmake/Qt6SerialPort}"

if [[ ! -f "$SERIALPORT_DIR/Qt6SerialPortConfig.cmake" ]]; then
    echo "Qt6 SerialPort development files were not found at: $SERIALPORT_DIR" >&2
    echo "Install them rootlessly with: apt-get download qt6-serialport-dev" >&2
    exit 1
fi

cmake -S "$ROOT_DIR/host/qt" -B "$BUILD_DIR" \
    -DQt6SerialPort_DIR="$SERIALPORT_DIR" \
    -DCMAKE_PREFIX_PATH="$QT_PREFIX"
cmake --build "$BUILD_DIR" --parallel "${CMAKE_BUILD_PARALLEL_LEVEL:-2}"

echo "Qt dashboard: $BUILD_DIR/basys3_monitor"
