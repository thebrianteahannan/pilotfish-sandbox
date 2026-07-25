#!/usr/bin/env python3
from __future__ import annotations

import select
import socket
import sys
import threading
import time

LISTEN_HOST = "0.0.0.0"
LISTEN_PORT = 3389
TARGET_HOST = "10.211.55.4"
TARGET_PORT = 3389


def pipe(a: socket.socket, b: socket.socket) -> None:
    try:
        while True:
            r, _, _ = select.select([a], [], [], 120)
            if not r:
                continue
            data = a.recv(65536)
            if not data:
                break
            b.sendall(data)
    except OSError:
        pass
    finally:
        for s in (a, b):
            try:
                s.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            try:
                s.close()
            except OSError:
                pass


def connect_target() -> socket.socket:
    last: Exception | None = None
    for _ in range(10):
        try:
            return socket.create_connection((TARGET_HOST, TARGET_PORT), timeout=5)
        except OSError as exc:
            last = exc
            time.sleep(0.5)
    raise OSError(f"target connect failed: {last}")


def main() -> int:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((LISTEN_HOST, LISTEN_PORT))
    srv.listen(50)
    print(f"RDP forward listening on {LISTEN_HOST}:{LISTEN_PORT} -> {TARGET_HOST}:{TARGET_PORT}", flush=True)
    while True:
        client, addr = srv.accept()
        print(f"connect from {addr}", flush=True)
        try:
            target = connect_target()
        except OSError as exc:
            print(exc, flush=True)
            client.close()
            continue
        threading.Thread(target=pipe, args=(client, target), daemon=True).start()
        threading.Thread(target=pipe, args=(target, client), daemon=True).start()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
