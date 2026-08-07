"""Documents PDF routes + XSLT / environment-settings V2 APIs for claim-scrub Web UI."""

from __future__ import annotations

import os
import re
from pathlib import Path

from flask import Flask, Response, jsonify, request, send_file

_SENSITIVE_ENV = re.compile(
    r"(password|secret|token|apikey|api[_-]?key|private[_-]?key|passphrase|credential)",
    re.I,
)
_XSLT_SUFFIXES = {".xsl", ".xslt"}


def discover_xslt_files(routes_dir: Path) -> list[dict]:
    if not routes_dir.is_dir():
        return []
    out: list[dict] = []
    root = routes_dir.resolve()
    for path in sorted(routes_dir.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in _XSLT_SUFFIXES:
            continue
        try:
            rel = path.resolve().relative_to(root).as_posix()
        except ValueError:
            continue
        out.append(
            {
                "path": rel,
                "name": path.name,
                "route": path.parent.name if path.parent != routes_dir else "",
                "bytes": path.stat().st_size,
            }
        )
    return out


def resolve_xslt_path(routes_dir: Path, rel: str) -> Path | None:
    if not rel or Path(rel).is_absolute() or ".." in Path(rel).parts:
        return None
    candidate = (routes_dir / rel).resolve()
    try:
        candidate.relative_to(routes_dir.resolve())
    except ValueError:
        return None
    if candidate.is_file() and candidate.suffix.lower() in _XSLT_SUFFIXES:
        return candidate
    return None


def register_docs_and_v2(
    app: Flask,
    *,
    routes_dir: Path,
    documents_dir: Path,
    route_pdf_name: str,
    capability_pdf_name: str,
    test_results_pdf_name: str,
    test_plan_pdf_name: str,
) -> None:
    def _route_pdf_path() -> Path | None:
        for base in (documents_dir, Path(__file__).resolve().parent.parent / "documents"):
            path = base / route_pdf_name
            if path.is_file():
                return path
        return None

    def _env_settings_candidates() -> list[Path]:
        demo = Path(__file__).resolve().parent.parent
        paths = [
            Path(os.environ.get("ENV_SETTINGS_FILE", "/environment-settings.conf")),
            demo / "pilotfish" / "demo-eip-root" / "environment-settings.conf",
            demo / "eip-root" / "environment-settings.conf",
            routes_dir.parent / "environment-settings.conf",
        ]
        seen: set[str] = set()
        out: list[Path] = []
        for p in paths:
            key = str(p)
            if key in seen:
                continue
            seen.add(key)
            out.append(p)
        return out

    def load_environment_settings() -> tuple[Path | None, dict[str, str]]:
        for path in _env_settings_candidates():
            if not path.is_file():
                continue
            settings: dict[str, str] = {}
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
                s = line.strip()
                if not s or s.startswith("#") or "=" not in s:
                    continue
                key, val = s.split("=", 1)
                settings[key.strip()] = val.strip().replace(r"\:", ":").replace(r"\=", "=")
            return path, settings
        return None, {}

    @app.get("/api/v2/xslt")
    def api_xslt_list():
        return jsonify({"ok": True, "files": discover_xslt_files(routes_dir)})

    @app.get("/api/v2/xslt/content")
    def api_xslt_content():
        rel = (request.args.get("path") or "").strip()
        path = resolve_xslt_path(routes_dir, rel)
        if not path:
            return Response("XSLT not found", status=404, mimetype="text/plain")
        return Response(
            path.read_text(encoding="utf-8", errors="replace"),
            mimetype="application/xml; charset=utf-8",
        )

    @app.get("/api/v2/environment-settings")
    def api_environment_settings():
        path, settings = load_environment_settings()
        safe: dict[str, str] = {}
        redacted: list[str] = []
        for key, val in settings.items():
            if _SENSITIVE_ENV.search(key):
                safe[key] = "••••••••"
                redacted.append(key)
            else:
                safe[key] = val
        return jsonify(
            {"ok": True, "path": str(path) if path else None, "settings": safe, "redacted": redacted}
        )

    @app.get("/documents/route-diagrams.pdf")
    def route_diagrams_pdf():
        path = _route_pdf_path()
        if not path:
            return (
                "Route design PDF not found. Run: python3 tools/export_route_diagrams.py --config changed",
                404,
            )
        return send_file(
            path, mimetype="application/pdf", as_attachment=False, download_name=route_pdf_name
        )

    @app.get("/documents/capability-brief.pdf")
    def capability_pdf_alias():
        path = documents_dir / capability_pdf_name
        if path.is_file():
            return send_file(path, mimetype="application/pdf", as_attachment=False)
        return Response(
            "Capability brief not generated yet. Run: python3 tools/export_stakeholder_brief.py",
            status=404,
        )

    @app.get("/documents/test-results.pdf")
    def test_results_pdf_alias():
        for name in (test_results_pdf_name, "test-results.pdf"):
            path = documents_dir / name
            if path.is_file():
                return send_file(
                    path, mimetype="application/pdf", as_attachment=False, download_name=name
                )
        return Response(
            "Test results PDF not found yet. Run: python3 tools/run_interface_tests.py --wait",
            status=404,
        )

    @app.get("/documents/test-plan.pdf")
    def test_plan_pdf_alias():
        path = documents_dir / test_plan_pdf_name
        if path.is_file():
            return send_file(path, mimetype="application/pdf", as_attachment=False)
        return Response(
            "Test plan PDF not found. Run: python3 tools/export_test_plan_pdf.py", status=404
        )

    @app.get("/documents/<path:name>")
    def documents_file(name: str):
        safe = Path(name)
        if safe.is_absolute() or ".." in safe.parts:
            return Response("Invalid path", status=400)
        path = (documents_dir / safe).resolve()
        try:
            path.relative_to(documents_dir.resolve())
        except ValueError:
            return Response("Invalid path", status=400)
        if not path.is_file():
            return Response("Not found", status=404)
        mime = "application/pdf" if path.suffix.lower() == ".pdf" else None
        return send_file(path, mimetype=mime, as_attachment=False, download_name=path.name)
