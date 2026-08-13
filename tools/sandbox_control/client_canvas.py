"""Serve a client's V2 routes on the same canvas the demo Web UI uses."""

from __future__ import annotations

import re
from pathlib import Path

from flask import Response, jsonify, render_template, send_file

import client_impl_docs as docs
import client_impl_story as story
import clients
import demos

VIEWER = demos.CLIENTS / "Demos" / "_shared" / "webui" / "static" / "route-viewer"
_MODULE_ID = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


def has_v2(root: Path) -> bool:
    eip = root / "eip-root" / "interfaces"
    return eip.is_dir() and any(eip.glob("*/routes/*/route.v2.xml"))


def list_routes(root: Path) -> list[dict]:
    rows = []
    for folder, _formats in docs.iter_routes(root):
        v2 = folder / "route.v2.xml"
        if not v2.is_file():
            continue
        info = story.explain(folder)
        info["dir"] = folder.name
        rows.append(info)
    return rows


def _folder(root: Path, rid: str) -> Path | None:
    rid = (rid or "").strip().lower()
    for folder, _formats in docs.iter_routes(root):
        if docs._slug(folder.name) == rid:
            return folder
    return None


def register(app) -> None:
    @app.get("/clients/<slug>/canvas")
    def client_canvas_page(slug: str):
        try:
            root = clients.require_root(slug)
        except ValueError as exc:
            return jsonify({"ok": False, "error": str(exc)}), 404
        routes = list_routes(root)
        return render_template(
            "client_canvas.html",
            title=clients.client_title(root),
            slug=slug,
            routes=routes,
            port=app.config.get("HUB_PORT") or 8077,
            lan=demos.lan_ip(),
        )

    @app.get("/api/clients/<slug>/v2/routes")
    def client_v2_list(slug: str):
        try:
            root = clients.require_root(slug)
        except ValueError as exc:
            return jsonify({"ok": False, "error": str(exc)}), 404
        return jsonify({"routes": list_routes(root)})

    @app.get("/api/clients/<slug>/v2/routes/<rid>/route.v2.xml")
    def client_v2_xml(slug: str, rid: str):
        try:
            root = clients.require_root(slug)
        except ValueError as exc:
            return jsonify({"ok": False, "error": str(exc)}), 404
        folder = _folder(root, rid)
        path = folder / "route.v2.xml" if folder else None
        if not path or not path.is_file():
            return Response("not found", status=404)
        return send_file(path, mimetype="application/xml")

    @app.get("/api/clients/<slug>/v2/routes/<rid>/diagram-groups.json")
    def client_v2_groups(slug: str, rid: str):
        try:
            root = clients.require_root(slug)
        except ValueError as exc:
            return jsonify({"ok": False, "error": str(exc)}), 404
        folder = _folder(root, rid)
        path = folder / "diagram-groups.json" if folder else None
        if path and path.is_file():
            return send_file(path, mimetype="application/json")
        return jsonify({"groups": []})

    @app.get("/api/clients/<slug>/v2/routes/<rid>/modules/<mid>.xml")
    def client_v2_mod(slug: str, rid: str, mid: str):
        try:
            root = clients.require_root(slug)
        except ValueError as exc:
            return jsonify({"ok": False, "error": str(exc)}), 404
        if not _MODULE_ID.match(mid):
            return Response("bad id", status=400)
        folder = _folder(root, rid)
        path = folder / "modules" / f"{mid}.xml" if folder else None
        if not path or not path.is_file():
            return Response("not found", status=404)
        return send_file(path, mimetype="application/xml")

    @app.get("/route-viewer/<path:name>")
    def client_route_viewer(name: str):
        path = (VIEWER / name).resolve()
        try:
            path.relative_to(VIEWER.resolve())
        except ValueError:
            return Response("not found", status=404)
        if not path.is_file():
            return Response("not found", status=404)
        return send_file(path)
