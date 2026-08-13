#!/usr/bin/env python3
"""Local Object Storage mock — POST/PUT /n/{ns}/b/{bucket}/o/{object}."""

from __future__ import annotations

import json
import os
from pathlib import Path

from flask import Flask, Response, jsonify, request

app = Flask(__name__)
DATA = Path(os.environ.get("OCI_DATA_DIR", "/data"))
DATA.mkdir(parents=True, exist_ok=True)


@app.get("/_floci-oci/health")
@app.get("/health")
def health():
    return jsonify({"ok": True, "service": "oci-mock"})


def _put(ns: str, bucket: str, name: str):
    folder = DATA / ns / bucket
    folder.mkdir(parents=True, exist_ok=True)
    dest = folder / name
    dest.write_bytes(request.get_data() or b"")
    # Flat copy for the Web UI
    flat = Path(os.environ.get("OCI_FLAT_DIR", str(DATA)))
    flat.mkdir(parents=True, exist_ok=True)
    (flat / name).write_bytes(dest.read_bytes())
    return Response(status=200)


@app.route("/n/<ns>/b/<bucket>/o/<path:name>", methods=["POST", "PUT"])
def put_object(ns: str, bucket: str, name: str):
    return _put(ns, bucket, name.replace("/", "_"))


@app.get("/n/<ns>/b/<bucket>/o")
def list_objects(ns: str, bucket: str):
    folder = DATA / ns / bucket
    names = sorted(p.name for p in folder.glob("*") if p.is_file()) if folder.is_dir() else []
    return jsonify({"objects": names})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "4599")), debug=False)
