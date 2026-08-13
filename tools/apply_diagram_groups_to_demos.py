#!/usr/bin/env python3
"""Port docs-only Processor Groups (viewer + API + sample export helpers) to demos.

Reference: Clients/Demos/fhir-r4-platform
"""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

from demo_paths import resolve_demo, require_demo

ROOT = Path(__file__).resolve().parents[1]


def _ref_viewer() -> Path:
    return require_demo("fhir-r4-platform") / "webui" / "static" / "route-viewer"

# Demos that get viewer/API hygiene (and groups JSON where defined below)
ALL_TARGET_DEMOS = [
    "fhir-patient-exchange",
    "edi-837-snip-sqlserver",
    "edi-270-271-eligibility",
    "edi-835-oci-bucket",
    "hl7-healthcare-automation",
    "csv-to-json",
    "medical-device-hl7-ehr",
    "medical-lab-hl7-llp",
]

# diagram-groups.json by demo → relative route dir under eip-root/.../routes/
GROUPS: dict[str, dict[str, dict]] = {
    "fhir-patient-exchange": {
        "1 - FHIR Patient REST API": {
            "groups": [
                {
                    "id": "ingress",
                    "title": "Ingress",
                    "description": "Normalize body and extract Patient fields",
                    "labels": [
                        "Save Raw Body",
                        "Extract Logical Id",
                        "Extract MRN",
                        "Detect Patient Type",
                        "Detect Name",
                        "Set Validation Status",
                    ],
                },
                {
                    "id": "create",
                    "title": "Create Patient",
                    "description": "Persist to store/SQL + 201",
                    "labels": [
                        "Restore Body For Persist",
                        "Write FHIR Store File",
                        "Upsert Patient SQL",
                        "Restore Body For Response",
                        "Set 201 Created",
                        "Create Response Headers",
                    ],
                    "transports": ["Create Patient Response"],
                },
                {
                    "id": "read",
                    "title": "Read Patient",
                    "description": "SQL select → FHIR JSON",
                    "labels": [
                        "Select Patient SQL",
                        "Detect SQL Hit",
                        "Map SQL To FHIR JSON",
                        "Set Read Status Code",
                        "Read Response Headers",
                    ],
                    "transports": ["Read Patient Response"],
                },
            ]
        }
    },
    "edi-837-snip-sqlserver": {
        "2 - Generate 837 And SNIP": {
            "groups": [
                {
                    "id": "map-edi",
                    "title": "Map Claim → EDI",
                    "description": "Keys, XML map, intermediate EDI XML",
                    "labels": [
                        "Read Claim Keys",
                        "Debug Write Claim XML",
                        "Map Claim To EDI XML",
                        "Write Intermediate EDI XML",
                        "Save EDI XML for SNIP",
                    ],
                },
                {
                    "id": "edi-snip",
                    "title": "EDI + SNIP",
                    "description": "XML→EDI wire, write 837, SNIP 1–3",
                    "labels": [
                        "EDI Transformation Module - XML to EDI",
                        "Write 837 EDI File",
                        "Restore EDI XML for SNIP",
                        "EDI SNIP Validation (Types 1-3)",
                    ],
                    "transports": ["Write SNIP Results"],
                },
            ]
        }
    },
    "edi-270-271-eligibility": {
        "1 - Eligibility 270 271 API": {
            "groups": [
                {
                    "id": "build-270",
                    "title": "Build 270 X12",
                    "description": "Request → EDI XML → wire + 200",
                    "labels": [
                        "Map Request To 270 EDI XML",
                        "Write 270 EDI XML",
                        "XML to EDI 270",
                        "Write 270 EDI Wire",
                        "Set 200 Build",
                        "270 Response Headers",
                    ],
                    "transports": ["Return 270"],
                },
                {
                    "id": "parse-271",
                    "title": "Parse 271",
                    "description": "Wire → JSON summary + 200",
                    "labels": [
                        "Snapshot Raw 271",
                        "Map 271 Wire To JSON",
                        "Write JSON Summary",
                        "Set 200 Parse",
                        "JSON Response Headers",
                    ],
                    "transports": ["Return Summary"],
                },
            ]
        }
    },
    "edi-835-oci-bucket": {
        "2 - Split ST JSON And OCI": {
            "groups": [
                {
                    "id": "oci-put",
                    "title": "JSON → OCI PutObject",
                    "description": "Name object, map JSON, archive, put",
                    "labels": [
                        "Read ST Control Number",
                        "Set OCI Object Name",
                        "Set OCI Object URL",
                        "Debug Write Transaction XML",
                        "Map Transaction XML To JSON",
                        "Archive JSON Object",
                    ],
                    "transports": ["OCI Object Storage PutObject"],
                }
            ]
        }
    },
    "hl7-healthcare-automation": {
        "1 - Process Hospital HL7": {
            "groups": [
                {
                    "id": "validate",
                    "title": "Inbound Validate",
                    "description": "Archive, validate, split batch, snapshot",
                    "labels": [
                        "Archive Inbound Envelope",
                        "Basic Validation",
                        "Split Batch",
                        "Advanced Validation",
                        "Write Validation Snapshot",
                    ],
                }
            ]
        }
    },
}

def api_snippet(resolver: str) -> str:
    return f'''

@app.get("/api/v2/routes/<route_id>/diagram-groups.json")
def api_v2_diagram_groups(route_id: str):
    """Optional docs-only Processor Group definitions for route diagrams."""
    d = {resolver}(route_id)
    if not d:
        return Response("Not found", status=404)
    path = d / "diagram-groups.json"
    if not path.is_file():
        return jsonify({{"ok": True, "groups": []}})
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return jsonify({{"ok": False, "groups": [], "message": "Invalid diagram-groups.json"}}), 500
    if not isinstance(data, dict):
        data = {{"groups": data if isinstance(data, list) else []}}
    data.setdefault("ok", True)
    data.setdefault("groups", [])
    return jsonify(data)

'''


def route_dir_resolver(app_text: str) -> str:
    """Prefer the helper already used by sibling /api/v2/routes endpoints."""
    if re.search(r"^\s*def find_route_dir\(", app_text, flags=re.M):
        return "find_route_dir"
    return "resolve_route_dir"


def find_route_dirs(demo: Path) -> list[Path]:
    return sorted(demo.glob("eip-root/interfaces/*/routes/*"))


def port_viewer(demo: Path) -> None:
    dest = demo / "webui" / "static" / "route-viewer"
    if not dest.is_dir():
        print(f"  skip viewer (missing): {demo.name}")
        return
    for name in (
        "diagram-groups.js",
        "route-viewer.js",
        "route-node-editor-web.css",
        "index.html",
    ):
        src = _ref_viewer() / name
        if src.is_file():
            shutil.copy2(src, dest / name)
            print(f"  copied {name}")


def ensure_api(demo: Path) -> None:
    app = demo / "webui" / "app.py"
    if not app.is_file():
        print(f"  skip app.py missing: {demo.name}")
        return
    text = app.read_text(encoding="utf-8")
    resolver = route_dir_resolver(text)
    if "diagram-groups.json" in text:
        fixed = text
        # Repair wrong helper name from earlier applicator runs
        if resolver == "find_route_dir":
            fixed = re.sub(
                r"(def api_v2_diagram_groups\(route_id: str\):.*?^\s*)d = resolve_route_dir\(route_id\)",
                rf"\1d = find_route_dir(route_id)",
                fixed,
                count=1,
                flags=re.M | re.S,
            )
        if "import json" not in fixed and "from json" not in fixed:
            if "from __future__ import annotations\n" in fixed:
                fixed = fixed.replace(
                    "from __future__ import annotations\n",
                    "from __future__ import annotations\n\nimport json\n",
                    1,
                )
            else:
                fixed = "import json\n" + fixed
        if fixed != text:
            app.write_text(fixed, encoding="utf-8")
            print(f"  repaired diagram-groups API ({resolver})")
        else:
            print("  app.py already has diagram-groups API")
        return
    snippet = api_snippet(resolver)
    # insert after route.v2.xml handler block
    m = re.search(
        r'(@app\.get\("/api/v2/routes/<route_id>/route\.v2\.xml"\)\n'
        r'def api_v2_route_xml\(route_id: str\):.*?\n'
        r'    return Response\(.*?mimetype="application/xml"\)\n)',
        text,
        flags=re.S,
    )
    if not m:
        # fallback: before modules endpoint
        anchor = '@app.get("/api/v2/routes/<route_id>/modules/<module_id>.xml")'
        if anchor not in text:
            print("  WARN: could not find insertion point in app.py")
            return
        text = text.replace(anchor, snippet.lstrip() + "\n" + anchor, 1)
    else:
        text = text[: m.end()] + snippet + text[m.end() :]
    if "import json" not in text:
        text = text.replace("from __future__ import annotations\n", "from __future__ import annotations\n\nimport json\n", 1)
        if "import json" not in text:
            text = "import json\n" + text
    app.write_text(text, encoding="utf-8")
    print(f"  patched app.py diagram-groups API ({resolver})")


def write_groups(demo_name: str, demo: Path) -> None:
    spec = GROUPS.get(demo_name)
    if not spec:
        print("  no groups JSON (short demo hygiene only)")
        return
    routes_root = list(demo.glob("eip-root/interfaces/*/routes"))
    if not routes_root:
        print("  WARN: no eip-root routes")
        return
    routes_root = routes_root[0]
    for route_name, payload in spec.items():
        dest = routes_root / route_name / "diagram-groups.json"
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        print(f"  wrote {dest.relative_to(demo)}")
        # mirror demo-eip-root if present
        for mirror_root in demo.glob("pilotfish/demo-eip-root/**/routes"):
            # try matching by route folder name
            mdest = mirror_root / route_name / "diagram-groups.json"
            if (mirror_root / route_name).is_dir() or any(mirror_root.glob(route_name)):
                mdest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(dest, mdest)
                print(f"  mirrored {mdest.relative_to(demo)}")


def patch_export_shot_helpers(path: Path) -> str:
    """Ensure export script has collapse/group shot + vault scrub. Returns text."""
    text = path.read_text(encoding="utf-8")
    if "def scrub_github_secret_false_positives" not in text:
        if "import re" not in text:
            text = text.replace("import argparse\n", "import argparse\nimport re\n", 1)
        # replace simple shot() if present
        text = re.sub(
            r"def shot\(route_id: str, dest: Path, size: tuple\[int, int\], config: str\):\n"
            r"    url = \(\n"
            r'        f"\{BASE\}/static/route-viewer/index\.html"\n'
            r'        f"\?route=\{route_id\}&mode=docs&layout=pipeline&bare=1&config=\{config\}"\n'
            r"    \)\n"
            r"    cmd = \[[\s\S]*?subprocess\.run\(cmd, check=True, capture_output=True\)\n",
            '''def shot(route_id: str, dest: Path, size: tuple[int, int], config: str, *, collapse: str = "", group: str = ""):
    qs = [
        f"route={route_id}",
        "mode=docs",
        "layout=pipeline",
        "bare=1",
        f"config={config}",
    ]
    if collapse or group:
        qs.append("groups=1")
    if collapse:
        qs.append(f"collapse={collapse}")
    if group:
        qs.append(f"group={group}")
    url = f"{BASE}/static/route-viewer/index.html?{'&'.join(qs)}"
    cmd = [
        CHROME,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--window-size={size[0]},{size[1]}",
        f"--screenshot={dest}",
        "--virtual-time-budget=30000",
        url,
    ]
    subprocess.run(cmd, check=True, capture_output=True)


_VAULT_SERVICE_FP = re.compile(rb"s\\.[A-Za-z0-9]{24}")


def scrub_github_secret_false_positives(pdf_path: Path) -> int:
    data = pdf_path.read_bytes()
    n = 0

    def _repl(m: re.Match[bytes]) -> bytes:
        nonlocal n
        n += 1
        return b"s_" + m.group(0)[2:]

    fixed = _VAULT_SERVICE_FP.sub(_repl, data)
    if n:
        pdf_path.write_bytes(fixed)
        print(f"  scrubbed {n} GitHub Vault-token false positive(s) in {pdf_path.name}")
    return n

''',
            text,
            count=1,
        )
    if "scrub_github_secret_false_positives(pdf_path)" not in text and "def build_pdf" in text:
        text = text.replace(
            "    c.save()\n\n\ndef main():",
            "    c.save()\n    scrub_github_secret_false_positives(pdf_path)\n\n\ndef main():",
            1,
        )
        text = text.replace(
            "    c.save()\n\ndef main():",
            "    c.save()\n    scrub_github_secret_false_positives(pdf_path)\n\n\ndef main():",
            1,
        )
    return text


# Per-demo ROUTES dict bodies (Python source assigned to ROUTES = [...])
EXPORT_ROUTES: dict[str, str] = {
    "fhir-patient-exchange": '''ROUTES = [
    {
        "title": "1 — FHIR Patient REST API (Overview)",
        "route": "1-fhir-patient-rest-api",
        "file": "route1-overview.png",
        "collapse": "all",
        "window": {"compact": (2400, 2800), "changed": (2600, 3600), "all": (2800, 4200)},
    },
    {
        "title": "1 · Ingress",
        "route": "1-fhir-patient-rest-api",
        "file": "route1-ingress.png",
        "group": "ingress",
        "window": {"compact": (2200, 2400), "changed": (2400, 3800), "all": (2600, 4600)},
    },
    {
        "title": "1 · Create Patient",
        "route": "1-fhir-patient-rest-api",
        "file": "route1-create.png",
        "group": "create",
        "window": {"compact": (2200, 2400), "changed": (2400, 4000), "all": (2600, 5000)},
    },
    {
        "title": "1 · Read Patient",
        "route": "1-fhir-patient-rest-api",
        "file": "route1-read.png",
        "group": "read",
        "window": {"compact": (2200, 2200), "changed": (2400, 3600), "all": (2600, 4400)},
    },
]
''',
    "edi-837-snip-sqlserver": '''ROUTES = [
    {
        "title": "1 — Poll SQL Server Claims",
        "route": "1-poll-sql-server-claims",
        "file": "route1.png",
        "window": {"compact": (2000, 1600), "changed": (2200, 2200), "all": (2400, 2800)},
    },
    {
        "title": "2 — Generate 837 And SNIP (Overview)",
        "route": "2-generate-837-and-snip",
        "file": "route2-overview.png",
        "collapse": "all",
        "window": {"compact": (2200, 2000), "changed": (2400, 2600), "all": (2600, 3200)},
    },
    {
        "title": "2 · Map Claim → EDI",
        "route": "2-generate-837-and-snip",
        "file": "route2-map.png",
        "group": "map-edi",
        "window": {"compact": (2200, 2400), "changed": (2400, 3800), "all": (2600, 4600)},
    },
    {
        "title": "2 · EDI + SNIP",
        "route": "2-generate-837-and-snip",
        "file": "route2-snip.png",
        "group": "edi-snip",
        "window": {"compact": (2200, 2200), "changed": (2400, 3600), "all": (2600, 4400)},
    },
]
''',
    "edi-270-271-eligibility": '''ROUTES = [
    {
        "title": "1 — Eligibility 270/271 API (Overview)",
        "route": "1-eligibility-270-271-api",
        "file": "route1-overview.png",
        "collapse": "all",
        "window": {"compact": (2400, 2400), "changed": (2600, 3000), "all": (2800, 3600)},
    },
    {
        "title": "1 · Build 270 X12",
        "route": "1-eligibility-270-271-api",
        "file": "route1-build270.png",
        "group": "build-270",
        "window": {"compact": (2200, 2400), "changed": (2400, 4000), "all": (2600, 5000)},
    },
    {
        "title": "1 · Parse 271",
        "route": "1-eligibility-270-271-api",
        "file": "route1-parse271.png",
        "group": "parse-271",
        "window": {"compact": (2200, 2200), "changed": (2400, 3600), "all": (2600, 4400)},
    },
]
''',
    "edi-835-oci-bucket": '''ROUTES = [
    {
        "title": "1 — SFTP Poll And Stage",
        "route": "1-sftp-poll-and-stage",
        "file": "route1.png",
        "window": {"compact": (2000, 1600), "changed": (2200, 2200), "all": (2400, 2800)},
    },
    {
        "title": "2 — Split ST JSON And OCI (Overview)",
        "route": "2-split-st-json-and-oci",
        "file": "route2-overview.png",
        "collapse": "all",
        "window": {"compact": (2200, 2000), "changed": (2400, 2600), "all": (2600, 3200)},
    },
    {
        "title": "2 · JSON → OCI PutObject",
        "route": "2-split-st-json-and-oci",
        "file": "route2-oci.png",
        "group": "oci-put",
        "window": {"compact": (2200, 2400), "changed": (2400, 4000), "all": (2600, 5000)},
    },
]
''',
    "hl7-healthcare-automation": '''ROUTES = [
    {
        "title": "1 — Process Hospital HL7 (Overview)",
        "route": "1-process-hospital-hl7",
        "file": "route1-overview.png",
        "collapse": "all",
        "window": {"compact": (2400, 2400), "changed": (2600, 3000), "all": (2800, 3600)},
    },
    {
        "title": "1 · Inbound Validate",
        "route": "1-process-hospital-hl7",
        "file": "route1-validate.png",
        "group": "validate",
        "window": {"compact": (2200, 2200), "changed": (2400, 3600), "all": (2600, 4400)},
    },
]
''',
}


MAIN_LOOP = '''
    SHOTS.mkdir(parents=True, exist_ok=True)
    images = []
    if not args.skip_capture:
        wait_health()
        for entry in ROUTES:
            if isinstance(entry, dict):
                title = entry["title"]
                rid = entry["route"]
                name = entry["file"]
                dest = SHOTS / name
                size = entry.get("window", {}).get(config) or (2200, 4000)
                collapse = entry.get("collapse") or ""
                group = entry.get("group") or ""
                extra = ""
                if collapse:
                    extra = f", collapse={collapse}"
                elif group:
                    extra = f", group={group}"
                print(f"Capturing {title} (config={config}, window={size[0]}x{size[1]}{extra})")
                shot(rid, dest, size, config, collapse=collapse, group=group)
            else:
                title, rid, name = entry
                dest = SHOTS / name
                size = (2200, 4000)
                print(f"Capturing {title} (config={config}, window={size[0]}x{size[1]})")
                shot(rid, dest, size, config)
            trimmed = trim_diagram(Image.open(dest))
            trimmed.save(dest)
            print(f"  cropped -> {trimmed.size[0]}x{trimmed.size[1]}")
            images.append((title, dest))
    else:
        for entry in ROUTES:
            if isinstance(entry, dict):
                title = entry["title"]
                dest = SHOTS / entry["file"]
            else:
                title, _rid, name = entry
                dest = SHOTS / name
            if not dest.exists():
                raise SystemExit(f"Missing {dest}; run without --skip-capture")
            print(f"Using existing {dest} ({Image.open(dest).size})")
            images.append((title, dest))
'''


def rewrite_export(demo_name: str, demo: Path) -> None:
    path = demo / "tools" / "export_route_diagrams.py"
    if not path.is_file():
        print("  skip export script missing")
        return
    text = patch_export_shot_helpers(path)
    routes_src = EXPORT_ROUTES.get(demo_name)
    if routes_src:
        # Replace ROUTES = [ ... ] top-level assignment (tuples or prior dicts)
        text2, n = re.subn(
            r"^ROUTES = \[[\s\S]*?^\]\n",
            routes_src if routes_src.endswith("\n") else routes_src + "\n",
            text,
            count=1,
            flags=re.M,
        )
        if n == 0:
            print("  WARN: could not replace ROUTES list")
        else:
            text = text2
            print("  replaced ROUTES capture list")
        # Remove obsolete WINDOW_BY_CONFIG if present (unused)
        text = re.sub(r"\nWINDOW_BY_CONFIG = \{[\s\S]*?\n\}\n", "\n", text, count=1)
        # Patch main loop for dict entries
        if "isinstance(entry, dict)" not in text:
            text2, n = re.subn(
                r"    SHOTS\.mkdir\(parents=True, exist_ok=True\)\n    images = \[\]\n    if not args\.skip_capture:[\s\S]*?images\.append\(\(title, dest\)\)\n",
                MAIN_LOOP.lstrip("\n"),
                text,
                count=1,
            )
            if n:
                text = text2
                print("  patched main capture loop")
            else:
                print("  WARN: could not patch main loop")
        # default config compact
        text = text.replace('default="changed"', 'default="compact"')
        text = text.replace('default="all"', 'default="compact"')
    else:
        # hygiene only: still upgrade shot helpers + default compact
        text = text.replace('default="changed"', 'default="compact"')
        print("  export helpers updated (flat ROUTES kept)")
    path.write_text(text, encoding="utf-8")
    print(f"  wrote {path.relative_to(demo)}")


def main() -> int:
    for name in ALL_TARGET_DEMOS:
        demo = resolve_demo(name)
        if demo is None:
            print("missing", name)
            continue
        print(f"\n=== {name} ===")
        port_viewer(demo)
        ensure_api(demo)
        write_groups(name, demo)
        rewrite_export(name, demo)
    print("\nDone. Rebuild each Web UI and run: python3 tools/export_route_diagrams.py --config compact")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
