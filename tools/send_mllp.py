#!/usr/bin/env python3
"""Send one HL7 file to an MLLP/LLP listener (start 0x0B, end 0x1C 0x0D)."""

from __future__ import annotations

import argparse
import os
import socket
import sys
from pathlib import Path

START = b"\x0b"
END = b"\x1c\x0d"


def send(host: str, port: int, payload: str, timeout: float) -> str:
    text = payload.replace("\r\n", "\r").replace("\n", "\r")
    if not text.endswith("\r"):
        text += "\r"
    framed = START + text.encode("utf-8") + END
    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(framed)
        buf = b""
        while END not in buf:
            chunk = sock.recv(4096)
            if not chunk:
                break
            buf += chunk
    if START in buf and END in buf:
        body = buf[buf.find(START) + 1 : buf.find(END)]
    else:
        body = buf
    return body.decode("utf-8", errors="replace")


def default_file() -> Path | None:
    demo = os.environ.get("CONSTRUCTION_VIDEO_DEMO") or ""
    if not demo:
        return None
    samples = Path(demo) / "samples"
    if not samples.is_dir():
        return None
    hits = sorted(samples.glob("*.hl7"))
    return hits[0] if hits else None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=2578)
    ap.add_argument("--file", default="")
    ap.add_argument("--timeout", type=float, default=20.0)
    args = ap.parse_args()
    path = Path(args.file) if args.file else default_file()
    if path is None or not path.is_file():
        print("Need --file or CONSTRUCTION_VIDEO_DEMO/samples/*.hl7", file=sys.stderr)
        return 2
    ack = send(args.host, args.port, path.read_text(encoding="utf-8"), args.timeout)
    print(ack.strip() or "(no ACK)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
