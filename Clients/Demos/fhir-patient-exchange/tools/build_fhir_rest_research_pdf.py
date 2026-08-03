#!/usr/bin/env python3
"""Build FHIR REST interface research / PilotFish design PDF."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "documents" / "FHIR_REST_Interface_Research.pdf"
BRAND = "PILOTFISH  ·  FHIR REST INTERFACE RESEARCH"


def styles():
    base = getSampleStyleSheet()
    return {
        "h1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=16,
            textColor=colors.HexColor("#0b6e4f"),
            spaceAfter=10,
            spaceBefore=4,
        ),
        "h2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12.5,
            textColor=colors.HexColor("#0b6e4f"),
            spaceBefore=14,
            spaceAfter=6,
            borderPadding=2,
        ),
        "h3": ParagraphStyle(
            "H3",
            parent=base["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=11,
            textColor=colors.HexColor("#243044"),
            spaceBefore=10,
            spaceAfter=4,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=13,
            alignment=TA_JUSTIFY,
            spaceAfter=6,
        ),
        "bullet": ParagraphStyle(
            "Bullet",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=12.5,
            leftIndent=8,
            alignment=TA_LEFT,
            spaceAfter=2,
        ),
        "code": ParagraphStyle(
            "Code",
            parent=base["Code"],
            fontName="Courier",
            fontSize=8.2,
            leading=11,
            backColor=colors.HexColor("#f3f6f8"),
            borderPadding=4,
            spaceAfter=8,
            spaceBefore=4,
        ),
        "note": ParagraphStyle(
            "Note",
            parent=base["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#334155"),
            spaceAfter=8,
        ),
        "footer": ParagraphStyle(
            "Footer",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=8,
            textColor=colors.HexColor("#64748b"),
        ),
    }


def bullets(items, st):
    return ListFlowable(
        [ListItem(Paragraph(i, st["bullet"]), leftIndent=12, value="•") for i in items],
        bulletType="bullet",
        start="•",
        leftIndent=14,
        spaceBefore=2,
        spaceAfter=8,
    )


def table(rows, col_widths):
    t = Table(rows, colWidths=col_widths, repeatRows=1)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0b6e4f")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8.5),
                ("LEADING", (0, 0), (-1, -1), 11),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c9d5e0")),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#f8fafb")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#f8fafb"), colors.white]),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def header_footer(canvas, doc):
    canvas.saveState()
    canvas.setFillColor(colors.HexColor("#0b6e4f"))
    canvas.setFont("Helvetica-Bold", 9)
    canvas.drawString(0.7 * inch, letter[1] - 0.45 * inch, BRAND)
    canvas.setStrokeColor(colors.HexColor("#0b6e4f"))
    canvas.setLineWidth(1.2)
    canvas.line(0.7 * inch, letter[1] - 0.55 * inch, letter[0] - 0.7 * inch, letter[1] - 0.55 * inch)
    canvas.setFillColor(colors.HexColor("#64748b"))
    canvas.setFont("Helvetica", 8)
    canvas.drawRightString(letter[0] - 0.7 * inch, 0.45 * inch, f"Page {doc.page}")
    canvas.restoreState()


def build():
    st = styles()
    story = []
    story.append(Paragraph("What FHIR Is — and How to Implement It in PilotFish", st["h1"]))
    story.append(
        Paragraph(
            "Research note for the PilotFish Sandbox. Purpose: replace the directory-listener "
            "demo pattern with a real FHIR REST design before rebuilding the interface.",
            st["note"],
        )
    )

    story.append(Paragraph("1. What FHIR actually is", st["h2"]))
    story.append(
        Paragraph(
            "FHIR (Fast Healthcare Interoperability Resources) is an HL7 standard for exchanging "
            "healthcare data as discrete <b>resources</b> (Patient, Observation, Encounter, "
            "Claim, etc.) over modern web APIs. The normative exchange model is <b>RESTful FHIR</b>: "
            "HTTP verbs against a service base URL, with JSON or XML payloads "
            "(<font face='Courier'>application/fhir+json</font> / "
            "<font face='Courier'>application/fhir+xml</font>).",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "FHIR is <b>not</b> “drop a file in a folder.” Directory pickup can be a Sandbox "
            "shortcut for non-FHIR demos, but it is not how FHIR systems talk to each other. "
            "Partners call HTTP endpoints; they expect HTTP status codes, Location headers, "
            "OperationOutcome errors, and CapabilityStatements.",
            st["body"],
        )
    )

    story.append(Paragraph("2. How FHIR “messages” / transactions work", st["h2"]))
    story.append(Paragraph("2.1 Primary model: RESTful interactions (usually synchronous)", st["h3"]))
    story.append(
        Paragraph(
            "Per HL7 FHIR R4 HTTP API, each resource type supports a common set of interactions. "
            "Default use is <b>synchronous request/response</b>: the client waits on the HTTP "
            "connection for the result. An async pattern also exists "
            "(<font face='Courier'>Prefer: respond-async</font>) for long-running work.",
            st["body"],
        )
    )

    rows = [
        [Paragraph("<b>Level</b>", st["bullet"]), Paragraph("<b>Interaction</b>", st["bullet"]), Paragraph("<b>HTTP</b>", st["bullet"]), Paragraph("<b>Meaning</b>", st["bullet"])],
        [Paragraph("Instance", st["bullet"]), Paragraph("read / vread / update / patch / delete / history", st["bullet"]), Paragraph("GET / PUT / PATCH / DELETE", st["bullet"]), Paragraph("Operate on one resource by id", st["bullet"])],
        [Paragraph("Type", st["bullet"]), Paragraph("create / search / history", st["bullet"]), Paragraph("POST / GET", st["bullet"]), Paragraph("Create or query a resource type", st["bullet"])],
        [Paragraph("System", st["bullet"]), Paragraph("capabilities / batch / transaction / search", st["bullet"]), Paragraph("GET / POST", st["bullet"]), Paragraph("Server metadata or multi-resource commit", st["bullet"])],
    ]
    story.append(table(rows, [0.9 * inch, 2.2 * inch, 1.35 * inch, 2.55 * inch]))
    story.append(Spacer(1, 8))

    story.append(Paragraph("Canonical examples", st["h3"]))
    story.append(
        Paragraph(
            "POST [base]/Patient<br/>"
            "→ create Patient; expect <b>201 Created</b> + Location + resource (or Outcome).<br/><br/>"
            "GET [base]/Patient/{id}<br/>"
            "→ read; expect <b>200</b> + Patient or <b>404</b> + OperationOutcome.<br/><br/>"
            "GET [base]/Patient?identifier=MRN|10001<br/>"
            "→ search; expect Bundle type=searchset.<br/><br/>"
            "POST [base]/  with Bundle type=transaction<br/>"
            "→ atomic multi-resource create/update/delete; response Bundle type=transaction-response.",
            st["code"],
        )
    )

    story.append(Paragraph("2.2 Bundle batch vs transaction", st["h3"]))
    story.append(
        bullets(
            [
                "<b>batch</b> — each entry processed independently; partial success allowed; response type batch-response.",
                "<b>transaction</b> — all-or-nothing; server commits none if any entry fails; response type transaction-response.",
                "Entries carry <font face='Courier'>request.method</font> + <font face='Courier'>request.url</font> (and usually a resource body for POST/PUT).",
            ],
            st,
        )
    )

    story.append(Paragraph("2.3 FHIR Messaging (optional, different channel)", st["h3"]))
    story.append(
        Paragraph(
            "FHIR also defines <b>Messaging</b>: a Bundle with type=message whose first entry is a "
            "MessageHeader, exchanged over HTTP POST to a mailbox URL, queues, or other transports. "
            "That is closer to “event/message” semantics (admit, lab result notice). Most modern "
            "interoperability (Patient Access, Provider Access, Payer-to-Payer, prior auth APIs, "
            "CMS-0057-F style APIs) centers on <b>RESTful resource APIs</b>, not HL7v2-style "
            "directory drops. Messaging can be a later Sandbox route; REST CRUD/search/transaction "
            "should be the first real demo.",
            st["body"],
        )
    )

    story.append(Paragraph("2.4 Is FHIR “real-time”?", st["h3"]))
    story.append(
        Paragraph(
            "Yes in the practical sense: clients invoke HTTP interactions and get immediate "
            "synchronous responses for create/read/search/transaction. That is interactive/"
            "request-driven, not a poll of a file share. Separately, systems may use subscriptions, "
            "async bulk ($export), or messaging for deferred work — but the core API is live HTTP.",
            st["body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("3. What was wrong with the directory-listener demo", st["h2"]))
    story.append(
        bullets(
            [
                "Partners never “drop XML envelopes” into a folder for FHIR; they call REST endpoints.",
                "No HTTP status codes, Location, ETag/versioning, or OperationOutcome contract.",
                "No CapabilityStatement describing supported resources/interactions.",
                "Validation wrapping metadata around RawFhir was a demo envelope — not on-the-wire FHIR.",
                "Useful as a temporary Sandbox scaffold; <b>not</b> a FHIR interface design to keep.",
            ],
            st,
        )
    )

    story.append(Paragraph("4. How PilotFish implements FHIR REST", st["h2"]))
    story.append(
        Paragraph(
            "PilotFish does <b>not</b> ship a dedicated “FHIR Listener” class. FHIR is a "
            "<b>format + REST/HTTP connectivity</b> problem: use the RESTful Web Service modules "
            "for the wire, JSON/XML transformers and the FHIR Format Builder for structure/mapping.",
            st["body"],
        )
    )

    story.append(Paragraph("4.1 Modules (looked up in PilotFish_V2 / modules.conf)", st["h3"]))
    mod_rows = [
        [Paragraph("<b>Role</b>", st["bullet"]), Paragraph("<b>FQCN</b>", st["bullet"]), Paragraph("<b>Notes</b>", st["bullet"])],
        [
            Paragraph("Inbound REST", st["bullet"]),
            Paragraph("com.pilotfish.eip.modules.http.rest.RESTfulWebServiceListener", st["bullet"]),
            Paragraph(
                "Path /eip/rest/{ServiceName}/{Resource}/{id}. Config: SERVICE_NAME, "
                "POST/GET/PUT/DELETE_SUPPORTED, Synchronous, Timeout, USER_NAME/PASSWORD, SupportedResources.",
                st["bullet"],
            ),
        ],
        [
            Paragraph("Sync reply", st["bullet"]),
            Paragraph("com.pilotfish.eip.modules.internal.SynchronousResponseTransport", st["bullet"]),
            Paragraph("Returns body to waiting REST/HTTP listener. Pair with Synchronous=true.", st["bullet"]),
        ],
        [
            Paragraph("HTTP status", st["bullet"]),
            Paragraph("com.pilotfish.eip.modules.http.HttpResponseCodeProcessor", st["bullet"]),
            Paragraph("Sets com.pilotfish.HTTPResponseCode (201/200/404/400/…).", st["bullet"]),
        ],
        [
            Paragraph("Response headers", st["bullet"]),
            Paragraph("com.pilotfish.eip.modules.http.AddHttpResponseHeadersProcessor", st["bullet"]),
            Paragraph("e.g. Content-Type: application/fhir+json, Location.", st["bullet"]),
        ],
        [
            Paragraph("JSON↔XML", st["bullet"]),
            Paragraph("com.pilotfish.eip.modules.json.JSONTransformationProcessor", st["bullet"]),
            Paragraph("Generic JSON tree ↔ PilotFish JSON XML — not FHIR profile validation by itself.", st["bullet"]),
        ],
        [
            Paragraph("Outbound FHIR call", st["bullet"]),
            Paragraph("com.pilotfish.eip.modules.http.rest.RESTfulWebServiceTransport", st["bullet"]),
            Paragraph("RESOURCE_PATH, METHOD_TO_EXECUTE, ACCEPT_MEDIA_TYPE=application/fhir+json.", st["bullet"]),
        ],
        [
            Paragraph("FHIR schemas (design-time)", st["bullet"]),
            Paragraph("FHIR Format Builder (xcs-format-fhir)", st["bullet"]),
            Paragraph("GUI mapping aid; versions in tree include v4.0.0 (R4). Not a runtime REST module.", st["bullet"]),
        ],
    ]
    story.append(table(mod_rows, [1.15 * inch, 2.55 * inch, 3.3 * inch]))
    story.append(Spacer(1, 8))
    story.append(
        Paragraph(
            "Proven Sandbox sync-HTTP pattern (non-FHIR): CRL Plus American Income Life uses "
            "HttpPostListener + SynchronousResponseTransport. V2 unit-test routes exercise "
            "RESTfulWebServiceListener with Synchronous=true. No Clients demo has smoke-tested "
            "RESTfulWebServiceListener on pilotfish-eip:23R1 yet — that is the next build risk to retire.",
            st["note"],
        )
    )

    story.append(Paragraph("4.2 URL shape on eiPlatform", st["h3"]))
    story.append(
        Paragraph(
            "/eip/rest/{ServiceName}/{ResourceName}/{ResourceID}<br/><br/>"
            "Example service name <b>fhir</b>:<br/>"
            "POST /eip/rest/fhir/Patient<br/>"
            "GET  /eip/rest/fhir/Patient/pat-alice-001<br/><br/>"
            "Listener attributes include com.pilotfish.HttpMethodName, ResourceName, ResourceID, "
            "query parameters, and headers — route logic branches on those.",
            st["code"],
        )
    )

    story.append(Paragraph("5. Recommended Sandbox target architecture", st["h2"]))
    story.append(
        Paragraph(
            "Rebuild the FHIR demo as a <b>small FHIR REST façade</b> (not a full EHR FHIR server).",
            st["body"],
        )
    )
    story.append(
        bullets(
            [
                "<b>Route A — FHIR REST Patient API (sync)</b>: RESTfulWebServiceListener "
                "(SERVICE_NAME=fhir, Synchronous=true, GET+POST) → branch on method → "
                "store/retrieve Patient JSON (SQL or file store) → set status/headers → "
                "SynchronousResponseTransport with application/fhir+json.",
                "<b>Create</b>: POST body Patient → validate required elements → assign/persist id → "
                "201 + Location + Patient.",
                "<b>Read</b>: GET by id → 200 Patient or 404 OperationOutcome.",
                "<b>Optional next</b>: search (GET Patient?identifier=… → Bundle searchset); "
                "transaction Bundle POST to base; outbound RESTfulWebServiceTransport to an external FHIR server.",
                "<b>Web UI</b>: act as FHIR client (curl-like) hitting LAN REST URLs — not a directory drop form.",
                "<b>LAN</b>: publish on 0.0.0.0 and set LAN_HINT to http://192.x.x.x:&lt;port&gt;/ per playbook §1.1.",
            ],
            st,
        )
    )

    story.append(Paragraph("Happy-path sequence (create)", st["h3"]))
    story.append(
        Paragraph(
            "1. Client POST application/fhir+json Patient to /eip/rest/fhir/Patient<br/>"
            "2. Listener accepts, Synchronous wait starts<br/>"
            "3. Route validates resourceType=Patient + identifier/name rules<br/>"
            "4. Persist resource; set HTTPResponseCode=201; Location header<br/>"
            "5. SynchronousResponseTransport returns Patient JSON to client<br/>"
            "6. Optional side effect: BI SQL audit row (after successful persist — no claim-before-complete)",
            st["code"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("6. Validation & honesty", st["h2"]))
    story.append(
        bullets(
            [
                "Demo may use heuristic/XSLT or schema checks — label clearly as not full StructureDefinition/IG validation.",
                "Prefer returning OperationOutcome on failure with 4xx, not silent file kickout-only behavior.",
                "Do not claim CMS-0057-F / SMART-on-FHIR / OAuth compliance without implementing those gates.",
                "CapabilityStatement can start minimal (Patient create+read) and grow.",
            ],
            st,
        )
    )

    story.append(Paragraph("7. Proposed rebuild phases", st["h2"]))
    phase_rows = [
        [Paragraph("<b>Phase</b>", st["bullet"]), Paragraph("<b>Deliverable</b>", st["bullet"]), Paragraph("<b>Exit criteria</b>", st["bullet"])],
        [
            Paragraph("0 — Research (this PDF)", st["bullet"]),
            Paragraph("Agree REST-first design; retire directory pattern as the FHIR story.", st["bullet"]),
            Paragraph("Stakeholder OK to rebuild.", st["bullet"]),
        ],
        [
            Paragraph("1 — REST smoke", st["bullet"]),
            Paragraph("RESTfulWebServiceListener + sync echo/Patient create on 23R1.", st["bullet"]),
            Paragraph("curl POST/GET from localhost + 192.x LAN works.", st["bullet"]),
        ],
        [
            Paragraph("2 — Patient API", st["bullet"]),
            Paragraph("Persist store, 201/200/404, OperationOutcome, Web UI as client.", st["bullet"]),
            Paragraph("Happy + fail paths documented; route PDF regenerated.", st["bullet"]),
        ],
        [
            Paragraph("3 — Expand", st["bullet"]),
            Paragraph("Searchset and/or transaction Bundle; optional outbound FHIR client route.", st["bullet"]),
            Paragraph("Samples + DESIGN.md risks updated.", st["bullet"]),
        ],
    ]
    story.append(table(phase_rows, [1.4 * inch, 3.1 * inch, 2.5 * inch]))
    story.append(Spacer(1, 10))

    story.append(Paragraph("8. Open questions before rebuild", st["h2"]))
    story.append(
        bullets(
            [
                "Confirm RESTfulWebServiceListener loads cleanly inside pilotfish-eip:23R1 WAR (first spike).",
                "Persistence: SQL JSON column vs filesystem FHIR store vs both (audit vs source of truth).",
                "Auth: demo basic auth only, or mock bearer token header check?",
                "Scope freeze for v1: Patient create+read only, or include Bundle transaction?",
                "Keep / deprecate current directory demo artifacts after REST rebuild?",
            ],
            st,
        )
    )

    story.append(Paragraph("9. References", st["h2"]))
    story.append(
        bullets(
            [
                "HL7 FHIR R4 HTTP API — https://www.hl7.org/fhir/R4/http.html",
                "HL7 FHIR R4 Bundle — https://hl7.org/fhir/R4/bundle.html",
                "PilotFish RESTful Web Service Listener — https://healthcare.pilotfishtechnology.com/restful-listener-configuration/",
                "PilotFish FHIR / CMS interoperability overview — https://healthcare.pilotfishtechnology.com/fhir-integration-cms-0057-f-compliance/",
                "In-repo module sources: PilotFish_V2 …/modules/http/rest/RESTfulWebService*.java",
                "Sandbox playbook: docs/INTERFACE_CONSTRUCTION_PLAYBOOK.md (§1.1 LAN, V1 runtime policy)",
            ],
            st,
        )
    )

    story.append(Spacer(1, 12))
    story.append(
        Paragraph(
            "Bottom line: implement FHIR as a synchronous RESTful Web Service on PilotFish "
            "(listener → process → SynchronousResponse), not as a DirectoryListener. Rebuild the "
            "Sandbox demo against that contract after Phase 1 smoke proves the module on 23R1.",
            st["note"],
        )
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.75 * inch,
        bottomMargin=0.65 * inch,
        title="FHIR REST Interface Research — PilotFish",
        author="PilotFish Sandbox",
    )
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    print("Wrote", OUT)


if __name__ == "__main__":
    build()
