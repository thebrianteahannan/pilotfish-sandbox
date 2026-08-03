#!/usr/bin/env python3
"""Minimal MLLP sink that pretends to be a hospital EHR."""
from __future__ import annotations

import datetime as dt
import os
import socket
import socketserver
from pathlib import Path

PORT = int(os.environ.get("MLLP_PORT", "2581"))
LABEL = os.environ.get("MLLP_LABEL", "EHR mock")
OUT = Path("/received")
START = b"\x0b"
END = b"\x1c\x0d"


def build_aa(msh_line: str) -> bytes:
    fields = msh_line.strip().split("|")
    while len(fields) < 12:
        fields.append("")
    ctrl = fields[9] if len(fields) > 9 else "UNKNOWN"
    version = fields[11] if len(fields) > 11 and fields[11] else "2.5.1"
    ts = dt.datetime.now().strftime("%Y%m%d%H%M%S")
    ack = (
        f"MSH|^~\\&|{fields[4]}|{fields[5]}|{fields[2]}|{fields[3]}|{ts}||ACK^R01|{ctrl}-ACK|P|{version}\r"
        f"MSA|AA|{ctrl}|{LABEL} accepted"
    )
    return START + ack.encode("utf-8") + END


class Handler(socketserver.BaseRequestHandler):
    def handle(self) -> None:
        buf = b""
        self.request.settimeout(60)
        try:
            while END not in buf:
                chunk = self.request.recv(4096)
                if not chunk:
                    break
                buf += chunk
        except socket.timeout:
            return
        if START in buf and END in buf:
            body = buf[buf.find(START) + 1 : buf.find(END)]
        else:
            body = buf
        text = body.decode("utf-8", errors="replace").replace("\r\n", "\r").replace("\n", "\r")
        OUT.mkdir(parents=True, exist_ok=True)
        name = f"EHR_{dt.datetime.now().strftime('%Y%m%d_%H%M%S_%f')}.hl7"
        (OUT / name).write_text(text.replace("\r", "\n"), encoding="utf-8")
        print(f"{LABEL}: received {len(text)} bytes -> {name}", flush=True)
        msh = text.split("\r")[0] if text else "MSH|"
        try:
            self.request.sendall(build_aa(msh))
        except OSError:
            pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    print(f"{LABEL} MLLP listening on {PORT}", flush=True)
    with Server(("0.0.0.0", PORT), Handler) as httpd:
        httpd.serve_forever()
