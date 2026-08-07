#!/usr/bin/env python3
"""Lightweight PilotFish EIP live status dashboard.

Usage:
  python3 tools/eip_status_monitor.py
  open http://127.0.0.1:8765/

Reads host-side logs + data dirs (and optional docker stats). No deps beyond stdlib.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import threading
import time
from collections import Counter
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
LOG = ROOT / "logs" / "eip.log"
IN_DIR = ROOT / "data" / "in"
OUT_DIR = ROOT / "data" / "out"
ARC_DIR = ROOT / "data" / "archive"
DEBUG_DIR = ROOT / "debug-trace"
HOST = os.environ.get("EIP_STATUS_HOST", "0.0.0.0")
PORT = int(os.environ.get("EIP_STATUS_PORT", "8765"))
CONTAINER = os.environ.get("EIP_CONTAINER", "pilotfish-eip")
RUN_MARKER = ROOT / "data" / "out" / "_active_run_marker.json"
TIMINGS_DIR = (
    ROOT
    / "Clients"
    / "Med Rec"
    / "data"
    / "Halifax-Historical-File-Issue"
    / "Halifax"
    / "Historical file - Output"
    / "Five_Parts_20260805"
)

# EIP log timestamps are unbracketed: "08/05/26 18:09:51 DEBUG ..."
STAGE_RE = re.compile(
    r"(?P<ts>\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}).*?"
    r"(?P<action>Entered|Exited) stage: \[(?P<body>[^\]]+)\](?P<rest>.*)$"
)
TX_RE = re.compile(r"\[TxID:(?P<txid>[^\]]+)\]")
ERROR_RE = re.compile(r"\b(ERROR|OutOfMemory|OOM|Exception)\b")
ATTR_KEYS = ("PartitionName", "ClientName", "FacilityName", "Partition", "Client", "Facility")


def _tail_lines(path: Path, max_bytes: int = 900_000) -> list[str]:
    if not path.exists():
        return []
    size = path.stat().st_size
    with path.open("rb") as f:
        if size > max_bytes:
            f.seek(size - max_bytes)
            f.readline()
        data = f.read().decode("utf-8", errors="replace")
    return data.splitlines()


def _count_data_rows(path: Path, limit_scan: int = 0) -> int | None:
    """Count non-header lines in a delimited text file. None if not a text table.

    For large MedReceivables files, prefer a fast `wc -l` estimate to keep the
    dashboard responsive (full Python scans of 250k+ lines make /api/status lag).
    """
    try:
        with path.open("r", errors="replace") as f:
            header = f.readline()
            if not header or ("|" not in header and "\t" not in header and "," not in header):
                return None
        # Fast path for large files
        if path.stat().st_size > 2_000_000:
            try:
                out = subprocess.check_output(["wc", "-l", str(path)], text=True)
                total = int(out.strip().split()[0])
                return max(total - 1, 0)  # subtract header
            except (subprocess.CalledProcessError, ValueError, OSError):
                pass
        with path.open("r", errors="replace") as f:
            f.readline()
            n = 0
            for line in f:
                if line.strip():
                    n += 1
                if limit_scan and n >= limit_scan:
                    return n
            return n
    except OSError:
        return None


def _hl7_counts(path: Path) -> dict:
    """Light HL7 scan: MSH / ADT / DFT / FT1 counts + sample FT1-4 years."""
    out = {"msh": 0, "adt": 0, "dft": 0, "ft1": 0, "ft1_years": {}}
    years: Counter[str] = Counter()
    try:
        with path.open("r", errors="replace") as f:
            for line in f:
                if line.startswith("MSH"):
                    out["msh"] += 1
                    if "|ADT" in line:
                        out["adt"] += 1
                    if "|DFT" in line:
                        out["dft"] += 1
                elif line.startswith("FT1"):
                    out["ft1"] += 1
                    fields = line.split("|")
                    if len(fields) > 4 and len(fields[4]) >= 4:
                        years[fields[4][:4]] += 1
        out["ft1_years"] = dict(years.most_common(8))
    except OSError:
        pass
    return out


def _list_files(dir_path: Path, patterns: tuple[str, ...] | None = None, limit: int = 40) -> list[dict]:
    if not dir_path.exists():
        return []
    items = []
    for p in sorted(dir_path.iterdir(), key=lambda x: x.stat().st_mtime, reverse=True):
        if not p.is_file():
            continue
        if p.name.startswith("."):
            continue
        if patterns and not any(p.match(pat) or p.name.endswith(pat.strip("*")) for pat in patterns):
            # simple contains/endswith fallback
            ok = False
            for pat in patterns:
                if pat.startswith("*") and p.name.endswith(pat[1:]):
                    ok = True
                elif pat.endswith("*") and p.name.startswith(pat[:-1]):
                    ok = True
                elif pat in p.name:
                    ok = True
            if not ok:
                continue
        st = p.stat()
        row = {
            "name": p.name,
            "bytes": st.st_size,
            "mtime": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(st.st_mtime)),
        }
        if p.suffix.lower() in {".txt", ".csv"} and "MedReceivables" in p.name:
            rows = _count_data_rows(p)
            if rows is not None:
                row["rows"] = rows
        if p.suffix.upper() in {".ADT", ".DFT", ".HL7"} or p.suffix.lower() == ".hl7":
            row["hl7"] = _hl7_counts(p)
        items.append(row)
        if len(items) >= limit:
            break
    return items


def _docker_status() -> dict:
    info: dict = {"container": CONTAINER, "running": False}
    try:
        st = subprocess.check_output(
            ["docker", "inspect", "-f", "{{.State.Status}}|{{.State.StartedAt}}|{{.State.ExitCode}}", CONTAINER],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        status, started, exit_code = (st.split("|") + ["", "", ""])[:3]
        info.update({"status": status, "started_at": started, "exit_code": exit_code, "running": status == "running"})
        if status == "running":
            mem = subprocess.check_output(
                ["docker", "stats", "--no-stream", "--format", "{{.MemUsage}}|{{.CPUPerc}}", CONTAINER],
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
            mem_u, cpu = (mem.split("|") + ["", ""])[:2]
            info["mem"] = mem_u
            info["cpu"] = cpu
    except (subprocess.CalledProcessError, FileNotFoundError, OSError) as e:
        info["error"] = str(e)
    return info


def _debug_trace_bytes() -> int:
    total = 0
    for base in (DEBUG_DIR, ROOT / "eip-root" / "debug-trace"):
        if not base.exists():
            continue
        for p in base.rglob("*"):
            if p.is_file():
                try:
                    total += p.stat().st_size
                except OSError:
                    pass
    return total


def _parse_log(lines: list[str]) -> dict:
    current = None
    history: list[dict] = []
    active_tx = None
    waiting_for = None
    recent_errors: list[str] = []
    attrs: Counter[str] = Counter()

    for line in lines:
        if ERROR_RE.search(line) and "Polling directory does not exist" not in line:
            recent_errors.append(line[-240:])
            if len(recent_errors) > 12:
                recent_errors = recent_errors[-12:]

        m = STAGE_RE.search(line)
        if not m:
            continue
        body = m.group("body")
        rest = m.group("rest") or ""
        # Prefer "Entered stage: [Route][Stage Name][Kind]"
        rest_parts = [p for p in re.findall(r"\[([^\]]+)\]", rest)]
        route = body
        stage = rest_parts[0] if rest_parts else body
        kind = rest_parts[1] if len(rest_parts) > 1 else ""
        txm = TX_RE.search(line)
        txid = txm.group("txid") if txm else None
        if txid and txid != "null":
            active_tx = txid
        entry = {
            "ts": m.group("ts"),
            "action": m.group("action"),
            "route": route,
            "stage": stage,
            "kind": kind,
            "txid": txid,
        }
        if m.group("action") == "Entered":
            current = entry
            history.append(entry)
            if len(history) > 25:
                history = history[-25:]

    # Infer waiting
    if current:
        stage_l = current["stage"].lower()
        if "listener" in current["kind"].lower() or "listener" in stage_l:
            waiting_for = "Waiting for input files (listener poll)"
        elif "database" in stage_l or "query" in stage_l:
            waiting_for = "Waiting on database"
        elif "transport" in current["kind"].lower():
            waiting_for = "Writing / transporting output"
        elif "xslt" in stage_l or "transform" in stage_l or "group" in stage_l or "tweak" in stage_l or "strip" in stage_l:
            waiting_for = f"CPU-bound processing: {current['stage']}"
        else:
            waiting_for = f"In stage: {current['stage']}"
    else:
        waiting_for = "Idle / no recent stage in log"

    # Pull attribute hints from last portion of log
    for line in lines[-400:]:
        for key in ATTR_KEYS:
            for val in re.findall(rf"{key}[=:]([A-Za-z0-9 _\-/]+)", line):
                attrs[f"{key}={val.strip()}"] += 1

    return {
        "current": current,
        "history": history[-15:],
        "active_txid": active_tx,
        "waiting_for": waiting_for,
        "recent_errors": recent_errors[-8:],
        "attribute_hints": dict(attrs.most_common(20)),
    }


_cache: dict = {"ts": 0.0, "payload": {}}
_lock = threading.Lock()


def _run_timings() -> dict:
    """Live stage timings for the active run (marker written when Part N is dropped)."""
    try:
        import importlib.util

        spec = importlib.util.spec_from_file_location(
            "eip_stage_timings", ROOT / "tools" / "eip_stage_timings.py"
        )
        mod = importlib.util.module_from_spec(spec)
        assert spec and spec.loader
        spec.loader.exec_module(mod)
    except Exception as e:
        return {"error": str(e)}

    after = None
    label = None
    if RUN_MARKER.exists():
        try:
            meta = json.loads(RUN_MARKER.read_text())
            label = meta.get("label")
            if meta.get("after"):
                after = mod.parse_ts(meta["after"])
        except (OSError, json.JSONDecodeError, ValueError):
            pass
    report = mod.collect_timings(LOG, after=after)
    report["label"] = label
    report["bottlenecks"] = (report.get("by_stage") or [])[:8]
    # Drop bulky raw list for API
    report.pop("durations", None)
    return report


def build_status() -> dict:
    now = time.time()
    with _lock:
        if now - _cache["ts"] < 1.5 and _cache["payload"]:
            return _cache["payload"]

    lines = _tail_lines(LOG)
    log_info = _parse_log(lines)
    docker = _docker_status()

    in_files = _list_files(IN_DIR, limit=30)
    out_files = _list_files(OUT_DIR, limit=40)
    # Prefer MedRec / HL7-ish archives
    arc_files = _list_files(ARC_DIR, patterns=("MedReceivables*",), limit=15)

    in_rows = sum(f.get("rows", 0) for f in in_files if "rows" in f)
    out_msh = sum((f.get("hl7") or {}).get("msh", 0) for f in out_files)
    out_ft1 = sum((f.get("hl7") or {}).get("ft1", 0) for f in out_files)

    # Clients / splits from HL7-ish output names (e.g. HAX0805d.DFT, DEX0805a.ADT)
    clients: Counter[str] = Counter()
    for f in out_files:
        name = f["name"]
        m = re.match(r"^([A-Z]{2,4})\d{4}[a-z]\.(ADT|DFT)$", name)
        if m:
            clients[m.group(1)] += 1
    # *_count.txt values (demo/charge tallies written by the interface)
    count_files: list[dict] = []
    if OUT_DIR.exists():
        for p in sorted(OUT_DIR.glob("*_count.txt"), key=lambda x: x.stat().st_mtime, reverse=True)[:20]:
            try:
                val = p.read_text(errors="replace").strip()
                count_files.append({"name": p.name, "value": val})
            except OSError:
                pass
    # Partition hints from input/archive MedReceivables names + attribute hints
    partitions = sorted({k.split("=", 1)[1] for k in log_info["attribute_hints"] if k.startswith("Partition")})
    facilities = sorted({k.split("=", 1)[1] for k in log_info["attribute_hints"] if k.startswith("Facility")})

    payload = {
        "updated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "root": str(ROOT),
        "docker": docker,
        "waiting_for": log_info["waiting_for"],
        "current_stage": log_info["current"],
        "active_txid": log_info["active_txid"],
        "stage_history": log_info["history"],
        "recent_errors": log_info["recent_errors"],
        "attribute_hints": log_info["attribute_hints"],
        "debug_trace_bytes": _debug_trace_bytes(),
        "clients": dict(clients),
        "partitions": partitions,
        "facilities": facilities,
        "count_files": count_files,
        "timings": _run_timings(),
        "counts": {
            "input_files": len(in_files),
            "input_table_rows": in_rows,
            "output_files": len([f for f in out_files if not f["name"].startswith("_")]),
            "output_msh": out_msh,
            "output_ft1": out_ft1,
            "archive_medreceivables": len(arc_files),
            "client_codes": len(clients),
        },
        "input_files": in_files,
        "output_files": out_files[:25],
        "archive_files": arc_files[:12],
    }
    with _lock:
        _cache["ts"] = now
        _cache["payload"] = payload
    return payload


HTML = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>EIP Status</title>
<style>
  :root {
    --bg:#0f1419; --panel:#1a2332; --text:#e7ecf3; --muted:#8b9bb4;
    --accent:#3d9cf0; --ok:#3ecf8e; --warn:#f0b429; --bad:#f07178; --line:#2a3548;
  }
  * { box-sizing:border-box; }
  body {
    margin:0; font:14px/1.45 "IBM Plex Sans", "Segoe UI", sans-serif;
    background: radial-gradient(1200px 600px at 10% -10%, #1c2a40 0%, var(--bg) 55%);
    color:var(--text); min-height:100vh; padding:20px;
  }
  h1 { font:600 22px/1.2 "IBM Plex Sans", sans-serif; margin:0 0 4px; }
  .sub { color:var(--muted); margin-bottom:16px; }
  .grid { display:grid; gap:12px; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); }
  .card {
    background:linear-gradient(180deg, #1e2a3d, var(--panel));
    border:1px solid var(--line); border-radius:10px; padding:14px;
  }
  .card h2 { margin:0 0 8px; font-size:12px; letter-spacing:.04em; text-transform:uppercase; color:var(--muted); }
  .big { font-size:28px; font-weight:650; letter-spacing:-.02em; }
  .ok { color:var(--ok); } .warn { color:var(--warn); } .bad { color:var(--bad); } .accent { color:var(--accent); }
  .mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size:12px; }
  table { width:100%; border-collapse:collapse; }
  th,td { text-align:left; padding:6px 4px; border-bottom:1px solid var(--line); vertical-align:top; }
  th { color:var(--muted); font-weight:600; font-size:11px; text-transform:uppercase; }
  .wide { grid-column:1/-1; }
  .pill { display:inline-block; padding:2px 8px; border-radius:999px; background:#243247; color:var(--muted); font-size:11px; }
  ul { margin:0; padding-left:18px; } li { margin:3px 0; }
</style>
</head>
<body>
  <h1>PilotFish EIP Status</h1>
  <div class="sub">Live view of <span class="mono" id="root"></span> · auto-refresh 2s · <span id="updated"></span></div>

  <div class="grid" id="top"></div>
  <div class="grid" style="margin-top:12px">
    <div class="card wide"><h2>Current step</h2><div id="current" class="mono"></div></div>
    <div class="card wide"><h2>Stage timings / bottlenecks (active run)</h2><div id="timings"></div></div>
    <div class="card wide"><h2>Recent stages</h2><div id="history"></div></div>
    <div class="card"><h2>Input files</h2><div id="inputs"></div></div>
    <div class="card"><h2>Output files</h2><div id="outputs"></div></div>
    <div class="card"><h2>Archive (MedReceivables)</h2><div id="archive"></div></div>
    <div class="card"><h2>Attribute hints</h2><div id="attrs" class="mono"></div></div>
    <div class="card wide"><h2>Recent errors (filtered)</h2><div id="errors" class="mono"></div></div>
  </div>
<script>
async function refresh(){
  let d;
  try {
    const r = await fetch('/api/status');
    if(!r.ok) throw new Error('HTTP '+r.status);
    d = await r.json();
  } catch(err) {
    document.getElementById('updated').textContent = 'API error: ' + err;
    document.getElementById('current').innerHTML = '<span class="bad">Cannot reach /api/status — is the monitor still running?</span>';
    return;
  }
  document.getElementById('root').textContent = d.root;
  document.getElementById('updated').textContent = 'updated ' + d.updated_at;
  const run = d.docker && d.docker.running;
  const dbg = d.debug_trace_bytes || 0;
  document.getElementById('top').innerHTML = `
    <div class="card"><h2>Container</h2>
      <div class="big ${run?'ok':'bad'}">${run?'RUNNING':'DOWN'}</div>
      <div class="mono">${d.docker.status||'?'} · mem ${d.docker.mem||'n/a'} · cpu ${d.docker.cpu||'n/a'}</div>
    </div>
    <div class="card"><h2>Waiting / doing</h2>
      <div class="big accent" style="font-size:18px">${esc(d.waiting_for||'')}</div>
      <div class="mono">txid ${d.active_txid||'—'}</div>
    </div>
    <div class="card"><h2>Input rows</h2>
      <div class="big">${fmt(d.counts.input_table_rows)}</div>
      <div class="mono">${d.counts.input_files} file(s) in data/in</div>
    </div>
    <div class="card"><h2>Output MSH / FT1</h2>
      <div class="big">${fmt(d.counts.output_msh)} <span style="font-size:14px;color:var(--muted)">/ ${fmt(d.counts.output_ft1)}</span></div>
      <div class="mono">${d.counts.output_files} output file(s)</div>
    </div>
    <div class="card"><h2>Debug-trace disk</h2>
      <div class="big ${dbg>0?'warn':'ok'}">${fmtBytes(dbg)}</div>
      <div class="mono">should stay 0 while debug is off</div>
    </div>
    <div class="card"><h2>Clients / splits in outputs</h2>
      <div class="mono">${Object.keys(d.clients||{}).length ? Object.entries(d.clients).map(([k,v])=>k+' ×'+v).join(' · ') : '—'}</div>
      <div class="mono" style="margin-top:6px;color:var(--muted)">partitions: ${(d.partitions||[]).join(', ')||'—'} · facilities: ${(d.facilities||[]).join(', ')||'—'}</div>
    </div>
    <div class="card"><h2>Count files</h2>
      <div class="mono">${(d.count_files||[]).length ? (d.count_files||[]).slice(0,8).map(c=>esc(c.name)+' = <b>'+esc(c.value)+'</b>').join('<br/>') : '—'}</div>
    </div>`;

  const cur = d.current_stage;
  document.getElementById('current').innerHTML = cur
    ? `<div><span class="pill">${esc(cur.ts)}</span> <b>${esc(cur.route)}</b></div>
       <div style="margin-top:8px;font-size:16px">${esc(cur.stage)}</div>
       <div class="muted">${esc(cur.kind||'')}</div>`
    : '<span class="warn">No active stage seen in recent log</span>';

  const t = d.timings || {};
  const bottles = t.bottlenecks || t.by_stage || [];
  const prog = t.in_progress || [];
  let timingHtml = `<div class="mono">run <b>${esc(t.label||'—')}</b> · wall ${t.wall_seconds!=null?t.wall_seconds+'s':'—'} · completed intervals ${t.completed_steps||0}</div>`;
  if(prog.length){
    timingHtml += '<div style="margin-top:8px"><b>In progress</b><ul>'+prog.slice(0,5).map(p=>`<li>${esc(p.stage)} · ${fmt(Math.round(p.seconds_so_far))}s so far</li>`).join('')+'</ul></div>';
  }
  if(bottles.length){
    timingHtml += table(['Stage','Total s','%','Max s','n'], bottles.slice(0,10).map(b=>[b.stage, b.total_seconds, (b.pct!=null?b.pct+'%':'—'), b.max_seconds, b.count]));
  } else {
    timingHtml += '<div class="warn" style="margin-top:8px">No completed Entered/Exited pairs yet for this run marker</div>';
  }
  document.getElementById('timings').innerHTML = timingHtml;

  document.getElementById('history').innerHTML = table(
    ['Time','Route','Stage'],
    (d.stage_history||[]).slice().reverse().map(h => [h.ts, h.route, h.stage])
  );
  document.getElementById('inputs').innerHTML = filesTable(d.input_files||[]);
  document.getElementById('outputs').innerHTML = filesTable(d.output_files||[], true);
  document.getElementById('archive').innerHTML = filesTable(d.archive_files||[]);
  const attrs = d.attribute_hints||{};
  document.getElementById('attrs').innerHTML = Object.keys(attrs).length
    ? '<ul>'+Object.entries(attrs).map(([k,v])=>`<li>${esc(k)} <span class="pill">×${v}</span></li>`).join('')+'</ul>'
    : '<span class="warn">none in recent log</span>';
  const errs = d.recent_errors||[];
  document.getElementById('errors').innerHTML = errs.length
    ? '<ul>'+errs.map(e=>`<li class="bad">${esc(e)}</li>`).join('')+'</ul>'
    : '<span class="ok">none</span>';
}
function filesTable(files, hl7){
  if(!files.length) return '<span class="warn">empty</span>';
  const rows = files.map(f => {
    let extra = f.rows!=null ? `${fmt(f.rows)} rows` : fmtBytes(f.bytes);
    if(hl7 && f.hl7){ extra += ` · MSH ${f.hl7.msh} FT1 ${f.hl7.ft1}`; }
    return [f.mtime, f.name, extra];
  });
  return table(['Modified','File','Detail'], rows);
}
function table(headers, rows){
  return `<table><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead>
    <tbody>${rows.map(r=>`<tr>${r.map(c=>`<td class="mono">${esc(String(c))}</td>`).join('')}</tr>`).join('')}</tbody></table>`;
}
function esc(s){ return String(s).replace(/[&<>"']/g, c=>({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function fmt(n){ return (n||0).toLocaleString(); }
function fmtBytes(n){
  if(n<1024) return n+' B';
  if(n<1048576) return (n/1024).toFixed(1)+' KB';
  if(n<1073741824) return (n/1048576).toFixed(1)+' MB';
  return (n/1073741824).toFixed(2)+' GB';
}
refresh(); setInterval(refresh, 2000);
</script>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # quieter
        if "/api/" in (args[0] if args else ""):
            return
        super().log_message(fmt, *args)

    def do_GET(self):
        path = urlparse(self.path).path
        if path in ("/", "/index.html"):
            body = HTML.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if path == "/api/status":
            body = json.dumps(build_status()).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.send_error(404)


def main():
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    lan = "127.0.0.1"
    try:
        import socket

        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        lan = s.getsockname()[0]
        s.close()
    except OSError:
        pass
    print(f"EIP status monitor on http://127.0.0.1:{PORT}/  (LAN http://{lan}:{PORT}/)")
    print(f"Watching log={LOG}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
