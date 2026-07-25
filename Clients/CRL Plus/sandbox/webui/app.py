#!/usr/bin/env python3
"""CRL Plus American Income Life (AIL) sandbox — HTTP POST + LAN results UI."""

from __future__ import annotations

import base64
import json
import os
import socket
import threading
import uuid
from datetime import datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", str(Path(__file__).resolve().parents[1] / "output")))
SAMPLE_DIR = Path(os.environ.get("SAMPLE_DIR", str(Path(__file__).resolve().parents[1] / "sample-data")))
AUTH_USER = os.environ.get("AIL_AUTH_USER", "ail")
AUTH_PASS = os.environ.get("AIL_AUTH_PASS", "AilSandbox$Test1")
SKIP_OUTBOUND = os.environ.get("AIL_SKIP_OUTBOUND", "true").lower() in {"1", "true", "yes"}
PORT = int(os.environ.get("PORT", "8094"))

_lock = threading.Lock()
_transactions: list[dict] = []

NS = {"a": "http://ACORD.org/Standards/Life/2"}


def _now() -> str:
    return datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")


def _lan_ip() -> str:
    override = (os.environ.get("LAN_IP") or "").strip()
    if override:
        return override
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except OSError:
        return "127.0.0.1"


def _check_basic_auth() -> bool:
    header = request.headers.get("Authorization", "")
    if not header.startswith("Basic "):
        return False
    try:
        decoded = base64.b64decode(header.split(" ", 1)[1]).decode("utf-8")
        user, _, password = decoded.partition(":")
        return user == AUTH_USER and password == AUTH_PASS
    except Exception:
        return False


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def _find_text(root: ET.Element, names: set[str]) -> str | None:
    for el in root.iter():
        if _local_name(el.tag) in names and (el.text or "").strip():
            return el.text.strip()
    return None


def _parse_121(xml_bytes: bytes) -> dict:
    root = ET.fromstring(xml_bytes)
    tracking = _find_text(root, {"TrackingID"}) or f"AIL-{uuid.uuid4().hex[:8]}"
    pol = _find_text(root, {"PolNumber"}) or "UNKNOWN"
    first = _find_text(root, {"FirstName"}) or ""
    last = _find_text(root, {"LastName"}) or ""
    trans_ref = _find_text(root, {"TransRefGUID"}) or tracking
    return {
        "trackingId": tracking,
        "polNumber": pol,
        "insured": f"{last}, {first}".strip(", "),
        "transRefGuid": trans_ref,
        "sourceClient": "AIL",
    }


def _sync_121_response(meta: dict, accepted: bool = True) -> str:
    status_tc = "1" if accepted else "5"
    status_text = "Success" if accepted else "Failure"
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<TXLife xmlns="http://ACORD.org/Standards/Life/2">
  <TXLifeResponse>
    <TransRefGUID>{meta['transRefGuid']}</TransRefGUID>
    <TransType tc="121">General Requirement Order Request</TransType>
    <TransResult>
      <ResultCode tc="{status_tc}">{status_text}</ResultCode>
      <ResultInfo>
        <ResultInfoCode tc="0">Success</ResultInfoCode>
        <ResultInfoDesc>AIL sandbox accepted order {meta['trackingId']}</ResultInfoDesc>
      </ResultInfo>
    </TransResult>
    <OLifEExtension ExtensionCode="PilotFishSandbox">
      <sourceClient>AIL</sourceClient>
      <inboundPath>/http-post/ail</inboundPath>
    </OLifEExtension>
  </TXLifeResponse>
</TXLife>
"""


def _status_1122_payload(meta: dict) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<TXLife xmlns="http://ACORD.org/Standards/Life/2">
  <TXLifeRequest>
    <TransRefGUID>{meta['transRefGuid']}-1122</TransRefGUID>
    <TransType tc="1122">Status or Result</TransType>
    <OLifE>
      <SourceInfo>
        <SourceInfoName>AIL</SourceInfoName>
      </SourceInfo>
      <Holding>
        <Policy>
          <PolNumber>{meta['polNumber']}</PolNumber>
          <RequirementInfo>
            <ReqStatus tc="11">Completed</ReqStatus>
            <TrackingID>{meta['trackingId']}</TrackingID>
            <StatusEvent>
              <StatusEventCode>S78</StatusEventCode>
              <ProviderEventCode>COMPLETE</ProviderEventCode>
            </StatusEvent>
          </RequirementInfo>
        </Policy>
      </Holding>
    </OLifE>
  </TXLifeRequest>
</TXLife>
"""


def _record(tx: dict) -> None:
    with _lock:
        _transactions.insert(0, tx)
        del _transactions[100:]
    (OUTPUT_DIR / "transactions.json").write_text(
        json.dumps(_transactions, indent=2), encoding="utf-8"
    )


def _run_pipeline(xml_bytes: bytes, via: str) -> dict:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for sub in ("orders", "status", "responses"):
        (OUTPUT_DIR / sub).mkdir(parents=True, exist_ok=True)

    meta = _parse_121(xml_bytes)
    tx_id = uuid.uuid4().hex[:12]
    steps = []

    order_path = OUTPUT_DIR / "orders" / f"{meta['trackingId']}-{tx_id}.xml"
    order_path.write_bytes(xml_bytes)
    steps.append(
        {
            "route": "AmericanIncomeLife / 1 - 121 Incoming",
            "detail": f"HttpPostListener RequestPath=ail; sourceClient=AIL; saved {order_path.name}",
            "ok": True,
        }
    )

    sync = _sync_121_response(meta, accepted=True)
    sync_path = OUTPUT_DIR / "responses" / f"{meta['trackingId']}-121rs.xml"
    sync_path.write_text(sync, encoding="utf-8")
    steps.append(
        {
            "route": "AmericanIncomeLife / 2 - 121 Response",
            "detail": "Synchronous 121 success response generated for sender",
            "ok": True,
        }
    )

    steps.append(
        {
            "route": "Status / 4 - Route to client specific",
            "detail": "sourceClient=AIL → Transport To AmericanIncomeLife → ServiceName AIL 1122 Status",
            "ok": True,
        }
    )

    status_xml = _status_1122_payload(meta)
    status_path = OUTPUT_DIR / "status" / f"{meta['trackingId']}-1122.xml"
    status_path.write_text(status_xml, encoding="utf-8")
    outbound = {
        "attempted": not SKIP_OUTBOUND,
        "skipped": SKIP_OUTBOUND,
        "url": "http://localhost:8094/ail/status",
        "responseCode": None,
        "note": "Outbound POST skipped until AIL provides/needs a web-service callback (FGL email pattern)",
    }
    if not SKIP_OUTBOUND:
        # Loopback mock on same app
        import urllib.request

        req = urllib.request.Request(
            f"http://127.0.0.1:{PORT}/ail/status",
            data=status_xml.encode("utf-8"),
            headers={"Content-Type": "text/xml; charset=UTF-8"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                outbound["responseCode"] = resp.getcode()
                outbound["note"] = "Mock AIL outbound accepted status/result"
        except Exception as exc:  # noqa: BLE001
            outbound["note"] = f"Outbound mock failed: {exc}"
            outbound["responseCode"] = None

    steps.append(
        {
            "route": "AmericanIncomeLife / 3 - 1122 Status or Result POST",
            "detail": outbound["note"],
            "ok": True,
            "outbound": outbound,
        }
    )
    steps.append(
        {
            "route": "AmericanIncomeLife / 4 - 1122 POST Response",
            "detail": "Archive response + mark status sent (sandbox simulated)",
            "ok": True,
        }
    )

    tx = {
        "id": tx_id,
        "receivedAt": _now(),
        "via": via,
        "meta": meta,
        "steps": steps,
        "syncResponse": sync,
        "statusPayload": status_xml,
    }
    _record(tx)
    return tx


@app.get("/")
def index():
    lan = _lan_ip()
    with _lock:
        txs = list(_transactions)
    return render_template(
        "index.html",
        lan_ip=lan,
        port=PORT,
        auth_user=AUTH_USER,
        auth_pass=AUTH_PASS,
        skip_outbound=SKIP_OUTBOUND,
        transactions=txs,
        external_url="https://plus.intg.crlcorp.com/http-post/ail",
        local_url=f"http://{lan}:{PORT}/http-post/ail",
    )


@app.get("/api/transactions")
def api_transactions():
    with _lock:
        return jsonify({"ok": True, "transactions": list(_transactions)})


@app.post("/http-post/ail")
@app.post("/http-post/ail/")
def http_post_ail():
    if not _check_basic_auth():
        return (
            "Unauthorized — provide Basic auth matching auth-test.txt (ail / AilSandbox$Test1)",
            401,
            {"WWW-Authenticate": 'Basic realm="PilotFish"'},
        )
    body = request.get_data()
    if not body:
        return "Empty body", 400
    try:
        tx = _run_pipeline(body, via="HTTP POST /http-post/ail")
    except ET.ParseError as exc:
        return f"Invalid XML: {exc}", 400
    return tx["syncResponse"], 200, {"Content-Type": "text/xml; charset=UTF-8"}


@app.post("/api/run-sample")
def run_sample():
    sample = SAMPLE_DIR / "ail-121-order.xml"
    if not sample.exists():
        return jsonify({"ok": False, "error": "sample missing"}), 404
    tx = _run_pipeline(sample.read_bytes(), via="UI sample inject")
    return jsonify({"ok": True, "transaction": tx})


@app.post("/ail/status")
def ail_status_mock():
    """Mock carrier web service for optional outbound 1122 POST."""
    body = request.get_data(as_text=True)
    path = OUTPUT_DIR / "responses" / f"ail-outbound-{uuid.uuid4().hex[:8]}.xml"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "responses").mkdir(parents=True, exist_ok=True)
    path.write_text(body or "", encoding="utf-8")
    return (
        '<?xml version="1.0"?><Ack><Status>OK</Status><Receiver>AIL-MOCK</Receiver></Ack>',
        200,
        {"Content-Type": "text/xml; charset=UTF-8"},
    )


@app.get("/api/health")
def health():
    return jsonify(
        {
            "ok": True,
            "client": "AmericanIncomeLife",
            "sourceClient": "AIL",
            "requestPath": "ail",
            "lan": f"http://{_lan_ip()}:{PORT}/",
        }
    )


if __name__ == "__main__":
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    app.run(host=os.environ.get("HOST", "0.0.0.0"), port=PORT, debug=False)
