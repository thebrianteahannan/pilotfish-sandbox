#!/usr/bin/env python3
"""Export this interface Test Plan PDF."""
from __future__ import annotations

import runpy
import sys
from pathlib import Path


def sandbox_tool(name: str) -> Path:
    for parent in Path(__file__).resolve().parents:
        cand = parent / "tools" / name
        if cand.is_file() and (parent / "Clients" / "Demos").is_dir():
            return cand
    raise SystemExit(f"Sandbox tool not found: {name}")


DEMO_ROOT = Path(__file__).resolve().parents[1]
TOOL = sandbox_tool("export_test_plan_pdf.py")
sys.argv = [str(TOOL), "--root", str(DEMO_ROOT), *sys.argv[1:]]
runpy.run_path(str(TOOL), run_name="__main__")
