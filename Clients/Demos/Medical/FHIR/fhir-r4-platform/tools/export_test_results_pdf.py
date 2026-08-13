#!/usr/bin/env python3
"""Export this interface Test Results PDF from documents/test-results.json."""
from __future__ import annotations
import runpy, sys
from pathlib import Path
DEMO_ROOT = Path(__file__).resolve().parents[1]
TOOL = Path(__file__).resolve().parents[4] / "tools" / "export_test_results_pdf.py"
sys.argv = [str(TOOL), "--root", str(DEMO_ROOT), *sys.argv[1:]]
runpy.run_path(str(TOOL), run_name="__main__")
