#!/usr/bin/env python3
"""Local stand-ins for CRL Plus carrier HTTP/SOAP, FlowNet, and image web services."""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, Response, jsonify, request

app = Flask(__name__)
OUT = Path(os.environ.get("OUTPUT_DIR", "/output"))
OK_XML = (
    b'<?xml version="1.0" encoding="UTF-8"?>'
    b'<TXLife xmlns="http://ACORD.org/Standards/Life/2">'
    b"<TXLifeResponse><TransResult><ResultCode tc=\"1\">Success</ResultCode>"
    b"</TransResult></TXLifeResponse></TXLife>"
)
SOAP_OK = (
    b'<?xml version="1.0" encoding="UTF-8"?>'
    b'<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
    b"<soap:Body><OK>true</OK></soap:Body></soap:Envelope>"
)


def _save(kind: str) -> None:
    folder = OUT / kind
    folder.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    name = f"{stamp}_{request.method}_{request.path.strip('/').replace('/', '_') or 'root'}.xml"
    (folder / name).write_bytes(request.get_data() or b"")


@app.get("/health")
def health():
    return jsonify({"ok": True, "service": "crl-plus-mocks"})


@app.route("/carrier/<path:rest>", methods=["GET", "POST", "PUT"])
def carrier(rest: str):
    _save(rest.split("/")[0] if rest else "carrier")
    return Response(OK_XML, status=200, mimetype="text/xml")


@app.route("/exam-order", methods=["GET", "POST"])
def exam_order():
    _save("exam-order")
    return Response(SOAP_OK, status=200, mimetype="text/xml")


@app.route("/flownet", methods=["GET", "POST"])
def flownet():
    _save("flownet")
    return Response(SOAP_OK, status=200, mimetype="text/xml")


@app.route("/image/<kind>", methods=["GET", "POST"])
def image(kind: str):
    _save(f"image-{kind}")
    return Response(SOAP_OK, status=200, mimetype="text/xml")


@app.route("/", defaults={"path": ""}, methods=["GET", "POST", "PUT"])
@app.route("/<path:path>", methods=["GET", "POST", "PUT"])
def any_path(path: str):
    _save("other")
    if request.method == "GET" and not request.get_data():
        return jsonify({"ok": True, "path": path})
    return Response(OK_XML, status=200, mimetype="text/xml")


if __name__ == "__main__":
    app.run(host=os.environ.get("HOST", "0.0.0.0"), port=int(os.environ.get("PORT", "8095")), debug=False)
