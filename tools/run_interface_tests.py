#!/usr/bin/env python3
"""Run an interface test plan (tests/plan.json), write pass/fail results.

Usage:
  python3 tools/run_interface_tests.py --root Clients/Demos/fhir-r4-platform
  python3 tools/run_interface_tests.py --root . --wait
  python3 tools/run_interface_tests.py --root . --watch
  cd Clients/Demos/fhir-r4-platform && python3 tools/run_interface_tests.py
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.request
from pathlib import Path

# Allow running as sandbox tool or via demo wrapper
_SANDBOX_TOOLS = Path(__file__).resolve().parent
if str(_SANDBOX_TOOLS) not in sys.path:
    sys.path.insert(0, str(_SANDBOX_TOOLS))

from export_test_results_pdf import write_from_report  # noqa: E402
from interface_testlib import find_plan, load_plan, run_plan, write_report  # noqa: E402


def wait_health(urls: list[str], timeout: float = 90.0) -> None:
    deadline = time.time() + timeout
    pending = list(urls)
    while pending and time.time() < deadline:
        still = []
        for url in pending:
            try:
                with urllib.request.urlopen(url, timeout=3) as r:
                    if r.status < 500:
                        print(f"  ready {url}")
                        continue
            except Exception:
                pass
            still.append(url)
        pending = still
        if pending:
            time.sleep(2)
    if pending:
        print("WARNING: still not ready:", ", ".join(pending))


def run_once(root: Path, wait: bool) -> int:
    # Keep module deep-dive PDFs aligned with current routes (playbook §6.1c).
    try:
        from sync_module_docs import sync_demo  # noqa: WPS433

        sync_demo(root)
        print("Synced documents/module-docs/ from route modules")
    except Exception as exc:
        print(f"WARNING: sync_module_docs skipped ({exc})")

    plan_path = find_plan(root)
    plan = load_plan(plan_path)
    if wait:
        urls = []
        bases = plan.get("base_urls") or {}
        for key, raw in bases.items():
            u = str(raw).rstrip("/")
            if key == "fhir":
                urls.append(u + "/metadata")
            elif key == "token":
                # token endpoint is POST-only; realm root is a better GET probe
                if "/protocol/openid-connect/token" in u:
                    urls.append(u.split("/protocol/openid-connect/token")[0])
                else:
                    urls.append(u)
            else:
                urls.append(u + "/")
        # prefer explicit health list
        for u in plan.get("healthcheck_urls") or []:
            urls.append(u)
        # dedupe
        seen = set()
        uniq = []
        for u in urls:
            if u not in seen:
                seen.add(u)
                uniq.append(u)
        if uniq:
            print("Waiting for health…")
            wait_health(uniq, timeout=float(plan.get("wait_timeout_sec", 120)))
    print(f"Running {plan_path} …")
    report = run_plan(root, plan, plan_path)
    docs_json, html = write_report(root, report)
    try:
        pdf = write_from_report(root, report)
    except Exception as exc:  # keep JSON/HTML even if reportlab is missing
        pdf = None
        print(f"WARNING: could not write test-results.pdf ({exc})")
    s = report.summary
    print(
        f"Results: pass={s.get('pass',0)} fail={s.get('fail',0)} "
        f"error={s.get('error',0)} skip={s.get('skip',0)} total={s.get('total',0)}"
    )
    print("JSON:", docs_json)
    print("HTML:", html)
    if pdf is not None:
        print("PDF:", pdf)
    for r in report.results:
        mark = {"pass": "PASS", "fail": "FAIL", "error": "ERR ", "skip": "SKIP"}.get(r["status"], r["status"])
        print(f"  [{mark}] {r['suite']} · {r['name']} — {r['message']}")
    failed = s.get("fail", 0) + s.get("error", 0)
    return 1 if failed else 0


def watch(root: Path, wait: bool) -> int:
    plan_path = find_plan(root)
    watch_globs = [
        root / "tests" / "plan.json",
        root / "DESIGN.md",
        root / "README.md",
        root / "eip-root",
        root / "pilotfish" / "demo-eip-root",
        root / "sql",
        root / "samples",
        root / "webui" / "app.py",
    ]

    def snapshot() -> dict[str, float]:
        snaps = {}
        for p in watch_globs:
            if p.is_file():
                snaps[str(p)] = p.stat().st_mtime
            elif p.is_dir():
                for f in p.rglob("*"):
                    if f.is_file() and f.suffix.lower() in {
                        ".xml",
                        ".json",
                        ".md",
                        ".sql",
                        ".py",
                        ".sh",
                        ".yml",
                        ".yaml",
                        ".conf",
                        ".hl7",
                        ".edi",
                        ".csv",
                        ".xsl",
                        ".xslt",
                    }:
                        snaps[str(f)] = f.stat().st_mtime
        return snaps

    print(f"Watching {root} (plan {plan_path}). Ctrl+C to stop.")
    prev = snapshot()
    code = run_once(root, wait=wait)
    try:
        while True:
            time.sleep(2)
            cur = snapshot()
            if cur != prev:
                print("\nChange detected — re-running tests…")
                prev = cur
                code = run_once(root, wait=False)
    except KeyboardInterrupt:
        print("\nStopped watch.")
    return code


def main() -> int:
    parser = argparse.ArgumentParser(description="Run interface tests from tests/plan.json")
    parser.add_argument("--root", type=Path, default=None, help="Interface root (default: cwd)")
    parser.add_argument("--wait", action="store_true", help="Wait for health URLs before running")
    parser.add_argument("--watch", action="store_true", help="Re-run when plan/routes/DESIGN/samples change")
    args = parser.parse_args()
    root = (args.root or Path.cwd()).resolve()
    if args.watch:
        return watch(root, wait=args.wait)
    return run_once(root, wait=args.wait)


if __name__ == "__main__":
    raise SystemExit(main())
