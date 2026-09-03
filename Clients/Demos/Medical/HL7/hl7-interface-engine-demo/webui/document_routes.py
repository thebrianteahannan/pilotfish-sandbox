"""Stable /documents/* aliases. Idempotent if a demo already registered them."""

from __future__ import annotations

from html import escape
from pathlib import Path

from flask import Flask, Response, send_file


def _send_plaintext_html(path: Path) -> Response:
    title = escape(path.name)
    body = escape(path.read_text(encoding="utf-8", errors="replace"))
    return Response(
        "<!DOCTYPE html><html lang=en><head><meta charset=utf-8>"
        f"<title>{title}</title>"
        "<style>html,body{margin:0;background:#111418;color:#e8eaed}"
        "pre{margin:0;padding:1.25rem 1.5rem;font:14px/1.55 ui-monospace,Menlo,monospace;"
        "white-space:pre-wrap;word-break:break-word}</style></head>"
        f"<body><pre>{body}</pre></body></html>",
        mimetype="text/html; charset=utf-8",
    )


def _bases(documents_dir: Path) -> list[Path]:
    bases = [documents_dir]
    local = Path(__file__).resolve().parent.parent / "documents"
    if local not in bases:
        bases.append(local)
    return bases


def _find(documents_dir: Path, preferred: str | None, patterns: tuple[str, ...]) -> Path | None:
    for base in _bases(documents_dir):
        if preferred:
            path = base / preferred
            if path.is_file():
                return path
        for pattern in patterns:
            matches = sorted(base.glob(pattern))
            if matches:
                return matches[0]
    return None


def ensure_document_routes(
    app: Flask,
    documents_dir: Path,
    *,
    route_pdf_name: str | None = None,
    capability_pdf_name: str | None = None,
    test_plan_pdf_name: str | None = None,
    test_results_pdf_name: str | None = None,
) -> None:
    existing = {rule.rule for rule in app.url_map.iter_rules()}

    def _send(path: Path, download_name: str | None = None):
        return send_file(
            path,
            mimetype="application/pdf",
            as_attachment=False,
            download_name=download_name or path.name,
        )

    if "/documents/route-diagrams.pdf" not in existing:

        @app.get("/documents/route-diagrams.pdf")
        def _info_route_diagrams_pdf():
            path = _find(
                documents_dir,
                route_pdf_name,
                ("*_V2_Route_Diagrams.pdf", "*Route_Diagrams.pdf"),
            )
            if not path:
                return Response(
                    "Route design PDF not found. Run: python3 tools/export_route_diagrams.py",
                    status=404,
                )
            return _send(path)

    if "/documents/capability-brief.pdf" not in existing:

        @app.get("/documents/capability-brief.pdf")
        def _info_capability_pdf():
            path = _find(
                documents_dir,
                capability_pdf_name,
                ("*_Capability_Brief.pdf", "*Capability_Brief.pdf"),
            )
            if not path:
                return Response(
                    "Capability brief not found. Run: python3 tools/export_stakeholder_brief.py",
                    status=404,
                )
            return _send(path)

    if "/documents/test-plan.pdf" not in existing:

        @app.get("/documents/test-plan.pdf")
        def _info_test_plan_pdf():
            path = _find(
                documents_dir,
                test_plan_pdf_name,
                ("*_Test_Plan.pdf", "*Test_Plan.pdf"),
            )
            if not path:
                return Response(
                    "Test plan PDF not found. Run: python3 tools/export_test_plan_pdf.py",
                    status=404,
                )
            return _send(path)

    if "/documents/test-results.pdf" not in existing:

        @app.get("/documents/test-results.pdf")
        def _info_test_results_pdf():
            path = _find(
                documents_dir,
                test_results_pdf_name,
                ("*_Test_Results.pdf", "test-results.pdf"),
            )
            if not path:
                return Response(
                    "Test results PDF not found. Run: python3 tools/run_interface_tests.py --wait",
                    status=404,
                )
            return _send(path)

    if "/documents/<path:name>" not in existing:

        @app.get("/documents/<path:name>")
        def _info_documents_file(name: str):
            rel = Path(name)
            parts = rel.parts
            if not parts or ".." in parts or rel.is_absolute():
                return Response("Invalid document name", status=400)
            if len(parts) == 1:
                pass
            elif len(parts) == 2 and parts[0] == "module-docs":
                pass
            else:
                return Response("Invalid document name", status=400)
            for base in _bases(documents_dir):
                path = (base / rel).resolve()
                try:
                    path.relative_to(base.resolve())
                except ValueError:
                    continue
                if path.is_file():
                    if path.suffix.lower() == ".txt":
                        return _send_plaintext_html(path)
                    return send_file(path, as_attachment=False)
            return Response(f"Document not found: {name}", status=404)

    ensure_module_docs_api(app, documents_dir)
    ensure_construction_video_api(app, documents_dir)


def ensure_build_timing_api(app: Flask, documents_dir: Path) -> None:
    from flask import jsonify

    existing = {rule.rule for rule in app.url_map.iter_rules()}
    if "/api/build-timing" in existing:
        return

    @app.get("/api/build-timing")
    def _api_build_timing():
        import json

        for base in _bases(documents_dir):
            path = base / "build-timing.json"
            if path.is_file():
                try:
                    data = json.loads(path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as exc:
                    return jsonify({"ok": False, "error": str(exc)}), 500
                return jsonify({"ok": True, "path": str(path), "timing": data})
        return jsonify({"ok": False, "error": "documents/build-timing.json not found"}), 404


def ensure_build_status_api(app: Flask, documents_dir: Path) -> None:
    import json

    from flask import jsonify

    existing = {rule.rule for rule in app.url_map.iter_rules()}
    if "/api/build-status" in existing:
        return

    @app.get("/api/build-status")
    def _api_build_status():
        for base in _bases(documents_dir):
            path = base / "build-status.json"
            if path.is_file():
                try:
                    data = json.loads(path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as exc:
                    return jsonify({"ok": False, "error": str(exc)}), 500
                if not isinstance(data, dict):
                    return jsonify({"ok": False, "error": "build-status.json must be an object"}), 500
                data.setdefault("ok", True)
                data["path"] = str(path)
                return jsonify(data)
        return jsonify(
            {
                "ok": True,
                "active": False,
                "phase": "idle",
                "message": "No documents/build-status.json — treating build as idle.",
                "routes_ready": [],
            }
        )


def ensure_module_docs_api(app: Flask, documents_dir: Path) -> None:
    import json

    from flask import jsonify

    existing = {rule.rule for rule in app.url_map.iter_rules()}

    def _load_manifest() -> dict | None:
        for base in _bases(documents_dir):
            path = base / "module-docs" / "manifest.json"
            if path.is_file():
                try:
                    return json.loads(path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError):
                    return None
        return None

    if "/api/module-docs" not in existing:

        @app.get("/api/module-docs")
        def _api_module_docs():
            data = _load_manifest()
            if not data:
                return jsonify(
                    {
                        "ok": False,
                        "error": "documents/module-docs/manifest.json not found. "
                        "Run: python3 tools/sync_module_docs.py",
                    }
                ), 404
            return jsonify({"ok": True, "manifest": data})

    if getattr(app, "_pf_module_docs_ctx", False):
        return
    app._pf_module_docs_ctx = True  # type: ignore[attr-defined]

    @app.context_processor
    def _module_docs_info_context():
        data = _load_manifest() or {}
        modules = [
            m
            for m in (data.get("modules") or [])
            if m.get("pdf") and m.get("status") == "ok"
        ]
        seen: set[str] = set()
        items: list[str] = []
        for m in modules:
            pdf = m["pdf"]
            if pdf in seen:
                continue
            seen.add(pdf)
            label = f"{m.get('kind') or ''}: {m.get('ui_type') or Path(pdf).name}"
            items.append(
                f'<a href="/documents/{pdf}" target="_blank" rel="noopener">{label}</a>'
            )
        sections = []
        if items:
            sections.append(
                {
                    "title": "Module documentation (deep-dives)",
                    "items": items,
                    "note": "Copied from the PilotFish Documentation library for every module in this interface. "
                    "Re-sync with <code>python3 tools/sync_module_docs.py</code> after route changes.",
                }
            )
        return {"module_docs_sections": sections}


def ensure_build_replay_api(app: Flask, documents_dir: Path) -> None:
    import json
    import re

    from flask import jsonify, send_file

    existing = {rule.rule for rule in app.url_map.iter_rules()}
    _STEP = re.compile(r"^\d{4}$")
    _MODULE_ID = re.compile(
        r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    )

    def _replay_root() -> Path | None:
        for base in _bases(documents_dir):
            path = base / "build-replay"
            if path.is_dir():
                return path
        return None

    if "/api/build-replay" not in existing:

        @app.get("/api/build-replay")
        def _api_build_replay():
            root = _replay_root()
            if not root:
                return jsonify({"ok": True, "steps": [], "count": 0, "available": False})
            path = root / "manifest.json"
            if not path.is_file():
                return jsonify({"ok": True, "steps": [], "count": 0, "available": False})
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                return jsonify({"ok": False, "error": str(exc)}), 500
            steps = data.get("steps") if isinstance(data, dict) else []
            if not isinstance(steps, list):
                steps = []
            return jsonify(
                {
                    "ok": True,
                    "available": len(steps) > 0,
                    "count": len(steps),
                    "title": (data or {}).get("title") if isinstance(data, dict) else None,
                    "updated_at": (data or {}).get("updated_at") if isinstance(data, dict) else None,
                    "steps": steps,
                    "default_pause_ms": 8000,
                }
            )

    if "/api/build-replay/steps/<step_id>/route.v2.xml" not in existing:

        @app.get("/api/build-replay/steps/<step_id>/route.v2.xml")
        def _api_build_replay_xml(step_id: str):
            if not _STEP.match(step_id):
                return Response("bad step", status=400)
            root = _replay_root()
            if not root:
                return Response("not found", status=404)
            path = root / "steps" / step_id / "route.v2.xml"
            if not path.is_file():
                return Response("not found", status=404)
            return send_file(path, mimetype="application/xml")

    if "/api/build-replay/steps/<step_id>/diagram-groups.json" not in existing:

        @app.get("/api/build-replay/steps/<step_id>/diagram-groups.json")
        def _api_build_replay_groups(step_id: str):
            if not _STEP.match(step_id):
                return Response("bad step", status=400)
            root = _replay_root()
            if not root:
                return jsonify({"groups": []})
            path = root / "steps" / step_id / "diagram-groups.json"
            if path.is_file():
                return send_file(path, mimetype="application/json")
            return jsonify({"groups": []})

    if "/api/build-replay/steps/<step_id>/modules/<module_id>.xml" not in existing:

        @app.get("/api/build-replay/steps/<step_id>/modules/<module_id>.xml")
        def _api_build_replay_module(step_id: str, module_id: str):
            if not _STEP.match(step_id) or not _MODULE_ID.match(module_id):
                return Response("bad id", status=400)
            root = _replay_root()
            if not root:
                return Response("not found", status=404)
            path = root / "steps" / step_id / "modules" / f"{module_id}.xml"
            if not path.is_file():
                return Response("not found", status=404)
            return send_file(path, mimetype="application/xml")

    ensure_construction_video_api(app, documents_dir)


def ensure_construction_video_api(app: Flask, documents_dir: Path) -> None:
    import json
    import os
    from urllib.error import HTTPError, URLError
    from urllib.request import Request, urlopen

    from flask import jsonify, request

    existing = {rule.rule for rule in app.url_map.iter_rules()}
    if "/api/construction-video" in existing:
        return
    slug = (
        os.environ.get("DEMO_SLUG")
        or Path(__file__).resolve().parent.parent.name
        or ""
    ).strip()
    port = int(os.environ.get("CONSTRUCTION_VIDEO_WORKER_PORT", "8764"))

    def _state() -> dict:
        out = {"ok": True, "slug": slug, "ready": False, "mp4": False, "job": None, "sections": []}
        for base in _bases(documents_dir):
            mp4 = base / "construction-replay.mp4"
            if mp4.is_file():
                out["mp4"] = True
                out["ready"] = True
                out["size_kb"] = mp4.stat().st_size // 1024
            job = base / "construction-video-job.json"
            if job.is_file():
                try:
                    loaded = json.loads(job.read_text(encoding="utf-8"))
                    if isinstance(loaded, dict):
                        out["job"] = loaded
                except (OSError, json.JSONDecodeError):
                    pass
            sections = base / "video-sections.json"
            if sections.is_file():
                try:
                    loaded = json.loads(sections.read_text(encoding="utf-8"))
                    if isinstance(loaded, list):
                        out["sections"] = loaded
                except (OSError, json.JSONDecodeError):
                    pass
        return out

    @app.get("/api/construction-video")
    def _api_construction_video_get():
        return jsonify(_state())

    @app.post("/api/construction-video")
    def _api_construction_video_post():
        incoming = request.get_json(silent=True) or {}
        payload = {"slug": slug}
        if isinstance(incoming, dict) and incoming.get("section"):
            payload["section"] = str(incoming.get("section") or "").strip()
        body = json.dumps(payload).encode("utf-8")
        last = "exporter not running"
        for host in ("host.docker.internal", "127.0.0.1"):
            try:
                req = Request(
                    f"http://{host}:{port}/run",
                    data=body,
                    headers={"Content-Type": "application/json"},
                    method="POST",
                )
                with urlopen(req, timeout=4) as resp:
                    raw = resp.read().decode("utf-8", errors="replace")
                    code = getattr(resp, "status", 200)
                data = json.loads(raw or "{}")
                if not isinstance(data, dict):
                    data = {"ok": True}
                data.setdefault("ok", True)
                return jsonify(data), int(code or 200)
            except HTTPError as exc:
                raw = exc.read().decode("utf-8", errors="replace") if exc.fp else "{}"
                try:
                    data = json.loads(raw or "{}")
                except json.JSONDecodeError:
                    data = {"ok": False, "error": str(exc)}
                if isinstance(data, dict):
                    return jsonify(data), int(exc.code)
                return jsonify({"ok": False, "error": str(exc)}), int(exc.code)
            except (URLError, OSError, TimeoutError) as exc:
                last = str(exc)
        return jsonify(
            {
                "ok": False,
                "error": last,
                "message": "Video exporter is not running on the host.",
                "command": "python3 tools/construction_video_worker.py",
            }
        ), 503


def ensure_build_experience_api(app: Flask, documents_dir: Path) -> None:
    import json

    from flask import jsonify

    existing = {rule.rule for rule in app.url_map.iter_rules()}
    if "/api/build-experience" in existing:
        return

    @app.get("/api/build-experience")
    def _api_build_experience():
        for base in _bases(documents_dir):
            path = base / "build-experience.json"
            if path.is_file():
                try:
                    data = json.loads(path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as exc:
                    return jsonify({"ok": False, "error": str(exc)}), 500
                if not isinstance(data, dict):
                    return jsonify({"ok": False, "error": "build-experience.json must be an object"}), 500
                events = data.get("events") if isinstance(data.get("events"), list) else []
                return jsonify(
                    {
                        "ok": True,
                        "available": len(events) > 0,
                        "count": len(events),
                        "title": data.get("title") or "Interface construction experience",
                        "demo": data.get("demo"),
                        "updated_at": data.get("updated_at"),
                        "events": events,
                        "default_pause_ms": int(data.get("default_pause_ms") or 4000),
                    }
                )
        return jsonify(
            {
                "ok": True,
                "available": False,
                "count": 0,
                "events": [],
                "title": "Interface construction experience",
                "message": "No documents/build-experience.json yet. Log events with tools/log_build_experience.py",
            }
        )
