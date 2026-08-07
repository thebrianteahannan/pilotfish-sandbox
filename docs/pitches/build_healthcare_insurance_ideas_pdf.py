#!/usr/bin/env python3
"""Build docs/pitches/Healthcare_Insurance_PilotFish_Opportunity_Ideas.pdf."""

from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
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

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Healthcare_Insurance_PilotFish_Opportunity_Ideas.pdf"
BRAND = "PILOTFISH SANDBOX  ·  HEALTHCARE & INSURANCE IDEAS"
GREEN = colors.HexColor("#0b6e4f")
INK = colors.HexColor("#1e293b")
MUTED = colors.HexColor("#475569")
RULE = colors.HexColor("#cbd5e1")
SOFT = colors.HexColor("#f1f5f4")
ACCENT = colors.HexColor("#0ea5e9")
WARN = colors.HexColor("#b45309")


def styles():
    base = getSampleStyleSheet()

    def p(name, parent, **kw):
        return ParagraphStyle(name, parent=base[parent], **kw)

    return {
        "title": p(
            "Title",
            "Title",
            fontName="Helvetica-Bold",
            fontSize=18,
            leading=22,
            textColor=GREEN,
            alignment=TA_CENTER,
            spaceAfter=6,
        ),
        "subtitle": p(
            "Subtitle",
            "Normal",
            fontName="Helvetica",
            fontSize=10.5,
            leading=14,
            textColor=MUTED,
            alignment=TA_CENTER,
            spaceAfter=14,
        ),
        "h1": p(
            "H1",
            "Heading1",
            fontName="Helvetica-Bold",
            fontSize=13,
            textColor=GREEN,
            spaceBefore=10,
            spaceAfter=6,
        ),
        "h2": p(
            "H2",
            "Heading2",
            fontName="Helvetica-Bold",
            fontSize=11,
            textColor=INK,
            spaceBefore=10,
            spaceAfter=4,
        ),
        "body": p(
            "Body",
            "Normal",
            fontName="Helvetica",
            fontSize=9.2,
            leading=12.5,
            textColor=INK,
            alignment=TA_JUSTIFY,
            spaceAfter=6,
        ),
        "bullet": p(
            "Bullet",
            "Normal",
            fontName="Helvetica",
            fontSize=9.0,
            leading=12,
            textColor=INK,
            alignment=TA_LEFT,
            spaceAfter=1,
        ),
        "callout": p(
            "Callout",
            "Normal",
            fontName="Helvetica-Oblique",
            fontSize=9.0,
            leading=12.2,
            textColor=MUTED,
            alignment=TA_JUSTIFY,
            spaceBefore=2,
            spaceAfter=8,
        ),
        "tag": p(
            "Tag",
            "Normal",
            fontName="Helvetica-Bold",
            fontSize=8.2,
            leading=10,
            textColor=WARN,
            spaceBefore=2,
            spaceAfter=2,
        ),
        "cell": p("Cell", "Normal", fontName="Helvetica", fontSize=8.0, leading=10.5, textColor=INK),
        "cellh": p(
            "CellH",
            "Normal",
            fontName="Helvetica-Bold",
            fontSize=8.1,
            leading=10.5,
            textColor=colors.white,
        ),
    }


def bullets(items, st):
    return ListFlowable(
        [ListItem(Paragraph(i, st["bullet"]), leftIndent=10, value="•") for i in items],
        bulletType="bullet",
        start="•",
        leftIndent=12,
        spaceBefore=0,
        spaceAfter=6,
    )


def table(rows, col_widths):
    st = styles()
    data = [
        [Paragraph(c, st["cellh" if i == 0 else "cell"]) for c in row]
        for i, row in enumerate(rows)
    ]
    t = Table(data, colWidths=col_widths, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), GREEN),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, SOFT]),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("GRID", (0, 0), (-1, -1), 0.35, RULE),
                ("LEFTPADDING", (0, 0), (-1, -1), 5),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def footer(canvas, doc):
    canvas.saveState()
    y = 0.5 * inch
    canvas.setStrokeColor(RULE)
    canvas.setLineWidth(0.6)
    canvas.line(0.7 * inch, y + 10, letter[0] - 0.7 * inch, y + 10)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(0.7 * inch, y, BRAND)
    canvas.drawRightString(letter[0] - 0.7 * inch, y, f"Page {doc.page}")
    canvas.restoreState()


def idea(story, st, title, why_hard, pilotfish_angle, demo_hook=None, tags=None):
    story.append(Paragraph(title, st["h2"]))
    if tags:
        story.append(Paragraph(" · ".join(tags), st["tag"]))
    story.append(Paragraph(f"<b>Why this hurts:</b> {why_hard}", st["body"]))
    story.append(Paragraph(f"<b>PilotFish angle:</b> {pilotfish_angle}", st["body"]))
    if demo_hook:
        story.append(Paragraph(f"<b>Demo sketch:</b> {demo_hook}", st["callout"]))


def build():
    st = styles()
    story = []
    w = [1.35 * inch, 2.2 * inch, 3.55 * inch]

    story.append(Paragraph("Healthcare &amp; Insurance Opportunity Ideas for PilotFish", st["title"]))
    story.append(
        Paragraph(
            "Tough industry problems plus common integration patterns not yet covered by the "
            "current Sandbox demos. Use this as a sales conversation starter, demo backlog, "
            "or custom-module / case-study shortlist.",
            st["subtitle"],
        )
    )
    story.append(
        Paragraph(
            "PilotFish wins when traffic is noisy, multi-protocol, heavily transformed, and "
            "someone has to own exceptions at 2 a.m. These ideas lean into that — not “call an "
            "API once,” but “keep claims, clinical, billing, and payer traffic moving when "
            "every trading partner is slightly different.”",
            st["body"],
        )
    )

    # --- Covered today ---
    story.append(Paragraph("1. What the Sandbox already demonstrates", st["h1"]))
    story.append(
        Paragraph(
            "Avoid re-building these as net-new ideas unless you deepen them (more SNIP types, "
            "real partner endpoints, production ops):",
            st["body"],
        )
    )
    story.append(
        table(
            [
                ["Demo", "Domain", "Core pattern"],
                ["hl7-healthcare-automation", "Payer / hospital HL7", "HL7 ADT batch → validate → SQL + clearinghouse"],
                ["doc-healthcare-hl7-workflow", "Gov / behavioral health", "Multi-DB poll → HL7 ADT for EHR"],
                ["medical-lab-hl7-llp", "Lab", "ORU over LLP → validate → MEDITECH LLP"],
                ["medical-device-hl7-ehr", "Devices", "Vitals/CGM ORU LLP → EHR LLP"],
                ["fhir-patient-exchange", "Interop / EHR", "FHIR R4 Patient REST create/read"],
                ["edi-837-snip-sqlserver", "Claims outbound", "SQL claims → 837P + SNIP 1–3"],
                ["edi-835-oci-bucket", "Payments / cloud", "835 → split ST → JSON → OCI Object Storage"],
                ["sqlserver-pilotfish-demo", "Foundation", "DB poll → XML file export"],
            ],
            w,
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        Paragraph(
            "Big open surface after those demos: member enrollment (834), eligibility (270/271), "
            "claim status (276/277), remittance enrichment, prior auth, quality measures, "
            "pharmacy, imaging, worker’s comp, ACA / state exchange, and “dirty data” MDM bridges.",
            st["callout"],
        )
    )

    # --- Tough problems ---
    story.append(Paragraph("2. Tough problems companies struggle to solve", st["h1"]))
    story.append(
        Paragraph(
            "These are the ones that burn budget on one-off scripts, brittle RPA, or “temporary” "
            "Point-to-Point connections that become permanent liability. Hard = multi-party, "
            "exception-heavy, regulated, or version drift across partners.",
            st["body"],
        )
    )

    idea(
        story,
        st,
        "2.1 Prior authorization that does not die in fax and portal hell",
        "Payers and providers still lose days to incomplete clinical attachments, portal "
        "re-keying, and mismatched code sets (CPT/HCPCS/ICD-10/LOINC). Every payer portal "
        "is a snowflake; denial and pended rates stay high.",
        "Ingest FHIR Questionnaires / Da Vinci PAS bundles (or 278/275), enrich from EHR "
        "(FHIR/HL7), attach clinical docs (CDA/PDF/X12 275), validate completeness, route "
        "to payer APIs or legacy X12, and return decision status events to the EHR work queue.",
        "Inbound 278 or FHIR PAS → completeness rules → simulated payer decision → 278 "
        "response + EHR “auth decided” ORU/SIU notice.",
        ["HARD", "PROVIDER + PAYER", "FHIR / X12 278"],
    )

    idea(
        story,
        st,
        "2.2 Claims rejection reduction before the clearinghouse",
        "Providers discover edits late (clearinghouse or payer). Resubmission cycles destroy "
        "revenue-cycle KPIs. Rules differ by payer, plan, and even billing TIN.",
        "Run SNIP + payer-specific business edits in PilotFish before outbound 837. Kick "
        "failures to a work queue with human-readable reasons; only clean claims leave the "
        "building. Log every edit outcome to a BI store.",
        "Extend the 837 demo: add a “payer profile” router and synthetic payer edit table "
        "that rejects missing referring NPI / invalid POS — show kickout UI.",
        ["HARD", "RCM", "EDI 837 / SNIP+"],
    )

    idea(
        story,
        st,
        "2.3 834 enrollment chaos (employer ↔ broker ↔ payer ↔ TPA)",
        "Enrollment files arrive late, partially, or with contradictory add/terminate/"
        "reinstate logic. Dependent linking, COBRA, and mid-month changes break HR systems "
        "and cause denied claims for “not eligible.”",
        "Normalize multiple inbound 834 dialects (and Excel/CSV from brokers) into a "
        "canonical member model; apply term/add reconciliation; emit clean 834/999/TA1 "
        "responses plus exception files. Optional: push enrollment deltas to FHIR Coverage / "
        "member MDM.",
        "Inbound messy CSV + one 834 → canonicalize → outbound clean 834 + exception report.",
        ["HARD", "INSURANCE / BENEFITS", "EDI 834"],
    )

    idea(
        story,
        st,
        "2.4 Real-time eligibility that is actually reliable (270/271 + FHIR CoverageEligibility)",
        "Front desks still get “unable to verify.” Trading partners time out, return "
        "partial AAA errors, or contradict portal truth. Caching and fallback logic is ad hoc.",
        "Front a single eligibility façade: try FHIR CoverageEligibilityRequest, fall back "
        "to 270/271, apply timeout/retry/circuit-breaker policy, normalize responses, and "
        "cache “known good” windows with audit trails for disputes.",
        "Mock flaky payer + PilotFish retry/fallback showing normalized eligibility JSON "
        "to a clinic UI.",
        ["HARD", "FRONT DESK / PAYER", "270/271 · FHIR"],
    )

    idea(
        story,
        st,
        "2.5 Payment integrity / 835 that finance can trust",
        "ERA files show up, but posting fails because CAS codes, PLB adjustments, and "
        "split payments do not match open AR. Underpayments hide in noise.",
        "Beyond “835 → JSON → bucket”: enrich remits with claim lineage, flag underpay "
        "thresholds, create denial follow-up work items, and post only confidently matched "
        "lines to the PM/EHR with a reconcile report.",
        "Feed sample 835s with underpays; produce matched vs exception buckets + underpay "
        "alert CSV.",
        ["HARD", "RCM / FINANCE", "EDI 835"],
    )

    idea(
        story,
        st,
        "2.6 Quality &amp; HEDIS / Star measure data plumbing",
        "Payers and ACOs chase incomplete clinical evidence across EHRs, labs, and claims. "
        "Measure season becomes an ETL panic every year.",
        "Continuous PilotFish pipelines: claims + ADT + ORU + FHIR Observations into a "
        "measure-prep lake/warehouse, with gap-in-care events back to care management "
        "(task / SIU / FHIR Task).",
        "Toy Star measure: diabetic A1C gap — claim says diabetic, no recent ORU/Observation "
        "→ emit care-gap work item.",
        ["HARD", "PAYER QUALITY", "MULTI-FEED"],
    )

    idea(
        story,
        st,
        "2.7 Provider data management (roster, directory, 274 / FHIR Practitioner)",
        "Wrong specialty, address, or network status means misdirected referrals and "
        "directory inaccuracy (CMS / state scrutiny).",
        "Ingest rosters from CAQH-like XML, Excel, or payer 274; validate NPI via registry "
        "mock; publish FHIR PractitionerRole + directory feed; push deltas to claims "
        "adjudication / referral systems.",
        "Dirty Excel roster → validated FHIR Practitioner bundle + rejection file.",
        ["HARD", "NETWORK OPS", "ROSTER / FHIR"],
    )

    idea(
        story,
        st,
        "2.8 Interoperability mandates that never stay done (TEFCA / CMS rules / state APIs)",
        "Rulesets and partner onboarding change faster than IT project cycles. Every new "
        "endpoint becomes another brittle microservice.",
        "Use PilotFish as the durable edge: versioned transforms, partner-specific "
        "policies, FHIR bulk export/import, and audit logging — so “new regulation” is "
        "mostly configuration + route clone, not a rewrite.",
        "Demonstrate Bulk FHIR NDJSON import with patient matching kickouts.",
        ["HARD", "COMPLIANCE", "FHIR BULK"],
    )

    story.append(PageBreak())

    # --- Common missing demos ---
    story.append(Paragraph("3. Common high-value demos not covered yet", st["h1"]))
    story.append(
        Paragraph(
            "These are bread-and-butter healthcare/insurance integrations customers expect. "
            "They are excellent Sandbox candidates: clear happy path, visible kickouts, "
            "and easy executive storytelling.",
            st["body"],
        )
    )

    story.append(
        table(
            [
                ["Idea", "Difficulty", "Why it sells / why build it"],
                [
                    "EDI 834 enrollment → member DB / FHIR Coverage",
                    "Med",
                    "Every benefits conversation; pairs with 270/271 story.",
                ],
                [
                    "270/271 eligibility request/response",
                    "Med",
                    "Front-desk pain everyone knows; great live demo.",
                ],
                [
                    "276/277 claim status inquiry",
                    "Med",
                    "Closes the loop after 837/835 demos.",
                ],
                [
                    "277CA / 999 / TA1 acknowledgments",
                    "Low–Med",
                    "Shows productionops maturity, not just “files out.”",
                ],
                [
                    "ADT + 837 companion: census ↔ claims guardrails",
                    "Med",
                    "Reject claims if no matching admit — concrete $ story.",
                ],
                [
                    "CCD/C-CDA → FHIR DocumentReference",
                    "Med",
                    "Transitions of care / HIE storytelling.",
                ],
                [
                    "SIU scheduling ↔ EHR / call center",
                    "Low–Med",
                    "Visible to operations leaders; easy mock.",
                ],
                [
                    "Pharmacy NCPDP or eRx stub",
                    "Med–Hard",
                    "Opens retail/pharmacy vertical; partner-sensitive.",
                ],
                [
                    "DICOM worklist / imaging order ORM→ORU",
                    "Med",
                    "Radiology is still a major PilotFish foothold.",
                ],
                [
                    "Workers’ comp / property-casualty claim feed (ACORD-ish)",
                    "Med",
                    "Insurance beyond health; ACORD/XML often undersold.",
                ],
                [
                    "Broker portal CSV → canonical → 834 + exceptions",
                    "Low–Med",
                    "Shows “Excel still runs healthcare.”",
                ],
                [
                    "SFTP + AS2 + API multi-channel same route family",
                    "Med",
                    "One business process, many intake channels — classic PF win.",
                ],
            ],
            [2.55 * inch, 0.85 * inch, 3.7 * inch],
        )
    )

    story.append(Paragraph("3.1 “Quick win” Sandbox shortlist (suggested order)", st["h2"]))
    story.append(
        bullets(
            [
                "<b>Eligibility 270/271</b> — mock payer, clinic UI, AAA error theater, then success.",
                "<b>834 enrollment</b> — CSV + EDI in, clean 834 + exception report out.",
                "<b>276/277 claim status</b> — reuse 837 seed data; status inquiry UI.",
                "<b>835 payment integrity</b> — deepen existing 835 demo with underpay exceptions.",
                "<b>C-CDA → FHIR</b> — one continuity-of-care story for IDN / HIE pitches.",
                "<b>Prior auth (278 or FHIR PAS stub)</b> — harder, but differentiates vs “file mover” tools.",
            ],
            st,
        )
    )

    # --- Industry vertical slices ---
    story.append(Paragraph("4. Vertical slices worth a focused case study", st["h1"]))

    idea(
        story,
        st,
        "4.1 Behavioral health / Medicaid MCO",
        "Authorization + encounter data + social determinants from multiple community systems "
        "land in incompatible formats. Audits are brutal.",
        "Extend the DOC-style multi-DB pattern with auth (278), encounters (837I/P), and "
        "HL7 ADT into a single Medicaid encounter submission pipeline with missing-data "
        "kickouts.",
        tags=["MEDICAID", "MCO"],
    )

    idea(
        story,
        st,
        "4.2 Dental / vision / specialty carve-outs",
        "Carve-out payers speak their own dialects; providers hate portal sprawl.",
        "Normalize specialty claim input to 837D (or proprietary), apply carve-out edits, "
        "return proprietary remits mapped to 835 semantics.",
        tags=["SPECIALTY PAYER"],
    )

    idea(
        story,
        st,
        "4.3 Health system merger / EHR migration bridge",
        "During Epic/Oracle Health go-lives, temporary interfaces become permanent monsters.",
        "PilotFish as dual-write / dual-read bridge: legacy HL7 ↔ FHIR ↔ new EHR for a "
        "controlled cutover window with replay and compare reports.",
        tags=["IDN", "CUTOVER"],
    )

    idea(
        story,
        st,
        "4.4 Insurance (life / annuity / P&amp;C) new-business and claims",
        "ACORD XML, PDF apps, and carrier admin systems still do not line up; STP rates "
        "suffer.",
        "Intake ACORD / eApp JSON/XML → validate → transform to policy admin API + imaging "
        "doc store; claim FNOL intake to core claims with acknowledgment SLAs.",
        tags=["LIFE / P&amp;C"],
    )

    story.append(PageBreak())

    # --- Differentiating demo patterns ---
    story.append(Paragraph("5. Demo patterns that make PilotFish look uniquely strong", st["h1"]))
    story.append(
        Paragraph(
            "Any middleware can POST JSON. Pitch and demo the failure modes:",
            st["body"],
        )
    )
    story.append(
        bullets(
            [
                "<b>Exception theater:</b> show kickouts with readable reasons, not just dead-letter dumps.",
                "<b>Partner variance:</b> two hospitals / two payers, one pipeline, two dialect maps.",
                "<b>Protocol bouquet:</b> SFTP + LLP + REST into the same canonical process.",
                "<b>Ack literacy:</b> 999/TA1/277CA/AA/AE — prove you speak production EDI/HL7.",
                "<b>Replay &amp; reprocess:</b> “fix this claim and send it again” without redeploying code.",
                "<b>Observability:</b> transaction timeline from listener → transform → transport.",
                "<b>Custom module honesty:</b> like OCI Object Storage — show gap → Java module → close gap.",
            ],
            st,
        )
    )

    story.append(Paragraph("6. Conversation prompts for discovery calls", st["h1"]))
    story.append(
        bullets(
            [
                "Which trading partner still requires a human to re-key data every week?",
                "Where do you lose the most days in prior auth or claim resubmission?",
                "How many “temporary” Python/PowerShell bridges survived last year’s audit?",
                "What breaks first when a payer changes an EDI companion guide?",
                "Can eligibility, claim status, and remittance tell one consistent member/claim story?",
                "If TEFCA / state exchange / CMS adds another API tomorrow, is that config or a project?",
            ],
            st,
        )
    )

    story.append(Paragraph("7. Suggested next step in this Sandbox", st["h1"]))
    story.append(
        Paragraph(
            "Pick one quick-win demo and one hard differentiator:",
            st["body"],
        )
    )
    story.append(
        table(
            [
                ["Track", "Candidate", "Outcome artifact"],
                [
                    "Quick win",
                    "270/271 eligibility façade + clinic UI",
                    "Runnable demo + LAN URL + route diagrams",
                ],
                [
                    "Quick win",
                    "834 CSV/EDI → member table + exceptions",
                    "Runnable demo + exception PDF sample",
                ],
                [
                    "Differentiator",
                    "Prior auth PAS/278 completeness + decision loop",
                    "Case-study style demo + gaps/custom module notes",
                ],
                [
                    "Deepen existing",
                    "835 underpay / posting exceptions on OCI demo",
                    "Upgrade existing 835 demo rather than new folder",
                ],
            ],
            [1.2 * inch, 2.9 * inch, 3.0 * inch],
        )
    )
    story.append(Spacer(1, 10))
    story.append(
        Paragraph(
            "This PDF is intentionally idea-dense, not a build plan. When you pick one, "
            "follow docs/INTERFACE_CONSTRUCTION_PLAYBOOK.md and pull module semantics from "
            "the external PilotFish Documentation project referenced by "
            "PilotFish_Documentation/DOCUMENTATION_LOCATION.txt.",
            st["callout"],
        )
    )

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.75 * inch,
        title="Healthcare & Insurance PilotFish Opportunity Ideas",
        author="PilotFish Sandbox",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
