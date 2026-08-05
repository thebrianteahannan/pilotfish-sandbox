#!/usr/bin/env python3
"""Build PilotFish gaps / custom module recommendation PDF for EDI 835 → OCI demo."""

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
OUT = ROOT / "documents" / "PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf"
BRAND = "PILOTFISH  ·  EDI 835 → OCI GAPS & CUSTOM MODULES"


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
        ),
        "h2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12.5,
            textColor=colors.HexColor("#0b6e4f"),
            spaceBefore=14,
            spaceAfter=6,
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
            spaceAfter=2,
            alignment=TA_LEFT,
        ),
        "code": ParagraphStyle(
            "Code",
            parent=base["Code"],
            fontName="Courier",
            fontSize=8,
            leading=10.5,
            backColor=colors.HexColor("#f3f6f8"),
            borderPadding=4,
            spaceAfter=8,
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
    }


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#64748b"))
    canvas.drawString(0.75 * inch, 0.45 * inch, BRAND)
    canvas.drawRightString(letter[0] - 0.75 * inch, 0.45 * inch, f"Page {doc.page}")
    canvas.restoreState()


def bullets(items, st):
    return ListFlowable(
        [ListItem(Paragraph(i, st["bullet"]), leftIndent=12, value="•") for i in items],
        bulletType="bullet",
        start="•",
    )


def main():
    st = styles()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.7 * inch,
    )
    story = []

    story.append(Paragraph("PilotFish Gaps, Bottlenecks &amp; Custom Module Plan", st["h1"]))
    story.append(
        Paragraph(
            "Scoped to the Brian Wolfe workflow: <b>SFTP poll EDI 835</b> → <b>split each ST</b> → "
            "<b>JSON</b> → <b>Oracle OCI Object Storage</b>. This document is intentionally critical of "
            "product gaps the demo hits, and recommends <b>custom Java eiPlatform modules</b>.",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "Companion runnable demo: <font face='Courier'>Clients/Demos/edi-835-oci-bucket/</font>. "
            "See also DESIGN.md.",
            st["note"],
        )
    )

    story.append(Paragraph("1. Target architecture (boss conversation)", st["h2"]))
    story.append(
        Paragraph(
            "SFTP Polling (EDI 835 files) → Split out each ST segment and create a JSON file → "
            "Send JSON to Oracle OCI bucket (using HTTP POST right now, since we do not have an OCI Transport).",
            st["body"],
        )
    )

    story.append(Paragraph("2. Issue register", st["h2"]))
    rows = [
        [
            Paragraph("<b>Sev</b>", st["bullet"]),
            Paragraph("<b>Gap / flaw / bottleneck</b>", st["bullet"]),
            Paragraph("<b>Why it matters</b>", st["bullet"]),
            Paragraph("<b>Recommendation</b>", st["bullet"]),
        ],
        [
            Paragraph("Critical", st["bullet"]),
            Paragraph("No native <b>OCI Object Storage Transport</b> (or Listener)", st["bullet"]),
            Paragraph(
                "AWS S3 / GCS modules exist on 23R1; OCI does not. Forces HTTP workarounds and weak ops (no native opc-* headers, multipart, PAR).",
                st["bullet"],
            ),
            Paragraph(
                "Build <font face='Courier'>OciObjectStorageTransport</font> (Java) using OCI Java SDK or signed REST.",
                st["bullet"],
            ),
        ],
        [
            Paragraph("High", st["bullet"]),
            Paragraph("<font face='Courier'>HttpPostTransport</font> is POST-only", st["bullet"]),
            Paragraph(
                "OCI PutObject is HTTP <b>PUT</b> to <font face='Courier'>/n/{ns}/b/{bucket}/o/{object}</font>. Method mismatch and wrong signing model.",
                st["bullet"],
            ),
            Paragraph("Custom transport with configurable PUT/POST + upload API; or pre-authenticated request (PAR) URL mode.", st["bullet"]),
        ],
        [
            Paragraph("High", st["bullet"]),
            Paragraph("No OCI request signing helper", st["bullet"]),
            Paragraph(
                "Oracle requires tenancy/user/fingerprint + private key (API key) or instance principals / resource principals. Naked HTTP will 401 against real OCI.",
                st["bullet"],
            ),
            Paragraph("Module config: region, namespace, bucket, auth mode (API key / instance / resource / PAR).", st["bullet"]),
        ],
        [
            Paragraph("Med", st["bullet"]),
            Paragraph("ST split is multi-module choreography", st["bullet"]),
            Paragraph(
                "Demo uses EDI→XML + XPath <font face='Courier'>//Transaction</font>. Fragile if Friendly Names / legacy XML / version tables change. Alternative FileRecordForkingListener / EdiForkingModule still not “835-aware JSON”.",
                st["bullet"],
            ),
            Paragraph(
                "Optional <font face='Courier'>EdiStSplitToJsonProcessor</font>: ST/SE aware splitter emitting one JSON TX per ST with ISA/GS wrappers.",
                st["bullet"],
            ),
        ],
        [
            Paragraph("Med", st["bullet"]),
            Paragraph("Partial failure on multi-ST files", st["bullet"]),
            Paragraph(
                "N HTTP calls after fork; mid-file OCI failure leaves half uploaded without a compensation store.",
                st["bullet"],
            ),
            Paragraph("Transport batch + transaction store; or join + zip multipart upload.", st["bullet"]),
        ],
        [
            Paragraph("Med", st["bullet"]),
            Paragraph("No first-class OCI observability", st["bullet"]),
            Paragraph("Missing opc-request-id correlation attributes, bucket/object attrs, eTag persistence.", st["bullet"]),
            Paragraph("Populate TX attrs from response headers in custom transport.", st["bullet"]),
        ],
        [
            Paragraph("Low", st["bullet"]),
            Paragraph("Demo OCI mock ≠ IAM / CMEK / lifecycle", st["bullet"]),
            Paragraph("Accepted for lab; real customers need compartment policies, encryption keys, retention.", st["bullet"]),
            Paragraph("Document SDK module features; do not pretend mock == OCI.", st["bullet"]),
        ],
    ]
    table = Table(rows, colWidths=[0.7 * inch, 1.7 * inch, 2.3 * inch, 2.1 * inch])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#d9f0e7")),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#94a3b8")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
                ("BACKGROUND", (0, 1), (-1, 1), colors.HexColor("#fff1f2")),
                ("BACKGROUND", (0, 2), (-1, 2), colors.HexColor("#fff7ed")),
            ]
        )
    )
    story.append(table)
    story.append(Spacer(1, 0.15 * inch))

    story.append(PageBreak())
    story.append(Paragraph("3. Recommended custom Java modules", st["h2"]))

    story.append(Paragraph("3.1 OciObjectStorageTransport (priority #1)", st["h3"]))
    story.append(
        Paragraph(
            "FQCN sketch: <font face='Courier'>com.pilotfish.eip.modules.oci.OciObjectStorageTransport</font> "
            "extends <font face='Courier'>AbstractTransport</font>. Categories: WEB, CLOUD, SPECIAL_PROTOCOL.",
            st["body"],
        )
    )
    story.append(
        bullets(
            [
                "Config: Region, Namespace, Bucket, ObjectName (OGNL), ContentType, AuthMode, ConfigFile/Profile or API key fields, Timeout, Multipart threshold.",
                "Behavior: PutObject (default), optional Get/Head for response listeners; set attributes <font face='Courier'>com.pilotfish.oci.requestId</font>, <font face='Courier'>eTag</font>, <font face='Courier'>opc-content-md5</font>.",
                "Deps: <font face='Courier'>oci-java-sdk-objectstorage</font> (+ common + bom). Ship as <font face='Courier'>modules-oci</font> jar into WEB-INF/lib.",
                "Why not HttpPost: wrong verb, no signing, no multipart, no native PAR/SSE-C/KMS knobs.",
            ],
            st,
        )
    )

    story.append(Paragraph("Skeleton in this demo", st["h3"]))
    story.append(
        Paragraph(
            "<font face='Courier'>custom-modules/oci-object-storage-transport/</font> — compile against eiPlatform "
            "extend APIs + OCI SDK. Not loaded into the demo image until built/signed per customer license policy.",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "Key methods: getType()/getDescription(), getConfigurationDescriptor(), "
            "processTransaction(...) → ObjectStorageClient.putObject(...).",
            st["code"],
        )
    )

    story.append(Paragraph("3.2 EdiStSplitToJsonProcessor (priority #2)", st["h3"]))
    story.append(
        bullets(
            [
                "Input: raw X12; detect element / segment / repetition delimiters from ISA.",
                "Split on ST–SE boundaries; wrap each with reconstructed ISA/GS/GE/IEA (control # rewrite).",
                "Emit JSON ({documentType, controlNumber, segments[], monetarySummary}) or fork child transactions.",
                "Reduces XPath fragility vs EDITransformationModule + Friendly Names variance.",
            ],
            st,
        )
    )

    story.append(Paragraph("3.3 Optional OciObjectStorageListener", st["h3"]))
    story.append(
        Paragraph(
            "Poll bucket prefixes / events for downstream 835/999/277. Useful later; not required for this upload-only boss flow.",
            st["body"],
        )
    )

    story.append(Paragraph("4. What the demo deliberately fakes", st["h2"]))
    story.append(
        bullets(
            [
                "Local Flask mock implements OCI-shaped paths and accepts PUT <b>and</b> POST.",
                "No OCI tenancy, compartments, IAM policies, or customer-managed keys.",
                "HttpPostTransport stands in for the missing OCI Transport (same workaround Brian described).",
                "Synthetic 2×ST 835 — not a certified SNIP clinic.",
            ],
            st,
        )
    )

    story.append(Paragraph("5. Suggested delivery plan for PF engineering", st["h2"]))
    story.append(
        bullets(
            [
                "Sprint A: OciObjectStorageTransport PutObject + API-key auth + attribute echo (parity with AwsS3Transport).",
                "Sprint B: PAR URL mode + multipart + retries with opc-client-request-id.",
                "Sprint C: Instance/resource principal auth for OKE/Compute.",
                "Sprint D (optional): EdiStSplitToJsonProcessor productized from this demo’s XSLT logic.",
            ],
            st,
        )
    )

    story.append(Paragraph("6. Bottom line for stakeholders", st["h2"]))
    story.append(
        Paragraph(
            "PilotFish can already own the <b>SFTP → EDI → fork → JSON</b> half cleanly. The structural product hole is "
            "<b>Oracle Cloud Object Storage as a first-class Transport</b>. Continuing to paper over it with "
            "HttpPostTransport creates signing, method, multipart, and ops blind spots. Invest in a custom (then "
            "productized) Java <b>OciObjectStorageTransport</b>.",
            st["body"],
        )
    )

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
