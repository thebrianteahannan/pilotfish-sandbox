#!/usr/bin/env python3
"""FHIR expert due-diligence PDF — honest critique of PilotFish as a FHIR server facade."""
from __future__ import annotations

from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    KeepTogether,
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
OUT = ROOT / "documents" / "FHIR_R4_Platform_Expert_Due_Diligence.pdf"
NAVY = colors.HexColor("#0b3d5c")
TEAL = colors.HexColor("#0e7490")
LIGHT = colors.HexColor("#f0f9ff")
WARN = colors.HexColor("#fef3c7")
OK = colors.HexColor("#ecfdf5")
BORDER = colors.HexColor("#cbd5e1")


def styles():
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle(
            "ct", parent=base["Title"], fontSize=22, textColor=NAVY, spaceAfter=8, leading=26
        ),
        "cover_sub": ParagraphStyle(
            "cs", parent=base["Normal"], fontSize=12, textColor=TEAL, alignment=TA_CENTER, spaceAfter=6
        ),
        "h1": ParagraphStyle(
            "h1", parent=base["Heading1"], fontSize=14, textColor=NAVY, spaceBefore=14, spaceAfter=6
        ),
        "h2": ParagraphStyle(
            "h2", parent=base["Heading2"], fontSize=11, textColor=TEAL, spaceBefore=10, spaceAfter=4
        ),
        "body": ParagraphStyle(
            "body", parent=base["Normal"], fontSize=9.5, leading=13, alignment=TA_JUSTIFY, spaceAfter=6
        ),
        "small": ParagraphStyle(
            "small", parent=base["Normal"], fontSize=8.5, leading=11, textColor=colors.HexColor("#475569")
        ),
        "q": ParagraphStyle(
            "q", parent=base["Normal"], fontSize=9.5, leading=12, textColor=NAVY, fontName="Helvetica-Bold", spaceAfter=3
        ),
        "a": ParagraphStyle(
            "a", parent=base["Normal"], fontSize=9, leading=12, alignment=TA_JUSTIFY, spaceAfter=8, leftIndent=8
        ),
        "bullet": ParagraphStyle("bu", parent=base["Normal"], fontSize=9, leading=12),
        "footer": ParagraphStyle("ft", parent=base["Normal"], fontSize=8, textColor=colors.gray, alignment=TA_CENTER),
        "callout": ParagraphStyle("co", parent=base["Normal"], fontSize=9, leading=12, textColor=colors.HexColor("#78350f")),
    }


def callout(text: str, s, bg=WARN) -> Table:
    t = Table([[Paragraph(text, s["callout"])]], colWidths=[6.5 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), bg),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#d97706")),
                ("LEFTPADDING", (0, 0), (-1, -1), 10),
                ("RIGHTPADDING", (0, 0), (-1, -1), 10),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return t


def qa(question: str, answer: str, s) -> KeepTogether:
    return KeepTogether([Paragraph(f"Q: {question}", s["q"]), Paragraph(f"<b>A:</b> {answer}", s["a"])])


def build():
    s = styles()
    story = []

    # Cover
    story.append(Spacer(1, 1.4 * inch))
    story.append(Paragraph("FHIR R4 Expert Due Diligence", s["cover_title"]))
    story.append(
        Paragraph(
            "What a FHIR expert will ask before trusting PilotFish<br/>as the FHIR server for their organization",
            s["cover_sub"],
        )
    )
    story.append(Spacer(1, 0.25 * inch))
    story.append(
        Paragraph(
            f"PilotFish FHIR R4 Expandable Platform · CapabilityStatement 0.6.0 · {date.today().isoformat()}",
            s["cover_sub"],
        )
    )
    story.append(Spacer(1, 0.4 * inch))
    story.append(
        callout(
            "<b>How to read this document.</b> This is not a sales brochure. It explains what a real FHIR "
            "server is expected to do, maps those expectations onto this demo, and answers the hard questions "
            "a FHIR architect, ONC/USHIK reviewer, or EHR integration lead would ask. Gaps are named "
            "explicitly so buyers can decide if PilotFish is the right <i>primary</i> FHIR store, a "
            "<i>facade/orchestrator</i>, or both over time.",
            s,
        )
    )

    story.append(PageBreak())

    # 1 — What is a FHIR server
    story.append(Paragraph("1. What “a FHIR server” actually means", s["h1"]))
    story.append(
        Paragraph(
            "People say “FHIR server” casually. Experts mean a system that implements a large slice of the "
            "<b>HL7 FHIR HTTP API</b> (R4 = version 4.0.1), exposes an accurate <b>CapabilityStatement</b> at "
            "<font face='Courier'>/metadata</font>, stores (or proxies) resources with correct HTTP semantics, "
            "and participates in an ecosystem of clients, IGs (Implementation Guides), security profiles, and "
            "conformance tests. It is not “JSON over REST with Patient in the path.”",
            s["body"],
        )
    )
    story.append(Paragraph("Core expectations experts bring into any evaluation:", s["body"]))
    bullets = [
        "<b>Conformance:</b> CapabilityStatement matches real behavior; undeclared features must not silently half-work.",
        "<b>Resource lifecycle:</b> create / read / update / delete / history / vread; version ids and ETags; "
        "conditional create/update/delete when claimed.",
        "<b>Search:</b> typed parameters, modifiers, prefixes, chaining, includes, revIncludes, paging "
        "(<font face='Courier'>_count</font>, next links), and result Bundle semantics.",
        "<b>Transactions:</b> Bundle type=transaction and batch with atomicity rules and correct response entries.",
        "<b>Validation:</b> structural + terminology + profile/IG validation (base R4 is the floor, not the ceiling).",
        "<b>Security:</b> TLS, OAuth2/OIDC, SMART on FHIR scopes, audit (Provenance / AuditEvent), least privilege.",
        "<b>Bulk Data:</b> HL7 Bulk Data Access IG (async <font face='Courier'>$export</font>, NDJSON, status, kickoff semantics).",
        "<b>Operations:</b> named ops (<font face='Courier'>$everything</font>, <font face='Courier'>$validate</font>, "
        "<font face='Courier'>$export</font>, …) with correct Parameters/Binary/OperationOutcome patterns.",
        "<b>Operational maturity:</b> multi-node, backups, DR, tenancy, rate limits, observability, upgrade path.",
    ]
    story.append(
        ListFlowable(
            [ListItem(Paragraph(b, s["bullet"]), leftIndent=12, value="•") for b in bullets],
            bulletType="bullet",
            start="•",
        )
    )
    story.append(Spacer(1, 0.15 * inch))
    story.append(
        Paragraph(
            "Reference-class open-source servers (e.g. HAPI FHIR JPA, Firely/Spark, Microsoft FHIR Server) "
            "optimize for being the <b>system of record for FHIR resources</b>. Middleware like PilotFish "
            "typically shines as a <b>facade, orchestrator, and integration fabric</b> — transforming, "
            "routing, securing, and composing systems — which may or may not also persist FHIR documents. "
            "That distinction is the root of most expert skepticism.",
            s["body"],
        )
    )

    # 2 — What this demo is
    story.append(Paragraph("2. What this PilotFish demo is (and is not)", s["h1"]))
    data = [
        [
            Paragraph("<b>Dimension</b>", s["small"]),
            Paragraph("<b>This demo (Phase 1–6)</b>", s["small"]),
            Paragraph("<b>Typical “full” FHIR server</b>", s["small"]),
        ],
        [
            Paragraph("Role", s["small"]),
            Paragraph("EIP facade + SQL persistence for selected resources", s["small"]),
            Paragraph("Dedicated FHIR persistence engine + search index", s["small"]),
        ],
        [
            Paragraph("CRUD", s["small"]),
            Paragraph("Patient, Observation, Condition, Encounter (+ metadata)", s["small"]),
            Paragraph("Broad resource catalog (often 50–100+ types)", s["small"]),
        ],
        [
            Paragraph("Search", s["small"]),
            Paragraph("Targeted token/string params (core-6 style), not full grammar", s["small"]),
            Paragraph("FHIR search chap. + modifiers + chaining + includes", s["small"]),
        ],
        [
            Paragraph("History / vread", s["small"]),
            Paragraph("Deferred", s["small"]),
            Paragraph("Usually required for clinical systems of record", s["small"]),
        ],
        [
            Paragraph("Validation", s["small"]),
            Paragraph("HAPI validator, base R4 profiles", s["small"]),
            Paragraph("Base + IG packages (US Core, Da Vinci, …)", s["small"]),
        ],
        [
            Paragraph("Auth", s["small"]),
            Paragraph("Keycloak Bearer on write + Bulk; open reads in demo", s["small"]),
            Paragraph("SMART App Launch + scopes + sometimes backend services", s["small"]),
        ],
        [
            Paragraph("Bulk $export", s["small"]),
            Paragraph("Async system-level export → NDJSON (demo partitions)", s["small"]),
            Paragraph("Patient/Group/system export, _since, deletion markers", s["small"]),
        ],
        [
            Paragraph("IG / US Core", s["small"]),
            Paragraph("Not packaged", s["small"]),
            Paragraph("Required for many US payer/provider programs", s["small"]),
        ],
        [
            Paragraph("CapStatement", s["small"]),
            Paragraph("Draft 0.6.0 — intentionally scoped", s["small"]),
            Paragraph("Production-grade, tested against Inferno/Touchstone", s["small"]),
        ],
    ]
    tbl = Table(data, colWidths=[1.2 * inch, 2.7 * inch, 2.6 * inch])
    tbl.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), NAVY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 1), (-1, -1), LIGHT),
                ("GRID", (0, 0), (-1, -1), 0.4, BORDER),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [LIGHT, colors.white]),
            ]
        )
    )
    story.append(tbl)
    story.append(Spacer(1, 0.12 * inch))
    story.append(
        callout(
            "<b>One-sentence truth:</b> This platform proves PilotFish can <i>speak FHIR R4</i> end-to-end "
            "(HTTP semantics, validation, OAuth Bearer, Bundle, Bulk export) with honest CapabilityStatement "
            "scoping — it does <b>not</b> claim parity with HAPI/Firely as a general-purpose FHIR repository.",
            s,
            bg=OK,
        )
    )

    story.append(PageBreak())

    # 3 — Expert questions
    story.append(Paragraph("3. Questions a true FHIR expert will ask", s["h1"]))
    story.append(
        Paragraph(
            "Below are the questions that separate “we put Patient JSON on a URL” from a viable FHIR program. "
            "Answers are candid about <b>this demo</b> and what a production PilotFish program would still need.",
            s["body"],
        )
    )

    story.append(Paragraph("3.1 Conformance & truth in advertising", s["h2"]))
    story.append(
        qa(
            "Does your CapabilityStatement accurately describe what the server does — and refuse what it doesn’t?",
            "Experts treat CapStatement as a contract. This demo publishes a draft CapStatement (0.6.0) that "
            "lists implemented interactions and explicitly defers full search grammar, history, US Core packages, "
            "Group/Patient compartment export, CapStatement $validate, and full SMART launch. That honesty matters. "
            "A deal-breaker is CapStatement inflation. Production stance: keep CapStatement generated from "
            "runtime truth (or rigorously reviewed against Inferno/Touchstone), never marketing copy.",
            s,
        )
    )
    story.append(
        qa(
            "Have you run official conformance suites (Inferno, Touchstone, Crucible) against this endpoint?",
            "Not claimed for this demo. Experts will ask for suite evidence before accepting PilotFish as a "
            "certified FHIR surface for CMS/ONC-facing programs. Path: scope CapStatement → lock behavior → "
            "run Inferno modules that match declared features → fix deltas before claiming production readiness.",
            s,
        )
    )

    story.append(Paragraph("3.2 Persistence model & identity", s["h2"]))
    story.append(
        qa(
            "Is PilotFish the system of record, or a facade over another clinical store?",
            "This demo persists selected resources in SQL via PilotFish listeners — it is a self-contained "
            "facade+store for demo resources. Experts will ask which production model you intend: "
            "(A) PilotFish as SoR for FHIR documents, (B) PilotFish façade over EHR/CDR with on-the-fly mapping, "
            "or (C) hybrid (cache + origin). Each has different identity, conflict, and deletion rules. "
            "Clarify this before search and history conversations.",
            s,
        )
    )
    story.append(
        qa(
            "How are resource ids, versions (meta.versionId), and ETags managed on concurrent updates?",
            "A production FHIR server needs strict versioning and often optimistic concurrency "
            "(If-Match / versionId). This demo implements CRUD and soft delete but defers full history/vread "
            "semantics. Experts will press until versioning is explicit — especially if clinical apps rely on "
            "lost-update protection.",
            s,
        )
    )
    story.append(
        qa(
            "What happens on DELETE — hard delete, soft delete, or FHIR deletion markers for Bulk _since?",
            "Demo uses soft-delete style retention for CRUD. Bulk Data IG consumers often require deletion "
            "markers when using _since. That behavior is explicitly deferred. Call it out in any payer/Bulk RFP.",
            s,
        )
    )

    story.append(Paragraph("3.3 Search — the #1 expert trap", s["h2"]))
    story.append(
        qa(
            "Do you implement the FHIR Search specification, or a curated subset?",
            "Curated subset — by design in Phase 1–6. Full FHIR search includes parameter types, modifiers "
            "(:exact, :contains, :missing, …), prefixes (ge/le), composites, chaining (subject.name), "
            "_include/_revinclude, _sort, _summary, and paging. Experts reject “we have ?name=” as search. "
            "Viable path with PilotFish: declare only supported params in CapStatement; implement a search "
            "index (SQL/Elastic/OpenSearch) for declared params; expand deliberately per IG (e.g. US Core "
            "required searches) rather than pretending full grammar exists.",
            s,
        )
    )
    story.append(
        qa(
            "How do you guarantee CapStatement searchParam lists stay in sync with the implementation?",
            "This is a governance problem. Experts have been burned by CapStatements that advertise "
            "parameters the server ignores. Recommend: generate CapStatement fragments from the same config "
            "that drives the search listener, plus automated tests that probe each declared parameter.",
            s,
        )
    )

    story.append(Paragraph("3.4 Transactions, integrity & consistency", s["h2"]))
    story.append(
        qa(
            "Are Bundle type=transaction requests truly atomic?",
            "FHIR transaction Bundles require all-or-nothing semantics (with precise failure reporting). "
            "Experts will ask whether PilotFish wraps SQL transactions correctly across multi-resource "
            "writes, how referential integrity is handled for literal references vs urn:uuid placeholders, "
            "and how partial batch failures are reported. Demo implements transaction/batch handling — "
            "production buyers should request failure-mode tests (constraint violation mid-Bundle).",
            s,
        )
    )
    story.append(
        qa(
            "Do you support conditional create/update/delete and If-None-Exist?",
            "Often required by EHR sync patterns. If not implemented, CapStatement must not advertise them. "
            "Experts will probe with Prefer headers and conditional URL syntax early in an RFP.",
            s,
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("3.5 Validation, profiles & IGs", s["h2"]))
    story.append(
        qa(
            "Is validation base FHIR R4 only, or do you load IG packages (US Core, Da Vinci, CARIN)?",
            "Demo: HAPI validator with base R4. That catches structural and many cardinality bugs. It does "
            "<b>not</b> prove US Core Patient/US Core Observation conformance. US programs almost always "
            "require IG package loading, StructureDefinitions, ValueSets, and often terminology services. "
            "PilotFish can integrate HAPI’s IG support or call an external validator — but packaging IGs "
            "is a deliberate project, not a checkbox.",
            s,
        )
    )
    story.append(
        qa(
            "Do you expose $validate and refuse invalid writes under a profile?",
            "CapStatement $validate is deferred. Experts distinguish “we can validate in a pipeline” from "
            "“clients can POST to $validate” and “server rejects non-conformant creates.” Decide policy: "
            "warn vs hard-fail; document it.",
            s,
        )
    )

    story.append(Paragraph("3.6 Security & SMART", s["h2"]))
    story.append(
        qa(
            "Is this SMART App Launch compliant, or just “OAuth Bearer somewhere”?",
            "Demo uses Keycloak Bearer for writes and Bulk export; reads are intentionally open for demo "
            "friction reduction. SMART adds launch context, scopes (patient/*.read, system/*.rs), "
            "well-known endpoints, PKCE, and often EHR launch vs standalone. Experts will reject "
            "“we put Keycloak in front” as SMART. Production: either implement SMART correctly or "
            "position PilotFish behind an API gateway that already does SMART and pass identity claims into EIP.",
            s,
        )
    )
    story.append(
        qa(
            "How are scopes enforced per resource and per compartment?",
            "Token presence ≠ authorization. patient/Observation.rs must not return another patient’s data. "
            "Experts will ask for compartment isolation tests. Demo is not positioned as a multi-tenant "
            "SMART authorization engine — that must be designed (claims → patient compartment filters).",
            s,
        )
    )
    story.append(
        qa(
            "Where is the audit trail (AuditEvent / Provenance) for clinical forensic requirements?",
            "Not a Phase 1–6 claim. Hospitals and payers often require who-read-what and who-changed-what. "
            "PilotFish can emit AuditEvent resources or SIEM logs — experts will ask which, with retention.",
            s,
        )
    )

    story.append(Paragraph("3.7 Bulk Data Access", s["h2"]))
    story.append(
        qa(
            "Is $export aligned with the HL7 Bulk Data Access IG (kickoff, status, complete, NDJSON)?",
            "Demo implements async system-level $export with 202 + Content-Location, status polling, and "
            "NDJSON file download behind Bearer auth — the right shape. Experts will still ask about: "
            "Patient- and Group-level export, _typeFilters, _since with deletion markers, multi-node job "
            "coordination, TLS file URLs, and backend-services authorization (client_credentials + scopes). "
            "Those are the usual production deltas from a working demo.",
            s,
        )
    )

    story.append(Paragraph("3.8 Performance, scale & operations", s["h2"]))
    story.append(
        qa(
            "Can this survive EHR-scale read volume and nightly Bulk extracts?",
            "Search and Bulk are index/IO problems. A generalist integration engine + row store can struggle "
            "if you treat FHIR as “dump JSON columns and SELECT LIKE.” Experts want: search indexing strategy, "
            "pagination cost, export job isolation from interactive API, horizontal scale of EIP vs DB, "
            "and SLOs. PilotFish viability improves when FHIR interactive API is bounded and heavy extract "
            "work is async (as this demo starts to show with $export).",
            s,
        )
    )
    story.append(
        qa(
            "How do you upgrade FHIR versions (R4 → R4B/R5) and migrate stored resources?",
            "Stored JSON must remain readable across upgrades. Experts ask for migration playbooks. Middleware "
            "facades that map from an EHR can often version the surface API without migrating a FHIR warehouse — "
            "another reason to clarify SoR vs facade early.",
            s,
        )
    )

    story.append(Paragraph("3.9 Why PilotFish instead of HAPI / Azure FHIR / AWS HealthLake?", s["h2"]))
    story.append(
        qa(
            "If I only need a FHIR repository, why not buy/run a purpose-built FHIR server?",
            "Fair question. Purpose-built servers win on search depth, IG tooling, and conformance velocity. "
            "PilotFish wins when the hard problem is <b>integration</b>: many protocols (HL7v2, X12, files, "
            "vendor APIs) must become FHIR; multiple backends must look like one CapStatement; transformations "
            "and orchestration dominate; and you already standardize on PilotFish for enterprise interfaces. "
            "The sophisticated answer is often: PilotFish as the FHIR <i>edge and orchestration layer</i>, "
            "optionally backing onto a purpose-built FHIR store — or owning persistence where the resource "
            "set and search requirements are bounded and well declared.",
            s,
        )
    )
    story.append(
        qa(
            "Can PilotFish sit in front of HAPI (or a cloud FHIR store) as the enterprise facade?",
            "Yes — and many experts will prefer that hybrid: PilotFish for authZ enrichment, protocol "
            "mediation, non-FHIR ingress, and policy; HAPI/cloud FHIR for deep search and resource storage. "
            "This demo intentionally shows PilotFish owning the HTTP FHIR surface so you can evaluate the "
            "facade path; hybrid is a natural Phase N.",
            s,
        )
    )

    story.append(PageBreak())

    # 4 — Decision matrix
    story.append(Paragraph("4. Decision guide — when is PilotFish viable?", s["h1"]))
    guide = [
        [
            Paragraph("<b>Your primary need</b>", s["small"]),
            Paragraph("<b>Expert stance</b>", s["small"]),
            Paragraph("<b>PilotFish fit</b>", s["small"]),
        ],
        [
            Paragraph("Expose FHIR from many non-FHIR systems (v2, X12, vendor APIs)", s["small"]),
            Paragraph("Facade + mapping is the product", s["small"]),
            Paragraph("<b>Strong</b> — PilotFish’s home turf", s["small"]),
        ],
        [
            Paragraph("Bounded internal FHIR API (known resources, known search params)", s["small"]),
            Paragraph("CapStatement honesty + tests required", s["small"]),
            Paragraph("<b>Viable</b> — this demo’s trajectory", s["small"]),
        ],
        [
            Paragraph("Nationwide Bulk + SMART + US Core for apps / TEFCA-style exchange", s["small"]),
            Paragraph("Deep conformance + IG program", s["small"]),
            Paragraph("<b>Only with deliberate IG/SMART program</b> or hybrid backend", s["small"]),
        ],
        [
            Paragraph("General-purpose FHIR repository replacing HAPI for all apps", s["small"]),
            Paragraph("Experts will resist unless search/history/IG parity is proven", s["small"]),
            Paragraph("<b>Weak as sole SoR today</b> — prefer hybrid or scoped SoR", s["small"]),
        ],
        [
            Paragraph("Orchestrate export, enrichment, routing across multiple FHIR stores", s["small"]),
            Paragraph("Integration fabric value is clear", s["small"]),
            Paragraph("<b>Strong</b>", s["small"]),
        ],
    ]
    g = Table(guide, colWidths=[2.4 * inch, 2.1 * inch, 2.0 * inch])
    g.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), NAVY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.4, BORDER),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, LIGHT]),
            ]
        )
    )
    story.append(g)

    story.append(Paragraph("5. Evidence this demo already gives an expert", s["h1"]))
    evidence = [
        "Working FHIR R4 CapStatement (draft) that names deferred features instead of hiding them.",
        "CRUD + soft delete + targeted search for core clinical resources.",
        "HAPI-based validation on the write path (base R4).",
        "Bundle transaction/batch handling.",
        "Keycloak OIDC Bearer integration (writes / Bulk).",
        "Async system $export → status → NDJSON files (Bulk shape).",
        "Living automated test plan + smoke evidence under documents/.",
        "Route diagrams showing real PilotFish topology — not a black-box container labeled “FHIR.”",
    ]
    story.append(
        ListFlowable(
            [ListItem(Paragraph(e, s["bullet"]), leftIndent=12, value="•") for e in evidence],
            bulletType="bullet",
            start="•",
        )
    )

    story.append(Paragraph("6. What to bring to the next expert review", s["h1"]))
    story.append(
        Paragraph(
            "If you are evaluating PilotFish with a FHIR architect, walk in with answers to these five:",
            s["body"],
        )
    )
    next5 = [
        "<b>SoR model:</b> PilotFish store, facade over EHR/CDR, or hybrid?",
        "<b>Declared surface:</b> exact CapStatement resource/interaction/searchParam list for go-live.",
        "<b>Conformance plan:</b> which Inferno/Touchstone modules, and who owns failures?",
        "<b>Security model:</b> SMART vs gateway-brokered OAuth; compartment enforcement design.",
        "<b>IG program:</b> which packages (US Core version?), terminology source, fail-open vs fail-closed.",
    ]
    story.append(
        ListFlowable(
            [ListItem(Paragraph(x, s["bullet"]), leftIndent=12, value="•") for x in next5],
            bulletType="bullet",
            start="•",
        )
    )
    story.append(Spacer(1, 0.2 * inch))
    story.append(
        callout(
            "<b>Bottom line for experts:</b> PilotFish is credible as a FHIR-capable integration and "
            "facade platform today, with a working expandable R4 surface demonstrated here. Whether it is "
            "viable as <i>your</i> FHIR server depends less on “can it return Patient JSON?” and more on "
            "whether you are honest about CapStatement scope, search/history needs, SMART/IG obligations, "
            "and whether persistence belongs in PilotFish or behind it. Use this demo to prove the HTTP/EIP "
            "mechanics; use the questions in §3 to size the real program.",
            s,
        )
    )
    story.append(Spacer(1, 0.25 * inch))
    story.append(
        Paragraph(
            "Related demo artifacts: Capability Brief · Route Diagrams · Living Test Plan · CapStatement at "
            "/eip/rest/fhir/metadata · DESIGN.md honest-scope table.",
            s["small"],
        )
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.gray)
        canvas.drawString(0.75 * inch, 0.5 * inch, "PilotFish FHIR R4 · Expert Due Diligence (honest scope)")
        canvas.drawRightString(letter[0] - 0.75 * inch, 0.5 * inch, f"Page {doc.page}")
        canvas.restoreState()

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.75 * inch,
        rightMargin=0.75 * inch,
        topMargin=0.7 * inch,
        bottomMargin=0.75 * inch,
        title="FHIR R4 Expert Due Diligence — PilotFish Platform",
        author="PilotFish Sandbox Demo",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
