#!/usr/bin/env python3
"""Basys3 Mastery Lab local server.

The server intentionally uses only the Python standard library so the lab can
start on a fresh FPGA workstation.  It serves the teaching UI and exposes a
small, explicit bridge to the local Vivado/USB environment.
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import tempfile
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent
APP_ROOT = ROOT / "lab_app"
DATA_ROOT = APP_ROOT / "data"
GENERATED_ROOT = ROOT / "generated"


def find_executable(name: str) -> str | None:
    """Find a command on PATH and in the Xilinx installation found here."""

    found = shutil.which(name)
    if found:
        return found

    known_roots = [
        Path("/home/dmehta/xilinux-petalinux/components/xsct/bin"),
        Path("/home/dmehta/xilinux-petalinux/components/xsct/bin/unwrapped/lnx64.o"),
    ]
    for root in known_roots:
        candidate = root / name
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


def run_command(command: list[str], timeout: float = 4.0) -> dict[str, Any]:
    """Run a diagnostic command and keep failures useful but bounded."""

    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            check=False,
        )
        output = (completed.stdout or "").strip()
        return {"ok": completed.returncode == 0, "code": completed.returncode, "output": output[-4000:]}
    except FileNotFoundError:
        return {"ok": False, "code": 127, "output": "command not found"}
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") if isinstance(exc.stdout, str) else ""
        return {"ok": False, "code": 124, "output": (output + "\ncommand timed out")[-4000:]}
    except OSError as exc:
        return {"ok": False, "code": 1, "output": str(exc)}


def health_snapshot() -> dict[str, Any]:
    commands = ["vivado", "vivado_lab", "hw_server", "xsdb", "iverilog", "verilator", "openocd"]
    tools: dict[str, Any] = {}
    for name in commands:
        path = find_executable(name)
        tools[name] = {"found": bool(path), "path": path}

    usb = run_command(["lsusb"], timeout=2.0) if shutil.which("lsusb") else {"ok": False, "output": "lsusb is not installed"}
    usb_text = usb.get("output", "")
    board_usb = "0403:6010" in usb_text or "Digilent" in usb_text or "FTDI" in usb_text
    serial_ports = sorted(glob.glob("/dev/ttyUSB*") + glob.glob("/dev/ttyACM*"))
    return {
        "tools": tools,
        "usb": {"boardCandidate": board_usb, "raw": usb_text[-4000:]},
        "serialPorts": serial_ports,
        "vivadoReady": bool(tools["vivado"]["found"] or tools["vivado_lab"]["found"]),
        "programmingNote": (
            "Vivado Lab is visible; the server can attempt JTAG programming."
            if tools["vivado_lab"]["found"]
            else "Install Vivado Lab or Vivado to enable one-click programming."
        ),
    }


def load_curriculum() -> Any:
    with (DATA_ROOT / "curriculum.json").open(encoding="utf-8") as handle:
        return json.load(handle)


def json_response(handler: SimpleHTTPRequestHandler, payload: Any, status: int = 200) -> None:
    encoded = json.dumps(payload).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(encoded)))
    handler.send_header("Cache-Control", "no-store")
    handler.end_headers()
    handler.wfile.write(encoded)


def read_json_body(handler: SimpleHTTPRequestHandler) -> dict[str, Any]:
    try:
        length = int(handler.headers.get("Content-Length", "0"))
        raw = handler.rfile.read(length) if length else b"{}"
        value = json.loads(raw.decode("utf-8"))
        return value if isinstance(value, dict) else {}
    except (ValueError, json.JSONDecodeError):
        return {}


def safe_relative_path(value: str) -> Path:
    """Resolve a user-supplied file path without allowing it outside the lab."""

    candidate = (ROOT / value).resolve() if not os.path.isabs(value) else Path(value).resolve()
    if candidate != ROOT and ROOT not in candidate.parents:
        raise ValueError("path must stay inside the Basys3 workspace")
    return candidate


def starter_project(slug: str) -> dict[str, Any]:
    clean = re.sub(r"[^a-zA-Z0-9_-]+", "-", slug).strip("-").lower() or "my-first-led-lab"
    project_root = (GENERATED_ROOT / clean).resolve()
    if GENERATED_ROOT.resolve() not in project_root.parents:
        raise ValueError("invalid project name")
    project_root.mkdir(parents=True, exist_ok=True)

    files = {
        "basys3_hello.v": """module basys3_hello(\n    input  wire       clk,\n    input  wire [15:0] sw,\n    output wire [15:0] led\n);\n    reg [25:0] heartbeat;\n\n    always @(posedge clk) begin\n        heartbeat <= heartbeat + 1'b1;\n    end\n\n    // The slow heartbeat makes the physical cause/effect visible.\n    assign led = sw ^ {16{heartbeat[25]}};\nendmodule\n""",
        "Basys3_Master.xdc": """## Basys3 starter constraints\nset_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk]\ncreate_clock -name sys_clk_pin -period 10.00 [get_ports clk]\n\nset_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]\nset_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]\nset_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]\nset_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]\nset_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports {sw[4]}]\nset_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {sw[5]}]\nset_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports {sw[6]}]\nset_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {sw[7]}]\nset_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {sw[8]}]\nset_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {sw[9]}]\nset_property -dict {PACKAGE_PIN T2 IOSTANDARD LVCMOS33} [get_ports {sw[10]}]\nset_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports {sw[11]}]\nset_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports {sw[12]}]\nset_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {sw[13]}]\nset_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {sw[14]}]\nset_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {sw[15]}]\n\nset_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {led[0]}]\nset_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {led[1]}]\nset_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[2]}]\nset_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports {led[3]}]\nset_property -dict {PACKAGE_PIN W18 IOSTANDARD LVCMOS33} [get_ports {led[4]}]\nset_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {led[5]}]\nset_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[6]}]\nset_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]\nset_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {led[8]}]\nset_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS33} [get_ports {led[9]}]\nset_property -dict {PACKAGE_PIN W3 IOSTANDARD LVCMOS33} [get_ports {led[10]}]\nset_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS33} [get_ports {led[11]}]\nset_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {led[12]}]\nset_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports {led[13]}]\nset_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS33} [get_ports {led[14]}]\nset_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports {led[15]}]\n\nset_property CONFIG_VOLTAGE 3.3 [current_design]\nset_property CFGBVS VCCO [current_design]\n""",
        "README.md": """# First Basys3 hardware lab\n\n1. Open `basys3_hello.v` and change the `assign led = ...` line.\n2. Use the included XDC to create a Vivado project for `xc7a35tcpg236-1`.\n3. Synthesize, implement, generate a bitstream, and program the board.\n4. Return to Mastery Lab and mark the checkpoint after you can explain every signal.\n\nThe board facts and pin names come from Digilent's Basys3 reference material.\n""",
    }
    for relative, content in files.items():
        (project_root / relative).write_text(content, encoding="utf-8")
    return {"ok": True, "project": clean, "path": str(project_root), "files": list(files)}


class LabHandler(SimpleHTTPRequestHandler):
    server_version = "Basys3MasteryLab/0.1"

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, directory=str(APP_ROOT), **kwargs)

    def log_message(self, format: str, *args: Any) -> None:
        # Keep the terminal useful without printing every asset request.
        if self.path.startswith("/api/"):
            super().log_message(format, *args)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path == "/api/health":
            json_response(self, health_snapshot())
            return
        if parsed.path == "/api/curriculum":
            json_response(self, load_curriculum())
            return
        if parsed.path == "/api/status":
            json_response(self, {"app": "Basys3 Mastery Lab", "root": str(ROOT), "health": health_snapshot()})
            return
        if parsed.path == "/":
            self.path = "/index.html"
        super().do_GET()

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path != "/api/actions":
            json_response(self, {"ok": False, "error": "unknown endpoint"}, HTTPStatus.NOT_FOUND)
            return

        body = read_json_body(self)
        action = body.get("action")
        try:
            if action == "health":
                json_response(self, health_snapshot())
            elif action == "generate_starter":
                json_response(self, starter_project(str(body.get("name", "my-first-led-lab"))))
            elif action == "program_board":
                json_response(self, self.program_board(str(body.get("bitstream", ""))))
            elif action == "simulate_with_iverilog":
                json_response(self, self.simulate_with_iverilog(body))
            else:
                json_response(self, {"ok": False, "error": "unknown action"}, HTTPStatus.BAD_REQUEST)
        except (ValueError, OSError) as exc:
            json_response(self, {"ok": False, "error": str(exc)}, HTTPStatus.BAD_REQUEST)

    def program_board(self, bitstream: str) -> dict[str, Any]:
        if not bitstream.strip():
            raise ValueError("choose a .bit file inside this workspace first")
        bit_path = safe_relative_path(bitstream)
        if bit_path.suffix.lower() != ".bit":
            raise ValueError("programming expects a .bit bitstream")
        if not bit_path.is_file():
            raise ValueError(f"bitstream does not exist: {bit_path}")
        vivado_lab = find_executable("vivado_lab") or find_executable("vivado")
        if not vivado_lab:
            return {"ok": False, "error": "Vivado Lab/Vivado was not found", "health": health_snapshot()}
        tcl = ROOT / "scripts" / "program.tcl"
        if not tcl.is_file():
            raise ValueError("scripts/program.tcl is missing")
        result = run_command([vivado_lab, "-mode", "batch", "-source", str(tcl), "-tclargs", str(bit_path)], timeout=120.0)
        return {"ok": result["ok"], "tool": vivado_lab, "bitstream": str(bit_path), **result}

    def simulate_with_iverilog(self, body: dict[str, Any]) -> dict[str, Any]:
        """Run user code only when iverilog exists; the UI has a no-install fallback."""

        iverilog = find_executable("iverilog")
        vvp = find_executable("vvp")
        if not iverilog or not vvp:
            return {"ok": False, "available": False, "error": "iverilog/vvp is not installed"}
        code = str(body.get("code", ""))
        if len(code) > 20000:
            raise ValueError("simulation source is too large")
        with tempfile.TemporaryDirectory(prefix="basys3-lab-") as temp:
            root = Path(temp)
            source = root / "main.v"
            output = root / "a.out"
            source.write_text(code, encoding="utf-8")
            compile_result = run_command([iverilog, "-g2012", "-o", str(output), str(source)], timeout=8.0)
            if not compile_result["ok"]:
                return {"ok": False, "available": True, "stage": "compile", **compile_result}
            run_result = run_command([vvp, str(output)], timeout=8.0)
            return {"ok": run_result["ok"], "available": True, "stage": "run", **run_result}


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve the Basys3 Mastery Lab")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), LabHandler)
    print(f"Basys3 Mastery Lab → http://{args.host}:{args.port}")
    print(f"Workspace: {ROOT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping lab server")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
