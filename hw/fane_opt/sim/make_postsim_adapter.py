#!/usr/bin/env python3
"""Wrap a fixed Y=1 Vivado netlist with the original unpacked-array ports."""
from __future__ import annotations

import argparse
from pathlib import Path
import re


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rtl", type=Path, required=True)
    parser.add_argument("--netlist", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--testbench", type=Path, required=True)
    parser.add_argument("--testbench-output", type=Path, required=True)
    parser.add_argument("--period", type=float, required=True)
    args = parser.parse_args()
    original = args.rtl.read_text()
    match = re.search(r"module\s+(\w+)\s*#.*?\);", original, re.S)
    if match is None:
        raise ValueError("Original chip module header not found")
    top = match.group(1)
    header = match.group().replace(f"module {top}", f"module {top}_post", 1)
    netlist = args.netlist.read_text()
    flat_header = re.search(rf"module\s+{top}_netlist\s*\((.*?)\);", netlist, re.S)
    if flat_header is None:
        raise ValueError("Renamed netlist top not found")
    flat_ports = [p.strip() for p in flat_header.group(1).split(",")]
    connections = []
    for line in header.splitlines():
        if not re.match(r"\s*(input|output)\b", line):
            continue
        port = re.fullmatch(
            r"\s*(?:input|output)\s*(?:\[[^\]]+\]\s*)?(\w+)\s*(\[Y\])?\s*,?\s*",
            line,
        )
        if port is None:
            raise ValueError(f"Unsupported port declaration: {line}")
        name, unpacked = port.groups()
        if f"\\{name}[0]" in flat_ports:
            netlist_name = f"\\{name}[0] "
        elif name in flat_ports:
            netlist_name = name
        else:
            raise ValueError(f"Netlist port missing: {name}")
        value = f"{name}[0]" if unpacked else name
        connections.append(f"    .{netlist_name}({value})")
    body = (
        "// Generated Y=1 port adapter; no data, timing or arithmetic logic.\n"
        "`timescale 1ns/1ps\n"
        + header
        + f"\ninitial if (Y != 1 || IMG_W != {args.width} || IMG_D != {args.height})\n"
        + '    $fatal(1, "Testbench parameters do not match the fixed netlist");\n'
        + f"{top}_netlist netlist (\n"
        + ",\n".join(connections)
        + "\n);\nendmodule\n"
    )
    args.output.write_text(body)
    # A fixed top keeps XSim's SDF root stable; generic_top specializes the
    # module name (including parameter values), which can skip SDF paths.
    testbench = args.testbench.read_text()
    tb_name = "tb_mm_chip" if top == "dsp_mm_chip" else "tb_conv_chip"
    constants = f"module {tb_name};\nlocalparam real CLK_PERIOD_NS = {args.period};\n"
    if top == "dsp_mm_chip":
        constants += f"localparam integer MVM_VECTORS = {args.width // 9};\n"
    else:
        constants += f"localparam integer IMG_W = {args.width};\nlocalparam integer IMG_D = {args.height};\n"
    testbench, count = re.subn(rf"module\s+{tb_name}\s*#\(.*?\);", constants, testbench, count=1, flags=re.S)
    if count != 1:
        raise ValueError("Testbench parameter header not found")
    args.testbench_output.write_text(testbench)


if __name__ == "__main__":
    main()
