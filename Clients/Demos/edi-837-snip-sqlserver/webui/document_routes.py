"""Stable /documents/* PDF aliases for Sandbox demo Web UIs.

Idempotent: skips Flask rules that are already registered so demos with
hand-written aliases keep working.
"""

from __future__ import annotations

from pathlib import Path

from flask import Flask, Response, send_file


def _bases(documents_dir: Path) -> list[Path]:
    bases = [documents_dir]
    # Prefer container mount, then demo-local documents/ next to webui/
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
    """Register capability / route / test-plan / test-results aliases + catch-all."""
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
            # Allow top-level files and documents/module-docs/*.pdf (synced module deep-dives).
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
                    return send_file(path, as_attachment=False)
            return Response(f"Document not found: {name}", status=404)

    # Module deep-dive PDFs (documents/module-docs/) — API + Info tab links
    ensure_module_docs_api(app, documents_dir)


def ensure_build_timing_api(app: Flask, documents_dir: Path) -> None:
    """GET /api/build-timing → documents/build-timing.json for the Timing tab."""
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


def ensure_module_docs_api(app: Flask, documents_dir: Path) -> None:
    """GET /api/module-docs → documents/module-docs/manifest.json + Info-tab context."""
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

    # Avoid stacking duplicate context processors on repeated ensure_* calls
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
