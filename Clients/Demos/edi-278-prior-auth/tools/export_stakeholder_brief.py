#!/usr/bin/env python3
"""Generate stakeholder Capability Brief PDF for this interface.

Thin wrapper around Sandbox tools/export_stakeholder_brief.py
"""
from __future__ import annotations

import runpy
import sys
from pathlib import Path

DEMO_ROOT = Path(__file__).resolve().parents[1]
SANDBOX_TOOL = Path(__file__).resolve().parents[4] / "tools" / "export_stakeholder_brief.py"

if not SANDBOX_TOOL.is_file():
    raise SystemExit(f"Shared exporter not found: {SANDBOX_TOOL}")

sys.argv = [str(SANDBOX_TOOL), "--root", str(DEMO_ROOT), *sys.argv[1:]]
runpy.run_path(str(SANDBOX_TOOL), run_name="__main__")

