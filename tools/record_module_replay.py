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
from demo_paths import require_demo
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
    "RequestPath",
    "SERVICE_NAME",
    "SupportedResources",
    "Synchronous",
    "TargetURL",
    "Queue",
    "URI",
    "ConnectionMethod",
    "PointToPointMode",
    "Exchange",
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
    ("XML Formatting", "Processor"): "an XML Formatting processor that pretty-prints the file before we write it",
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

    m = re.match(
        r"^getAttribute\('([^']+)'\)(?:\.toString\(\))?\.trim\(\)$",
        e,
    )
    if m:
        return f"trimmed {{{friendly_attr(m.group(1))}}}"

    m = re.match(
        r"^'([^']+)'\s*\+\s*getAttribute\('([^']+)'\)(?:\.toString\(\))?\.trim\(\)$",
        e,
    )
    if m:
        return f"{m.group(1)}{{trimmed {friendly_attr(m.group(2))}}}"

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
        for item in child.iter():
            key = item.tag.split("}")[-1]
            if key in {"ModuleConfig", "RoutingPorts", "inputs", "outputs", "input", "output"}:
                continue
            val = (item.text or "").strip()
            if key and val:
                if key in cfg and cfg[key] != val:
                    cfg[key] = f"{cfg[key]} | {val}"
                else:
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
    if not raw:
        return ""
    out = resolve_token(raw, env)
    if "$$" in out:
        return ""
    return out


def _file_ext_spoken(ext: str) -> str:
    parts = [p.strip().lstrip(".") for p in (ext or "").split(",") if p.strip()]
    return ", ".join(f".{p}" for p in parts)


def speak_ftp(text: str) -> str:
    """Prefer 'FTP' in narration — the S is secure; saying SFTP aloud sounds awkward."""
    t = re.sub(r"\bSFTP\b", "FTP", text or "")
    t = re.sub(r"\bSftp\b", "FTP", t)
    return t


def soft_module_name(label: str) -> str:
    """Turn diagram labels into something a person would say."""
    raw = (label or "").strip()
    low = raw.lower()
    if "poll" in low and "control" in low:
        return "the control-file listener"
    if "poll" in low and ("sftp" in low or "ftp" in low):
        return "the FTP listener"
    if "poll" in low and "staged" in low:
        return "the staged-folder listener"
    if "save" in low and "body" in low:
        return "stash the file name"
    if "remote file name" in low:
        return "the remote file name"
    if "remote full path" in low or ("full path" in low and "remote" in low):
        return "the remote path"
    if "trigger" in low and "ftp" in low:
        return "the download trigger"
    if "programmable" in low or ("trigger" in low and "listener" in low):
        return "the trigger listener"
    if "no outbound" in low or "trigger only" in low:
        return "no outbound"
    if "archive" in low:
        return "the archive step"
    if "write" in low and "staged" in low:
        return "the stage-to-disk step"
    if "csv" in low and "xml" in low and "sql" not in low:
        return "the CSV processor"
    if "sqlxml" in low or ("map" in low and "sql" in low):
        return "the mapping step"
    if "insert" in low or (low.endswith("sql") or " sql" in f" {low}"):
        return "the SQL step"
    return speak_ftp(raw)


def explain_from_label(label: str) -> str:
    """Human why-it's-there copy from the diagram label when config XML is missing."""
    low = (label or "").lower()
    if "poll" in low and "control" in low:
        return (
            "First up is a directory listener — it watches a local folder for control files "
            "that name what to download."
        )
    if "save" in low and "body" in low:
        return (
            "The control file is just a name on one line. "
            "This processor copies that text onto the transaction "
            "so the later steps can use it without parsing the body again."
        )
    if "remote file name" in low:
        return (
            "We trim the name and keep it on the transaction as the remote file name, "
            "so we don't carry stray whitespace into FTP."
        )
    if "remote full path" in low or ("full path" in low and "remote" in low):
        return (
            "Then we build the full remote path — the upload folder plus that file name — "
            "so the download listener knows exactly what to fetch."
        )
    if "trigger" in low and "ftp" in low:
        return (
            "Now we kick the FTP download listener for one cycle. "
            "This route doesn't pull the file itself — it just tells that listener "
            "to go get the named file."
        )
    if "programmable" in low or ("trigger" in low and "listener" in low):
        return (
            "This is a programmable trigger listener. "
            "The first route hands the batch here so we can fork and process each row."
        )
    if "no outbound" in low or "trigger only" in low:
        return (
            "This route has nothing to send outbound. "
            "The work was the trigger, so we end on a null transport."
        )
    if "http" in low and "post" in low:
        return (
            "First up is an HTTP Post listener — partners POST a body to a path on this server, "
            "and that starts the transaction."
        )
    if "publish" in low and "queue" in low:
        return (
            "Then we publish that same body onto a RabbitMQ queue, so downstream consumers can pick it up."
        )
    if "rabbit" in low:
        return (
            "Then we publish that same body onto a RabbitMQ queue, so downstream consumers can pick it up."
        )
    return ""


def infer_purpose_from_routes(demo: Path) -> str:
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_demo_context import purpose_from_route_labels

    return purpose_from_route_labels(demo)


def demo_overview(demo: Path, env: dict[str, str], route_count: int) -> str:
    """Opening beat from this demo's DESIGN.md — not a canned CSV/SQL story."""
    tools_dir = Path(__file__).resolve().parent
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from construction_demo_context import first_sentence, load_purpose

    purpose = first_sentence(load_purpose(demo), 220) or infer_purpose_from_routes(demo)
    bits: list[str] = []
    if purpose:
        bits.append(purpose if purpose.endswith((".", "!", "?")) else purpose + ".")
    if route_count > 1:
        bits.append(f"We'll build that in {route_count} routes.")
    return speak_ftp(" ".join(bits) if bits else "We'll build the routes one module at a time.")


def empty_canvas_detail(
    route_name: str,
    env: dict[str, str],
    events: list[dict],
    *,
    is_first_route: bool = False,
    demo: Path | None = None,
    route_count: int = 1,
) -> tuple[str, str | None]:
    """Short demo-style open for a route — no config dumps, no formal route titles."""
    used_id = None
    if is_first_route and demo is not None:
        text = demo_overview(demo, env, route_count) + " Starting with a blank canvas on the first route."
    elif is_first_route:
        text = "We'll start with a blank canvas on the first route."
    else:
        text = "Next route — blank canvas again, then the modules one at a time."
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
    demo: Path | None = None,
    route_dir: Path | None = None,
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

    has_ftp = any(k.upper().startswith("SFTP") or k.upper().startswith("FTP") for k in env)
    staged = "stag" in f"{poll_dir} {target} {label}".lower()

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
            ext_disp = _file_ext_spoken(ext)
            if ext_disp:
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
        control = "control" in label.lower() or ext.lower().lstrip(".") == "ctl"
        if has_ftp and staged:
            bits = [
                "Next is the staged-folder listener — it never talks to FTP, just the local stage.",
            ]
        elif control:
            bits = [
                "First up is a directory listener — it watches a local folder for control files.",
            ]
        else:
            bits = ["Here's a directory listener — it watches a local folder."]
        if poll_dir:
            bits.append(f"That folder is {poll_dir}.")
        if ext:
            ext_disp = _file_ext_spoken(ext)
            if ext_disp:
                bits.append(f"We're only taking {ext_disp} files.")
        if interval:
            bits.append(f"It checks about every {interval} seconds.")
        if post == "move":
            bits.append("After pickup we move the file aside so the folder stays clean.")
        return speak_ftp(" ".join(bits)), None

    # --- Listener: REST ---
    if "restfulwebservice" in class_l or "restful web service" in type_l:
        svc = (cfg.get("SERVICE_NAME") or "").strip() or "the service"
        resources = (cfg.get("SupportedResources") or "").strip()
        bits = [
            f"First up is a REST listener — clinic systems POST to /eip/rest/{svc}.",
        ]
        if resources:
            names = " and ".join(p.strip() for p in resources.split(",") if p.strip())
            bits.append(f"The resources are {names}.")
        if (cfg.get("Synchronous") or "").strip().lower() == "true":
            bits.append("We wait for the route to finish so the caller gets an HTTP response back.")
        return speak_ftp(" ".join(bits)), None

    # --- Listener: HTTP Post ---
    if "httppostlistener" in class_l or (tag_l == "listener" and "http post" in type_l):
        path = (cfg.get("RequestPath") or "").strip() or "the configured path"
        if path and not path.startswith("/"):
            path = f"/{path}"
        bits = [
            f"First up is an HTTP Post listener — partners POST a body to {path} on this server, "
            "and that starts the transaction.",
        ]
        if (cfg.get("Synchronous") or "").strip().lower() == "true":
            bits.append("We wait for the route to finish so the caller gets an HTTP response back.")
        return speak_ftp(" ".join(bits)), None

    # --- Listener: Programmable trigger (route-to-route handoff) ---
    if "triggerablelistener" in class_l or (tag_l == "listener" and "programmable" in type_l):
        return speak_ftp(
            "This is a programmable trigger listener. "
            "The first route hands the batch here so we can fork and process each row."
        ), None

    # --- Save body onto the transaction (don't say "attribute" — TTS mangles it) ---
    if "savedatatoattribute" in class_l or "data attribute swapper" in type_l:
        lab = label.lower()
        if "raw 271" in lab or "save raw" in lab:
            return speak_ftp(
                "We keep the raw 271 on the transaction so we can wrap it without losing the wire text."
            ), None
        if "wrapped" in lab or "load wrapped" in lab:
            return speak_ftp(
                "Then we put that wrapped XML back on the body so the next XSLT can parse it."
            ), None
        return speak_ftp(
            "The control file is just a name on one line. "
            "This processor copies that text onto the transaction "
            "so the later steps can use it without parsing the body again."
        ), None

    # --- Transaction field population ---
    if "transactionattributepopulation" in class_l or "transaction attribute population" in type_l:
        expr = (cfg.get("Expression") or "").lower()
        dest = (cfg.get("AttributeName") or "").lower()
        lab = label.lower()
        if "wrap" in lab and "271" in lab:
            return speak_ftp(
                "We wrap the raw 271 in a tiny XML envelope so the parse stylesheet can read it."
            ), None
        if "patient" in dest or "patient" in lab:
            return speak_ftp(
                "Then we stitch last name and first name into one patient name on the transaction."
            ), None
        if "full path" in lab or "fullpath" in dest or "upload/" in expr:
            return speak_ftp(
                "Then we build the full remote path — the upload folder plus that file name — "
                "so the download listener knows exactly what to fetch."
            ), None
        if has_ftp or "file name" in dest or "filename" in dest or "remote" in lab:
            return speak_ftp(
                "We trim the name and keep it on the transaction as the remote file name, "
                "so we don't carry stray whitespace into FTP."
            ), None
        return speak_ftp(
            "We keep this value on the transaction so later steps can use it."
        ), None

    # --- Listener Trigger ---
    if "listenertrigger" in class_l or "listener trigger" in type_l:
        once = (cfg.get("RUN_ONCE") or "").strip().lower() in {"true", "1", "yes"}
        cycle = " for one cycle" if once else ""
        return speak_ftp(
            f"Now we kick the FTP download listener{cycle}. "
            "This route doesn't pull the file itself — it just tells that listener "
            "to go get the named file."
        ), None

    # --- Null transport ---
    if "nulltransport" in class_l or type_l in {"null", "none"}:
        lab = label.lower()
        if any(k in lab for k in ("update", "sql", "open ar", "ar matched", "ar exception")):
            return speak_ftp(
                "The SQL update already ran on this path, so we finish on a null transport — "
                "nothing else to send."
            ), None
        if "complete" in lab or "no-op" in lab:
            return speak_ftp(
                "We're done with this claim — files already wrote to disk — so we finish on a null transport."
            ), None
        return speak_ftp(
            "This route has nothing to send outbound, so we end on a null transport."
        ), None

    # --- File Writing / archive ---
    if "file writing" in type_l or "filewrite" in class_l:
        where = f"{label} {target} {cfg.get('TargetFileName') or ''}".lower()
        if "debug" in where:
            bits = ["This writes a debug copy of the XML so we can inspect what the route saw."]
            if target:
                bits.append(f"That lands under {target}.")
            return speak_ftp(" ".join(bits)), None
        if ".json" in where or "json" in where or "summary" in label.lower():
            bits = ["Then we write the JSON summary to disk."]
        elif ".xml" in where or "edi xml" in where:
            bits = ["Then we write that XML to disk so we can inspect it."]
        elif ".edi" in where or "wire" in label.lower():
            bits = ["Then we write the X12 text to disk."]
        else:
            bits = [
                "Next we archive a copy of the body — original name plus a timestamp.",
            ]
        if target:
            bits.append(f"That lands under {target}.")
        return speak_ftp(" ".join(bits)), None

    # --- XML pretty-print (transport-side; required before writing an XML file) ---
    if "xmlformatting" in class_l or "xml formatting" in type_l:
        return speak_ftp(
            "This processor pretty-prints the XML — line breaks and indent — "
            "so the file on disk is readable."
        ), None

    # --- Directory transport ---
    if tag_l == "transport" and "directory" in type_l:
        bits = ["Then we write the file out"]
        if target:
            bits[0] = bits[0] + f" to {target}"
        bits[0] += "."
        if has_ftp and staged:
            bits.append("That keeps FTP pickup separate from the next route.")
        return speak_ftp(" ".join(bits)), None

    # --- Conditional / XPath router ---
    if (
        tag_l in {"routingmodule", "routing"}
        or "routingmodule" in class_l
        or "conditional node router" in type_l
    ):
        blob = " ".join(str(v) for v in cfg.values())
        expr = (cfg.get("condition") or cfg.get("Expression") or cfg.get("OGNLExpression") or "").strip()
        if "ResourceName" in blob and "check" in blob.lower():
            return speak_ftp(
                "Then a conditional router. POST to check takes the realtime round-trip; anything else is a 405."
            ), None
        if "ResourceName" in blob and ("build" in blob.lower() or "parse" in blob.lower()):
            return speak_ftp(
                "Then a conditional router. POST to build goes down the 270 path, parse goes down the 271 path, and anything else is a 405."
            ), None
        if expr in {"true()", "true"}:
            return speak_ftp(
                "Then a conditional router. Here the rule is always true, so every transaction goes down the same path."
            ), None
        return speak_ftp(
            "Then a conditional router — it uses XPath to pick which path this transaction takes."
        ), None

    # --- RabbitMQ transport ---
    if "rabbitmqtransport" in class_l or (tag_l == "transport" and "rabbit" in type_l):
        queue = _resolved(cfg, env, "Queue") or "the queue"
        bits = [
            f"Then we publish that same body onto RabbitMQ queue {queue}, "
            "so downstream consumers can pick it up.",
        ]
        if (cfg.get("Declare") or "").strip().lower() == "true":
            bits.append("The transport declares the queue if it isn't there yet.")
        return speak_ftp(" ".join(bits)), None

    # --- CSV ---
    if type_l == "csv" or "csvtransformation" in class_l:
        return speak_ftp(
            "Here's the CSV processor — it turns the file into XML "
            "and uses the header row for the column names."
        ), None

    # --- XSLT ---
    if "xslt" in type_l or "xslt" in class_l:
        sheet = Path(xslt).name if xslt else "our stylesheet"
        engine = (
            "This is a custom module using"
            if is_custom_module(class_name)
            else "We're using the stock XSLT processor with"
        )
        opener = f"Now for the mapping — {engine[0].lower() + engine[1:]} {sheet}."
        hints = ""
        xslt_text = ""
        if route_dir and xslt:
            for cand in (route_dir / Path(xslt).name, route_dir / xslt, Path(xslt)):
                if cand.is_file():
                    xslt_text = cand.read_text(encoding="utf-8", errors="replace")
                    break
        if not xslt_text and demo and xslt:
            want = Path(xslt).name.lower()
            for p in demo.rglob(Path(xslt).name):
                if "node_modules" in p.parts:
                    continue
                if p.name.lower() == want and p.is_file():
                    xslt_text = p.read_text(encoding="utf-8", errors="replace")
                    break
        if xslt_text:
            tools_dir = Path(__file__).resolve().parent
            if str(tools_dir) not in sys.path:
                sys.path.insert(0, str(tools_dir))
            from construction_demo_context import xslt_talking_points

            hints = xslt_talking_points(xslt_text)
        return speak_ftp((opener + (" " + hints if hints else "")).strip()), None

    # --- XPath fork ---
    if (
        "xpathfork" in class_l
        or "xpath forking" in type_l
        or ("fork" in label.lower() and "xpath" in f"{type_l} {class_l} {label.lower()}")
    ):
        return speak_ftp(
            "This XPath fork splits the file so each transaction set becomes its own message."
        ), None

    # --- XPath Evaluation ---
    if "xpathevaluator" in class_l or "xpath evaluation" in type_l:
        lab = label.lower()
        if "clp" in lab or "remit" in lab:
            return speak_ftp(
                "XPath evaluation pulls the claim control number, paid amount, and charge "
                "off the EDI XML."
            ), None
        if "open ar" in lab or "expected" in lab:
            return speak_ftp(
                "Another XPath evaluation — this time from the SQL result, so we have "
                "expected paid and the patient name."
            ), None
        if "decision" in lab:
            return speak_ftp(
                "XPath evaluation copies the match bucket off the decision XML "
                "so the router can fan out."
            ), None
        return speak_ftp(
            "XPath evaluation copies a few fields off the XML onto the transaction "
            "so later steps can use them."
        ), None

    # --- HTTP Post transport (payer / partner call) ---
    if "httpposttransport" in class_l or (tag_l == "transport" and "http post" in type_l):
        url = _resolved(cfg, env, "TargetURL") or ""
        lab = (label or "").lower()
        dump_url = bool(url) and "{ognl" not in url.lower() and "$$" not in url
        if "object storage" in lab or "oci-mock" in url.lower() or "oci" in lab:
            bits = ["Then we HTTP POST each JSON object to the Object Storage mock."]
        elif dump_url:
            bits = [f"Then we HTTP POST the body to {url}."]
        else:
            bits = ["Then we HTTP POST the body to the partner."]
        bits.append("After the response comes back, post-processors keep going on that same transaction.")
        return speak_ftp(" ".join(bits)), None

    # --- Sync reply processor (after HttpPost, not a transport) ---
    if "synchronousresponseprocessor" in class_l:
        return speak_ftp(
            "This processor replies on the original REST call, so the clinic gets the JSON on the same request."
        ), None

    if "synchronousresponsetransport" in class_l or (
        tag_l == "transport" and "synchronous response" in type_l
    ):
        return speak_ftp(
            "This transport replies on the original REST call with whatever body we just built."
        ), None

    if "httpresponsecode" in class_l or "http response status" in type_l:
        code = (cfg.get("StatusCode") or "").strip()
        if code:
            return speak_ftp(f"We set the HTTP status to {code}."), None
        return speak_ftp("We set the HTTP status on the way out."), None

    if "addhttpresponseheaders" in class_l or "http response headers" in type_l:
        return speak_ftp(
            "We set the response content type so the clinic client knows what it got back."
        ), None

    # --- EDI transformation ---
    if "editransformation" in class_l or "edi transformation" in type_l:
        direction = (cfg.get("TransformationDirection") or "").lower()
        if "xml to edi" in direction:
            return speak_ftp(
                "Here's the EDI transformation — it turns our EDI XML into X12 text on the wire."
            ), None
        return speak_ftp(
            "Here's the EDI transformation — it turns the X12 into XML we can query."
        ), None

    # --- Database SQL ---
    if "database" in type_l or "databasesql" in class_l:
        where = db or "the database"
        polling = (
            tag_l == "listener"
            or "polling" in type_l
            or "databasesqllistener" in class_l
        )
        if polling:
            bits = [
                f"First up is a SQL polling listener — it runs a query against {where} over JDBC.",
            ]
            if interval:
                bits.append(f"It checks about every {interval} seconds.")
            return speak_ftp(" ".join(bits)), None
        q = (cfg.get("Query") or "").lstrip()
        q_up = q.upper()
        if q_up.startswith("SELECT"):
            return speak_ftp(
                f"This is a SQL lookup — we query {where} over JDBC using a key from the transaction."
            ), None
        if q_up.startswith("UPDATE"):
            return speak_ftp(
                f"Then we update that row in {where} so the status matches the decision."
            ), None
        if q_up.startswith("INSERT"):
            return speak_ftp(
                f"And we write to SQL — those inserts go into {where} over JDBC."
            ), None
        return speak_ftp(
            f"And we write to SQL — those statements go into {where} over JDBC."
        ), None

    # --- Custom fallback ---
    if is_custom_module(class_name):
        return speak_ftp(
            f"Next we add {soft_module_name(label)}. "
            "This one's custom for this interface — not a stock catalog module."
        ), None

    # --- Label fallback when module XML is missing (never "a module named X") ---
    story = explain_from_label(label)
    if story:
        return speak_ftp(story), None
    kind = (type_name or tag or "").strip()
    if kind:
        article = "an" if kind[:1].lower() in "aeiou" else "a"
        return speak_ftp(f"Here's {article} {kind} processor — next step in the flow."), None
    return speak_ftp("Here's the next step in the route."), None


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
    route_count: int = 1,
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
        demo=root,
        route_count=route_count,
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
    empty_msg = "First route" if is_first_route else "Next route"
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
            demo=root,
            route_dir=route_dir,
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
    root = require_demo(args.root)
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
            route_count=len(routes),
        )
    print(f"Done — {total} steps in {replay}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
