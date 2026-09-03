"""Local Ollama chat for hub features (plan builder). Implement stays mechanical."""

from __future__ import annotations

import json
import os
import subprocess
import threading
import urllib.error
import urllib.request

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://127.0.0.1:11434").rstrip("/")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "llama3.2")

_pull = {"busy": False, "error": "", "log": ""}
_lock = threading.Lock()


def _models(data: dict) -> list[dict]:
    out = []
    for rec in data.get("models") or []:
        name = rec.get("name") or rec.get("model") or ""
        if not name:
            continue
        size = int(rec.get("size") or 0)
        out.append(
            {
                "name": name,
                "size": size,
                "size_gb": round(size / (1024**3), 2) if size else 0,
                "modified": rec.get("modified_at") or "",
            }
        )
    return out[:32]


def status() -> dict:
    with _lock:
        pulling = dict(_pull)
    try:
        with urllib.request.urlopen(f"{OLLAMA_URL}/api/tags", timeout=3) as resp:
            data = json.loads(resp.read().decode("utf-8") or "{}")
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as exc:
        return {
            "ok": False,
            "url": OLLAMA_URL,
            "model": OLLAMA_MODEL,
            "error": str(exc)[:200],
            "models": [],
            "model_present": False,
            "pull": pulling,
        }
    models = _models(data)
    names = [m["name"] for m in models]
    have = any(n == OLLAMA_MODEL or n.startswith(OLLAMA_MODEL + ":") for n in names)
    return {
        "ok": True,
        "url": OLLAMA_URL,
        "model": OLLAMA_MODEL,
        "model_present": have,
        "models": models,
        "error": "" if have else f"Pull the model: ollama pull {OLLAMA_MODEL}",
        "pull": pulling,
    }


def start_service() -> dict:
    try:
        proc = subprocess.run(
            ["brew", "services", "start", "ollama"],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"ok": False, "error": str(exc)[:200]}
    if proc.returncode != 0:
        return {"ok": False, "error": (proc.stderr or proc.stdout or "brew start failed")[:300]}
    return {"ok": True, "log": (proc.stdout or "")[:300]}


def _run_pull() -> None:
    try:
        proc = subprocess.run(
            ["ollama", "pull", OLLAMA_MODEL],
            capture_output=True,
            text=True,
            timeout=900,
        )
        log = ((proc.stdout or "") + "\n" + (proc.stderr or "")).strip()[-800:]
        with _lock:
            _pull["busy"] = False
            _pull["error"] = "" if proc.returncode == 0 else (log or "pull failed")
            _pull["log"] = log
    except (OSError, subprocess.TimeoutExpired) as exc:
        with _lock:
            _pull["busy"] = False
            _pull["error"] = str(exc)[:200]
            _pull["log"] = ""


def pull_start() -> dict:
    with _lock:
        if _pull["busy"]:
            return {"ok": True, "busy": True}
        _pull["busy"] = True
        _pull["error"] = ""
        _pull["log"] = ""
    threading.Thread(target=_run_pull, daemon=True).start()
    return {"ok": True, "busy": True}


def ping() -> dict:
    try:
        text = chat(
            [{"role": "user", "content": "Reply with the single word pong."}],
            format_json=False,
            timeout=60,
        )
    except Exception as exc:
        return {"ok": False, "error": str(exc)[:300], "reply": ""}
    return {"ok": True, "error": "", "reply": (text or "").strip()[:500]}


def chat(messages: list[dict], *, format_json: bool = True, timeout: int = 180) -> str:
    payload = {
        "model": OLLAMA_MODEL,
        "messages": messages,
        "stream": False,
        "options": {"temperature": 0.1},
    }
    if format_json:
        payload["format"] = "json"
    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/chat",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode("utf-8") or "{}")
    return str((data.get("message") or {}).get("content") or "")


def chat_json(messages: list[dict], timeout: int = 180) -> dict:
    raw = chat(messages, format_json=True, timeout=timeout)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        return {}
    return data if isinstance(data, dict) else {}
