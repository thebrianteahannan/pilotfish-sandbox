#!/usr/bin/env python3
"""Launch the Sandbox control hub (creates a local venv with Flask if needed).

  python3 tools/sandbox_control.py
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PKG = HERE / "sandbox_control"
VENV_PY = PKG / ".venv" / "bin" / "python"
APP = PKG / "app.py"


def ensure_venv() -> Path:
    if VENV_PY.is_file():
        return VENV_PY
    subprocess.check_call([sys.executable, "-m", "venv", str(PKG / ".venv")])
    pip = PKG / ".venv" / "bin" / "pip"
    subprocess.check_call([str(pip), "install", "-q", "flask>=3,<4", "reportlab>=4,<5"])
    return VENV_PY


def main() -> int:
    py = ensure_venv()
    os.execv(str(py), [str(py), str(APP), *sys.argv[1:]])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
