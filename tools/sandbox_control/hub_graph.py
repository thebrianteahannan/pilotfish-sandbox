"""Microsoft Graph (OAuth device login) for Microsoft 365 Outlook."""

from __future__ import annotations

import json
import threading
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
DATA = HERE / "data"
TOKEN_CACHE = DATA / "msal_cache.bin"
DEVICE_STATE = DATA / "msal_device.json"

# Microsoft Graph Command Line Tools — public client used by mgc / Graph PowerShell.
CLIENT_ID = "14d82eec-204b-4c2f-b7e8-296a70dab67e"
AUTHORITY = "https://login.microsoftonline.com/organizations"
SCOPES = ["User.Read", "Mail.Read", "Calendars.Read"]

_lock = threading.Lock()
_device = {"busy": False, "user_code": "", "uri": "", "message": "", "error": "", "done": False}


def _pca():
    import msal

    DATA.mkdir(parents=True, exist_ok=True)
    cache = msal.SerializableTokenCache()
    if TOKEN_CACHE.is_file():
        cache.deserialize(TOKEN_CACHE.read_text(encoding="utf-8"))
    app = msal.PublicClientApplication(CLIENT_ID, authority=AUTHORITY, token_cache=cache)
    return app, cache


def _persist(cache) -> None:
    if cache.has_state_changed:
        TOKEN_CACHE.write_text(cache.serialize(), encoding="utf-8")


def signed_in() -> bool:
    try:
        app, cache = _pca()
    except Exception:
        return False
    return bool(app.get_accounts())


def device_status() -> dict:
    with _lock:
        return {**_device, "signed_in": signed_in()}


def clear() -> None:
    for path in (TOKEN_CACHE, DEVICE_STATE):
        if path.is_file():
            path.unlink()
    with _lock:
        _device.update({"busy": False, "user_code": "", "uri": "", "message": "", "error": "", "done": False})


def access_token() -> str:
    app, cache = _pca()
    accounts = app.get_accounts()
    if not accounts:
        raise ValueError("Sign in with Microsoft first.")
    result = app.acquire_token_silent(SCOPES, account=accounts[0]) or {}
    _persist(cache)
    token = result.get("access_token") or ""
    if not token:
        raise ValueError("Microsoft session expired. Sign in again.")
    return token


def graph_get(path: str, params: dict | None = None, headers: dict | None = None) -> dict:
    token = access_token()
    url = "https://graph.microsoft.com/v1.0" + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    hdrs = {"Authorization": "Bearer " + token, "Accept": "application/json"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, headers=hdrs)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")[:400]
        raise RuntimeError(f"Graph HTTP {exc.code}: {body}") from exc


def me() -> dict:
    return graph_get("/me", {"$select": "displayName,mail,userPrincipalName"})


def _wait_device(flow: dict) -> None:
    with _lock:
        _device.update({"busy": True, "error": "", "done": False, "message": "Waiting for Microsoft sign-in…"})
    try:
        app, cache = _pca()
        result = app.acquire_token_by_device_flow(flow)
        _persist(cache)
        if result.get("access_token"):
            info = {}
            try:
                info = me()
            except Exception:
                info = {}
            with _lock:
                _device.update(
                    {
                        "busy": False,
                        "done": True,
                        "error": "",
                        "message": "Signed in",
                        "user": info.get("mail") or info.get("userPrincipalName") or "",
                    }
                )
            return
        err = result.get("error_description") or result.get("error") or "Sign-in failed"
        with _lock:
            _device.update({"busy": False, "done": False, "error": str(err)[:400], "message": "Sign-in failed"})
    except Exception as exc:
        with _lock:
            _device.update({"busy": False, "done": False, "error": str(exc)[:400], "message": "Sign-in failed"})


def start_device_login() -> dict:
    app, _cache = _pca()
    flow = app.initiate_device_flow(scopes=SCOPES)
    if "user_code" not in flow:
        raise RuntimeError("Could not start Microsoft sign-in.")
    with _lock:
        _device.update(
            {
                "busy": True,
                "done": False,
                "error": "",
                "user_code": flow.get("user_code") or "",
                "uri": flow.get("verification_uri") or "https://microsoft.com/devicelogin",
                "message": flow.get("message") or "Enter the code in the browser.",
            }
        )
    threading.Thread(target=_wait_device, args=(flow,), daemon=True).start()
    return device_status()
