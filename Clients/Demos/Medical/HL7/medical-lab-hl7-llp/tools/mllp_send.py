#!/usr/bin/env python3
"""Send an HL7 file over MLLP and print the ACK."""
from __future__ import annotations

import argparse
import socket
from pathlib import Path

START = b"\x0b"
END = b"\x1c\x0d"


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("hl7_file", type=Path)
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=2575)
    p.add_argument("--timeout", type=float, default=60)
    args = p.parse_args()
    raw = args.hl7_file.read_bytes()
    text = raw.replace(b"\r\n", b"\r").replace(b"\n", b"\r")
    if not text.endswith(b"\r"):
        text += b"\r"
    framed = START + text + END
    with socket.create_connection((args.host, args.port), timeout=args.timeout) as s:
        s.settimeout(args.timeout)
        s.sendall(framed)
        buf = b""
        while END not in buf:
            chunk = s.recv(4096)
            if not chunk:
                break
            buf += chunk
    print(buf.decode("utf-8", errors="replace"))


if __name__ == "__main__":
    main()
