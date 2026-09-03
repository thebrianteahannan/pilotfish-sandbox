#!/usr/bin/env python3
"""Shared interface test-plan library (stdlib only; plans are JSON)."""
from __future__ import annotations

import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


@dataclass
class TestResult:
    id: str
    name: str
    suite: str
    status: str  # pass | fail | skip | error
    duration_ms: int = 0
    message: str = ""
    detail: str = ""


@dataclass
class RunReport:
    interface: str
    root: str
    started_at: str
    finished_at: str = ""
    summary: dict[str, int] = field(default_factory=dict)
    results: list[dict[str, Any]] = field(default_factory=list)
    plan_path: str = ""


def load_plan(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or "suites" not in data:
        raise ValueError(f"Invalid test plan: {path}")
    return data


def resolve_vars(value: Any, vars_map: dict[str, str]) -> Any:
    if isinstance(value, str):
        out = value
        for k, v in vars_map.items():
            out = out.replace("{" + k + "}", v)
        # env:VAR
        def env_sub(m):
            return os.environ.get(m.group(1), "")

        out = re.sub(r"\{env:([A-Z0-9_]+)\}", env_sub, out)
        return out
    if isinstance(value, list):
        return [resolve_vars(v, vars_map) for v in value]
    if isinstance(value, dict):
        return {k: resolve_vars(v, vars_map) for k, v in value.items()}
    return value


def http_request(
    method: str,
    url: str,
    headers: dict[str, str] | None = None,
    body: bytes | None = None,
    timeout: float = 30.0,
) -> tuple[int, dict[str, str], bytes]:
    req = urllib.request.Request(url, data=body, method=method.upper())
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            hdrs = {k.lower(): v for k, v in resp.headers.items()}
            return resp.status, hdrs, raw
    except urllib.error.HTTPError as e:
        raw = e.read() if e.fp else b""
        hdrs = {k.lower(): v for k, v in (e.headers.items() if e.headers else [])}
        return e.code, hdrs, raw


def body_text(raw: bytes) -> str:
    try:
        return raw.decode("utf-8", errors="replace")
    except Exception:
        return ""


def expect_match(text: str, expect: dict[str, Any]) -> str | None:
    for needle in expect.get("contains") or []:
        if needle not in text:
            return f"body missing: {needle!r}"
    for needle in expect.get("not_contains") or []:
        if needle in text:
            return f"body unexpectedly contains: {needle!r}"
    for pattern in expect.get("regex") or []:
        if not re.search(pattern, text, re.I | re.M):
            return f"regex not matched: {pattern!r}"
    return None


def run_http_test(test: dict[str, Any], root: Path, vars_map: dict[str, str]) -> TestResult:
    t0 = time.time()
    tid = test.get("id") or "http"
    name = test.get("name") or tid
    suite = test.get("_suite") or ""
    try:
        req = resolve_vars(test.get("request") or {}, vars_map)
        method = (req.get("method") or "GET").upper()
        url = req.get("url") or ""
        headers = dict(req.get("headers") or {})
        body = None
        if req.get("body_file"):
            path = root / resolve_vars(req["body_file"], vars_map)
            body = path.read_bytes()
        elif req.get("json") is not None:
            body = json.dumps(req["json"]).encode("utf-8")
            headers.setdefault("Content-Type", "application/json")
        elif req.get("body") is not None:
            b = req["body"]
            body = b.encode("utf-8") if isinstance(b, str) else json.dumps(b).encode("utf-8")
            if not isinstance(b, str):
                headers.setdefault("Content-Type", "application/json")
        if req.get("auth_bearer_var"):
            token = vars_map.get(req["auth_bearer_var"], "")
            if not token:
                return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), "missing bearer token var")
            headers["Authorization"] = f"Bearer {token}"
        status, hdrs, raw = http_request(method, url, headers, body, timeout=float(req.get("timeout", 30)))
        text = body_text(raw)
        expect = resolve_vars(test.get("expect") or {}, vars_map)
        want = expect.get("status")
        status_in = expect.get("status_in")
        if status_in is not None:
            allowed = {int(x) for x in status_in}
            if int(status) not in allowed:
                return TestResult(
                    tid,
                    name,
                    suite,
                    "fail",
                    int((time.time() - t0) * 1000),
                    f"expected HTTP one of {sorted(allowed)}, got {status}",
                    text[:400],
                )
        elif want is not None and int(want) != int(status):
            return TestResult(
                tid,
                name,
                suite,
                "fail",
                int((time.time() - t0) * 1000),
                f"expected HTTP {want}, got {status}",
                text[:400],
            )
        err = expect_match(text, expect)
        if err:
            return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), err, text[:400])
        for hk, hv in (expect.get("headers") or {}).items():
            actual = hdrs.get(hk.lower(), "")
            if hv not in actual:
                return TestResult(
                    tid,
                    name,
                    suite,
                    "fail",
                    int((time.time() - t0) * 1000),
                    f"header {hk} missing {hv!r} (got {actual!r})",
                )
        # optional store
        store = test.get("store") or {}
        if store.get("json_path") and store.get("as"):
            try:
                data = json.loads(text)
                cur: Any = data
                for part in str(store["json_path"]).split("."):
                    if part.endswith("]"):
                        # simple key[0]
                        m = re.match(r"([^\[]+)\[(\d+)\]", part)
                        if not m:
                            raise KeyError(part)
                        cur = cur[m.group(1)][int(m.group(2))]
                    else:
                        cur = cur[part]
                vars_map[store["as"]] = str(cur)
            except Exception as e:
                return TestResult(
                    tid, name, suite, "fail", int((time.time() - t0) * 1000), f"store failed: {e}", text[:200]
                )
        if store.get("header") and store.get("as"):
            val = hdrs.get(str(store["header"]).lower(), "")
            if store.get("basename"):
                val = val.rstrip("/").split("/")[-1]
            vars_map[store["as"]] = val
        return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), f"HTTP {status}")
    except Exception as e:
        return TestResult(tid, name, suite, "error", int((time.time() - t0) * 1000), str(e))


def run_oauth_test(test: dict[str, Any], vars_map: dict[str, str]) -> TestResult:
    t0 = time.time()
    tid = test.get("id") or "oauth"
    name = test.get("name") or tid
    suite = test.get("_suite") or ""
    try:
        cfg = resolve_vars(test.get("request") or test.get("oauth") or {}, vars_map)
        url = cfg.get("token_url") or vars_map.get("token", "")
        data = urllib.parse.urlencode(
            {
                "grant_type": cfg.get("grant_type", "client_credentials"),
                "client_id": cfg.get("client_id", ""),
                "client_secret": cfg.get("client_secret", ""),
            }
        ).encode()
        status, _hdrs, raw = http_request(
            "POST",
            url,
            {"Content-Type": "application/x-www-form-urlencoded"},
            data,
            timeout=20,
        )
        text = body_text(raw)
        if status != 200:
            return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), f"HTTP {status}", text[:300])
        token = json.loads(text).get("access_token")
        if not token:
            return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), "no access_token")
        vars_map[test.get("store_as") or "token"] = token
        return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), "token acquired")
    except Exception as e:
        return TestResult(tid, name, suite, "error", int((time.time() - t0) * 1000), str(e))


def run_wait_test(test: dict[str, Any], vars_map: dict[str, str]) -> TestResult:
    t0 = time.time()
    tid = test.get("id") or "wait"
    name = test.get("name") or tid
    suite = test.get("_suite") or ""
    try:
        cfg = resolve_vars(test.get("wait") or test.get("request") or {}, vars_map)
        url = cfg.get("url")
        timeout = float(cfg.get("timeout_sec", 30))
        interval = float(cfg.get("interval_sec", 1))
        contains = cfg.get("contains") or []
        status_ok = set(int(x) for x in (cfg.get("status_in") or [200]))
        headers = {}
        if cfg.get("auth_bearer_var"):
            token = vars_map.get(cfg["auth_bearer_var"], "")
            if not token:
                return TestResult(tid, name, suite, "fail", 0, "missing bearer token var")
            headers["Authorization"] = f"Bearer {token}"
        deadline = time.time() + timeout
        last = ""
        while time.time() < deadline:
            st, _h, raw = http_request("GET", url, headers=headers, timeout=10)
            text = body_text(raw)
            last = f"HTTP {st}: {text[:180]}"
            if st in status_ok and all(c in text for c in contains):
                return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), last)
            time.sleep(interval)
        return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), "wait timed out", last)
    except Exception as e:
        return TestResult(tid, name, suite, "error", int((time.time() - t0) * 1000), str(e))


def run_file_test(test: dict[str, Any], root: Path, vars_map: dict[str, str]) -> TestResult:
    t0 = time.time()
    tid = test.get("id") or "file"
    name = test.get("name") or tid
    suite = test.get("_suite") or ""
    try:
        cfg = resolve_vars(test.get("file") or test.get("request") or {}, vars_map)
        path = root / cfg.get("path", "")
        timeout = float(cfg.get("timeout_sec", 0))
        deadline = time.time() + timeout
        while True:
            exists = path.exists()
            if cfg.get("exists", True) and exists:
                if cfg.get("contains"):
                    text = path.read_text(encoding="utf-8", errors="replace")
                    err = expect_match(text, {"contains": cfg["contains"]})
                    if err:
                        if time.time() >= deadline:
                            return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), err)
                    else:
                        return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), str(path))
                else:
                    return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), str(path))
            if not cfg.get("exists", True) and not exists:
                return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), "absent as expected")
            if time.time() >= deadline:
                break
            time.sleep(0.5)
        return TestResult(
            tid,
            name,
            suite,
            "fail",
            int((time.time() - t0) * 1000),
            f"file condition not met: {path}",
        )
    except Exception as e:
        return TestResult(tid, name, suite, "error", int((time.time() - t0) * 1000), str(e))


def run_ui_test(test: dict[str, Any], vars_map: dict[str, str]) -> TestResult:
    """Basic Web UI check: HTTP fetch and/or Chrome dump-dom contains."""
    t0 = time.time()
    tid = test.get("id") or "ui"
    name = test.get("name") or tid
    suite = test.get("_suite") or ""
    try:
        cfg = resolve_vars(test.get("ui") or test.get("request") or {}, vars_map)
        url = cfg.get("url") or vars_map.get("webui", "")
        expect = resolve_vars(test.get("expect") or {}, vars_map)
        status, _h, raw = http_request("GET", url, timeout=20)
        text = body_text(raw)
        want = expect.get("status", 200)
        if int(status) != int(want):
            return TestResult(
                tid, name, suite, "fail", int((time.time() - t0) * 1000), f"expected HTTP {want}, got {status}", text[:300]
            )
        err = expect_match(text, expect)
        if err and cfg.get("use_chrome"):
            # Retry with headless Chrome dump-dom for JS-rendered pages
            if Path(CHROME).exists():
                proc = subprocess.run(
                    [CHROME, "--headless=new", "--disable-gpu", "--dump-dom", "--virtual-time-budget=8000", url],
                    capture_output=True,
                    text=True,
                    timeout=40,
                )
                text = proc.stdout or ""
                err = expect_match(text, expect)
        if err:
            return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), err, text[:400])
        return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), f"UI OK ({url})")
    except Exception as e:
        return TestResult(tid, name, suite, "error", int((time.time() - t0) * 1000), str(e))


def run_shell_test(test: dict[str, Any], root: Path, vars_map: dict[str, str]) -> TestResult:
    t0 = time.time()
    tid = test.get("id") or "shell"
    name = test.get("name") or tid
    suite = test.get("_suite") or ""
    try:
        cfg = resolve_vars(test.get("shell") or {}, vars_map)
        cmd = cfg.get("command")
        if not cmd:
            return TestResult(tid, name, suite, "skip", 0, "no command")
        proc = subprocess.run(
            cmd,
            shell=True,
            cwd=str(root),
            capture_output=True,
            text=True,
            timeout=float(cfg.get("timeout_sec", 120)),
            env={**os.environ, **{k.upper(): v for k, v in vars_map.items()}},
        )
        out = (proc.stdout or "") + (proc.stderr or "")
        expect = resolve_vars(test.get("expect") or {}, vars_map)
        if "exit_code" in expect and proc.returncode != int(expect["exit_code"]):
            return TestResult(
                tid,
                name,
                suite,
                "fail",
                int((time.time() - t0) * 1000),
                f"exit {proc.returncode}, expected {expect['exit_code']}",
                out[:400],
            )
        if "exit_code" not in expect and proc.returncode != 0:
            return TestResult(
                tid, name, suite, "fail", int((time.time() - t0) * 1000), f"exit {proc.returncode}", out[:400]
            )
        err = expect_match(out, expect)
        if err:
            return TestResult(tid, name, suite, "fail", int((time.time() - t0) * 1000), err, out[:400])
        return TestResult(tid, name, suite, "pass", int((time.time() - t0) * 1000), "ok")
    except Exception as e:
        return TestResult(tid, name, suite, "error", int((time.time() - t0) * 1000), str(e))


def run_one(test: dict[str, Any], root: Path, vars_map: dict[str, str]) -> TestResult:
    typ = (test.get("type") or "http").lower()
    if test.get("skip"):
        return TestResult(test.get("id", "x"), test.get("name", "skipped"), test.get("_suite", ""), "skip", 0, str(test.get("skip")))
    if typ == "http":
        return run_http_test(test, root, vars_map)
    if typ in ("oauth", "oauth_client_credentials"):
        return run_oauth_test(test, vars_map)
    if typ == "wait":
        return run_wait_test(test, vars_map)
    if typ == "file":
        return run_file_test(test, root, vars_map)
    if typ == "ui":
        return run_ui_test(test, vars_map)
    if typ == "shell":
        return run_shell_test(test, root, vars_map)
    return TestResult(test.get("id", "x"), test.get("name", typ), test.get("_suite", ""), "skip", 0, f"unknown type {typ}")


def flatten_tests(plan: dict[str, Any]) -> list[dict[str, Any]]:
    out = []
    for suite in plan.get("suites") or []:
        sid = suite.get("id") or suite.get("name") or "suite"
        sname = suite.get("name") or sid
        for t in suite.get("tests") or []:
            item = dict(t)
            item["_suite"] = sname
            item["_suite_id"] = sid
            out.append(item)
    return out


def run_plan(root: Path, plan: dict[str, Any], plan_path: Path | None = None) -> RunReport:
    started = datetime.now(timezone.utc).isoformat()
    vars_map = {k: str(v) for k, v in (plan.get("base_urls") or {}).items()}
    # allow auth defaults into vars for templates
    auth = plan.get("auth") or {}
    cc = auth.get("client_credentials") or {}
    for k, v in cc.items():
        vars_map[f"auth_{k}"] = str(v)
    results: list[TestResult] = []
    for test in flatten_tests(plan):
        results.append(run_one(test, root, vars_map))
    finished = datetime.now(timezone.utc).isoformat()
    summary = {"pass": 0, "fail": 0, "skip": 0, "error": 0, "total": len(results)}
    for r in results:
        summary[r.status] = summary.get(r.status, 0) + 1
    return RunReport(
        interface=plan.get("interface") or root.name,
        root=str(root),
        started_at=started,
        finished_at=finished,
        summary=summary,
        results=[asdict(r) for r in results],
        plan_path=str(plan_path or ""),
    )


def write_report(root: Path, report: RunReport) -> tuple[Path, Path]:
    docs = root / "documents"
    out = root / "output" / "test-results"
    docs.mkdir(parents=True, exist_ok=True)
    out.mkdir(parents=True, exist_ok=True)
    payload = asdict(report)
    docs_json = docs / "test-results.json"
    latest = out / "latest.json"
    docs_json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    latest.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    # simple HTML list for easy viewing without Web UI
    rows = []
    for r in report.results:
        cls = r["status"]
        rows.append(
            f"<tr class='{cls}'><td>{cls.upper()}</td><td>{_html(r['suite'])}</td>"
            f"<td>{_html(r['name'])}</td><td>{_html(r['message'])}</td>"
            f"<td>{r['duration_ms']}ms</td></tr>"
        )
    html = f"""<!doctype html>
<html><head><meta charset="utf-8"/><title>Test results — {_html(report.interface)}</title>
<style>
body{{font-family:system-ui,sans-serif;margin:1.5rem;background:#0b1c33;color:#e8eef8}}
h1{{font-size:1.25rem}} .sum span{{margin-right:1rem;font-weight:700}}
table{{border-collapse:collapse;width:100%;margin-top:1rem}}
th,td{{border-bottom:1px solid #2a4466;padding:.45rem .5rem;text-align:left;vertical-align:top}}
tr.pass td:first-child{{color:#3dd68c}} tr.fail td:first-child,tr.error td:first-child{{color:#ff6b6b}}
tr.skip td:first-child{{color:#f0a202}}
</style></head><body>
<h1>Test results — {_html(report.interface)}</h1>
<p class="sum">
<span>pass {report.summary.get('pass',0)}</span>
<span>fail {report.summary.get('fail',0)}</span>
<span>error {report.summary.get('error',0)}</span>
<span>skip {report.summary.get('skip',0)}</span>
<span>total {report.summary.get('total',0)}</span>
</p>
<p>Finished { _html(report.finished_at) }</p>
<table><thead><tr><th>Status</th><th>Suite</th><th>Test</th><th>Message</th><th>Time</th></tr></thead>
<tbody>
{''.join(rows)}
</tbody></table>
</body></html>"""
    html_path = docs / "test-results.html"
    html_path.write_text(html, encoding="utf-8")
    (out / "latest.html").write_text(html, encoding="utf-8")
    return docs_json, html_path


def _html(s: str) -> str:
    return (
        str(s)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def find_plan(root: Path) -> Path:
    for cand in (root / "tests" / "plan.json", root / "test-plan.json"):
        if cand.is_file():
            return cand
    raise FileNotFoundError(f"No tests/plan.json under {root}")
