#!/usr/bin/env python3
"""Record module-by-module construction replay (starts empty, adds one node at a time).

Reads finished route.v2.xml graphs under a demo, then writes documents/build-replay/
with an empty canvas step and then one module per step.

Each step's ``detail`` is a short spoken-style transcript of what is being built:
module role, chosen config (with human-readable OGNL), external systems, custom
modules/XSLT, and any decision rationale — written like a person talking, not a
config dump.

  python3 tools/record_module_replay.py --root Clients/Demos/csv-sftp-to-sql
  python3 tools/record_module_replay.py --root Clients/Demos/edi-999-ta1-ack-triage --clear-only
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from xml.dom import minidom
from xml.etree import ElementTree as ET

STOCK_PREFIXES = (
    "com.pilotfish.eip.modules.",
    "com.pilotfish.eip.modules.internal.",
)

# Config keys that are usually worth speaking about when set.
HIGHLIGHT_KEYS = {
    "FTPListenerType",
    "Host",
    "Port",
    "PollingInterval",
    "PollingDirectory",
    "FileExtensionRestriction",
    "FileNameRestriction",
    "UseFullFilePath",
    "FullPathToFile",
    "PostProcessOperation",
    "TargetDirectory",
    "TargetFileName",
    "FileName",
    "FileExtension",
    "TransformationDirection",
    "Delimiter",
    "OutputColumnHeaders",
    "DetectDelimiter",
    "LinesToSkip",
    "XSLTPath",
    "XSLTEngine",
    "JdbcDriver",
    "JdbcURL",
    "UserName",
    "Password",
    "UseDataSource",
    "DataSource",
    "Autocommit",
    "LogSQL",
    "Query",
    "WriteQuery",
    "AppendToFile",
    "ExecuteProcessor",
    "ExecuteTransformation",
    "UserName",  # noqa: duplicated ok
}

SKIP_VALUES = {"", "false", "null", "Null", "Disabled", "-1", "0", "System Default", "true"}
# Keys that are noise in spoken transcript (always-on flags, etc.)
SKIP_SPEAK_KEYS = {
    "ExecuteProcessor",
    "ExecuteTransformation",
    "Password",
    "KeyStoreFilePassword",
    "TrustStoreFilePassword",
    "UseFullFilePath",
    "FullPathToFile",
    "AppendToFile",
    "WriteQuery",
    "UseDataSource",
    "DataSource",
    "DetectDelimiter",
    "LinesToSkip",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def pretty(root: ET.Element) -> str:
    rough = ET.tostring(root, encoding="utf-8")
    return minidom.parseString(rough).toprettyxml(indent="   ", encoding="UTF-8").decode("utf-8")


# Spoken opening for each module kind (natural, not catalog copy).
OPENING = {
    ("Directory / File", "Listener"): "a Directory Listener that watches a local folder",
    ("Directory / File", "Transport"): "a Directory Transport that writes the file out locally",
    ("FTPListener", "Listener"): "an SFTP Listener that polls a remote folder",
    ("FTP / SFTP", "Listener"): "an SFTP Listener that polls a remote folder",
    ("File Writing", "Processor"): "a File Writing processor to keep a raw copy on disk",
    ("CSV", "Processor"): "a CSV Transformation that turns the file into Dialect A XML",
    ("XSLT Transformation", "Processor"): "an XSLT Transformation to reshape the XML",
    ("Database (SQL)", "Transport"): "a Database SQL Transport that runs the SQLXML against JDBC",
    ("XPath", "Processor"): "an XPath Fork to split multi-transaction payloads",
    ("XPath Evaluation", "Processor"): "XPath Evaluation to pull fields into attributes",
    ("EDI", "Processor"): "an EDI Transformation between X12 text and XML",
    ("Conditional Node Router", "RoutingModule"): "a Conditional Node Router for XPath-based routing",
}


def friendly_attr(name: str) -> str:
    if name == "com.pilotfish.FileName":
        return "sourceFileName"
    return name


def summarize_ognl_expr(expr: str) -> str:
    """Port of route-viewer module-config.js summarizeOgnlExpr (human reading)."""
    e = re.sub(r"\s+", " ", expr).strip()

    m = re.match(
        r"^'([^']*)'\s*\+\s*@java\.lang\.System@currentTimeMillis\(\)\s*\+\s*'([^']*)'$",
        e,
    )
    if m:
        return f"{m.group(1)}<timestamp>{m.group(2)}"

    # Ternary FileName + timestamp (+ optional extension literal)
    m = re.match(
        r"^\(getAttribute\('([^']+)'\)\s*!=\s*null\s*\?\s*getAttribute\('\1'\)\s*:\s*'([^']*)'\)"
        r"\s*\+\s*'([^']*)'\s*\+\s*@java\.lang\.System@currentTimeMillis\(\)"
        r"(?:\s*\+\s*'([^']*)')?$",
        e,
    )
    if m:
        attr, _fallback, mid, suffix = m.group(1), m.group(2), m.group(3), m.group(4) or ""
        return f"{{{friendly_attr(attr)}}}{mid}<timestamp>{suffix}"

    m = re.match(r"^getAttribute\('([^']+)'\)\s*\+\s*'([^']*)'$", e)
    if m:
        return f"{{{friendly_attr(m.group(1))}}}{m.group(2)}"

    m = re.match(r"^getAttribute\('([^']+)'\)$", e)
    if m:
        return f"{{{friendly_attr(m.group(1))}}}"

    if re.search(r"getAttribute\('ClaimId'\)\s*!=\s*null", e) and (
        "isEmpty()" in e or "trim()" in e
    ):
        return "only when ClaimId is set"

    if "#xpath(" in e and "IsBatch" in e:
        return "only when //IsBatch is true/1"

    m = re.match(r"^getAttribute\('([^']+)'\)\s*==\s*'([^']+)'$", e)
    if m:
        return f"only when {{{friendly_attr(m.group(1))}}} is '{m.group(2)}'"

    if "getAttribute(" in e and "+" in e and not re.search(r"[!<>=]|&&|\|\|", e):
        bits: list[str] = []
        ok = True
        for tok in re.split(r"\s*\+\s*", e):
            t = tok.strip()
            m = re.match(r"^getAttribute\('([^']+)'\)$", t)
            if m:
                bits.append(f"{{{friendly_attr(m.group(1))}}}")
                continue
            m = re.match(r"^'([^']*)'$", t)
            if m:
                bits.append(m.group(1))
                continue
            if t == "@java.lang.System@currentTimeMillis()":
                bits.append("<timestamp>")
                continue
            ok = False
            break
        if ok and bits:
            return "".join(bits)

    return (
        e.replace("@java.lang.System@currentTimeMillis()", "currentTimeMillis()")
        .replace("&&", " and ")
        .replace("||", " or ")
    )


def extract_ognl(raw: str) -> str | None:
    text = (raw or "").strip()
    m = re.match(r"^\{ognl:([\s\S]*)\}$", text, flags=re.I)
    return m.group(1).strip() if m else None


def human_value(key: str, raw: str, env: dict[str, str]) -> str | None:
    if key in SKIP_SPEAK_KEYS:
        return None
    if raw in SKIP_VALUES and "$$" not in raw:
        return None
    ognl = extract_ognl(raw)
    if ognl is not None:
        return summarize_ognl_expr(ognl)
    if "@java.lang.System@currentTimeMillis()" in raw or "{ognl:" in raw.lower():
        # Unwrapped / partial OGNL
        return summarize_ognl_expr(raw)
    resolved = resolve_token(raw, env)
    if key == "JdbcURL" and "databaseName=" in resolved:
        m = re.search(r"databaseName=([^;]+)", resolved)
        host = "sqlserver" if "sqlserver" in resolved else "SQL Server"
        return f"JDBC to {host}, database {m.group(1)}" if m else resolved[:80]
    if key == "JdbcDriver" and "SQLServer" in resolved:
        return "Microsoft SQL Server JDBC driver"
    if resolved != raw and "$$" in raw:
        return resolved
    return resolved if len(resolved) < 100 else resolved[:97] + "…"


def speak_config_bits(cfg: dict[str, str], env: dict[str, str]) -> list[str]:
    """Natural fragments about chosen config (not key=value dumps)."""
    bits: list[str] = []
    ftp_type = cfg.get("FTPListenerType") or ""
    if "SFTP" in ftp_type or "JSCH" in ftp_type:
        bits.append("encrypted SFTP via JSCH")
    elif ftp_type:
        bits.append(ftp_type)

    host = human_value("Host", cfg.get("Host", ""), env) if cfg.get("Host") else None
    port = human_value("Port", cfg.get("Port", ""), env) if cfg.get("Port") else None
    poll_dir = (
        human_value("PollingDirectory", cfg.get("PollingDirectory", ""), env)
        if cfg.get("PollingDirectory")
        else None
    )
    ext = cfg.get("FileExtensionRestriction") or cfg.get("FileExtension") or ""
    interval = cfg.get("PollingInterval") or ""
    post = cfg.get("PostProcessOperation") or ""
    target = (
        human_value("TargetDirectory", cfg.get("TargetDirectory", ""), env)
        if cfg.get("TargetDirectory")
        else None
    )
    tname = cfg.get("TargetFileName") or cfg.get("FileName") or ""
    tname_h = human_value("TargetFileName", tname, env) if tname else None
    direction = cfg.get("TransformationDirection") or ""
    delim = cfg.get("Delimiter") or ""
    headers = cfg.get("OutputColumnHeaders") or ""
    xslt = cfg.get("XSLTPath") or ""
    engine = cfg.get("XSLTEngine") or ""
    user = human_value("UserName", cfg.get("UserName", ""), env) if cfg.get("UserName") else None
    jdbc = human_value("JdbcURL", cfg.get("JdbcURL", ""), env) if cfg.get("JdbcURL") else None

    if host or port or poll_dir:
        loc = []
        if host:
            loc.append(host)
        if port:
            loc.append(f"port {port}")
        if poll_dir:
            loc.append(f"folder {poll_dir}")
        # Prefer "connects to …" as a full clause (caller joins with periods)
        bits.append("connects to " + ", ".join(loc))
    if user and cfg.get("Host"):
        bits.append(f"logs in as {user}")
    if ext:
        bits.append(f"only .{ext.lstrip('.')} files")
    if interval and interval not in SKIP_VALUES:
        bits.append(f"polls every {interval} seconds")
    if post and post.lower() not in {"none", "null", ""}:
        if post.lower() == "delete":
            bits.append("deletes the remote file after pickup")
        elif post.lower() == "move" and target:
            bits.append(f"then moves the file to {target}")
        else:
            bits.append(f"post-process {post}")
    if target and "PollingDirectory" not in cfg and post.lower() != "move":
        bits.append(f"writes to {target}")
    if tname_h:
        bits.append(f"names files {tname_h}")
    if direction:
        bits.append(direction.lower())
    if delim:
        bits.append("comma-delimited" if delim == "," else f"delimiter {delim}")
    if headers.lower() == "true":
        bits.append("keeps the header row as column names")
    if xslt and xslt.lower() not in {"null", "none"}:
        bits.append(f"uses stylesheet {xslt}" + (f" on {engine}" if engine else ""))
    if jdbc:
        if user:
            bits.append(f"{jdbc}, as user {user}")
        else:
            bits.append(jdbc)
    return bits


def format_config_sentence(bits: list[str]) -> str:
    if not bits:
        return ""
    # Keep "connects to…" / "writes to…" as their own clauses
    clauses = []
    rest = []
    for b in bits:
        if b.startswith(("connects to ", "writes to ", "uses stylesheet ", "JDBC ")):
            clauses.append(b[0].upper() + b[1:] + ".")
        else:
            rest.append(b)
    parts = []
    if rest:
        if len(rest) == 1:
            parts.append(f"It's set up for {rest[0]}.")
        else:
            parts.append("It's set up for " + "; ".join(rest[:-1]) + f"; and {rest[-1]}.")
    parts.extend(clauses)
    return " ".join(parts)


def load_env_settings(root: Path) -> dict[str, str]:
    candidates = [
        root / "pilotfish" / "demo-eip-root" / "environment-settings.conf",
        *root.glob("eip-root/interfaces/*/environment-settings.conf"),
    ]
    env: dict[str, str] = {}
    for path in candidates:
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().replace("\\:", ":").replace("\\=", "=")
    return env


def load_experience(root: Path) -> list[dict]:
    path = root / "documents" / "build-experience.json"
    if not path.is_file():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    events = data.get("events") if isinstance(data, dict) else []
    return [e for e in events if isinstance(e, dict)] if isinstance(events, list) else []


def resolve_token(value: str, env: dict[str, str]) -> str:
    def repl(m: re.Match[str]) -> str:
        key = m.group(1)
        return env.get(key, m.group(0))

    return re.sub(r"\$\$([A-Za-z0-9_.-]+)", repl, value)


def human_system_from_env(env: dict[str, str]) -> list[str]:
    """High-level external systems for empty-canvas / intro narration."""
    systems: list[str] = []
    if any(k.startswith("SFTP_") or k == "SFTP_HOST" for k in env):
        host = env.get("SFTP_HOST", "SFTP")
        port = env.get("SFTP_PORT", "")
        directory = env.get("SFTP_POLL_DIR", env.get("SFTP_REMOTE_DIR", ""))
        user = env.get("SFTP_USER", "")
        bits = [f"SFTP host {host}"]
        if port:
            bits.append(f"port {port}")
        if directory:
            bits.append(f"directory {directory}")
        if user:
            bits.append(f"user {user}")
        systems.append(", ".join(bits))
    url = env.get("sqlserver.url") or env.get("SQLSERVER_URL") or ""
    if url or env.get("sqlserver.driver"):
        db = ""
        m = re.search(r"databaseName=([^;]+)", url)
        if m:
            db = m.group(1)
        host = "SQL Server"
        if "sqlserver" in url:
            host = "SQL Server (Docker service sqlserver)"
        systems.append(f"{host}" + (f", database {db}" if db else "") + " via JDBC")
    if env.get("OCI_BUCKET") or env.get("OCI_ENDPOINT"):
        systems.append(
            "OCI Object Storage"
            + (f" bucket {env.get('OCI_BUCKET')}" if env.get("OCI_BUCKET") else "")
        )
    return systems


def is_custom_module(class_name: str) -> bool:
    if not class_name:
        return False
    if class_name.startswith("com.pilotfish.eip.modules."):
        return False
    if "custom" in class_name.lower() or "client" in class_name.lower():
        return True
    # Anything outside PilotFish module packages is treated as custom / callout
    return not class_name.startswith("com.pilotfish.")


def load_module_meta(modules_dir: Path, module_id: str) -> dict:
    path = modules_dir / f"{module_id}.xml"
    if not path.is_file():
        return {"tag": "", "type": "", "name": module_id, "class": "", "config": {}, "path": None}
    root = ET.parse(path).getroot()
    cfg: dict[str, str] = {}
    for child in root:
        tag = child.tag.split("}")[-1]
        if tag != "ModuleConfig":
            continue
        for item in child:
            key = item.tag.split("}")[-1]
            val = (item.text or "").strip()
            if key:
                cfg[key] = val
    return {
        "tag": root.attrib.get("tag", ""),
        "type": root.attrib.get("type", ""),
        "name": root.attrib.get("name", ""),
        "class": root.attrib.get("class", ""),
        "config": cfg,
        "path": path,
    }


def config_highlights(cfg: dict[str, str], env: dict[str, str]) -> list[str]:
    """Machine-friendly highlights for the manifest (human OGNL, resolved $$)."""
    lines: list[str] = []
    ordered = [k for k in HIGHLIGHT_KEYS if k in cfg] + [
        k for k in sorted(cfg) if k not in HIGHLIGHT_KEYS and "$$" in (cfg.get(k) or "")
    ]
    seen: set[str] = set()
    for key in ordered:
        if key in seen or key in SKIP_SPEAK_KEYS:
            continue
        seen.add(key)
        raw = cfg.get(key, "")
        hv = human_value(key, raw, env)
        if not hv:
            continue
        lines.append(f"{key}: {hv}")
    return lines[:12]


def pick_decision(
    events: list[dict],
    *,
    route_name: str,
    label: str,
    type_name: str,
    class_name: str = "",
    cfg: dict[str, str] | None = None,
    for_empty: bool = False,
) -> dict | None:
    """Best matching experience decision for this step (no generic notes on modules)."""
    cfg = cfg or {}
    # Do not include route_name for module matching — it false-matches "sftp"/"csv" everywhere.
    hay = " ".join(
        [
            label.lower(),
            (type_name or "").lower(),
            (class_name or "").lower(),
            " ".join(f"{k} {v}" for k, v in list(cfg.items())[:30]).lower(),
        ]
    )
    scored: list[tuple[int, dict]] = []
    for ev in events:
        kind = (ev.get("kind") or "")
        if for_empty:
            if kind not in {"decision", "note"}:
                continue
        else:
            if kind != "decision":
                continue
        keys = [str(k).lower() for k in (ev.get("keywords") or [])]
        blob = " ".join(
            [str(ev.get(k) or "") for k in ("title", "summary", "detail", "rationale")]
            + keys
        ).lower()
        if not blob:
            continue
        score = 0
        if for_empty:
            if "two-route" in blob or "architecture" in keys or "two-route" in keys:
                score += 8
            elif kind == "note" and "external" in keys:
                score += 1  # weak; only if nothing else
            else:
                continue
        else:
            # Hard requirements for operation-specific decisions
            post = (cfg.get("PostProcessOperation") or "").lower()
            type_l = (type_name or "").lower()
            class_l = (class_name or "").lower()
            if "delete" in keys and post != "delete":
                continue
            if "jsch" in keys and "jsch" not in hay and "encrypted ftp" not in hay:
                continue
            if "jdbc" in keys and "jdbc" not in hay and "sqlserver" not in hay:
                continue
            if "xslt" in keys and "xslt" not in type_l and "xsltpath" not in hay.replace(" ", ""):
                continue
            if "archive" in keys and "file writing" not in type_l and "filewriteprocessor" not in class_l:
                continue
            if "transport" in keys and "transport" not in class_l and "transport" not in type_l:
                continue
            overlap = [t for t in keys if t and t in hay]
            # Ignore weak alone tokens
            strong = [t for t in overlap if t not in {"csv", "poll", "directory", "stage", "sql"}]
            if not strong and not any(t in overlap for t in ("jsch", "archive", "xslt", "jdbc", "header", "delete")):
                continue
            if not overlap:
                continue
            score += len(overlap) * 2 + len(strong) * 3
            if label and label.lower() in blob:
                score += 2
            if "two-route" in keys or "architecture" in keys:
                score -= 6
        if score >= 5:
            scored.append((score, ev))
    if not scored:
        return None
    scored.sort(key=lambda x: -x[0])
    return scored[0][1]



def opening_for(tag: str, type_name: str, label: str) -> str:
    key = (type_name, tag)
    if key in OPENING:
        return OPENING[key]
    for (t, tg), phrase in OPENING.items():
        if t.lower() == (type_name or "").lower() and (not tg or tg == tag):
            return phrase
    return f"a {type_name or tag or 'module'} named {label}"


def _resolved(cfg: dict[str, str], env: dict[str, str], key: str, default: str = "") -> str:
    raw = cfg.get(key) or default
    return resolve_token(raw, env) if raw else ""


def speak_ftp(text: str) -> str:
    """Prefer 'FTP' in narration — the S is secure; saying SFTP aloud sounds awkward."""
    t = re.sub(r"\bSFTP\b", "FTP", text or "")
    t = re.sub(r"\bSftp\b", "FTP", t)
    return t


def soft_module_name(label: str) -> str:
    """Turn diagram labels into something a person would say."""
    raw = (label or "").strip()
    low = raw.lower()
    if "poll" in low and ("sftp" in low or "ftp" in low):
        return "the FTP listener"
    if "poll" in low and "staged" in low:
        return "the staged-folder listener"
    if "archive" in low:
        return "the archive step"
    if "write" in low and "staged" in low:
        return "the stage-to-disk step"
    if "csv" in low and "xml" in low and "sql" not in low:
        return "the CSV processor"
    if "sqlxml" in low or ("map" in low and "sql" in low):
        return "the mapping step"
    if "insert" in low or ("sql" in low and "patient" in low):
        return "the SQL insert"
    return speak_ftp(raw)


def demo_overview(env: dict[str, str]) -> str:
    """Opening beat after pipeline/systems — keep short; don't re-lecture the stack."""
    return (
        "Ops drops a patient CSV and we land the rows in the database — "
        "no hand-loading. "
        "Two routes: pickup first, then the load."
    )


def empty_canvas_detail(
    route_name: str,
    env: dict[str, str],
    events: list[dict],
    *,
    is_first_route: bool = False,
) -> tuple[str, str | None]:
    """Short demo-style open for a route — no config dumps, no formal route titles."""
    low = route_name.strip().lower()
    used_id = None
    if "sftp" in low and "stage" in low:
        if is_first_route:
            text = (
                demo_overview(env)
                + " "
                + "Starting with pickup: grab the file from FTP, "
                "keep a raw archive, and stage a local copy — "
                "before we ever touch the database."
            )
        else:
            text = (
                "Pickup route next. "
                "Grab the file from FTP, keep a raw archive, and stage a local copy — "
                "before we ever touch the database."
            )
        for ev in events:
            if ev.get("kind") == "decision" and "two-route" in " ".join(
                str(k) for k in (ev.get("keywords") or [])
            ):
                used_id = str(ev.get("id") or "") or None
                break
    elif "csv" in low and "sql" in low:
        text = (
            "Onto the load route — this one never talks to FTP. "
            "It watches the staged folder, turns each CSV into SQL, and loads the patients table."
        )
    else:
        text = "Next route — we'll add the modules one at a time."
    return speak_ftp(text), used_id


def explain_module_rich(
    *,
    tag: str,
    type_name: str,
    label: str,
    class_name: str,
    cfg: dict[str, str],
    env: dict[str, str],
    events: list[dict],
    route_name: str,
) -> tuple[str, str | None]:
    """Demo-presenter narration — short, concrete, no key=value junk."""
    type_l = (type_name or "").lower()
    tag_l = (tag or "").lower()
    class_l = (class_name or "").lower()

    host = _resolved(cfg, env, "Host")
    port = _resolved(cfg, env, "Port")
    poll_dir = _resolved(cfg, env, "PollingDirectory")
    target = _resolved(cfg, env, "TargetDirectory")
    interval = (cfg.get("PollingInterval") or "").strip()
    post = (cfg.get("PostProcessOperation") or "").strip().lower()
    ext = (cfg.get("FileExtensionRestriction") or cfg.get("FileExtension") or "").strip()
    xslt = (cfg.get("XSLTPath") or "").strip()
    jdbc = _resolved(cfg, env, "JdbcURL")
    db = ""
    m = re.search(r"databaseName=([^;]+)", jdbc or "")
    if m:
        db = m.group(1)

    # --- Listener: FTP / SFTP ---
    if "ftp" in type_l or "ftp" in class_l:
        where = poll_dir or "the remote folder"
        if where in ("upload", "download") or (
            where
            and "/" not in where
            and " " not in where
            and where != "the remote folder"
        ):
            where_phrase = f"the {where} folder"
        else:
            where_phrase = where
        bits = [
            f"First up is the FTP listener — it watches {where_phrase}"
            + (" on the FTP server" if host else "")
            + ".",
        ]
        if ext:
            ext_disp = ext if str(ext).startswith(".") else f".{ext}"
            bits.append(f"We're only taking {ext_disp} files.")
        if interval:
            bits.append(f"It checks about every {interval} seconds.")
        if post == "delete":
            bits.append(
                "Once we've got the file, we delete it remotely so it doesn't get picked up again."
            )
        elif post == "move" and target:
            bits.append(f"Once we've got it, we move it to {target}.")
        return speak_ftp(" ".join(bits)), None

    # --- Listener: Directory ---
    if tag_l == "listener" and "directory" in type_l:
        bits = [
            "Next is the staged-folder listener — it never talks to FTP, just the local stage.",
        ]
        if poll_dir:
            bits.append(f"It watches {poll_dir}.")
        if ext:
            ext_disp = ext if str(ext).startswith(".") else f".{ext}"
            bits.append(f"Same idea: only {ext_disp} files.")
        if interval:
            bits.append(f"It polls every {interval} seconds.")
        if post == "move" and target:
            bits.append("After pickup we move the file aside so the folder stays clean.")
        return speak_ftp(" ".join(bits)), None

    # --- File Writing / archive ---
    if "file writing" in type_l or "filewrite" in class_l:
        bits = [
            "Next we archive the raw file — an exact copy of whatever arrived, before we touch the data.",
        ]
        if target:
            bits.append(f"That lands under {target}, original name plus a timestamp.")
        return speak_ftp(" ".join(bits)), None

    # --- Directory transport / stage ---
    if tag_l == "transport" and "directory" in type_l:
        bits = [
            "Then we stage a local copy for the next route",
        ]
        if target:
            bits[-1] = bits[-1] + f", writing to {target},"
        else:
            bits[-1] = bits[-1] + ","
        bits.append("so FTP pickup stays separate from the database work.")
        return speak_ftp(" ".join(bits)), None

    # --- CSV ---
    if type_l == "csv" or "csvtransformation" in class_l:
        return speak_ftp(
            "Here's the CSV processor — it turns the file into XML "
            "and uses the header row for the column names."
        ), None

    # --- XSLT ---
    if "xslt" in type_l or "xslt" in class_l:
        sheet = xslt or "our stylesheet"
        if is_custom_module(class_name):
            return speak_ftp(
                f"Now for the mapping — I'll open the custom stylesheet. "
                f"This is a custom module using {sheet}. "
                "Watch the for-each over each CSV record and the column mappings: "
                "Dialect A tags like PATIENTID into the SQL insert fields, "
                "and STATE becomes StateCode."
            ), None
        return speak_ftp(
            f"Now for the mapping — I'll open the stylesheet. "
            f"We're using the stock XSLT processor with {sheet}. "
            "Watch the for-each over each CSV record and the column mappings: "
            "Dialect A tags like PATIENTID into the SQL insert fields, "
            "and STATE becomes StateCode."
        ), None

    # --- Database SQL ---
    if "database" in type_l or "databasesql" in class_l:
        where = "the demo database"
        if db and "demo" not in db.lower() and "sftp" not in db.lower():
            where = db
        return speak_ftp(
            f"And finally we insert into SQL — those inserts go into {where} over JDBC. "
            "That's it: CSV in, patients in SQL."
        ), None

    # --- Custom fallback ---
    if is_custom_module(class_name):
        return speak_ftp(
            f"Next we add {soft_module_name(label)}. "
            "This one's custom for this interface — not a stock catalog module."
        ), None

    # --- Generic fallback: still keep it short ---
    role = opening_for(tag, type_name, label)
    return speak_ftp(f"Next we add {soft_module_name(label)} — {role}."), None


def clear_replay(root: Path) -> Path:
    replay = root / "documents" / "build-replay"
    if replay.exists():
        shutil.rmtree(replay)
    (replay / "steps").mkdir(parents=True)
    manifest = {
        "version": 1,
        "title": "Module-by-module construction replay",
        "steps": [],
        "updated_at": utc_now(),
        "default_pause_ms": 4500,
    }
    (replay / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return replay


def topo_nodes(nodes: list[ET.Element], connections: list[ET.Element]) -> list[ET.Element]:
    by_id = {n.attrib["id"]: n for n in nodes}
    indeg = {n.attrib["id"]: 0 for n in nodes}
    outs: dict[str, list[str]] = {n.attrib["id"]: [] for n in nodes}
    for c in connections:
        s, t = c.attrib.get("sourceNodeId"), c.attrib.get("targetNodeId")
        if s in indeg and t in indeg:
            indeg[t] += 1
            outs[s].append(t)
    ready = sorted(
        [i for i, d in indeg.items() if d == 0],
        key=lambda i: (float(by_id[i].attrib.get("x", 0)), float(by_id[i].attrib.get("y", 0)), by_id[i].attrib.get("label", "")),
    )
    ordered: list[str] = []
    seen = set()
    while ready:
        cur = ready.pop(0)
        if cur in seen:
            continue
        seen.add(cur)
        ordered.append(cur)
        for nxt in outs.get(cur, []):
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                ready.append(nxt)
        ready.sort(
            key=lambda i: (float(by_id[i].attrib.get("x", 0)), float(by_id[i].attrib.get("y", 0)), by_id[i].attrib.get("label", ""))
        )
    for n in nodes:
        if n.attrib["id"] not in seen:
            ordered.append(n.attrib["id"])
    return [by_id[i] for i in ordered]


def clone(el: ET.Element) -> ET.Element:
    out = ET.Element(el.tag, {k: v for k, v in el.attrib.items()})
    out.text = el.text
    out.tail = el.tail
    for child in el:
        out.append(clone(child))
    return out


def write_partial_v2(
    full_root: ET.Element,
    keep_ids: set[str],
    dest: Path,
    modules_src: Path,
) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    out = ET.Element(full_root.tag, {k: v for k, v in full_root.attrib.items()})
    for child in full_root:
        tag = child.tag.split("}")[-1]
        if tag == "RouteSettings":
            out.append(clone(child))
        elif tag == "Nodes":
            nodes_el = ET.SubElement(out, "Nodes")
            for n in child:
                if n.attrib.get("id") in keep_ids:
                    nodes_el.append(clone(n))
        elif tag == "Connections":
            conns_el = ET.SubElement(out, "Connections")
            for c in child:
                if c.attrib.get("sourceNodeId") in keep_ids and c.attrib.get("targetNodeId") in keep_ids:
                    conns_el.append(clone(c))
        else:
            out.append(clone(child))
    (dest / "route.v2.xml").write_text(pretty(out), encoding="utf-8")
    mods = dest / "modules"
    if mods.exists():
        shutil.rmtree(mods)
    mods.mkdir()
    for mid in {
        n.attrib.get("moduleId")
        for n in list(out.find("Nodes") if out.find("Nodes") is not None else [])
        if n.attrib.get("moduleId")
    }:
        src = modules_src / f"{mid}.xml"
        if src.is_file():
            shutil.copy2(src, mods / src.name)
    groups = modules_src.parent / "diagram-groups.json"
    if groups.is_file():
        shutil.copy2(groups, dest / "diagram-groups.json")


def record_route(
    root: Path,
    route_dir: Path,
    replay: Path,
    manifest_path: Path,
    *,
    env: dict[str, str],
    events: list[dict],
    used_decision_ids: set[str] | None = None,
    is_first_route: bool = False,
) -> int:
    v2 = route_dir / "route.v2.xml"
    if not v2.is_file():
        return 0
    modules_src = route_dir / "modules"
    tree = ET.parse(v2)
    rroot = tree.getroot()
    nodes_el = None
    conns_el = None
    for child in rroot:
        tag = child.tag.split("}")[-1]
        if tag == "Nodes":
            nodes_el = child
        elif tag == "Connections":
            conns_el = child
    nodes = list(nodes_el) if nodes_el is not None else []
    conns = list(conns_el) if conns_el is not None else []
    ordered = topo_nodes(nodes, conns)
    route_name = route_dir.name
    route_id = (
        route_name.strip().lower().replace(" - ", "-").replace(" ", "-").replace("_", "-")
    )

    tmp = replay / "steps" / "_staging"
    if tmp.exists():
        shutil.rmtree(tmp)
    write_partial_v2(rroot, set(), tmp, modules_src)
    if used_decision_ids is None:
        used_decision_ids = set()
    empty_detail, empty_dec = empty_canvas_detail(
        route_name,
        env,
        [e for e in events if not (e.get("kind") == "decision" and str(e.get("id") or "") in used_decision_ids)],
        is_first_route=is_first_route,
    )
    if empty_dec:
        used_decision_ids.add(empty_dec)
    try:
        tools_dir = Path(__file__).resolve().parent
        if str(tools_dir) not in sys.path:
            sys.path.insert(0, str(tools_dir))
        from construction_narration_naturalize import naturalize_spoken

        empty_detail = naturalize_spoken(empty_detail)
    except Exception:
        pass
    low_name = route_name.lower()
    if is_first_route and "sftp" in low_name:
        empty_msg = "Pickup first"
    elif "csv" in low_name and "sql" in low_name:
        empty_msg = "The load route"
    elif "sftp" in low_name or "ftp" in low_name:
        empty_msg = "The pickup route"
    else:
        empty_msg = "Next route"
    entry = {
        "route_id": route_id,
        "route_name": route_name,
        "message": empty_msg,
        "detail": empty_detail,
        "modules_visible": 0,
        "focus_label": "",
        "focus_node_id": "",
        "external_systems": human_system_from_env(env),
    }
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    seq = len(data.get("steps") or []) + 1
    step_id = f"{seq:04d}"
    dest = replay / "steps" / step_id
    if dest.exists():
        shutil.rmtree(dest)
    shutil.move(str(tmp), str(dest))
    entry.update({"id": step_id, "seq": seq, "recorded_at": utc_now()})
    data.setdefault("steps", []).append(entry)
    data["updated_at"] = utc_now()
    data["default_pause_ms"] = 4500
    manifest_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"Recorded {step_id}: {entry['message']}")
    count = 1

    keep: set[str] = set()
    for node in ordered:
        keep.add(node.attrib["id"])
        mid = node.attrib.get("moduleId", "")
        label = node.attrib.get("label") or "Module"
        meta = load_module_meta(modules_src, mid)
        filtered_events = [
            ev
            for ev in events
            if not (
                ev.get("kind") == "decision"
                and str(ev.get("id") or "") in used_decision_ids
            )
        ]
        detail, used_dec = explain_module_rich(
            tag=meta.get("tag") or "",
            type_name=meta.get("type") or "",
            label=label,
            class_name=meta.get("class") or "",
            cfg=meta.get("config") or {},
            env=env,
            events=filtered_events,
            route_name=route_name,
        )
        try:
            tools_dir = Path(__file__).resolve().parent
            if str(tools_dir) not in sys.path:
                sys.path.insert(0, str(tools_dir))
            from construction_narration_naturalize import naturalize_spoken

            detail = naturalize_spoken(detail)
        except Exception:
            pass
        if used_dec:
            used_decision_ids.add(used_dec)
        msg = f"Add {soft_module_name(label)}"
        # Prefer human overlay text over raw diagram labels when they say SFTP
        overlay = soft_module_name(label)
        if overlay.startswith("the "):
            overlay = overlay[4:]
        overlay = overlay[:1].upper() + overlay[1:] if overlay else label
        msg = overlay
        tmp = replay / "steps" / "_staging"
        if tmp.exists():
            shutil.rmtree(tmp)
        write_partial_v2(rroot, keep, tmp, modules_src)
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        seq = len(data.get("steps") or []) + 1
        step_id = f"{seq:04d}"
        dest = replay / "steps" / step_id
        if dest.exists():
            shutil.rmtree(dest)
        shutil.move(str(tmp), str(dest))
        entry = {
            "id": step_id,
            "seq": seq,
            "route_id": route_id,
            "route_name": route_name,
            "message": msg,
            "detail": detail,
            "modules_visible": len(keep),
            "focus_label": label,
            "focus_node_id": node.attrib["id"],
            "module_type": meta.get("type") or "",
            "module_tag": meta.get("tag") or "",
            "module_class": meta.get("class") or "",
            "custom_module": is_custom_module(meta.get("class") or ""),
            "config_highlights": config_highlights(meta.get("config") or {}, env),
            "recorded_at": utc_now(),
        }
        data.setdefault("steps", []).append(entry)
        data["updated_at"] = utc_now()
        data["default_pause_ms"] = 4500
        manifest_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        print(f"Recorded {step_id}: {msg}")
        count += 1
    return count


def find_route_dirs(root: Path) -> list[Path]:
    demo = root / "pilotfish" / "demo-eip-root" / "routes"
    if demo.is_dir():
        return sorted([p for p in demo.iterdir() if (p / "route.v2.xml").is_file()])
    found = []
    for p in root.glob("eip-root/interfaces/*/routes/*"):
        if (p / "route.v2.xml").is_file():
            found.append(p)
    return sorted(found)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True)
    ap.add_argument("--clear-only", action="store_true")
    args = ap.parse_args()
    root = Path(args.root).expanduser().resolve()
    replay = clear_replay(root)
    if args.clear_only:
        print(replay)
        return 0
    manifest = replay / "manifest.json"
    routes = find_route_dirs(root)
    if not routes:
        print("No route.v2.xml found", file=sys.stderr)
        return 1
    env = load_env_settings(root)
    events = load_experience(root)
    total = 0
    used_decision_ids: set[str] = set()
    for idx, route_dir in enumerate(routes):
        print("Recording", route_dir.name)
        total += record_route(
            root,
            route_dir,
            replay,
            manifest,
            env=env,
            events=events,
            used_decision_ids=used_decision_ids,
            is_first_route=(idx == 0),
        )
    print(f"Done — {total} steps in {replay}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
