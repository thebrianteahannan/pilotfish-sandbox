#!/usr/bin/env python3
"""Mock quality-reporting REST service from the HIMSS / YouTube demo."""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, request

app = Flask(__name__)
OUT = Path(os.environ.get("ANALYTICS_DIR", "/output/analytics"))


@app.post("/aggregationanalytics/restservice")
@app.post("/aggregationanalytics/restservice/")
def ingest():
    OUT.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_%f")
    body = request.get_data() or b"{}"
    (OUT / f"post_{stamp}.json").write_bytes(body)
    return {"ok": True}, 200


@app.get("/health")
def health():
    return {"ok": True}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "7072")))
