#!/usr/bin/env python3
"""Sandbox control hub — host Flask UI to start/stop demos and inspect disk.

  python3 tools/sandbox_control/app.py
  # http://127.0.0.1:8077/
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from flask import Flask, jsonify, render_template, request, send_file

import client_ocr
import client_package
import client_pipeline
import client_request_video
import client_requests
import clients
import demos
import disk
import sandbox_docker
import videos

app = Flask(__name__, template_folder=str(HERE / "templates"), static_folder=str(HERE / "static"))
app.config["TEMPLATES_AUTO_RELOAD"] = True
app.config["MAX_CONTENT_LENGTH"] = 20 * 1024 * 1024
PORT = int(os.environ.get("SANDBOX_HUB_PORT", "8077"))


@app.after_request
def _no_store_static(resp):
    if request.path.startswith("/static/"):
        resp.headers["Cache-Control"] = "no-store"
    return resp


@app.get("/")
def index():
    return render_template("index.html", port=PORT, lan=demos.lan_ip())


@app.get("/api/health")
def health():
    return jsonify({"ok": True, "service": "sandbox-control", "port": PORT})


@app.get("/api/demos")
def api_demos():
    return jsonify(
        {
            "ok": True,
            "job": demos.job_snapshot(),
            "video_worker": videos.worker_status(),
            "video_queue": videos.queue_snapshot(),
            "demos": demos.list_demos(),
            "lan": demos.lan_ip(),
        }
    )


@app.post("/api/demos/<slug>/<action>")
def api_demo_action(slug: str, action: str):
    action = (action or "").strip().lower()
    if action not in {"start", "stop", "restart", "video"}:
        return jsonify({"ok": False, "error": "action must be start, stop, restart, or video"}), 400
    result = demos.enqueue(action, slug)
    code = 202 if result.get("ok") else 409
    return jsonify(result), code


@app.get("/api/demos/<slug>/video/file")
def api_video_file(slug: str):
    try:
        root = demos.require_root(slug)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    mp4 = root / "documents" / "construction-replay.mp4"
    if not mp4.is_file():
        return jsonify({"ok": False, "error": "No construction video yet"}), 404
    resp = send_file(mp4, mimetype="video/mp4", as_attachment=False, download_name="construction-replay.mp4")
    resp.headers["Cache-Control"] = "no-store"
    return resp


@app.get("/api/disk")
def api_disk():
    force = request.args.get("refresh") in {"1", "true", "yes"}
    return jsonify({"ok": True, **disk.scan(force=force)})


@app.post("/api/disk/delete")
def api_disk_delete():
    body = request.get_json(silent=True) or {}
    raw = str(body.get("path") or "").strip()
    if not raw:
        return jsonify({"ok": False, "error": "path required"}), 400
    target = (demos.ROOT / raw).resolve() if not Path(raw).is_absolute() else Path(raw)
    result = disk.delete_path(target)
    return jsonify(result), (200 if result.get("ok") else 400)


@app.post("/api/disk/delete-videos")
def api_disk_delete_videos():
    return jsonify(disk.delete_all_construction_videos())


@app.get("/api/docker")
def api_docker():
    return jsonify(sandbox_docker.snapshot())


@app.get("/api/clients")
def api_clients():
    return jsonify(
        {
            "ok": True,
            "job": clients.job_snapshot(),
            "pipeline": client_pipeline.job_snapshot(),
            "clients": clients.list_clients(),
            "lan": demos.lan_ip(),
        }
    )


@app.post("/api/clients/<slug>/<action>")
def api_client_action(slug: str, action: str):
    action = (action or "").strip().lower()
    if action not in {"start", "stop", "restart"}:
        return jsonify({"ok": False, "error": "action must be start, stop, or restart"}), 400
    result = clients.enqueue(action, slug)
    return jsonify(result), (202 if result.get("ok") else 409)


@app.get("/api/clients/<slug>/requests")
def api_client_requests(slug: str):
    try:
        clients.require_root(slug)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    return jsonify(
        {
            "ok": True,
            "requests": client_requests.list_requests(slug),
            "pipeline": client_pipeline.job_snapshot(),
            "deploy": client_package.snapshot(slug),
        }
    )


@app.post("/api/clients/<slug>/requests/screenshot")
def api_client_screenshot(slug: str):
    try:
        clients.require_root(slug)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    upload = request.files.get("file")
    if upload is None or not upload.filename:
        return jsonify({"ok": False, "error": "Drop a screenshot image."}), 400
    data = upload.read()
    if not data:
        return jsonify({"ok": False, "error": "Empty file."}), 400
    parsed = client_ocr.ingest(slug, data, upload.filename)
    if parsed.get("error") and not parsed.get("email"):
        return jsonify({"ok": False, **parsed}), 422
    return jsonify({"ok": True, **parsed})


@app.get("/api/clients/<slug>/requests/<req_id>/screenshot/<name>")
def api_client_screenshot_file(slug: str, req_id: str, name: str):
    try:
        root = clients.require_root(slug)
        folder = client_requests.request_path(root, req_id)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    path = folder / Path(name).name
    if not path.is_file() or path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".tif", ".tiff"}:
        return jsonify({"ok": False, "error": "screenshot not found"}), 404
    return send_file(path)


@app.post("/api/clients/<slug>/requests")
def api_client_request_create(slug: str):
    try:
        clients.require_root(slug)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    body = request.get_json(silent=True) or {}
    try:
        meta = client_requests.create_request(slug, body)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 400
    if body.get("process"):
        queued = client_pipeline.enqueue_process(slug, meta["id"])
        if not queued.get("ok"):
            return jsonify({"ok": True, "request": meta, "process": queued}), 202
    return jsonify({"ok": True, "request": meta}), 201


@app.get("/api/clients/<slug>/requests/<req_id>")
def api_client_request_get(slug: str, req_id: str):
    try:
        meta = client_requests.get_request(slug, req_id)
    except (ValueError, FileNotFoundError) as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    return jsonify({"ok": True, "request": meta, "pipeline": client_pipeline.job_snapshot()})


@app.post("/api/clients/<slug>/requests/<req_id>/work")
def api_client_request_work(slug: str, req_id: str):
    try:
        client_requests.get_request(slug, req_id)
    except (ValueError, FileNotFoundError) as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    result = client_pipeline.enqueue_work(slug, req_id)
    return jsonify(result), (202 if result.get("ok") else 409)


@app.post("/api/clients/<slug>/requests/<req_id>/merge")
def api_client_request_merge(slug: str, req_id: str):
    try:
        client_requests.get_request(slug, req_id)
    except (ValueError, FileNotFoundError) as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    result = client_pipeline.enqueue_merge(slug, req_id)
    return jsonify(result), (202 if result.get("ok") else 409)


@app.get("/api/clients/<slug>/requests/<req_id>/plan.pdf")
def api_client_plan_pdf(slug: str, req_id: str):
    try:
        root = clients.require_root(slug)
        folder = client_requests.request_path(root, req_id)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    path = folder / "changes-needed.pdf"
    if not path.is_file():
        return jsonify({"ok": False, "error": "No change-plan PDF yet"}), 404
    resp = send_file(path, mimetype="application/pdf", as_attachment=False, download_name="changes-needed.pdf")
    resp.headers["Cache-Control"] = "no-store"
    return resp


@app.post("/api/clients/<slug>/requests/<req_id>/comments")
def api_client_request_comments(slug: str, req_id: str):
    body = request.get_json(silent=True) or {}
    try:
        client_requests.add_comment(slug, req_id, str(body.get("text") or body.get("comments") or ""))
        meta = client_requests.get_request(slug, req_id)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 400
    except FileNotFoundError as extra:
        return jsonify({"ok": False, "error": str(extra)}), 404
    return jsonify({"ok": True, "request": meta})


@app.post("/api/clients/<slug>/requests/<req_id>/comments/screenshot")
def api_client_request_comment_screenshot(slug: str, req_id: str):
    try:
        client_requests.get_request(slug, req_id)
    except (ValueError, FileNotFoundError) as extra:
        return jsonify({"ok": False, "error": str(extra)}), 404
    upload = request.files.get("file")
    if upload is None or not upload.filename:
        return jsonify({"ok": False, "error": "Drop a screenshot image."}), 400
    data = upload.read()
    if not data:
        return jsonify({"ok": False, "error": "Empty file."}), 400
    parsed = client_ocr.ingest(slug, data, upload.filename)
    if parsed.get("error") and not parsed.get("email"):
        return jsonify({"ok": False, **parsed}), 422
    text = str(parsed.get("email") or parsed.get("ocr") or "").strip()
    if not text:
        return jsonify({"ok": False, "error": "Could not read text from the screenshot."}), 422
    try:
        client_requests.add_comment(slug, req_id, text, screenshot=str(parsed.get("path") or ""))
        meta = client_requests.get_request(slug, req_id)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 400
    return jsonify({"ok": True, "request": meta})


@app.route("/api/clients/<slug>/requests/<req_id>/comments/<int:idx>", methods=["PATCH", "DELETE"])
def api_client_request_comment_item(slug: str, req_id: str, idx: int):
    try:
        if request.method == "DELETE":
            client_requests.delete_comment(slug, req_id, idx)
        else:
            body = request.get_json(silent=True) or {}
            client_requests.edit_comment(slug, req_id, idx, str(body.get("text") or body.get("comments") or ""))
        meta = client_requests.get_request(slug, req_id)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 400
    except FileNotFoundError as extra:
        return jsonify({"ok": False, "error": str(extra)}), 404
    return jsonify({"ok": True, "request": meta})


@app.post("/api/clients/<slug>/requests/<req_id>/process")
def api_client_request_process(slug: str, req_id: str):
    try:
        client_requests.get_request(slug, req_id)
    except (ValueError, FileNotFoundError) as extra:
        return jsonify({"ok": False, "error": str(extra)}), 404
    result = client_pipeline.enqueue_process(slug, req_id)
    return jsonify(result), (202 if result.get("ok") else 409)


@app.post("/api/clients/<slug>/requests/deploy")
def api_client_deploy_build(slug: str):
    try:
        clients.require_root(slug)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    result = client_pipeline.enqueue_deploy(slug)
    return jsonify(result), (202 if result.get("ok") else 409)


@app.get("/api/clients/<slug>/requests/deploy")
def api_client_deploy_file(slug: str):
    try:
        root = clients.require_root(slug)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    info = client_package.snapshot(slug)
    name = str(info.get("name") or "")
    zpath = client_package.deploy_dir(root) / name if name else None
    if not zpath or not zpath.is_file():
        return jsonify({"ok": False, "error": "No TEST zip yet"}), 404
    resp = send_file(zpath, mimetype="application/zip", as_attachment=True, download_name=name)
    resp.headers["Cache-Control"] = "no-store"
    return resp


@app.get("/api/clients/<slug>/requests/<req_id>/file")
def api_client_request_file(slug: str, req_id: str):
    try:
        client_requests.get_request(slug, req_id)
        data = client_requests.view_file(slug, request.args.get("path") or "", request.args.get("side") or "after")
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 400
    except FileNotFoundError:
        return jsonify({"ok": False, "error": "File not found"}), 404
    return jsonify({"ok": True, **data})


@app.post("/api/clients/<slug>/requests/<req_id>/video")
def api_client_request_video(slug: str, req_id: str):
    try:
        client_requests.get_request(slug, req_id)
    except (ValueError, FileNotFoundError) as extra:
        return jsonify({"ok": False, "error": str(extra)}), 404
    result = client_pipeline.enqueue_video(slug, req_id)
    return jsonify(result), (202 if result.get("ok") else 409)


@app.get("/api/clients/<slug>/requests/<req_id>/video/file")
def api_client_request_video_file(slug: str, req_id: str):
    try:
        root = clients.require_root(slug)
        folder = client_requests.request_path(root, req_id)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    path = folder / client_request_video.MP4_NAME
    if not path.is_file():
        return jsonify({"ok": False, "error": "No request demo video yet"}), 404
    resp = send_file(path, mimetype="video/mp4", as_attachment=False, download_name=client_request_video.MP4_NAME)
    resp.headers["Cache-Control"] = "no-store"
    return resp


@app.get("/api/clients/<slug>/requests/<req_id>/zip")
def api_client_request_zip(slug: str, req_id: str):
    try:
        root = clients.require_root(slug)
        folder = client_requests.request_path(root, req_id)
        meta = client_requests.load_meta(folder)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 404
    name = str(meta.get("zip") or "")
    zpath = folder / name if name else None
    if not zpath or not zpath.is_file():
        return jsonify({"ok": False, "error": "No TEST zip yet"}), 404
    resp = send_file(zpath, mimetype="application/zip", as_attachment=True, download_name=name)
    resp.headers["Cache-Control"] = "no-store"
    return resp


def main() -> int:
    print(f"Sandbox control hub http://127.0.0.1:{PORT}/", flush=True)
    print(f"LAN  http://{demos.lan_ip()}:{PORT}/", flush=True)
    app.run(host="0.0.0.0", port=PORT, debug=False, threaded=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
