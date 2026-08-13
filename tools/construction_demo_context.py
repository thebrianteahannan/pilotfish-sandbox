#!/usr/bin/env python3
"""Per-demo facts for construction video / transcript (no slug special-cases)."""

from __future__ import annotations

import base64
import json
import re
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen


def _text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""


def load_demo_display_name(demo: Path) -> str:
    design = demo / "DESIGN.md"
    if design.is_file():
        for line in _text(design).splitlines():
            if line.startswith("# "):
                name = re.sub(r"\s*[—\-–]\s*Design\s*$", "", line[2:].strip(), flags=re.I)
                if name:
                    return name
    interfaces = demo / "eip-root" / "interfaces"
    if interfaces.is_dir():
        kids = sorted(p.name for p in interfaces.iterdir() if p.is_dir() and not p.name.startswith("."))
        if kids:
            return kids[0]
    return demo.name.replace("-", " ").strip() or "PilotFish Demo"


def parse_design_sections(design_text: str) -> dict[str, str]:
    sections: dict[str, str] = {}
    current = ""
    buf: list[str] = []
    for line in design_text.splitlines():
        m = re.match(r"^#{1,3}\s+(?:\d+\.\s*)?(.+)$", line)
        if m:
            if current:
                sections[current] = "\n".join(buf).strip()
            current = m.group(1).strip().lower()
            buf = []
        else:
            buf.append(line)
    if current:
        sections[current] = "\n".join(buf).strip()
    return sections


def section_match(sections: dict[str, str], *needles: str) -> str:
    for key, body in sections.items():
        if any(n in key for n in needles):
            return body
    return ""


def first_sentence(text: str, limit: int = 280) -> str:
    t = re.sub(r"\s+", " ", (text or "").strip())
    t = re.sub(r"\*\*([^*]+)\*\*", r"\1", t)
    t = re.sub(r"`([^`]+)`", r"\1", t)
    if not t:
        return ""
    m = re.match(r"(.+?[.!?])(?:\s|$)", t)
    s = m.group(1) if m else t
    if len(s) > limit:
        s = s[: limit - 1].rsplit(" ", 1)[0] + "."
    return s


def load_design_blurb(demo: Path | None) -> str:
    if not demo:
        return ""
    design = demo / "DESIGN.md"
    if not design.is_file():
        return ""
    lines = _text(design).splitlines()
    past_title = False
    buf: list[str] = []
    for line in lines:
        if not past_title:
            if line.startswith("# "):
                past_title = True
            continue
        if line.startswith("#"):
            break
        if not line.strip():
            if buf:
                break
            continue
        if re.match(r"(?i)^status\s*:", line.strip()):
            continue
        buf.append(line.strip())
    return re.sub(r"\s+", " ", " ".join(buf)).strip()


def load_purpose(demo: Path | None) -> str:
    if not demo:
        return ""
    design = demo / "DESIGN.md"
    if not design.is_file():
        return load_design_blurb(demo)
    sections = parse_design_sections(_text(design))
    body = section_match(sections, "purpose", "business goal", "goal")
    para = ""
    for line in (body or "").splitlines():
        if line.strip() and not line.startswith("|") and not line.startswith("#"):
            para = re.sub(r"^[-*]\s+", "", line.strip())
            break
    if re.fullmatch(r"(tbd|todo|n/?a|none|\.+)", para or "", flags=re.I):
        para = ""
    return para or load_design_blurb(demo) or purpose_from_route_labels(demo)


def load_design_actors(demo: Path | None) -> list[str]:
    if not demo:
        return []
    design = demo / "DESIGN.md"
    if not design.is_file():
        return []
    sections = parse_design_sections(_text(design))
    body = section_match(sections, "actor", "system", "context")
    out: list[str] = []
    for line in (body or "").splitlines():
        s = re.sub(r"^[-*]\s+", "", line.strip())
        s = re.sub(r"\*\*([^*]+)\*\*", r"\1", s)
        s = re.sub(r"`([^`]+)`", r"\1", s)
        if s and not s.startswith("|") and not s.startswith("#"):
            out.append(s)
    return out[:8]


def has_custom_modules(demo: Path | None) -> bool:
    if not demo:
        return False
    custom = demo / "custom-modules"
    if not custom.is_dir():
        return False
    return any(p.is_file() for p in custom.rglob("*") if p.suffix in {".java", ".xml", ".py", ".js"})


def _clean_html(s: str) -> str:
    t = re.sub(r"<br\s*/?>", " · ", s or "", flags=re.I)
    t = re.sub(r"<[^>]+>", "", t)
    return re.sub(r"\s+", " ", t).strip()


def pipeline_stages_from_html(demo: Path) -> list[dict]:
    html = _text(demo / "webui" / "templates" / "index.html")
    if not html:
        return []
    stages: list[dict] = []
    for m in re.finditer(
        r'<div class="pipe-node[^"]*">\s*<strong>(.*?)</strong>\s*<span>(.*?)</span>',
        html,
        flags=re.S,
    ):
        title = _clean_html(m.group(1))
        subtitle = _clean_html(m.group(2))
        if title:
            stages.append({"title": title, "subtitle": subtitle})
    return stages


def pipeline_stages_from_design(demo: Path) -> list[dict]:
    design = demo / "DESIGN.md"
    if not design.is_file():
        return []
    sections = parse_design_sections(_text(design))
    body = section_match(sections, "pipeline")
    rows: list[dict] = []
    for line in (body or "").splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells or set(cells[0]) <= {"-", ":"}:
            continue
        if cells[0].lower() in {"stage", "step"}:
            continue
        title = re.sub(r"`([^`]+)`", r"\1", cells[0])
        subtitle = re.sub(r"`([^`]+)`", r"\1", cells[1]) if len(cells) > 1 else ""
        if title:
            rows.append({"title": title, "subtitle": subtitle})
    if len(rows) > 5:
        return [rows[0], rows[len(rows) // 3], rows[(2 * len(rows)) // 3], rows[-1]]
    return rows


def purpose_from_route_labels(demo: Path | None) -> str:
    """One spoken sentence from first-route labels when DESIGN purpose is empty."""
    if not demo:
        return ""
    xml_paths = sorted((demo / "pilotfish" / "demo-eip-root" / "routes").glob("*/route.v2.xml"))
    if not xml_paths:
        xml_paths = sorted(demo.glob("eip-root/interfaces/*/routes/*/route.v2.xml"))
    if not xml_paths:
        return ""
    labels = re.findall(r'<Node\b[^>]*\blabel="([^"]+)"', _text(xml_paths[0]))
    blob = " ".join(labels).lower()
    if "control" in blob and "trigger" in blob:
        return "A control file names a remote file, then we trigger an FTP listener to go get it."
    return ""


def humanize_stage_title(label: str) -> str:
    """Overlay titles — explain the step, don't paste the diagram card."""
    low = (label or "").lower()
    if "poll" in low and "control" in low:
        return "Control file"
    if "save" in low and "body" in low:
        return "Stash the name"
    if "remote file name" in low:
        return "Remote file name"
    if "remote full path" in low or ("full path" in low and "remote" in low):
        return "Remote path"
    if "trigger" in low and ("ftp" in low or "listener" in low):
        return "Trigger download"
    if "no outbound" in low or "trigger only" in low:
        return "No outbound"
    return (label or "").strip()


def pipeline_stages_from_routes(demo: Path) -> list[dict]:
    """Fall back to module labels on the first route.v2.xml."""
    xml_paths = sorted((demo / "pilotfish" / "demo-eip-root" / "routes").glob("*/route.v2.xml"))
    if not xml_paths:
        xml_paths = sorted(demo.glob("eip-root/interfaces/*/routes/*/route.v2.xml"))
    if not xml_paths:
        return []
    labels = re.findall(r'<Node\b[^>]*\blabel="([^"]+)"', _text(xml_paths[0]))
    if not labels:
        return []
    if len(labels) > 4:
        labels = [labels[0], labels[len(labels) // 3], labels[(2 * len(labels)) // 3], labels[-1]]
    return [{"title": humanize_stage_title(t), "subtitle": ""} for t in labels]


def load_pipeline_stages(demo: Path | None) -> list[dict]:
    if not demo:
        return []
    return (
        pipeline_stages_from_html(demo)
        or pipeline_stages_from_design(demo)
        or pipeline_stages_from_routes(demo)
    )


def _service_role(name: str, image: str) -> str:
    hay = f"{name} {image}".lower()
    if "webui" in hay or name == "webui":
        return "Sandbox Web UI"
    if "pilotfish" in hay or name in {"eip", "eiplatform"}:
        return "Runs the routes"
    if "sftp" in hay or re.search(r"\bftp\b", hay):
        return "File drop"
    if "sql" in hay or "mssql" in hay or "postgres" in hay:
        return "Database"
    if "mock" in hay:
        return "Mock backend"
    if "rabbit" in hay:
        return "Message queue"
    return "Compose service"


def _human_service_name(name: str) -> str:
    low = name.lower()
    if low in {"sftp", "ftp"}:
        return "FTP drop"
    if low in {"sqlserver", "sql", "mssql"}:
        return "SQL Server"
    if low == "webui":
        return "Demo Web UI"
    if low in {"pilotfish", "eip"}:
        return "PilotFish eiPlatform"
    if "rabbit" in low:
        return "RabbitMQ"
    return name.replace("-", " ").replace("_", " ").title()


def load_compose_systems(demo: Path | None) -> list[dict]:
    if not demo:
        return []
    compose = demo / "docker-compose.yml"
    if not compose.is_file():
        return []
    text = _text(compose)
    m = re.search(r"(?ms)^services:\n(.*)", text)
    block = m.group(1) if m else text
    systems: list[dict] = []
    parts = re.split(r"(?m)^  ([a-zA-Z0-9_-]+):\s*$", block)
    # parts: [preamble, name1, body1, name2, body2, ...]
    for i in range(1, len(parts) - 1, 2):
        name = parts[i]
        body = parts[i + 1]
        if name.endswith("-init") or name.endswith("_init"):
            continue
        img_m = re.search(r"^\s+image:\s*(\S+)", body, re.M)
        image = (img_m.group(1) if img_m else "").strip().strip("\"'")
        if not image and re.search(r"^\s+build:", body, re.M):
            image = f"pilotfish-{demo.name}-{name}"
        ports: list[str] = []
        for pm in re.finditer(r'"(\d+):\d+"', body):
            ports.append(f"localhost:{pm.group(1)}")
        systems.append(
            {
                "name": _human_service_name(name),
                "kind": "Docker",
                "image": image or name,
                "detail": " · ".join(ports) if ports else "",
                "role": _service_role(name, image),
            }
        )
    return systems


def find_ognl_example(demo: Path | None) -> tuple[str, str] | None:
    if not demo:
        return None
    tools_dir = Path(__file__).resolve().parent
    import sys

    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    from record_module_replay import summarize_ognl_expr

    roots = [
        demo / "pilotfish" / "demo-eip-root",
        demo / "eip-root",
        demo / "documents" / "build-replay",
    ]
    for base in roots:
        if not base.exists():
            continue
        for path in base.rglob("*.xml"):
            try:
                raw = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            m = re.search(r"\{ognl:([^}]+)\}", raw, flags=re.I)
            if not m:
                continue
            expr = m.group(0)
            return expr, summarize_ognl_expr(m.group(1))
    return None


def find_xslt_for_step(demo: Path | None, step: dict | None = None) -> tuple[str, str] | None:
    """Return (filename, text) for the stylesheet this step (or demo) uses."""
    names: list[str] = []
    if step:
        for h in step.get("config_highlights") or []:
            hm = re.search(r"(?:stylesheet|XSLTPath)\s*[: ]\s*(\S+\.xslt?)", str(h), flags=re.I)
            if hm:
                names.append(Path(hm.group(1)).name)
        detail = str(step.get("detail") or "")
        for hm in re.finditer(r"(\S+\.xslt?)", detail, flags=re.I):
            names.append(Path(hm.group(1)).name)
    search_dirs: list[Path] = []
    if demo:
        if step and step.get("id"):
            snap = demo / "documents" / "build-replay" / "steps" / str(step["id"])
            if snap.is_dir():
                search_dirs.append(snap)
        search_dirs.extend(
            [
                demo / "pilotfish" / "demo-eip-root" / "routes",
                demo / "eip-root",
                demo,
            ]
        )
    seen: set[Path] = set()
    hits: list[Path] = []
    for d in search_dirs:
        if not d.exists():
            continue
        for p in d.rglob("*.xslt"):
            if p in seen or "node_modules" in p.parts:
                continue
            seen.add(p)
            hits.append(p)
        for p in d.rglob("*.xsl"):
            if p in seen or "node_modules" in p.parts:
                continue
            seen.add(p)
            hits.append(p)
    if names:
        want = {n.lower() for n in names}
        for p in hits:
            if p.name.lower() in want:
                return p.name, p.read_text(encoding="utf-8", errors="replace")
    if hits:
        p = hits[0]
        return p.name, p.read_text(encoding="utf-8", errors="replace")
    return None


def xslt_highlight_lines(text: str) -> list[int]:
    hot: list[int] = []
    keys = (
        "for-each",
        "xsl:template",
        "xsl:choose",
        "xsl:if",
        "xsl:value-of",
        "xsl:attribute",
        "match=",
        "select=",
    )
    for i, line in enumerate(text.splitlines(), start=1):
        low = line.lower()
        if any(k in low for k in keys):
            hot.append(i)
    return hot[:40]


def _human_xpath(expr: str) -> str:
    names = re.findall(r"local-name\(\)\s*=\s*['\"]([^'\"]+)['\"]", expr or "")
    if names:
        return names[-1]
    vars_ = re.findall(r"\$([A-Za-z_]\w*)", expr or "")
    if vars_:
        return vars_[-1]
    paths = re.findall(r"//([A-Za-z_][\w.-]*)", expr or "")
    if paths:
        return paths[-1]
    step = (expr or "").strip("/").split("/")[-1]
    step = re.sub(r"^@+", "", step)
    step = re.sub(r"\[.*", "", step)
    step = re.sub(r"[^A-Za-z0-9_.-].*$", "", step)
    if step in {"", ".", "text()", "*"}:
        return ""
    return step


def xslt_talking_points(text: str) -> str:
    """One spoken sentence from the stylesheet — no for-each / $var dumps."""
    bits: list[str] = []
    if re.search(r"method\s*=\s*['\"]text['\"]", text or "", flags=re.I):
        if re.search(r"2100", text or ""):
            bits.append("The stylesheet writes a 2100-character fixed-width text record.")
        elif re.search(r"json", text or "", flags=re.I):
            bits.append("The stylesheet writes JSON as text.")
        else:
            bits.append("The stylesheet writes a text record instead of XML.")
        return " ".join(bits)
    shown: list[str] = []
    for v in re.findall(r'value-of[^>]*select="([^"]+)"', text or "", flags=re.I):
        if re.match(r"^\$[A-Za-z_]\w*$", (v or "").strip()):
            continue
        h = _human_xpath(v)
        if not h or re.match(r"^[a-z]\d+$", h) or h in shown:
            continue
        shown.append(h)
        if len(shown) >= 3:
            break
    if shown:
        bits.append("It maps " + ", ".join(shown) + ".")
    return " ".join(bits)


def detect_demo_test(url: str, demo: Path) -> dict | None:
    """Live Demo-tab test: file inject, or insert-row (SQL poll demos)."""
    base = url.rstrip("/") + "/"
    html = _text(demo / "webui" / "templates" / "index.html")
    has_inject = "inject-form" in html or 'id="inject"' in html
    has_insert = 'id="insert-form"' in html or 'id="insert-btn"' in html
    if not has_inject and not has_insert:
        return None
    health: dict = {}
    try:
        with urlopen(base + "api/health", timeout=4) as resp:
            parsed = json.loads(resp.read().decode("utf-8", errors="replace"))
            if isinstance(parsed, dict):
                health = parsed
    except (URLError, OSError, TimeoutError, json.JSONDecodeError):
        pass
    results_h2 = ""
    for panel_id in ("results", "export", "captures"):
        hm = re.search(
            rf'id="{panel_id}"[\s\S]{{0,400}}?<h2>(.*?)</h2>',
            html,
            flags=re.I,
        )
        if hm:
            results_h2 = _clean_html(hm.group(1))
            if panel_id == "export" or results_h2:
                break
    has_sql = (
        bool(health.get("db_ok"))
        or has_insert
        or bool(re.search(r"sql|database|captures", results_h2, re.I))
    )
    has_queue = bool(re.search(r"rabbit|queue", results_h2, re.I)) or any(
        "rabbit" in s["name"].lower() for s in load_compose_systems(demo)
    )
    has_ftp = bool(re.search(r"sftp|ftp", html, re.I)) or any(
        "sftp" in s["name"].lower() or "ftp" in s["name"].lower()
        for s in load_compose_systems(demo)
    )
    if has_insert and not has_inject:
        export_h2 = ""
        em = re.search(r'id="export"[\s\S]{0,400}?<h2>(.*?)</h2>', html, flags=re.I)
        if em:
            export_h2 = _clean_html(em.group(1))
        return {
            "sample": "insert-row",
            "samples": ["insert-row"],
            "mode": "insert",
            "has_sql": True,
            "has_ftp": False,
            "has_queue": False,
            "results_label": export_h2 or results_h2 or "XML export",
            "sftp_hint": str(health.get("sftp_hint") or ""),
        }
    samples = None
    try:
        with urlopen(base + "api/samples", timeout=4) as resp:
            samples = json.loads(resp.read().decode("utf-8", errors="replace"))
    except Exception:
        samples = None
    if not isinstance(samples, dict):
        sample_dir = demo / "samples"
        if not sample_dir.is_dir():
            return None
        names = [
            p.name
            for p in sorted(sample_dir.iterdir())
            if p.is_file() and not p.name.startswith(".")
        ]
        if not names:
            return None
        samples = {"files": [{"name": n} for n in names]}
    files = samples.get("files") if isinstance(samples, dict) else None
    if not isinstance(files, list) or not files:
        return None
    names = [str(f.get("name") or "") for f in files if isinstance(f, dict)]
    names = [n for n in names if n]
    if not names:
        return None
    # A couple of live tests: two different samples when they exist, else the same one twice.
    picked = names[:2] if len(names) >= 2 else [names[0], names[0]]
    return {
        "sample": picked[0],
        "samples": picked,
        "has_sql": has_sql,
        "has_ftp": has_ftp,
        "has_queue": has_queue,
        "results_label": results_h2 or "Results",
        "sftp_hint": str(health.get("sftp_hint") or ""),
    }


def logo_data_uri(demo: Path | None = None) -> str:
    """Inline PilotFish logo so the welcome card never depends on a missing static file."""
    candidates: list[Path] = []
    if demo is not None:
        candidates.append(demo / "webui" / "static" / "pilotfish-logo.jpg")
    candidates.append(
        Path(__file__).resolve().parents[1] / "Clients" / "Demos" / "_shared" / "webui" / "static" / "pilotfish-logo.jpg"
    )
    for path in candidates:
        if path.is_file():
            b64 = base64.b64encode(path.read_bytes()).decode("ascii")
            return f"data:image/jpeg;base64,{b64}"
    return "/static/pilotfish-logo.jpg"
