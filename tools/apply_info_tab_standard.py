#!/usr/bin/env python3
"""Apply standard Info tab + document PDF aliases across Sandbox demos.

Source of truth:
  Clients/Demos/_shared/webui/document_routes.py
  Clients/Demos/_shared/webui/templates/partials/info_tab.html

Run from Sandbox root:
  python3 tools/apply_info_tab_standard.py
  python3 tools/apply_info_tab_standard.py --demo edi-837-snip-sqlserver
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

SANDBOX = Path(__file__).resolve().parents[1]
DEMOS = SANDBOX / "Clients" / "Demos"
SHARED_WEB = DEMOS / "_shared" / "webui"
SHARED_DOC_ROUTES = SHARED_WEB / "document_routes.py"
SHARED_PARTIAL = SHARED_WEB / "templates" / "partials" / "info_tab.html"

# Per-demo Info content. Ports are host ports from docker-compose.
DEMOS_META: dict[str, dict] = {
    "csv-to-json": {
        "title": "CSV → JSON File Conversion",
        "blurb": "Drop a CSV into the inbound folder. PilotFish polls, converts CSV→XML→JSON, and writes a <code>.json</code> file to the output folder.",
        "note": "Demo only — directory poll inbound CSV to outbound JSON.",
        "eip_url": "http://localhost:8108/eip/",
        "ports": [("PilotFish EIP", "8108"), ("Demo Web UI", "8109")],
        "lan_env": "LAN_HINT",
        "test_results_pdf": None,
    },
    "edi-270-271-eligibility": {
        "title": "Clinic eligibility — AAA theater then success",
        "blurb": "Build real X12 270 → mock payer 271 → parse benefits / AAA. Orchestrated by this clinic UI.",
        "note": "Demo only — orchestrated eligibility theater with mock payer.",
        "eip_url": "http://localhost:8106/eip/",
        "ports": [("Mock payer", "8210"), ("PilotFish EIP", "8106"), ("Demo Web UI", "8107")],
        "extra_links": [],
        "test_results_pdf": None,
    },
    "edi-270-271-realtime": {
        "title": "Realtime eligibility — PilotFish owns the 270/271 round-trip",
        "blurb": "Clinic posts <code>EligibilityRequest</code> once to PilotFish. Maps to X12 270, posts to the mock payer, parses the 271, and returns clinic JSON on the same HTTP request.",
        "note": "Demo only — realtime 270/271 round-trip on eiPlatform.",
        "eip_url": "http://localhost:8120/eip/",
        "ports": [("Mock payer", "8211"), ("PilotFish EIP", "8120"), ("Demo Web UI", "8121")],
        "extra_links": [
            {"href": "/documents/differences.pdf", "label": "How this differs from edi-270-271-eligibility"}
        ],
        "test_results_pdf": None,
    },
    "edi-278-prior-auth": {
        "title": "EDI 278 prior authorization",
        "blurb": "Synthetic 278 intake with SQL completeness / disposition theater and file-drop ORU (no LLP).",
        "note": "Demo only — synthetic 278, SQL completeness / disposition theater, file-drop ORU (no LLP).",
        "eip_url": "http://localhost:8120/eip/",
        "ports": [("SQL Server", "14340"), ("PilotFish EIP", "8120"), ("Demo Web UI", "8121")],
        "test_results_pdf": "EDI278_Prior_Auth_Test_Results.pdf",
    },
    "edi-835-oci-bucket": {
        "title": "SFTP 835 → ST split → JSON → OCI",
        "blurb": "Boss pattern: SFTP poll · fork each ST/Transaction · JSON · Object Storage REST (HTTP until OCI Transport exists).",
        "note": "Demo only — SFTP 835 to JSON Object Storage path.",
        "eip_url": "http://localhost:8104/eip/",
        "ports": [("SFTP", "2222"), ("Mock OCI", "4599"), ("PilotFish EIP", "8104"), ("Demo Web UI", "8105")],
        "extra_links": [
            {"href": "/documents/Connect_OciObjectStorageTransport_To_Real_Oracle_OCI.pdf", "label": "Connect OCI transport (guide PDF)"},
            {"href": "/documents/PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf", "label": "Gaps and custom modules PDF"},
        ],
        "test_results_pdf": None,
    },
    "edi-835-payment-integrity": {
        "title": "EDI 835 payment integrity",
        "blurb": "Poll remits, score underpay / integrity signals against Open AR, and route decisions with BI artifacts.",
        "note": "Demo only — synthetic 835 + Open AR.",
        "eip_url": "http://localhost:8110/eip/",
        "ports": [("SQL Server", "14339"), ("PilotFish EIP", "8110"), ("Demo Web UI", "8111")],
        "test_results_pdf": "EDI835_Payment_Integrity_Test_Results.pdf",
    },
    "edi-837-claim-scrub": {
        "title": "EDI 837 claim scrub (pre-clearinghouse)",
        "blurb": "Poll PENDING claims, apply synthetic payer edits, kick out failures, and emit clean 837 + SNIP for passers.",
        "note": "Demo only — synthetic payer edits before clearinghouse.",
        "eip_url": "http://localhost:8114/eip/",
        "ports": [("SQL Server", "14341"), ("PilotFish EIP", "8114"), ("Demo Web UI", "8115")],
        "test_results_pdf": "EDI837_Claim_Scrub_Test_Results.pdf",
    },
    "edi-837-snip-sqlserver": {
        "title": "SQL Server claims → 837P + SNIP",
        "blurb": "Poll PENDING claims, map to EDI XML, convert with the <strong>EDI Transformation Module</strong>, validate with <strong>EdiSNIPValidationProcessor</strong> (Types 1–3 at runtime), and view the SNIP HTML report in the UI.",
        "note": "Demo only — SQL → 837P + SNIP Types 1–3. Types 4–7 + <code>snip7-demo-rules.xml</code> are ready when <code>EDISNIP</code> is licensed.",
        "eip_url": "http://localhost:8093/eip/",
        "ports": [("SQL Server", "14335"), ("PilotFish EIP", "8093"), ("Demo Web UI", "8095")],
        "test_results_pdf": "EDI837_Test_Results.pdf",
        "extra_sections": [
            {
                "title": "SNIP levels (this demo)",
                "items": [
                    "Types 1–3 — <strong>on</strong> (integrity, HIPAA requirements, balancing)",
                    "Type 4 — off until <code>EDISNIP</code> (inter-segment)",
                    "Type 5 — off until <code>EDISNIP</code> (external code sets)",
                    "Types 6–7 — off until <code>EDISNIP</code>; rule file <code>snip7-demo-rules.xml</code> (demo: POS ≠ 99)",
                ],
                "note": "Sandbox <code>pflicense.key</code> lacks <code>EDISNIP</code>. Enabling Types 4–7 aborts SNIP and leaves reports empty — so runtime stays on Types 1–3.",
            }
        ],
    },
    "fhir-patient-exchange": {
        "title": "FHIR Patient REST API",
        "blurb": "Synchronous HL7 FHIR R4 Patient create/read on PilotFish <code>RESTfulWebServiceListener</code> — not a directory drop.",
        "note": "Demo only — FHIR R4 Patient create/read façade.",
        "eip_url": "http://localhost:8102/eip/",
        "ports": [("SQL Server", "14337"), ("PilotFish EIP", "8102"), ("Demo Web UI", "8103")],
        "extra_links": [
            {"href": "/documents/fhir-rest-research.pdf", "label": "FHIR REST research PDF"},
            {"href": "/documents/Why_PilotFish_eiPlatform_Not_Just_AI.pdf", "label": "Why PilotFish eiPlatform (PDF)"},
        ],
        "test_results_pdf": None,
    },
    "fhir-r4-platform": {
        "title": "FHIR R4 platform",
        "blurb": "Multi-resource FHIR R4 REST platform on eiPlatform with Call Route auth, capability statement, and SQL-backed resources.",
        "note": "Demo only — FHIR R4 REST platform façade.",
        "eip_url": "http://localhost:8110/eip/",
        "ports": [
            ("SQL Server", "14338"),
            ("PilotFish EIP", "8110"),
            ("Demo Web UI", "8111"),
            ("Keycloak", "8112"),
        ],
        "extra_links": [
            {"href": "/documents/FHIR_R4_Platform_AWS_Deployment_Guide.pdf", "label": "AWS deployment guide PDF"},
            {"href": "/documents/FHIR_R4_Platform_Expert_Due_Diligence.pdf", "label": "Expert due diligence PDF"},
        ],
        "test_results_pdf": "FHIR_R4_Platform_Test_Results.pdf",
    },
    "hl7-healthcare-automation": {
        "title": "HL7 healthcare automation",
        "blurb": "Directory listen → validate → router fan-out → SQL + file outputs for healthcare HL7 messaging.",
        "note": "Demo only — HL7 directory listen with router fan-out.",
        "eip_url": "http://localhost:8096/eip/",
        "ports": [("SQL Server", "14336"), ("PilotFish EIP", "8096"), ("Demo Web UI", "8097")],
        "test_results_pdf": None,
    },
    "medical-device-hl7-ehr": {
        "title": "Medical device HL7 → EHR",
        "blurb": "Device HL7 over LLP into PilotFish, transform, and hand off toward EHR / file outputs.",
        "note": "Demo only — medical device HL7 LLP intake.",
        "eip_url": "http://localhost:8100/eip/",
        "ports": [("LLP", "2580"), ("PilotFish EIP", "8100"), ("Demo Web UI", "8101")],
        "test_results_pdf": None,
    },
    "medical-lab-hl7-llp": {
        "title": "Medical lab HL7 LLP",
        "blurb": "Lab HL7 over LLP into PilotFish with acknowledgement and downstream file / SQL theater.",
        "note": "Demo only — lab HL7 LLP intake.",
        "eip_url": "http://localhost:8098/eip/",
        "ports": [("LLP", "2575"), ("PilotFish EIP", "8098"), ("Demo Web UI", "8099")],
        "test_results_pdf": None,
    },
    "doc-healthcare-hl7-workflow": {
        "title": "DOC healthcare HL7 workflow",
        "blurb": "SQL Server + Oracle housing / OMS events into PilotFish HL7 workflow (demo theater).",
        "note": "Demo only — DOC healthcare HL7 workflow from SQL Server + Oracle events.",
        "eip_url": "http://localhost:8091/eip/",
        "ports": [
            ("SQL Server", "14334"),
            ("Oracle", "1521"),
            ("PilotFish EIP", "8091"),
            ("Demo Web UI", "8092"),
        ],
        "test_results_pdf": None,
        "add_info_tab_chrome": True,
    },
}

MARKER_START = "<!-- INFO_TAB_STANDARD:START -->"
MARKER_END = "<!-- INFO_TAB_STANDARD:END -->"
INCLUDE = "{% include 'partials/info_tab.html' %}"
BOOTSTRAP_MARKER = "# INFO_TAB_STANDARD_BOOTSTRAP"


def copy_shared(demo_root: Path) -> None:
    webui = demo_root / "webui"
    webui.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SHARED_DOC_ROUTES, webui / "document_routes.py")
    dest_partial = webui / "templates" / "partials" / "info_tab.html"
    dest_partial.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SHARED_PARTIAL, dest_partial)
    ensure_dockerfile(demo_root)


def ensure_dockerfile(demo_root: Path) -> None:
    df = demo_root / "webui" / "Dockerfile"
    if not df.is_file():
        return
    text = df.read_text(encoding="utf-8")
    if "document_routes.py" in text:
        return
    replacements = [
        (r"COPY app\.py snip_report\.py docs_and_v2\.py \./", "COPY app.py snip_report.py docs_and_v2.py document_routes.py ./"),
        (r"COPY app\.py snip_report\.py \./", "COPY app.py snip_report.py document_routes.py ./"),
        (r"COPY app\.py \./", "COPY app.py document_routes.py ./"),
        (r"COPY app\.py \.", "COPY app.py document_routes.py ."),
    ]
    for pat, repl in replacements:
        if re.search(pat, text):
            df.write_text(re.sub(pat, repl, text, count=1), encoding="utf-8")
            return


def _replace_balanced_element(html: str, tag: str, id_value: str, replacement: str) -> str | None:
    open_re = re.compile(
        rf"[ \t]*<{tag}\b[^>]*\bid=[\"']{re.escape(id_value)}[\"'][^>]*>",
        re.I,
    )
    m = open_re.search(html)
    if not m:
        return None
    start = m.start()
    i = m.end()
    depth = 1
    open_tag = re.compile(rf"<{tag}\b", re.I)
    close_tag = re.compile(rf"</{tag}\s*>", re.I)
    while i < len(html) and depth:
        om = open_tag.search(html, i)
        cm = close_tag.search(html, i)
        if not cm:
            return None
        if om and om.start() < cm.start():
            depth += 1
            i = om.end()
        else:
            depth -= 1
            i = cm.end()
            if depth == 0:
                # include trailing newline
                end = i
                if end < len(html) and html[end] == "\n":
                    end += 1
                return html[:start] + replacement + html[end:]
    return None


def replace_info_block(html: str) -> str:
    """Replace existing #tab-info block (div or main) with include markers."""
    if MARKER_START in html and MARKER_END in html:
        return re.sub(
            re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END),
            f"{MARKER_START}\n  {INCLUDE}\n  {MARKER_END}",
            html,
            count=1,
            flags=re.S,
        )

    block = f"  {MARKER_START}\n  {INCLUDE}\n  {MARKER_END}\n"
    for tag in ("div", "main"):
        out = _replace_balanced_element(html, tag, "tab-info", block)
        if out is not None:
            return out
    m = re.search(r"[ \t]*<script\b", html)
    if m:
        return html[: m.start()] + block + "\n" + html[m.start() :]
    return html + "\n" + block


def ensure_info_button(html: str) -> str:
    if re.search(r"""data-(?:main-)?tab=["']info["']""", html):
        return html
    # Insert Info button after last tab button in tablist-ish container
    m = re.search(
        r"""(<button[^>]+data-(?:main-)?tab=["'][^"']+["'][^>]*>.*?</button>)(?![\s\S]*?<button[^>]+data-(?:main-)?tab=)""",
        html,
        re.S,
    )
    if not m:
        m = re.search(r"(<button[^>]*>\s*Routes\s*</button>)", html, re.I)
    if not m:
        return html
    btn = (
        '\n        <button type="button" class="main-tab" data-main-tab="info" '
        'role="tab" aria-selected="false">Info</button>'
    )
    if 'data-tab="' in m.group(1) and "data-main-tab=" not in m.group(1):
        btn = (
            '\n        <button type="button" class="tab" data-tab="info" '
            'aria-selected="false">Info</button>'
        )
    return html[: m.end()] + btn + html[m.end() :]


def ensure_app_bootstrap(app_py: Path, meta: dict, demo_name: str) -> None:
    text = app_py.read_text(encoding="utf-8") if app_py.is_file() else ""

    def env_default(name: str, fallback: str | None = None) -> str | None:
        m = re.search(
            rf'{name}\s*=\s*os\.environ\.get\(\s*"[^"]+"\s*,\s*"([^"]+)"',
            text,
        )
        return m.group(1) if m else fallback

    route_pdf = env_default("ROUTE_PDF_NAME")
    cap_pdf = env_default("CAPABILITY_PDF_NAME")
    plan_pdf = env_default("TEST_PLAN_PDF_NAME")
    results_pdf = env_default("TEST_RESULTS_PDF_NAME", meta.get("test_results_pdf"))

    ports_py = ",\n        ".join(
        f'{{"label": "{lab}", "value": "{val}"}}' for lab, val in meta.get("ports", [])
    )
    extra_links_py = repr(meta.get("extra_links") or [])
    extra_sections_py = repr(meta.get("extra_sections") or [])
    trp = repr(results_pdf) if results_pdf else "None"

    bootstrap = f'''
{BOOTSTRAP_MARKER}
try:
    from document_routes import ensure_document_routes
except ImportError:
    ensure_document_routes = None  # type: ignore

_INFO_TAB_CTX = {{
    "info_title": {repr(meta["title"])},
    "info_blurb": {repr(meta["blurb"])},
    "info_note": {repr(meta.get("note") or "")},
    "eip_url": {repr(meta.get("eip_url") or "")},
    "lan_hint": "",
    "info_ports": [
        {ports_py}
    ],
    "info_extra_links": {extra_links_py},
    "info_extra_sections": {extra_sections_py},
    "test_results_pdf": {trp},
}}

@app.context_processor
def _info_tab_standard_context():
    import os as _os
    ctx = dict(_INFO_TAB_CTX)
    eip = _os.environ.get("EIP_PUBLIC_URL")
    if eip:
        ctx["eip_url"] = eip
    lan = _os.environ.get("LAN_HINT", "")
    if lan:
        ctx["lan_hint"] = lan
    return ctx

if ensure_document_routes is not None:
    from pathlib import Path as _Path
    import os as _os
    _docs_dir = _Path(_os.environ.get("DOCUMENTS_DIR", "/documents"))
    ensure_document_routes(
        app,
        _docs_dir,
        route_pdf_name={repr(route_pdf)},
        capability_pdf_name={repr(cap_pdf)},
        test_plan_pdf_name={repr(plan_pdf)},
        test_results_pdf_name={repr(results_pdf)},
    )
# END INFO_TAB_STANDARD_BOOTSTRAP
'''

    if BOOTSTRAP_MARKER in text:
        text = re.sub(
            re.escape(BOOTSTRAP_MARKER) + r".*?# END INFO_TAB_STANDARD_BOOTSTRAP\n?",
            bootstrap.lstrip("\n"),
            text,
            count=1,
            flags=re.S,
        )
    else:
        m = re.search(r"\nif __name__ == [\"']__main__[\"']:", text)
        if m:
            text = text[: m.start()] + "\n" + bootstrap + text[m.start() :]
        else:
            text = text.rstrip() + "\n" + bootstrap + "\n"

    app_py.write_text(text, encoding="utf-8")


def ensure_muted_css(css_path: Path) -> None:
    if not css_path.is_file():
        return
    css = css_path.read_text(encoding="utf-8")
    snippet = """
/* Info tab standard */
.muted { color: var(--muted, #5a6a7a); font-size: 0.92em; }
#tab-info ul { margin: 0.35rem 0 0; padding-left: 1.25rem; line-height: 1.55; }
#tab-info li { margin: 0.25rem 0; }
#tab-info[hidden] { display: none !important; }
"""
    if "#tab-info ul" in css:
        return
    css_path.write_text(css.rstrip() + "\n" + snippet, encoding="utf-8")


def apply_demo(name: str) -> None:
    root = DEMOS / name
    if not root.is_dir():
        raise SystemExit(f"Unknown demo: {name}")
    meta = DEMOS_META[name]
    copy_shared(root)

    idx = root / "webui" / "templates" / "index.html"
    if idx.is_file():
        html = idx.read_text(encoding="utf-8")
        html = ensure_info_button(html)
        html = replace_info_block(html)
        idx.write_text(html, encoding="utf-8")
    else:
        print(f"  warn: no index.html for {name}", file=sys.stderr)

    app_py = root / "webui" / "app.py"
    if app_py.is_file():
        ensure_app_bootstrap(app_py, meta, name)
    else:
        print(f"  warn: no app.py for {name}", file=sys.stderr)

    ensure_muted_css(root / "webui" / "static" / "app.css")
    print(f"applied: {name}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--demo", action="append", help="Limit to demo folder name(s)")
    args = ap.parse_args()
    targets = args.demo or sorted(DEMOS_META.keys())
    for name in targets:
        if name not in DEMOS_META:
            raise SystemExit(f"No metadata for demo: {name}")
        apply_demo(name)


if __name__ == "__main__":
    main()
