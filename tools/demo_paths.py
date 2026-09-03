#!/usr/bin/env python3
"""Resolve Sandbox demos under Clients/Demos even when they live in category folders.

Layout (folder name = slug, unchanged for Compose project names):

  Clients/Demos/
    _shared/                 shared Web UI chrome
    Insurance/EDI/           X12 270/271, 276/277, 278, 834, 835, 837, 999
    Medical/HL7/             HL7 LLP, device, hospital, doc workflow
    Medical/FHIR/            FHIR R4
    Other/                   CSV, FTP, HTTP, SQL, RabbitMQ, smoke

Tools should resolve by **slug** (`csv-sftp-to-sql`) or any path under Clients/Demos/.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEMOS = ROOT / "Clients" / "Demos"

# Destination relative to Clients/Demos/ → slugs
CATEGORY_LAYOUT: dict[str, tuple[str, ...]] = {
    "Insurance/EDI": (
        "edi-270-271-eligibility",
        "edi-270-271-realtime",
        "edi-276-277-claim-status",
        "edi-278-prior-auth",
        "edi-835-oci-bucket",
        "edi-835-payment-integrity",
        "edi-837-claim-scrub",
        "edi-837-snip-sqlserver",
        "edi-837p-qcare",
        "edi-999-ta1-ack-triage",
        "xml-to-edi-834",
    ),
    "Medical/HL7": (
        "doc-healthcare-hl7-workflow",
        "hl7-healthcare-automation",
        "medical-device-hl7-ehr",
        "medical-lab-hl7-llp",
        "hl7-interface-engine-demo",
        "healthcare-reporting-analytics-demo",
    ),
    "Medical/FHIR": ("fhir-r4-platform",),
    "Other": (
        "csv-sftp-to-sql",
        "csv-to-json",
        "ftp-named-download-trigger",
        "http-post-to-rabbitmq",
        "sqlserver-pilotfish-demo",
        "triggered-ftp-download",
    ),
}

_SKIP_PARTS = {"_shared", "_incoming", "node_modules", "documents", "build-replay"}


def infer_category(slug: str) -> str:
    slug = (slug or "").strip()
    for cat, names in CATEGORY_LAYOUT.items():
        if slug in names:
            return cat
    s = slug.lower()
    if s.startswith("edi-") or s.startswith("xml-to-edi"):
        return "Insurance/EDI"
    if "hl7" in s or s.startswith("medical-") or s.startswith("doc-healthcare"):
        return "Medical/HL7"
    if s.startswith("fhir-"):
        return "Medical/FHIR"
    return "Other"


def is_demo_root(path: Path) -> bool:
    if not path.is_dir() or path.name.startswith("_"):
        return False
    try:
        rel = path.relative_to(DEMOS)
        if any(p.startswith("_") or p in _SKIP_PARTS for p in rel.parts[:-1]):
            return False
    except ValueError:
        pass
    return (
        (path / "docker-compose.yml").is_file()
        or (path / "DESIGN.md").is_file()
        or (path / "eip-root").is_dir()
        or (path / "pilotfish" / "demo-eip-root").is_dir()
    )


def iter_demo_roots() -> list[Path]:
    if not DEMOS.is_dir():
        return []
    found: list[Path] = []
    for compose in DEMOS.rglob("docker-compose.yml"):
        rel = compose.relative_to(DEMOS)
        if any(part.startswith("_") or part in _SKIP_PARTS for part in rel.parts[:-1]):
            continue
        root = compose.parent
        if is_demo_root(root):
            found.append(root)
    for design in DEMOS.rglob("DESIGN.md"):
        rel = design.relative_to(DEMOS)
        if any(part.startswith("_") or part in _SKIP_PARTS for part in rel.parts[:-1]):
            continue
        root = design.parent
        if is_demo_root(root):
            found.append(root)
    for eip in DEMOS.rglob("eip-root"):
        if not eip.is_dir() or eip.name != "eip-root":
            continue
        rel = eip.relative_to(DEMOS)
        if any(part.startswith("_") or part in _SKIP_PARTS for part in rel.parts[:-1]):
            continue
        root = eip.parent
        if is_demo_root(root):
            found.append(root)
    return sorted({p.resolve() for p in found}, key=lambda p: p.as_posix())


def find_enclosing_demo(start: Path) -> Path | None:
    cur = start.expanduser().resolve()
    for _ in range(16):
        if is_demo_root(cur):
            return cur
        if cur == DEMOS or cur.parent == cur:
            return None
        cur = cur.parent
    return None


def resolve_demo(raw: str | Path | None = None) -> Path | None:
    """Find a demo by path, repo-relative path, or slug (folder name)."""
    if raw is None or str(raw).strip() == "":
        return find_enclosing_demo(Path.cwd())
    text = str(raw).strip().rstrip("/")
    cand = Path(text).expanduser()
    options = []
    if cand.exists():
        options.append(cand.resolve())
    rooted = (ROOT / text).resolve()
    if rooted.exists() and rooted not in options:
        options.append(rooted)
    for path in options:
        if is_demo_root(path):
            return path
        enclosed = find_enclosing_demo(path)
        if enclosed:
            return enclosed
    slug = Path(text).name.lower()
    hits = [p for p in iter_demo_roots() if p.name.lower() == slug]
    if len(hits) == 1:
        return hits[0]
    if not hits:
        hits = [
            p
            for p in iter_demo_roots()
            if slug in p.name.lower() and not p.name.startswith("_")
        ]
        if len(hits) == 1:
            return hits[0]
    return None


def require_demo(raw: str | Path | None = None) -> Path:
    found = resolve_demo(raw)
    if found is None:
        known = ", ".join(p.name for p in iter_demo_roots()) or "(none)"
        raise SystemExit(f"Unknown demo {raw!r}. Known slugs: {known}")
    return found
