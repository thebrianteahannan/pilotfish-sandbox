from __future__ import annotations

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory

app = Flask(__name__)
DATA = Path(os.environ.get("OCI_DATA_DIR", "/data"))
DATA.mkdir(parents=True, exist_ok=True)


def object_path(namespace: str, bucket: str, name: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9._/@+-]+", "_", name).lstrip("/")
    dest = DATA / namespace / bucket / safe
    dest.parent.mkdir(parents=True, exist_ok=True)
    return dest


@app.get("/health")
def health():
    return jsonify({"ok": True, "service": "oci-object-storage-mock"})


@app.route("/n/<namespace>/b/<bucket>/o/<path:object_name>", methods=["PUT", "POST"])
def put_object(namespace: str, bucket: str, object_name: str):
    body = request.get_data()
    path = object_path(namespace, bucket, object_name)
    path.write_bytes(body)
    meta = {
        "namespace": namespace,
        "bucket": bucket,
        "object": object_name,
        "bytes": len(body),
        "contentType": request.headers.get("Content-Type", ""),
        "storedAt": datetime.now(timezone.utc).isoformat(),
        "method": request.method,
        "path": str(path.relative_to(DATA)),
    }
    path.with_suffix(path.suffix + ".meta.json").write_text(
        json.dumps(meta, indent=2), encoding="utf-8"
    )
    # OCI PutObject typically returns 200 with opc-request-id
    return (
        jsonify({"ok": True, **meta}),
        200,
        {"opc-request-id": f"demo-{int(datetime.now().timestamp())}"},
    )


@app.get("/n/<namespace>/b/<bucket>/o")
def list_objects(namespace: str, bucket: str):
    root = DATA / namespace / bucket
    objects = []
    if root.is_dir():
        for p in sorted(root.rglob("*")):
            if p.is_file() and not p.name.endswith(".meta.json"):
                objects.append(
                    {
                        "name": str(p.relative_to(root)).replace("\\", "/"),
                        "bytes": p.stat().st_size,
                        "mtime": int(p.stat().st_mtime),
                    }
                )
    return jsonify({"objects": objects, "namespace": namespace, "bucket": bucket})


@app.get("/objects")
def list_all():
    objects = []
    for p in sorted(DATA.rglob("*")):
        if p.is_file() and not p.name.endswith(".meta.json"):
            objects.append(
                {
                    "path": str(p.relative_to(DATA)).replace("\\", "/"),
                    "bytes": p.stat().st_size,
                    "mtime": int(p.stat().st_mtime),
                }
            )
    return jsonify({"objects": objects})


@app.get("/download/<path:rel>")
def download(rel: str):
    return send_from_directory(DATA, rel)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8200")))
