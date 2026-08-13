#!/usr/bin/env python3
"""Copy PilotFish module deep-dive PDFs into a demo's documents/module-docs/.

Scans V1 route.xml + V2 modules/*.xml for Listener / Processor / Transport /
Routing classes used by the interface, resolves deep-dive PDFs from the
external PilotFish Documentation library, and keeps the demo copy in sync.

Usage (from demo root or Sandbox root):
  python3 tools/sync_module_docs.py
  python3 tools/sync_module_docs.py --root Clients/Demos/ftp-named-download-trigger
  python3 tools/sync_module_docs.py --all-demos
  python3 tools/sync_module_docs.py --dry-run

Playbook: run after route changes (and convert_routes_to_v2). Also invoked
automatically by tools/run_interface_tests.py when routes change.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

from demo_paths import iter_demo_roots, require_demo

SANDBOX = Path(__file__).resolve().parents[1]
DEMOS = SANDBOX / "Clients" / "Demos"
DOC_ROOT = Path("/Users/brianhannan/Documents/PilotFish Documentation")
DOC_DOCS = DOC_ROOT / "Documents"
INVENTORY = DOC_DOCS / "General" / "Process" / "module-inventory-26R1.11.json"
TRACKER_SCRIPT = DOC_ROOT / "war-pipeline" / "scripts" / "rebuild-module-tracker.py"
DOC_LOCATION_PTR = SANDBOX / "PilotFish_Documentation" / "DOCUMENTATION_LOCATION.txt"

VERSION_PREF = ("26R1.11", "23R1.127", "Custom", "XCS", "25R1.43", "24R1.132", "22R1.211")

# V2 / route display names that differ from inventory UI types
TYPE_ALIASES: dict[str, str] = {
    "Transaction Attribute Population": "Attribute Population",
    "NULL": "NULL Transport",
    "Null": "NULL Transport",
    "Directory / File Transport": "Directory / File",
    "FTPListener": "FTP / SFTP",
    "OciObjectStorageTransport": "OciObjectStorageTransport",
}

# Short class → (kind, ui_type) when inventory omits the module
CLASS_FALLBACKS: dict[str, tuple[str, str]] = {
    "TransactionAttributePopulationProcessor": ("Processor", "Attribute Population"),
    "ListenerTriggeringProcessor": ("Processor", "Listener Trigger"),
    "SaveDataToAttributeProcessor": ("Processor", "Data Attribute Swapper"),
    "NullTransport": ("Transport", "NULL Transport"),
    "DirectoryListener": ("Listener", "Directory / File"),
    "DirectoryTransport": ("Transport", "Directory / File"),
    "FTPListener": ("Listener", "FTP / SFTP"),
    "FTPTransport": ("Transport", "FTP / SFTP"),
    "FileWriteProcessor": ("Processor", "File Writing"),
    "XSLTProcessor": ("Processor", "XSLT Transformation"),
    "EDITransformationProcessor": ("Processor", "EDI"),
    "EdiSNIPValidationProcessor": ("Processor", "EDI SNIP Validation"),
    "XPathEvaluatorProcessor": ("Processor", "XPath Evaluation"),
    "XPathForkingProcessor": ("Processor", "XPath"),
    "EIPTransport": ("Transport", "Route to Route"),
    "ConditionalNodeRoutingModule": ("Routing", "Conditional Node Router"),
    "XPathRoutingModule": ("Routing", "Conditional Node Router"),
    "DatabaseSqlListener": ("Listener", "Database Polling (SQL)"),
    "DatabaseSqlTransport": ("Transport", "Database (SQL)"),
    "TriggerableListener": ("Listener", "Programmable (Trigger)"),
    "HL7TCPListener": ("Listener", "HL7 LLP"),
    "RESTfulWebServiceListener": ("Listener", "RESTful Web Service"),
    "CSVTransformationProcessor": ("Processor", "CSV"),
    "JSONTransformationProcessor": ("Processor", "JSON"),
}

# Modules whose deep-dive is a Guide PDF rather than *-Reference-*.pdf
GUIDE_FALLBACKS: dict[str, str] = {
    # Relative to Documents/
    "CSVTransformationProcessor": "Listeners/26R1.11/PilotFish-CSV-XML-Guide-26R1.11.pdf",
    "JSONTransformationProcessor": "Processors/26R1.11/PilotFish-JSON-Formatting-Reference-26R1.11.pdf",
}

# Format / plumbing modules with no deep-dive PDF (skip quietly)
SKIP_FQCN = {
    "com.pilotfish.eip.modules.internal.NullRoutingModule",
    "com.pilotfish.eip.modules.internal.NullJoinModule",
    "com.pilotfish.eip.modules.internal.NullForkModule",
    "com.pilotfish.eip.modules.internal.RelayTransformationModule",
    "com.pilotfish.eip.modules.internal.NullTransformationModule",
}

SKIP_SHORT = {c.rsplit(".", 1)[-1] for c in SKIP_FQCN}

KIND_FROM_TAG = {
    "Listener": "Listener",
    "Processor": "Processor",
    "Transport": "Transport",
    "Routing": "Routing",
    "RoutingModule": "Routing",
    "Transformation": "Processor",
    "Join": "Processor",
    "Fork": "Processor",
}


@dataclass
class ModuleRef:
    fqcn: str
    kind: str | None = None
    ui_type: str | None = None
    sources: list[str] = field(default_factory=list)


@dataclass
class SyncResult:
    demo: str
    copied: list[str] = field(default_factory=list)
    unchanged: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)
    removed: list[str] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)


def local(tag: str) -> str:
    return tag.split("}")[-1] if "}" in tag else tag


def load_slug_map() -> dict[tuple[str, str], str]:
    if not TRACKER_SCRIPT.is_file():
        return {}
    spec = importlib.util.spec_from_file_location("pf_tracker", TRACKER_SCRIPT)
    if spec is None or spec.loader is None:
        return {}
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    raw = getattr(mod, "SLUG_MAP", {}) or {}
    return {(k[0], k[1]): v for k, v in raw.items()}


def load_inventory() -> tuple[dict[str, dict], dict[str, dict]]:
    """Return (by_fqcn, by_short_class) from module inventory."""
    by_fqcn: dict[str, dict] = {}
    by_short: dict[str, dict] = {}
    if not INVENTORY.is_file():
        return by_fqcn, by_short
    data = json.loads(INVENTORY.read_text(encoding="utf-8"))
    for m in data.get("modules") or []:
        fqcn = m.get("fqcn") or ""
        short = m.get("class") or (fqcn.rsplit(".", 1)[-1] if fqcn else "")
        if fqcn:
            by_fqcn[fqcn] = m
        if short and short not in by_short:
            by_short[short] = m
    return by_fqcn, by_short


def build_pdf_index(slug_map: dict[tuple[str, str], str]) -> dict[tuple[str, str], dict[str, Path]]:
    """(kind, ui_type) → {version: Path}."""
    index: dict[tuple[str, str], dict[str, Path]] = {}
    if not DOC_DOCS.is_dir():
        return index
    slug_to_keys: dict[str, list[tuple[str, str]]] = {}
    for key, slug in slug_map.items():
        slug_to_keys.setdefault(slug, []).append(key)

    folder_kind = {
        "Listeners": "Listener",
        "Processors": "Processor",
        "Transports": "Transport",
        "Routing": "Routing",
    }
    for pdf in DOC_DOCS.rglob("PilotFish-*-Reference*.pdf"):
        parts = pdf.relative_to(DOC_DOCS).parts
        if len(parts) < 2:
            continue
        kind = folder_kind.get(parts[0])
        if not kind:
            continue
        m = re.match(r"PilotFish-(.+)-Reference(?:-(.+))?$", pdf.stem)
        if not m:
            continue
        slug, ver_name = m.group(1), m.group(2)
        ver = parts[1] if re.match(r"^(XCS|\d{2}R\d|Custom)", parts[1]) else (ver_name or "XCS")
        if "Custom" in pdf.name:
            ver = "Custom"
        keys = [k for k in slug_to_keys.get(slug, []) if k[0] == kind]
        if not keys:
            # Heuristic: match any SLUG_MAP entry with same slug + kind
            keys = [(knd, typ) for (knd, typ), s in slug_map.items() if knd == kind and s == slug]
        for key in keys:
            index.setdefault(key, {})[ver] = pdf
    return index


def normalize_ui_type(ui_type: str | None, kind: str | None) -> str | None:
    if not ui_type:
        return None
    t = TYPE_ALIASES.get(ui_type, ui_type)
    if kind == "Transport" and t == "NULL":
        return "NULL Transport"
    if kind == "Processor" and t == "Transaction Attribute Population":
        return "Attribute Population"
    return t


def infer_kind_from_fqcn(fqcn: str) -> str | None:
    short = fqcn.rsplit(".", 1)[-1]
    if short.endswith("Listener"):
        return "Listener"
    if short.endswith("Transport"):
        return "Transport"
    if "Routing" in short or short.endswith("Router"):
        return "Routing"
    if short.endswith("Processor") or short.endswith("Module"):
        return "Processor"
    return None


def pick_pdf(
    kind: str,
    ui_type: str,
    index: dict[tuple[str, str], dict[str, Path]],
) -> Path | None:
    vers = index.get((kind, ui_type)) or {}
    for pref in VERSION_PREF:
        if pref in vers:
            return vers[pref]
    if vers:
        return next(iter(vers.values()))
    return None


def file_sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_from_xml(path: Path, refs: dict[str, ModuleRef]) -> None:
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError:
        return

    def add(fqcn: str, kind: str | None, ui_type: str | None) -> None:
        fqcn = (fqcn or "").strip()
        if not fqcn or not fqcn.startswith("com.pilotfish"):
            return
        if fqcn in SKIP_FQCN or fqcn.rsplit(".", 1)[-1] in SKIP_SHORT:
            return
        ref = refs.get(fqcn)
        if ref is None:
            ref = ModuleRef(fqcn=fqcn, kind=kind, ui_type=ui_type, sources=[str(path)])
            refs[fqcn] = ref
        else:
            if kind and not ref.kind:
                ref.kind = kind
            if ui_type and not ref.ui_type:
                ref.ui_type = ui_type
            src = str(path)
            if src not in ref.sources:
                ref.sources.append(src)

    for el in root.iter():
        tag = local(el.tag)
        cls = el.get("class") or ""
        if tag == "Module" and cls:
            kind = KIND_FROM_TAG.get(el.get("tag") or "", None) or infer_kind_from_fqcn(cls)
            add(cls, kind, el.get("type"))
            continue
        if tag in {"Listener", "Processor", "Transport", "RoutingModule", "TransformationModule"} and cls:
            kind = {
                "Listener": "Listener",
                "Processor": "Processor",
                "Transport": "Transport",
                "RoutingModule": "Routing",
                "TransformationModule": "Processor",
            }.get(tag)
            add(cls, kind, el.get("type"))


def discover_route_xmls(demo_root: Path) -> list[Path]:
    out: list[Path] = []
    for base in (
        demo_root / "eip-root",
        demo_root / "pilotfish" / "demo-eip-root",
    ):
        if not base.is_dir():
            continue
        for name in ("route.xml", "route.v2.xml"):
            out.extend(base.rglob(name))
        out.extend(base.rglob("modules/*.xml"))
    # de-dupe
    seen: set[Path] = set()
    uniq: list[Path] = []
    for p in out:
        rp = p.resolve()
        if rp in seen:
            continue
        seen.add(rp)
        uniq.append(p)
    return uniq


def resolve_module(
    ref: ModuleRef,
    by_fqcn: dict[str, dict],
    by_short: dict[str, dict],
    slug_map: dict[tuple[str, str], str] | None = None,
) -> tuple[str, str] | None:
    short = ref.fqcn.rsplit(".", 1)[-1]
    m = by_fqcn.get(ref.fqcn) or by_short.get(short)
    kind = (m or {}).get("kind") or ref.kind or infer_kind_from_fqcn(ref.fqcn)
    ui = normalize_ui_type((m or {}).get("type") or ref.ui_type, kind)

    def ok(k: str | None, u: str | None) -> bool:
        if not k or not u:
            return False
        if slug_map is not None:
            return (k, u) in slug_map
        return True

    if ok(kind, ui):
        return kind, ui  # type: ignore[return-value]
    if short in CLASS_FALLBACKS:
        return CLASS_FALLBACKS[short]
    if kind and ui:
        return kind, ui
    return None


def dest_name(kind: str, ui_type: str, src: Path) -> str:
    # Keep source filename so versions stay visible
    return src.name


def sync_demo(
    demo_root: Path,
    *,
    dry_run: bool = False,
    slug_map: dict[tuple[str, str], str] | None = None,
    pdf_index: dict[tuple[str, str], dict[str, Path]] | None = None,
    by_fqcn: dict[str, dict] | None = None,
    by_short: dict[str, dict] | None = None,
) -> SyncResult:
    demo_root = demo_root.resolve()
    result = SyncResult(demo=demo_root.name)
    if slug_map is None:
        slug_map = load_slug_map()
    if pdf_index is None:
        pdf_index = build_pdf_index(slug_map)
    if by_fqcn is None or by_short is None:
        by_fqcn, by_short = load_inventory()

    refs: dict[str, ModuleRef] = {}
    for xml in discover_route_xmls(demo_root):
        collect_from_xml(xml, refs)

    out_dir = demo_root / "documents" / "module-docs"
    if not dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)

    wanted_files: set[str] = set()
    manifest_modules: list[dict] = []

    for fqcn, ref in sorted(refs.items(), key=lambda x: x[0]):
        resolved = resolve_module(ref, by_fqcn or {}, by_short or {}, slug_map)
        if not resolved:
            result.missing.append(f"{fqcn} (unresolved kind/type)")
            continue
        kind, ui_type = resolved
        short = ref.fqcn.rsplit(".", 1)[-1]
        pdf = pick_pdf(kind, ui_type, pdf_index or {})
        if (pdf is None or not pdf.is_file()) and short in GUIDE_FALLBACKS:
            guide = DOC_DOCS / GUIDE_FALLBACKS[short]
            if guide.is_file():
                pdf = guide
        if pdf is None or not pdf.is_file():
            result.missing.append(f"{kind}|{ui_type} ({fqcn})")
            manifest_modules.append(
                {
                    "fqcn": fqcn,
                    "kind": kind,
                    "ui_type": ui_type,
                    "pdf": None,
                    "status": "missing",
                }
            )
            continue
        name = dest_name(kind, ui_type, pdf)
        wanted_files.add(name)
        dest = out_dir / name
        entry = {
            "fqcn": fqcn,
            "kind": kind,
            "ui_type": ui_type,
            "pdf": f"module-docs/{name}",
            "source": str(pdf.relative_to(DOC_DOCS)) if pdf.is_relative_to(DOC_DOCS) else str(pdf),
            "status": "ok",
        }
        manifest_modules.append(entry)
        if dry_run:
            result.copied.append(name)
            continue
        if dest.is_file() and file_sha256(dest) == file_sha256(pdf):
            result.unchanged.append(name)
        else:
            shutil.copy2(pdf, dest)
            result.copied.append(name)

    # Remove stale PDFs previously synced but no longer used
    if out_dir.is_dir() and not dry_run:
        for existing in out_dir.glob("PilotFish-*-Reference*.pdf"):
            if existing.name not in wanted_files:
                existing.unlink()
                result.removed.append(existing.name)

    # Also drop orphaned INDEX leftovers handled below
    manifest = {
        "version": 1,
        "demo": demo_root.name,
        "path": str(demo_root.relative_to(SANDBOX)) if demo_root.is_relative_to(SANDBOX) else str(demo_root),
        "synced_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "documentation_root": str(DOC_DOCS),
        "modules": sorted(manifest_modules, key=lambda m: (m.get("kind") or "", m.get("ui_type") or "", m["fqcn"])),
        "missing": list(result.missing),
        "note": "Auto-synced from route.xml / modules/*.xml. Re-run tools/sync_module_docs.py after route changes.",
    }

    if not dry_run:
        (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        index_lines = [
            f"# Module documentation — `{demo_root.name}`",
            "",
            "Deep-dive PDFs for every PilotFish module used by this interface.",
            f"Synced `{manifest['synced_at']}` from `{DOC_DOCS}`.",
            "",
            "Re-sync after route changes:",
            "",
            "```bash",
            f"python3 tools/sync_module_docs.py --root {demo_root.relative_to(SANDBOX) if demo_root.is_relative_to(SANDBOX) else demo_root}",
            "```",
            "",
            "| Kind | UI type | PDF | Class |",
            "|------|---------|-----|-------|",
        ]
        for m in manifest["modules"]:
            pdf = m.get("pdf") or "*(missing)*"
            if pdf and not pdf.startswith("*"):
                pdf = f"[`{Path(pdf).name}`]({Path(pdf).name})"
            index_lines.append(
                f"| {m.get('kind') or ''} | {m.get('ui_type') or ''} | {pdf} | `{m['fqcn'].rsplit('.', 1)[-1]}` |"
            )
        if result.missing:
            index_lines.extend(["", "## Missing", ""])
            for miss in result.missing:
                index_lines.append(f"- {miss}")
        (out_dir / "INDEX.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")

    return result


def find_demo_roots() -> list[Path]:
    roots: list[Path] = []
    for d in iter_demo_roots():
        if (d / "eip-root").is_dir() or (d / "pilotfish" / "demo-eip-root").is_dir():
            roots.append(d)
    return roots


def resolve_doc_root_from_pointer() -> None:
    global DOC_ROOT, DOC_DOCS, INVENTORY, TRACKER_SCRIPT
    if DOC_DOCS.is_dir():
        return
    if DOC_LOCATION_PTR.is_file():
        for line in DOC_LOCATION_PTR.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("/") and Path(line).is_dir():
                DOC_ROOT = Path(line)
                DOC_DOCS = DOC_ROOT / "Documents"
                INVENTORY = DOC_DOCS / "General" / "Process" / "module-inventory-26R1.11.json"
                TRACKER_SCRIPT = DOC_ROOT / "war-pipeline" / "scripts" / "rebuild-module-tracker.py"
                break


def print_result(r: SyncResult) -> None:
    print(f"[{r.demo}] copied={len(r.copied)} unchanged={len(r.unchanged)} "
          f"removed={len(r.removed)} missing={len(r.missing)}")
    for name in r.copied:
        print(f"  + {name}")
    for name in r.removed:
        print(f"  - {name}")
    for miss in r.missing:
        print(f"  ! missing {miss}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=None, help="Demo root (default: cwd if a demo)")
    parser.add_argument("--all-demos", action="store_true", help="Sync every Clients/Demos/* interface")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    resolve_doc_root_from_pointer()
    if not DOC_DOCS.is_dir():
        print(f"ERROR: PilotFish Documentation not found at {DOC_DOCS}", file=sys.stderr)
        print("See PilotFish_Documentation/DOCUMENTATION_LOCATION.txt", file=sys.stderr)
        return 2

    slug_map = load_slug_map()
    if not slug_map:
        print("WARNING: SLUG_MAP empty — PDF matching may fail", file=sys.stderr)
    pdf_index = build_pdf_index(slug_map)
    by_fqcn, by_short = load_inventory()

    roots: list[Path] = []
    if args.all_demos:
        roots = find_demo_roots()
    elif args.root:
        roots = [require_demo(args.root)]
    else:
        cwd = Path.cwd().resolve()
        if (cwd / "eip-root").is_dir() or (cwd / "documents").is_dir():
            roots = [cwd]
        else:
            print("Pass --root <demo> or --all-demos (or run from a demo directory).", file=sys.stderr)
            return 2

    rc = 0
    for root in roots:
        if not root.is_dir():
            print(f"ERROR: not a directory: {root}", file=sys.stderr)
            rc = 1
            continue
        result = sync_demo(
            root,
            dry_run=args.dry_run,
            slug_map=slug_map,
            pdf_index=pdf_index,
            by_fqcn=by_fqcn,
            by_short=by_short,
        )
        print_result(result)
        if result.missing:
            rc = max(rc, 0)  # missing docs are warnings, not hard failures
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
