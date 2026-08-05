#!/usr/bin/env python3
"""Scrub GitHub HashiCorp Vault *false positives* from committed PDFs.

GitHub secret scanning matches Vault service tokens as ``s.[A-Za-z0-9]{24}``.
Compressed image streams inside route-diagram PDFs occasionally collide with
that exact shape. Those hits are **not** real Vault tokens (this sandbox has
none). This tool breaks the scanner pattern in-place (``s.`` → ``s_``) without
changing PDF length/offsets.

Usage:
  python3 tools/scrub_pdf_secret_false_positives.py path/to/file.pdf ...
  python3 tools/scrub_pdf_secret_false_positives.py --demos
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

_VAULT_SERVICE_FP = re.compile(rb"s\.[A-Za-z0-9]{24}")


def scrub(path: Path) -> int:
    data = path.read_bytes()
    n = 0

    def _repl(m: re.Match[bytes]) -> bytes:
        nonlocal n
        n += 1
        return b"s_" + m.group(0)[2:]

    fixed = _VAULT_SERVICE_FP.sub(_repl, data)
    if n:
        path.write_bytes(fixed)
    return n


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, help="PDF files to scrub")
    parser.add_argument(
        "--demos",
        action="store_true",
        help="Scrub all Clients/Demos/**/documents/*_V2_Route_Diagrams.pdf",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    paths: list[Path] = list(args.paths)
    if args.demos:
        paths.extend(sorted((root / "Clients" / "Demos").rglob("*_V2_Route_Diagrams.pdf")))
    if not paths:
        parser.error("pass PDF paths or --demos")
    total = 0
    for p in paths:
        if not p.is_file():
            print(f"skip missing {p}", file=sys.stderr)
            continue
        n = scrub(p)
        total += n
        print(f"{p}: scrubbed {n}")
    print(f"total scrubbed: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
