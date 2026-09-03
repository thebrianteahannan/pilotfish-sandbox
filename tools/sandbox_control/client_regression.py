"""Per-client output regression: known-good inputs vs baseline HL7/files."""

from __future__ import annotations

import csv
import difflib
import json
import re
import shutil
import tempfile
import threading
import time
from datetime import datetime, timezone
from pathlib import Path

import clients

HL7_START = re.compile(r"^(MSH|BHS|FHS)\|", re.M)
CASE_ID = re.compile(r"^[a-z0-9][a-z0-9._-]{0,80}$")

_lock = threading.RLock()
_job = {
    "busy": False,
    "slug": "",
    "message": "",
    "error": "",
    "capture": False,
    "step": 0,
    "step_total": 0,
    "case_id": "",
    "wait_sec": 0,
    "timeout_sec": 0,
    "files": 0,
    "started_at": "",
    "log": [],
    "inbound": [],
    "picked": [],
    "outputs": [],
    "inbound_n": 0,
    "picked_n": 0,
    "output_n": 0,
    "queue": 0,
    "stage": "",
    "feed": "",
    "expected_sec": 0,
    "capture_sec": 0,
    "duration_sec": 0,
    "passed": [],
    "failed": [],
}


def job() -> dict:
    with _lock:
        return dict(_job)


def _set(**fields) -> None:
    with _lock:
        line = fields.pop("log_line", None)
        _job.update(fields)
        if line:
            log = list(_job.get("log") or [])
            log.append(str(line))
            _job["log"] = log[-12:]
            if not fields.get("message"):
                _job["message"] = str(line)


_FAST_POLL = False
_cancel = False
EIP_ROOT_IN = "/usr/local/tomcat/webapps/eip/eip-root"
POLL_ROUTES = (
    "interfaces/Flat File to HL7 and Kickout Reports/routes/1 - Incoming Flat Files by Partition and Client/route.xml",
    "interfaces/Flat File to HL7 and Kickout Reports/routes/1d - PPS Multi/route.xml",
)


def _docker(cmd: list[str], timeout: int = 120) -> tuple[int, str]:
    import demos

    return demos.run(cmd, timeout=timeout)


def _listeners_up(after: int = 0) -> bool:
    """True when the latest 'startup complete' is after the latest shutdown/launch.

    Do not scan only the tail: eip.log is multi-MB of transaction DEBUG, so the
    real startup line ages out of the last 200 KB while listeners are still up.
    """
    path = _eip_log()
    size = _log_offset(path)
    start = after if after else max(0, size - 8_000_000)
    low = _read_log(path, start).lower()
    last_complete = low.rfind("startup complete")
    last_launch = max(low.rfind("shutting down eipserver"), low.rfind("eipserver - launching"))
    return last_complete > last_launch


def _wait_eip(seconds: int = 180, after: int = 0) -> bool:
    import urllib.request

    deadline = time.time() + seconds
    http_ok = False
    while time.time() < deadline:
        try:
            urllib.request.urlopen("http://127.0.0.1:18080/eip/", timeout=3)
            http_ok = True
        except Exception:
            _set(message="Waiting for EIP HTTP on :18080…")
            time.sleep(2)
            continue
        if _listeners_up(after):
            _set(log_line="EIP listeners are up")
            return True
        _set(message="EIP HTTP is up. Waiting for listeners to finish starting…")
        time.sleep(2)
    _set(
        log_line=(
            "EIP HTTP is up but listeners never logged startup complete"
            if http_ok
            else "EIP did not answer on :18080 yet; continuing anyway"
        )
    )
    return False


def _set_fast_poll(root: Path) -> bool:
    """5s listener poll inside the container for this run only (host route.xml unchanged)."""
    global _FAST_POLL
    eip = root / "eip-root"
    copied = 0
    for rel in POLL_ROUTES:
        src = eip / rel
        if not src.is_file():
            continue
        text = src.read_text(encoding="utf-8", errors="replace")
        patched = text.replace("<PollingInterval>120</PollingInterval>", "<PollingInterval>5</PollingInterval>")
        if patched == text:
            continue
        dest = f"{EIP_ROOT_IN}/{rel}"
        with tempfile.NamedTemporaryFile("w", suffix=".xml", delete=False, encoding="utf-8") as tmp:
            tmp.write(patched)
            tmp_path = tmp.name
        try:
            _docker(["docker", "exec", "pilotfish-eip", "mkdir", "-p", str(Path(dest).parent)], timeout=20)
            code, _ = _docker(["docker", "cp", tmp_path, f"pilotfish-eip:{dest}"], timeout=60)
            if code == 0:
                copied += 1
                _docker(["docker", "exec", "pilotfish-eip", "chmod", "644", dest], timeout=15)
        finally:
            Path(tmp_path).unlink(missing_ok=True)
    if not copied:
        return False
    mark = _log_offset(_eip_log())
    _set(message="Restarting EIP with 5-second file pickup…", log_line="Listener poll 120s → 5s for this run")
    _docker(["docker", "restart", "pilotfish-eip"], timeout=120)
    ok = _wait_eip(120, after=mark)
    if ok:
        _FAST_POLL = True
        _set(log_line="EIP is up with fast pickup")
        return True
    _set(message="Fast poll did not start listeners. Restoring normal poll…", log_line="5s poll hung EIP; putting 120s back")
    for rel in POLL_ROUTES:
        src = eip / rel
        if src.is_file():
            dest = f"{EIP_ROOT_IN}/{rel}"
            _docker(["docker", "cp", str(src), f"pilotfish-eip:{dest}"], timeout=60)
            _docker(["docker", "exec", "pilotfish-eip", "chmod", "644", dest], timeout=15)
    mark = _log_offset(_eip_log())
    _docker(["docker", "restart", "pilotfish-eip"], timeout=120)
    _FAST_POLL = False
    if _wait_eip(180, after=mark):
        _set(log_line="EIP listeners are up (120s poll)")
    return False


def _restore_poll(root: Path) -> None:
    global _FAST_POLL
    if not _FAST_POLL:
        return
    eip = root / "eip-root"
    n = 0
    for rel in POLL_ROUTES:
        src = eip / rel
        if not src.is_file():
            continue
        dest = f"{EIP_ROOT_IN}/{rel}"
        code, _ = _docker(["docker", "cp", str(src), f"pilotfish-eip:{dest}"], timeout=60)
        if code == 0:
            n += 1
    _FAST_POLL = False
    if n:
        _set(message="Restoring normal EIP file pickup…", log_line="Listener poll back to 120s")
        mark = _log_offset(_eip_log())
        _docker(["docker", "restart", "pilotfish-eip"], timeout=120)
        _wait_eip(180, after=mark)
        _set(log_line="EIP restored")


def _reg(root: Path) -> Path:
    return root / "regression"


def _timings_path(root: Path) -> Path:
    return _reg(root) / "timings.json"


def _load_timings(root: Path) -> dict:
    path = _timings_path(root)
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def _capture_sec(root: Path) -> int:
    rec = _load_timings(root).get("capture") or {}
    return int(rec.get("last_sec") or rec.get("typical_sec") or 0)


def _need_files(root: Path, capture: bool) -> int:
    if capture:
        return 0
    rec = _load_timings(root).get("capture") or {}
    return int(rec.get("last_files") or 0)


def _typical_sec(root: Path, capture: bool) -> int:
    data = _load_timings(root)
    if not capture:
        n = _capture_sec(root)
        if n:
            return n
    rec = data.get("capture" if capture else "compare") or {}
    n = int(rec.get("typical_sec") or rec.get("last_sec") or 0)
    if n:
        return n
    return int(data.get("typical_sec") or 0)


def _record_timing(root: Path, capture: bool, duration_sec: int, files: int = 0) -> dict:
    duration_sec = int(duration_sec)
    if duration_sec < 20:
        return _load_timings(root)
    data = _load_timings(root)
    kind = "capture" if capture else "compare"
    rec = dict(data.get(kind) or {})
    samples = [int(x) for x in (rec.get("samples") or []) if int(x) >= 20][-5:]
    samples.append(duration_sec)
    samples = samples[-6:]
    ordered = sorted(samples)
    typical = ordered[len(ordered) // 2]
    rec = {"samples": samples, "typical_sec": typical, "last_sec": duration_sec}
    if files:
        rec["last_files"] = int(files)
    data[kind] = rec
    both = []
    for key in ("capture", "compare"):
        both.extend(int(x) for x in ((data.get(key) or {}).get("samples") or []) if int(x) >= 20)
    if both:
        data["typical_sec"] = sorted(both)[len(both) // 2]
    _timings_path(root).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    _write_progress_timing(root)
    return data


def _write_progress_timing(root: Path) -> None:
    sec = _capture_sec(root)
    dest = Path(__file__).resolve().parent / "static" / "regr-timing.json"
    try:
        dest.write_text(json.dumps({"capture_sec": sec}) + "\n", encoding="utf-8")
    except OSError:
        pass


def _load_manifest(root: Path) -> dict:
    path = _reg(root) / "manifest.json"
    if not path.is_file():
        return {"cases": [], "in_root": "data/in", "out_dir": "data/out"}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {"cases": [], "in_root": "data/in", "out_dir": "data/out"}
    return data if isinstance(data, dict) else {"cases": []}


def ensure_layout(root: Path) -> dict:
    man = _load_manifest(root)
    folder = _reg(root)
    folder.mkdir(parents=True, exist_ok=True)
    cases = list(man.get("cases") or [])
    if not cases and clients.slug_for(root.name) == "med-rec":
        cases = [
            {"id": "ngp-healthfirst", "title": "NGP Healthfirst", "drop": ".", "collect": [".ADT", ".DFT", ".adt", ".dft"]},
            {"id": "ariana-ligolab", "title": "Ariana LigoLab", "drop": ".", "collect": [".ADT", ".DFT", ".adt", ".dft"]},
        ]
        man = {
            "in_root": "data/in",
            "out_dir": "data/out",
            "timeout_sec": 180,
            "cases": cases,
        }
        (folder / "manifest.json").write_text(json.dumps(man, indent=2) + "\n", encoding="utf-8")
    for rec in cases:
        cid = rec.get("id") or ""
        if not CASE_ID.match(cid):
            continue
        base = folder / "cases" / cid
        (base / "in").mkdir(parents=True, exist_ok=True)
        (base / "baseline").mkdir(parents=True, exist_ok=True)
        (base / "last").mkdir(parents=True, exist_ok=True)
        meta = base / "case.json"
        if not meta.is_file():
            meta.write_text(json.dumps({k: rec[k] for k in rec if k != "id"}, indent=2) + "\n", encoding="utf-8")
    return man


def _case_dir(root: Path, cid: str) -> Path:
    return _reg(root) / "cases" / cid


def _list_files(folder: Path) -> list[Path]:
    if not folder.is_dir():
        return []
    return sorted(p for p in folder.iterdir() if p.is_file() and not p.name.startswith("."))


def _file_key(path: Path) -> str:
    stem = path.stem
    letters = re.match(r"[A-Za-z]+", stem)
    prefix = letters.group(0).upper() if letters else stem[:8].upper()
    return f"{prefix}:{path.suffix.lower()}"


def normalize(text: str, wipe_pv1: bool = False) -> str:
    raw = text.replace("\r\n", "\n").replace("\r", "\n")
    if not HL7_START.search(raw[:200] if len(raw) > 200 else raw) and not raw.startswith("MSH|") and not raw.startswith("BHS|"):
        return raw
    lines = []
    for line in raw.split("\n"):
        if not line:
            lines.append(line)
            continue
        tag = line[:3]
        if tag in ("MSH", "BHS", "FHS") and "|" in line:
            parts = line.split("|")
            wipe = (6, 9) if tag == "MSH" else (6, 10)
            for i in wipe:
                if i < len(parts):
                    parts[i] = re.sub(r"\d{8,20}", "*", parts[i] or "")
            line = "|".join(parts)
        elif tag == "EVN" and "|" in line:
            parts = line.split("|")
            if len(parts) > 2 and re.search(r"\d{8,}", parts[2] or ""):
                parts[2] = re.sub(r"\d{8,14}", "*", parts[2])
            line = "|".join(parts)
        elif wipe_pv1 and tag == "PV1" and "|" in line:
            parts = line.split("|")
            if len(parts) > 8:
                parts[8] = "*"
            line = "|".join(parts)
        lines.append(line)
    return "\n".join(lines)


def _order_ft1(text: str) -> str:
    """FT1 segment order is not significant; compare as a bag per message."""
    lines = text.split("\n")
    out: list[str] = []
    buf: list[str] = []

    def flush() -> None:
        if not buf:
            return
        ranked = sorted(ln for ln in buf if ln.startswith("FT1"))
        i = 0
        for ln in buf:
            if ln.startswith("FT1"):
                out.append(ranked[i])
                i += 1
            else:
                out.append(ln)
        buf.clear()

    for line in lines:
        if line.startswith("MSH") and buf:
            flush()
        buf.append(line)
    flush()
    return "\n".join(out)


def _lines(text: str, *, order_ft1: bool, wipe_pv1: bool) -> list[str]:
    blob = normalize(text, wipe_pv1=wipe_pv1)
    if order_ft1:
        blob = _order_ft1(blob)
    return blob.splitlines(keepends=True)


def _unified(left: list[str], right: list[str], name: str) -> list[str]:
    if left == right:
        return []
    return list(difflib.unified_diff(left, right, fromfile="baseline/" + name, tofile="last/" + name, n=2))


def _ignored_reason(lines: list[str]) -> str:
    body = []
    for raw in lines:
        s = str(raw)
        if s.startswith("+++") or s.startswith("---") or s.startswith("@@"):
            continue
        if s.startswith("+") or s.startswith("-"):
            body.append(s[1:])
    tags = []
    if any(x.startswith("FT1") for x in body):
        tags.append("FT1 order")
    if any(x.startswith("PV1") for x in body):
        tags.append("PV1 ordering physician")
    if not tags:
        tags.append("known noise")
    return "ignored · " + " · ".join(tags)


def _file_compare(a: str, b: str, name: str) -> dict | None:
    strict = _unified(_lines(a, order_ft1=False, wipe_pv1=False), _lines(b, order_ft1=False, wipe_pv1=False), name)
    canon = _unified(_lines(a, order_ft1=True, wipe_pv1=True), _lines(b, order_ft1=True, wipe_pv1=True), name)
    if not canon:
        if not strict:
            return None
        return {"kind": "ignored", "lines": strict[:400], "reason": _ignored_reason(strict)}
    return {"kind": "changed", "lines": canon[:400]}


def _diff(a: str, b: str, name: str) -> list[str]:
    hit = _file_compare(a, b, name)
    if not hit or hit.get("kind") == "ignored":
        return []
    return list(hit.get("lines") or [])


def _drop_dir(root: Path, man: dict, rec: dict) -> Path:
    rel = str(rec.get("drop") or ".")
    base = clients.ROOT / str(man.get("in_root") or "data/in")
    if rel in (".", "", "/"):
        return base
    return (base / rel).resolve()


def _inbound_dest(base: Path, name: str) -> Path:
    # HAX charges look up MedReceivables_Demographic_* in the same input dir.
    return base


def _still_sitting(dirs: list[Path], names: list[str]) -> list[str]:
    return [n for n in names if any((d / n).is_file() for d in dirs)]


def _out_dir(man: dict) -> Path:
    return clients.ROOT / str(man.get("out_dir") or "data/out")


def _collect_new(out: Path, started: float, suffixes: list[str]) -> list[Path]:
    want = {s.lower() if s.startswith(".") else "." + s.lower() for s in suffixes}
    found = []
    if not out.is_dir():
        return found
    for p in out.rglob("*"):
        if not p.is_file():
            continue
        if p.suffix.lower() not in want:
            continue
        if p.stat().st_mtime + 0.05 >= started:
            found.append(p)
    return sorted(found)


_LOG_NOISE = ("license", "Heartbeat", "Error while adding License", "Polling directory does not exist")


def _eip_log() -> Path:
    return clients.ROOT / "logs" / "eip.log"


def _log_offset(path: Path) -> int:
    try:
        return path.stat().st_size
    except OSError:
        return 0


def _read_log(path: Path, start: int) -> str:
    if not path.is_file():
        return ""
    with path.open("rb") as fh:
        fh.seek(start)
        return fh.read().decode("utf-8", errors="replace")


QUEUE_RE = re.compile(r"\[Queue: (\d+) /")
POOL_QUEUE_RE = re.compile(r'ThreadPool "([^"]+)"[^\n]*\[Queue: (\d+) /')
STAGE_RE = re.compile(r"Entered stage: \[([^\]]+)\]")
FEED_RE = re.compile(r"Set Partition and Client Name-([^\]\[]+)")
TX_RE = re.compile(r"\[TxID:([0-9a-fA-F-]{8,})\]")
WORK_POOL = ("Incoming Flat Files", "Stripping and Tweaking", "Generate DFT", "Generate ADT", "Kickout")


def _last_stage(chunk: str) -> str:
    hits = STAGE_RE.findall(chunk or "")
    return (hits[-1] or "").strip() if hits else ""


def _tail_log(path: Path, nbytes: int = 200000) -> str:
    if not path.is_file():
        return ""
    try:
        with path.open("rb") as fh:
            fh.seek(0, 2)
            sz = fh.tell()
            fh.seek(max(0, sz - nbytes))
            return fh.read().decode("utf-8", errors="replace")
    except OSError:
        return ""


def _work_queue(path: Path) -> int:
    chunk = _tail_log(path, 120000)
    best = 0
    for name, q in POOL_QUEUE_RE.findall(chunk):
        if any(tok in name for tok in WORK_POOL):
            best = max(best, int(q))
    return best


def _log_where(path: Path) -> dict:
    chunk = _tail_log(path, 250000)
    feeds = FEED_RE.findall(chunk)
    stages = STAGE_RE.findall(chunk)
    txs = {t for t in TX_RE.findall(chunk) if t.lower() != "null"}
    feed = (feeds[-1] or "").strip() if feeds else ""
    stage = (stages[-1] or "").strip() if stages else ""
    where = " · ".join(p for p in (feed, stage) if p)
    return {"feed": feed, "stage": stage, "where": where, "txs": len(txs), "queue": _work_queue(path)}


def _trim_ged(text: str, patients: int = 50) -> str:
    out: list[str] = []
    seen = 0
    skip = False
    for line in text.splitlines(keepends=True):
        if line.startswith("P"):
            seen += 1
            skip = seen > patients
        if not skip:
            out.append(line)
    return "".join(out)


def _trim_in_file(path: Path, patients: int = 50) -> None:
    suf = path.suffix.lower()
    if suf in {".xml", ".xlsx", ".xls"}:
        return
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return
    if not raw.strip():
        return
    if raw.lstrip()[:1] in "Hh":
        new = _trim_ged(raw, patients)
    else:
        lines = raw.splitlines(keepends=True)
        if len(lines) <= patients + 1:
            return
        new = "".join(lines[: patients + 1])
        if not new.endswith("\n"):
            new += "\n"
    if new and len(new) < len(raw):
        path.write_text(new, encoding="utf-8")


def _log_busy(chunk: str, needles: list[str]) -> bool:
    if not chunk:
        return False
    names = [n.lower() for n in needles if n]
    for line in chunk.splitlines():
        if any(tok in line for tok in _LOG_NOISE):
            continue
        low = line.lower()
        if any(n in low for n in names):
            return True
    return False


def _queue_depth(path: Path) -> int:
    return _work_queue(path)


def _fingerprint(files: list[Path]) -> tuple:
    rows = []
    for p in files:
        try:
            st = p.stat()
        except OSError:
            continue
        rows.append((str(p), st.st_size, int(st.st_mtime)))
    return tuple(sorted(rows))


def _copy_named(files: list[Path], dest: Path) -> list[str]:
    dest.mkdir(parents=True, exist_ok=True)
    for old in dest.iterdir():
        if old.is_file():
            old.unlink()
    names = []
    used: dict[str, int] = {}
    for src in files:
        key = _file_key(src)
        n = used.get(key, 0)
        used[key] = n + 1
        name = f"{key.replace(':', '_')}{'' if n == 0 else '_' + str(n)}"
        shutil.copy2(src, dest / name)
        names.append(name)
    return names


def _out_prefix(path: Path) -> str:
    m = re.match(r"[A-Za-z]+", path.stem)
    return (m.group(0) if m else path.stem[:8]).upper()


def _case_codes(root: Path, rec: dict) -> set[str]:
    extra = {}
    meta = _case_dir(root, rec["id"]) / "case.json"
    if meta.is_file():
        try:
            extra = json.loads(meta.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            extra = {}
    codes: set[str] = set()
    for src in (rec, extra):
        for key in ("client", "partition"):
            t = str(src.get(key) or "").strip().upper()
            for bit in t.replace("+", " ").split():
                if 2 <= len(bit) <= 8:
                    codes.add(bit)
        facs = src.get("facilities") or []
        if isinstance(facs, str):
            facs = [facs]
        for fac in facs:
            t = str(fac).strip().upper()
            if 2 <= len(t) <= 8:
                codes.add(t)
    return codes


def _wait_drop(drop: Path, names_in: list[str], out: Path, suffixes: list[str], started: float, timeout: int, label: str, sit_dirs: list[Path] | None = None) -> list[Path]:
    log_path = _eip_log()
    log_at = _log_offset(log_path)
    last_log = log_at
    watch = sit_dirs or [drop]
    start_deadline = started + max(timeout, 90)
    run_deadline = started + max(int(timeout), 90)
    quiet_need = 12
    pause = 0.5 if _FAST_POLL else 1
    collected: list[Path] = []
    fp = ()
    stable_since = 0.0
    saw_work = False
    sit_since = 0.0
    last_sit: tuple = ()
    while time.time() < run_deadline:
        if _cancel:
            return _collect_new(out, started, suffixes)
        collected = _collect_new(out, started, suffixes)
        now_off = _log_offset(log_path)
        recent = _read_log(log_path, last_log)
        since_drop = _read_log(log_path, log_at)
        last_log = now_off
        where = _log_where(log_path)
        queue = int(where.get("queue") or 0)
        log_work = queue > 0
        if collected or queue > 0:
            saw_work = True
        sitting = _still_sitting(watch, names_in)
        now = time.time()
        sit_key = tuple(sitting)
        if sit_key != last_sit:
            last_sit = sit_key
            sit_since = now
        stuck_in = bool(sitting) and (now - sit_since) >= 45 and queue == 0
        picked = [n for n in names_in if n not in sitting]
        out_names = [p.name for p in collected]
        stage = where.get("where") or where.get("stage") or ""
        now_fp = _fingerprint(collected)
        if now_fp != fp:
            fp = now_fp
            stable_since = now
        elapsed = int(now - started)
        cap = int(run_deadline - started) if saw_work else int(start_deadline - started)
        if sitting and not collected and not stuck_in:
            state = (
                f"{len(sitting)} file(s) still in data/in — waiting for poll"
                if _listeners_up()
                else "EIP listeners not started"
            )
        elif queue:
            state = f"EIP queue {queue} · picked {len(picked)}/{len(names_in)} · {len(out_names)} ADT/DFT"
        elif collected and now - stable_since < quiet_need:
            state = f"writing {len(out_names)} file(s)… ({len(sitting)} still inbound)"
        elif stuck_in:
            state = f"{len(sitting)} inbound not picked up — finishing with {len(out_names)} ADT/DFT"
        elif collected:
            state = f"{len(out_names)} file(s) stable · picked {len(picked)}/{len(names_in)}"
        else:
            state = "no output yet"
        need = int(_job.get("need_files") or 0)
        enough = (not need) or len(collected) >= max(1, int(need * 0.9))
        if queue == 0 and not sitting and collected and not enough:
            state = f"have {len(out_names)} ADT/DFT, waiting for ~{need} like capture"
        if stage:
            state = f"{stage} · {state}"
        extra = {}
        if (len(picked), len(sitting), len(out_names), queue, stage) != getattr(_wait_drop, "_sig", None):
            _wait_drop._sig = (len(picked), len(sitting), len(out_names), queue, stage)
            extra["log_line"] = (
                f"Picked {len(picked)}/{len(names_in)} · {len(sitting)} waiting in data/in · "
                f"{len(out_names)} ADT/DFT · queue {queue}"
                + (f" · {stage}" if stage else "")
            )
        _set(
            wait_sec=elapsed,
            files=len(collected),
            timeout_sec=cap,
            message=f"{label}: {state} ({elapsed}s)",
            inbound=sitting[:80],
            picked=picked[:80],
            outputs=out_names[:100],
            inbound_n=len(sitting),
            picked_n=len(picked),
            output_n=len(out_names),
            queue=queue,
            stage=stage,
            feed=where.get("feed") or "",
            step=len(picked),
            step_total=len(names_in),
            **extra,
        )
        try:
            live = Path(__file__).resolve().parent / "static" / "regr-live.json"
            live.write_text(
                json.dumps(
                    {
                        "busy": True,
                        "capture": bool(_job.get("capture")),
                        "message": f"{label}: {state} ({elapsed}s)",
                        "inbound": sitting[:80],
                        "picked": picked[:80],
                        "outputs": out_names[:100],
                        "inbound_n": len(sitting),
                        "picked_n": len(picked),
                        "output_n": len(out_names),
                        "queue": queue,
                        "stage": stage,
                        "feed": where.get("feed") or "",
                        "step": len(picked),
                        "step_total": len(names_in),
                        "files": len(collected),
                        "expected_sec": int(_job.get("expected_sec") or 0),
                        "capture_sec": int(_job.get("capture_sec") or _job.get("expected_sec") or 0),
                    }
                )
                + "\n",
                encoding="utf-8",
            )
        except OSError:
            pass
        outputs_done = bool(collected) and (now - stable_since) >= quiet_need and not log_work and queue == 0 and enough
        if outputs_done and not sitting:
            break
        if not saw_work and not sitting and now >= start_deadline:
            break
        time.sleep(pause)
    return _collect_new(out, started, suffixes)


def _finish_ran(root: Path, rec: dict, ran: dict, capture: bool) -> dict:
    title = rec.get("title") or rec["id"]
    if capture:
        case = _case_dir(root, rec["id"])
        (case / "baseline").mkdir(parents=True, exist_ok=True)
        last_files = _list_files(case / "last")
        if ran.get("ok") and last_files:
            for p in _list_files(case / "baseline"):
                p.unlink()
            for p in last_files:
                shutil.copy2(p, case / "baseline" / p.name)
            (case / "baseline" / ".captured").write_text("", encoding="utf-8")
        ran["baseline"] = [p.name for p in _list_files(case / "baseline")]
        _set(log_line=f"Saved {len(ran['baseline'])} baseline file(s) for {title}")
    elif not capture:
        ran.update(compare_case(root, rec["id"]))
        _set(log_line=f"{title}: {'pass' if ran.get('ok') else 'diff'}")
    (_case_dir(root, rec["id"]) / "compare.json").write_text(json.dumps(ran, indent=2) + "\n", encoding="utf-8")
    passed = list(_job.get("passed") or [])
    failed = list(_job.get("failed") or [])
    ignored_rows = list(_job.get("ignored") or [])
    item = {"id": rec["id"], "title": title}
    if ran.get("ignored"):
        packed_i = _pack_feed(rec["id"], {**ran, "diffs": ran.get("ignored") or []})
        packed_i["title"] = title
        packed_i["id"] = title
        packed_i["feed_id"] = rec["id"]
        ignored_rows.append(packed_i)
    if ran.get("ok"):
        passed.append(item)
    else:
        packed = _pack_feed(rec["id"], ran)
        packed["title"] = title
        packed["id"] = title
        packed["feed_id"] = rec["id"]
        failed.append(packed)
    _set(passed=passed, failed=failed, ignored=ignored_rows)
    _write_score()
    return ran


def _write_score() -> None:
    dest = Path(__file__).resolve().parent / "static" / "regr-score.json"
    try:
        dest.write_text(
            json.dumps(
                {
                    "passed": list(_job.get("passed") or []),
                    "failed": list(_job.get("failed") or []),
                    "ignored": list(_job.get("ignored") or []),
                    "current": _job.get("case_id") or "",
                    "step": _job.get("step") or 0,
                    "step_total": _job.get("step_total") or 0,
                }
            )
            + "\n",
            encoding="utf-8",
        )
    except OSError:
        pass


def _run_one(root: Path, man: dict, rec: dict, timeout: int) -> dict:
    cid = rec["id"]
    case = _case_dir(root, cid)
    inputs = _list_files(case / "in")
    if not inputs:
        return {"id": cid, "ok": False, "error": "No input files in in/", "diffs": [], "files": []}
    drop = _drop_dir(root, man, rec)
    drop.mkdir(parents=True, exist_ok=True)
    out = _out_dir(man)
    out.mkdir(parents=True, exist_ok=True)
    started = time.time()
    names_in = [src.name for src in inputs]
    _set(log_line=f"Dropped {len(inputs)} file(s) for {rec.get('title') or cid}", message="Dropped files into EIP input. Waiting for ADT/DFT…")
    for src in inputs:
        shutil.copy2(src, _inbound_dest(drop, src.name) / src.name)
    suffixes = rec.get("collect") or [".ADT", ".DFT", ".adt", ".dft"]
    collected = _wait_drop(drop, names_in, out, suffixes, started, timeout, rec.get("title") or cid, sit_dirs=[drop, drop / "HAL-Multi" / "in"])
    codes = _case_codes(root, rec)
    mine = [p for p in collected if _out_prefix(p) in codes] if codes else collected
    names = _copy_named(mine, case / "last")
    if not names:
        sitting = [n for n in names_in if (drop / n).is_file()]
        hint = " Input is still in data/in (listener never picked it up)." if sitting else ""
        return {
            "id": cid,
            "ok": False,
            "error": (
                f"No output under {out.relative_to(clients.ROOT).as_posix()} after {int(time.time() - started)}s."
                f"{hint} EIP must be running and the drop name must match the listener."
            ),
            "diffs": [],
            "files": [],
        }
    return {"id": cid, "ok": True, "error": "", "files": names, "diffs": []}


def _run_batch(root: Path, man: dict, recs: list[dict], timeout: int, capture: bool) -> list[dict]:
    drop = _drop_dir(root, man, recs[0] if recs else {"drop": "."})
    drop.mkdir(parents=True, exist_ok=True)
    out = _out_dir(man)
    out.mkdir(parents=True, exist_ok=True)
    names_in: list[str] = []
    nfiles = 0
    seen: set[str] = set()
    sit_dirs: set[Path] = {drop}
    for rec in recs:
        for src in _list_files(_case_dir(root, rec["id"]) / "in"):
            nfiles += 1
            _trim_in_file(src)
            if src.name in seen:
                continue
            seen.add(src.name)
            dest = _inbound_dest(drop, src.name)
            shutil.copy2(src, dest / src.name)
            sit_dirs.add(dest)
            names_in.append(src.name)
    _set(
        step=0,
        step_total=1,
        files=nfiles,
        message=f"Dropped {len(names_in)} file(s) at once. Waiting for EIP…",
        log_line=f"Batch drop {len(names_in)} unique file(s) ({nfiles} case inputs)",
    )
    started = time.time()
    suffixes = [".ADT", ".DFT", ".adt", ".dft"]
    collected = _wait_drop(drop, names_in, out, suffixes, started, max(timeout, 2400), "Batch", sit_dirs=list(sit_dirs))
    sitting = _still_sitting(list(sit_dirs), names_in)
    _set(log_line=f"EIP wrote {len(collected)} file(s); {len(sitting)} still inbound")
    results = []
    for i, rec in enumerate(recs, 1):
        if _cancel:
            break
        codes = _case_codes(root, rec)
        mine = [p for p in collected if _out_prefix(p) in codes] if codes else []
        names = _copy_named(mine, _case_dir(root, rec["id"]) / "last")
        ran = {
            "id": rec["id"],
            "ok": bool(names),
            "error": "" if names else "No matching ADT/DFT for this feed in the batch output.",
            "files": names,
            "diffs": [],
        }
        _set(step=i, step_total=len(recs), case_id=rec["id"], files=len(names), message=f"Sorted {i}/{len(recs)}: {rec.get('title') or rec['id']}")
        results.append(_finish_ran(root, rec, ran, capture))
    return results


def compare_case(root: Path, cid: str) -> dict:
    case = _case_dir(root, cid)
    base_files = {_file_key(p): p for p in _list_files(case / "baseline")}
    last_files = {_file_key(p): p for p in _list_files(case / "last")}
    diffs = []
    ignored = []
    missing = sorted(set(base_files) - set(last_files))
    extra = sorted(set(last_files) - set(base_files))
    for key in missing:
        diffs.append({"file": base_files[key].name, "kind": "missing", "lines": [f"missing in last run: {key}"]})
    for key in extra:
        diffs.append({"file": last_files[key].name, "kind": "extra", "lines": [f"new output not in baseline: {key}"]})
    for key in sorted(set(base_files) & set(last_files)):
        a = base_files[key].read_text(encoding="utf-8", errors="replace")
        b = last_files[key].read_text(encoding="utf-8", errors="replace")
        hit = _file_compare(a, b, last_files[key].name)
        if not hit:
            continue
        hit["file"] = last_files[key].name
        if hit.get("kind") == "ignored":
            ignored.append(hit)
        else:
            diffs.append(hit)
    return {
        "id": cid,
        "ok": not diffs,
        "error": "",
        "diffs": diffs,
        "ignored": ignored,
        "baseline_files": [p.name for p in _list_files(case / "baseline")],
        "last_files": [p.name for p in _list_files(case / "last")],
    }


def catalog(root: Path) -> list[dict]:
    """Lightweight case list for joining to H2 clients (no compare payloads)."""
    man = ensure_layout(root)
    rows = []
    for rec in man.get("cases") or []:
        cid = rec.get("id") or ""
        if not CASE_ID.match(cid):
            continue
        case = _case_dir(root, cid)
        extra = {}
        meta = case / "case.json"
        if meta.is_file():
            try:
                extra = json.loads(meta.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                extra = {}
        facs = extra.get("facilities") or rec.get("facilities") or []
        if isinstance(facs, str):
            facs = [facs]
        rows.append(
            {
                "id": cid,
                "title": extra.get("title") or rec.get("title") or cid,
                "partition": str(extra.get("partition") or rec.get("partition") or "").strip(),
                "client": str(extra.get("client") or rec.get("client") or "").strip(),
                "software_id": str(extra.get("software_id") or rec.get("software_id") or "").strip(),
                "facility": str(extra.get("facility") or "").strip(),
                "facilities": [str(x).strip() for x in facs if str(x).strip()],
                "inputs": [p.name for p in _list_files(case / "in")],
                "zips": extra.get("from_server_zips") or [p.name for p in _list_files(case / "from-server")],
                "baseline": [p.name for p in _list_files(case / "baseline")],
            }
        )
    return rows


def match_h2_client(cases: list[dict], rec: dict) -> list[dict]:
    sid = str(rec.get("software_id") or "").strip()
    part = str(rec.get("partition") or "").strip().upper()
    cli = str(rec.get("client") or "").strip().upper()
    facs = set()
    for row in rec.get("facilities") or []:
        if isinstance(row, dict):
            for key in ("FACILITY", "FACILITY_CODE", "CLIENT"):
                v = str(row.get(key) or "").strip().upper()
                if v:
                    facs.add(v)
        elif str(row).strip():
            facs.add(str(row).strip().upper())
    hits = []
    seen = set()
    for case in cases:
        cpart = (case.get("partition") or "").upper()
        ccli = (case.get("client") or "").upper()
        csid = str(case.get("software_id") or "").strip()
        cfacs = {str(x).upper() for x in (case.get("facilities") or []) if str(x).strip()}
        ok = False
        if sid and csid and sid == csid:
            ok = True
        elif part and cli and cpart == part and ccli == cli:
            ok = True
        elif part and cpart == part and facs and (facs & cfacs or cli in cfacs or ccli in facs):
            ok = True
        if ok and case["id"] not in seen:
            seen.add(case["id"])
            hits.append(case)
    return hits


def clients_table(root: Path) -> list[dict]:
    """All H2 CLIENT_SPLITS rows, with matched regression files (no Java)."""
    cases = catalog(root)
    path = root / "reports" / "CLIENT_SPLITS_full.csv"
    grouped: dict[str, dict] = {}
    if path.is_file():
        with path.open(newline="", encoding="utf-8", errors="replace") as fh:
            for row in csv.DictReader(fh):
                sid = str(row.get("SOFTWAREID") or "").strip()
                part = str(row.get("PARTITION") or "").strip()
                cli = str(row.get("SPLIT_CODE") or row.get("CLIENT") or "").strip()
                name = str(row.get("CLIENT_SPLIT") or row.get("CLIENTNAME") or "").strip()
                fac = str(row.get("FACILITY") or "").strip()
                key = f"{sid}|{part}|{cli}"
                rec = grouped.get(key)
                if not rec:
                    rec = {
                        "id": key,
                        "software_id": sid,
                        "name": name,
                        "partition": part,
                        "client": cli,
                        "facilities": [],
                    }
                    grouped[key] = rec
                if fac and fac not in rec["facilities"]:
                    rec["facilities"].append(fac)
                if name and not rec["name"]:
                    rec["name"] = name
    rows = sorted(grouped.values(), key=lambda r: ((r.get("name") or "").lower(), r.get("partition") or "", r.get("client") or ""))
    import client_listen_files as listen

    listens = listen.listeners(root)
    for rec in rows:
        rec["regression"] = match_h2_client(cases, rec)
        rec["has_files"] = any((c.get("inputs") or c.get("zips")) for c in rec["regression"])
        found = listen.match(listens, rec)
        rec["expected_files"] = [x.get("example") or x.get("pattern") for x in found if x.get("example") or x.get("pattern")]
        rec["filename_patterns"] = [x.get("pattern") for x in found if x.get("pattern")]
    return rows


def _last_run(root: Path) -> dict:
    path = _reg(root) / "last-run.json"
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def snapshot(slug: str) -> dict:
    root = clients.require_root(slug)
    man = ensure_layout(root)
    cases = []
    for rec in man.get("cases") or []:
        cid = rec.get("id") or ""
        if not CASE_ID.match(cid):
            continue
        case = _case_dir(root, cid)
        last_cmp = case / "compare.json"
        cmp = {}
        if last_cmp.is_file():
            try:
                cmp = json.loads(last_cmp.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                cmp = {}
        extra = {}
        meta = case / "case.json"
        if meta.is_file():
            try:
                extra = json.loads(meta.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                extra = {}
        cases.append(
            {
                **rec,
                **{k: extra[k] for k in ("partition", "client", "client_name", "facility", "facilities", "software_id", "sample") if k in extra},
                "inputs": [p.name for p in _list_files(case / "in")],
                "baseline": [p.name for p in _list_files(case / "baseline")],
                "last": [p.name for p in _list_files(case / "last")],
                "compare": cmp,
            }
        )
    last = _last_run(root)
    return {
        "ok": True,
        "path": _reg(root).relative_to(clients.ROOT).as_posix(),
        "note": (
            "Each case is one listener/feed. in/ holds a known-good inbound sample from the TEST zips. "
            "Capture baseline runs those through sandbox EIP and stores ADT/DFT in baseline/. "
            "Run regression after a change and diffs against that snapshot (timestamps and PV1 ordering physician ignored; FT1 order ignored)."
        ),
        "cases": cases,
        "clients": clients_table(root),
        "job": job(),
        "last_run": last,
        "timings": _load_timings(root),
        "coverage": (last or {}).get("coverage") or {},
    }


def _execute(slug: str, capture: bool, only: str) -> None:
    root = clients.require_root(slug)
    man = ensure_layout(root)
    timeout = int(man.get("timeout_sec") or 180)
    recs = [r for r in (man.get("cases") or []) if CASE_ID.match(r.get("id") or "")]
    if only:
        recs = [r for r in recs if r["id"] == only]
    recs = [r for r in recs if _list_files(_case_dir(root, r["id"]) / "in")]
    results: list[dict] = []
    verb = "Capturing baseline" if capture else "Running regression"
    t0 = time.time()
    expected = _typical_sec(root, capture)
    try:
        _set(step=0, step_total=len(recs), timeout_sec=timeout, expected_sec=expected, capture_sec=_capture_sec(root), need_files=_need_files(root, capture), passed=[], failed=[], log_line=f"{verb} · {len(recs)} case(s)")
        if not recs:
            _set(message="No cases with files in in/. Add inputs first.", error="")
            return
        if not clients.is_running(root):
            _set(message="Starting Med Rec sandbox…", log_line="Sandbox was down; starting it")
            clients.start_client(root)
            _set(message="Sandbox is up. Dropping test files…", log_line="Sandbox started")
        _set_fast_poll(root)
        per = min(max(timeout, 90), 120)
        for i, rec in enumerate(recs, 1):
            if _cancel:
                break
            _set(
                step=i,
                step_total=len(recs),
                case_id=rec["id"],
                need_files=0,
                message=f"{verb} {i}/{len(recs)}: {rec.get('title') or rec['id']}",
                log_line=f"{i}/{len(recs)} {rec.get('title') or rec['id']}",
            )
            ran = _run_one(root, man, rec, per)
            results.append(_finish_ran(root, rec, ran, capture))
        ok = True if capture and results and not _cancel else (all(r.get("ok") for r in results) if results else False)
        stamp = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")
        import client_regression_coverage as coverage

        cov = coverage.build(root, results)
        duration_sec = int(time.time() - t0)
        nfiles = sum(len(r.get("files") or r.get("baseline") or []) for r in results)
        timings = {} if _cancel else _record_timing(root, capture, duration_sec, files=nfiles)
        (_reg(root) / "last-run.json").write_text(
            json.dumps(
                {
                    "ok": ok,
                    "capture": capture,
                    "at": stamp,
                    "duration_sec": duration_sec,
                    "typical_sec": (timings.get("capture" if capture else "compare") or {}).get("typical_sec") or timings.get("typical_sec") or expected,
                    "results": results,
                    "coverage": cov,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        n = sum(len(r.get("diffs") or []) for r in results)
        splits = next((c for c in (cov.get("categories") or []) if c.get("label") == "Splits"), {})
        mins, secs = divmod(duration_sec, 60)
        took = f"{mins}m {secs}s" if mins else f"{secs}s"
        if _cancel:
            done = "Stopped."
        else:
            done = "Baseline saved." if capture else ("No regressions." if ok else f"{n} regression(s).")
            done += f" Took {took}."
            typ = int((timings.get("capture" if capture else "compare") or {}).get("typical_sec") or 0)
            if typ:
                tm, ts = divmod(typ, 60)
                done += f" Typical {tm}m {ts}s." if tm else f" Typical {ts}s."
            if splits:
                done += f" Coverage: {splits.get('hit')}/{splits.get('total')} splits ({splits.get('pct')}%)."
        _set(message=done, error="" if not _cancel else "Stopped", log_line=done, wait_sec=0, duration_sec=duration_sec)
    except Exception as exc:
        _set(error=str(exc)[:800], message="Regression failed")
    finally:
        try:
            _restore_poll(root)
        except Exception:
            pass
        _set(busy=False)


def run_sync(slug: str, *, capture: bool = False, case_id: str = "") -> dict:
    global _cancel
    with _lock:
        if _job.get("busy"):
            return {"ok": False, "error": "A regression run is already in progress."}
        _cancel = False
        root = clients.require_root(slug)
        expected = _typical_sec(root, capture)
        _set(
            busy=True,
            slug=slug,
            capture=capture,
            message="Starting…",
            error="",
            step=0,
            step_total=0,
            case_id="",
            wait_sec=0,
            files=0,
            log=[],
            expected_sec=expected,
            capture_sec=_capture_sec(root),
            duration_sec=0,
            started_at=datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        )
    _execute(slug, capture, case_id)
    root = clients.require_root(slug)
    path = _reg(root) / "last-run.json"
    if path.is_file():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {"ok": False, "error": "Could not read last-run.json"}
    return {"ok": False, "error": job().get("error") or "Regression produced no results"}


def _has_baseline(case: Path) -> bool:
    return bool(_list_files(case / "baseline")) or (case / "baseline" / ".captured").is_file()


def needs_baseline(slug: str) -> bool:
    root = clients.require_root(slug)
    man = ensure_layout(root)
    for rec in man.get("cases") or []:
        cid = rec.get("id") or ""
        if not CASE_ID.match(cid):
            continue
        case = _case_dir(root, cid)
        if _list_files(case / "in") and not _has_baseline(case):
            return True
    return False


def expected_case_ids(root: Path, dive: dict, meta: dict) -> list[str]:
    blob = (json.dumps(dive or {}) + " " + json.dumps(meta or {})).upper()
    ids = []
    for case in catalog(root):
        sid = str(case.get("software_id") or "").strip()
        part = str(case.get("partition") or "").strip().upper()
        cli = str(case.get("client") or "").strip().upper()
        hit = case["id"].upper() in blob
        if sid and sid in blob:
            hit = True
        if part and cli and part in blob and cli in blob:
            hit = True
        if hit:
            ids.append(case["id"])
    return ids


def _explain_expected(cid: str, ch: dict) -> str:
    """Plain-language why this expected-for-feature file differs."""
    kind = str(ch.get("kind") or "")
    fn = str(ch.get("file") or "")
    blob = "\n".join(str(x) for x in (ch.get("lines") or []))
    if kind == "missing":
        if cid == "irlcap" and fn.upper().startswith("CAQ"):
            return (
                f"{fn} was in Capital's baseline because NGP Capital uses the same CAQ_ prefix. "
                "This run did not copy a CAQ file into IRL CAP. Not an MUE split — shared output name with NGP CAQ."
            )
        return (
            f"{fn} was in the baseline and this run did not write it. "
            "That is a missing output for this feed, not an MUE quantity split on an existing charge."
        )
    if kind == "extra":
        return f"{fn} is new this run. It was not in the baseline."
    if "MUE^NGP" in blob:
        return (
            "Baseline VIF ADT included the Healthfirst MUE proof patient (PID MUE^NGP). "
            "This run did not emit that extra message, so the batch count dropped (BTS 5 to 4). "
            "Expected for this request: software 652 MUEs were proven with that test person; "
            "production NextGen VIF does not keep that extra ADT."
        )
    if "MUE^HAL" in blob or "AP_Halifax_MUE" in blob:
        which = "ADT" if fn.lower().endswith(".adt") else "DFT"
        extra = (
            " The DFT was a single FT1 for CPT 80048 qty 5 — the HAL MUE proof charge."
            if fn.lower().endswith(".dft")
            else " The ADT was only that proof patient (BHS file AP_Halifax_MUE.txt)."
        )
        return (
            f"Baseline HAA {which} was the Halifax MUE proof patient (PID MUE^HAL)."
            f"{extra} "
            "This case's inbound is production AP_Halifax_20260301.txt, so that proof message is gone. "
            "Expected: HAL is in scope for the new CDM MUE table; the proof drop is not this feed's production file."
        )
    if cid == "nsp-oh-pblab" or ("OH_MEDRC" in blob and ("irlstp" in blob.lower() or "STP|IRL" in blob or "|IRL|" in blob)):
        return (
            "Baseline STP is IRL St. Pete. This run's STP is NGP/Ohio PB Lab (OH_MEDRC CSV). "
            "Same STP_ filename, two clients. Not an MUE max-per-line split — output prefix collision."
        )
    if cid == "irltwiexp" or ("glftwhEXP" in blob and "irltwiEXP" in blob):
        return (
            "Baseline TWX is Gulf Coast export (glftwhEXP). This run's TWX is IRL Twin Cities export (irltwiEXP). "
            "Same TWX_ prefix, different hospitals, so the ADT/DFT look fully replaced. "
            "Not an MUE field change on one feed."
        )
    if "FT1|" in blob and blob.count("FT1|") >= 2:
        return (
            "FT1 lines differ after MUE rules (quantity split or CDM/CPT lookup). "
            "That is the mapping this request is supposed to change."
        )
    return (
        f"{fn} differs from baseline on this feed, which is on the expected list for this request. "
        "See the +/− lines for the exact segment change."
    )


def _summarize_diffs(ran: dict) -> list[dict]:
    out = []
    for d in ran.get("diffs") or []:
        if not isinstance(d, dict):
            out.append({"file": "", "kind": "changed", "lines": [str(d)]})
            continue
        kind = str(d.get("kind") or "changed")
        name = str(d.get("file") or "")
        raw = list(d.get("lines") or [])
        if kind == "missing":
            lines = [f"Baseline had {name}. This run did not write that file."]
        elif kind == "extra":
            lines = [f"This run wrote {name}. It was not in the baseline."]
        else:
            lines = [str(x).rstrip("\n") for x in raw[:80]]
        item = {"file": name, "kind": kind, "lines": lines}
        if d.get("reason"):
            item["reason"] = d.get("reason")
        out.append(item)
    return out


def _pack_feed(cid: str, ran: dict) -> dict:
    diffs = ran.get("diffs") or []
    return {
        "id": cid,
        "error": ran.get("error") or "",
        "diffs": len(diffs),
        "changes": _summarize_diffs(ran),
        "baseline_files": ran.get("baseline_files") or ran.get("baseline") or [],
        "last_files": ran.get("last_files") or ran.get("files") or [],
    }


def _is_incomplete(ran: dict) -> bool:
    diffs = [d for d in (ran.get("diffs") or []) if isinstance(d, dict)]
    kinds = {str(d.get("kind") or "") for d in diffs}
    last = ran.get("last_files") or ran.get("files") or []
    base = ran.get("baseline_files") or ran.get("baseline") or []
    err = str(ran.get("error") or "")
    if "No matching ADT/DFT" in err or "No output under" in err:
        return True
    if kinds and kinds <= {"missing"} and not last:
        return True
    if kinds and kinds <= {"extra"} and not base:
        return True
    return False


def classify_runs(before: dict, after: dict, expected_ids: list[str]) -> dict:
    want = set(expected_ids)
    amap = {r.get("id"): r for r in (after.get("results") or []) if r.get("id")}
    expected_changed, unexpected, incomplete, ignored, clean = [], [], [], [], []
    for cid, ran in amap.items():
        diffs = ran.get("diffs") or []
        failed = (not ran.get("ok")) or bool(diffs)
        packed = _pack_feed(cid, ran)
        if ran.get("ignored"):
            ign = _pack_feed(cid, {**ran, "diffs": ran.get("ignored") or []})
            ignored.append(ign)
        if _is_incomplete(ran):
            incomplete.append(packed)
        elif cid in want:
            if failed:
                for ch in packed.get("changes") or []:
                    ch["explain"] = _explain_expected(cid, ch)
                expected_changed.append(packed)
            else:
                clean.append(cid)
        elif failed:
            unexpected.append(packed)
        else:
            clean.append(cid)
    return {
        "ok": not unexpected and not incomplete,
        "expected_ids": expected_ids,
        "expected_changed": expected_changed,
        "unexpected": unexpected,
        "incomplete": incomplete,
        "ignored": ignored,
        "clean": len(clean),
        "before_ok": bool(before.get("ok")),
        "after_ok": bool(after.get("ok")) and not unexpected and not incomplete,
    }


def stop() -> dict:
    global _cancel
    _cancel = True
    _set(busy=False, message="Stopped.", log_line="Stopped")
    try:
        import client_pipeline

        client_pipeline._set(busy=False, kind="", message="Stopped.")
    except Exception:
        pass
    return {"ok": True, "message": "Stopped."}


def enqueue(slug: str, *, capture: bool = False, case_id: str = "") -> dict:
    global _cancel
    with _lock:
        if _job.get("busy"):
            return {"ok": False, "error": "A regression run is already in progress."}
        _cancel = False
        root = clients.require_root(slug)
        expected = _typical_sec(root, capture)
        _set(
            busy=True,
            slug=slug,
            capture=capture,
            message="Starting…",
            error="",
            step=0,
            step_total=0,
            case_id="",
            wait_sec=0,
            files=0,
            log=[],
            expected_sec=expected,
            capture_sec=_capture_sec(root),
            duration_sec=0,
            started_at=datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        )
    threading.Thread(target=_execute, args=(slug, capture, case_id), daemon=True).start()
    return {"ok": True, **job()}
