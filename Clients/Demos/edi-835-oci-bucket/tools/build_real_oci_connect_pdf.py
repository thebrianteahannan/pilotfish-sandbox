#!/usr/bin/env python3
"""PDF: manual steps to connect OciObjectStorageTransport to real Oracle OCI."""

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
OUT = ROOT / "documents" / "Connect_OciObjectStorageTransport_To_Real_Oracle_OCI.pdf"
BRAND = "PILOTFISH  ·  CONNECT CUSTOM OCI TRANSPORT TO REAL ORACLE OCI"


def styles():
    base = getSampleStyleSheet()
    return {
        "h1": ParagraphStyle(
            "H1",
            parent=base["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=15,
            textColor=colors.HexColor("#0b6e4f"),
            spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "H2",
            parent=base["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            textColor=colors.HexColor("#0b6e4f"),
            spaceBefore=12,
            spaceAfter=6,
        ),
        "h3": ParagraphStyle(
            "H3",
            parent=base["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=10.5,
            textColor=colors.HexColor("#243044"),
            spaceBefore=8,
            spaceAfter=4,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.5,
            leading=12.5,
            alignment=TA_JUSTIFY,
            spaceAfter=6,
        ),
        "bullet": ParagraphStyle(
            "Bullet",
            parent=base["Normal"],
            fontName="Helvetica",
            fontSize=9.3,
            leading=12,
            leftIndent=6,
            spaceAfter=2,
            alignment=TA_LEFT,
        ),
        "code": ParagraphStyle(
            "Code",
            parent=base["Code"],
            fontName="Courier",
            fontSize=7.8,
            leading=10.5,
            backColor=colors.HexColor("#f3f6f8"),
            borderPadding=4,
            spaceAfter=8,
            spaceBefore=3,
        ),
        "note": ParagraphStyle(
            "Note",
            parent=base["Normal"],
            fontName="Helvetica-Oblique",
            fontSize=9,
            leading=11.5,
            textColor=colors.HexColor("#334155"),
            spaceAfter=8,
        ),
        "warn": ParagraphStyle(
            "Warn",
            parent=base["Normal"],
            fontName="Helvetica-Bold",
            fontSize=9,
            leading=12,
            textColor=colors.HexColor("#9a3412"),
            backColor=colors.HexColor("#fff7ed"),
            borderPadding=5,
            spaceAfter=8,
        ),
    }


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#64748b"))
    canvas.drawString(0.7 * inch, 0.45 * inch, BRAND)
    canvas.drawRightString(letter[0] - 0.7 * inch, 0.45 * inch, f"Page {doc.page}")
    canvas.restoreState()


def bullets(items, st):
    return ListFlowable(
        [ListItem(Paragraph(i, st["bullet"]), leftIndent=10, value="•") for i in items],
        bulletType="bullet",
        start="•",
    )


def table(rows, widths):
    t = Table(rows, colWidths=widths)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#d9f0e7")),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#94a3b8")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def main():
    st = styles()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.6 * inch,
        bottomMargin=0.7 * inch,
    )
    story = []

    story.append(Paragraph("Connecting the Custom OCI Transport to Real Oracle OCI", st["h1"]))
    story.append(
        Paragraph(
            "This guide explains the <b>manual steps</b> to point PilotFish’s custom "
            "<font face='Courier'>OciObjectStorageTransport</font> at a real "
            "<b>Oracle Cloud Infrastructure Object Storage</b> tenancy (not the local floci-oci emulator).",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "Module FQCN: <font face='Courier'>com.pilotfish.eip.modules.oci.OciObjectStorageTransport</font>. "
            "Demo route today uses floci endpoint <font face='Courier'>http://floci-oci:4599</font> — "
            "that override is what you remove/change for production Oracle.",
            st["note"],
        )
    )
    story.append(
        Paragraph(
            "Naming note: OCI = Oracle Cloud Infrastructure. This is not Amazon S3.",
            st["warn"],
        )
    )

    story.append(Paragraph("1. Prerequisites in Oracle Cloud Console", st["h2"]))
    story.append(Paragraph("1.1 Tenancy &amp; identity", st["h3"]))
    story.append(
        bullets(
            [
                "Access to an OCI tenancy (Console URL typically <font face='Courier'>https://cloud.oracle.com</font>).",
                "A compartment where Object Storage buckets are allowed (often root or a dedicated Integration compartment).",
                "An IAM <b>user</b> (or group) that PilotFish will authenticate as, with Object Storage write permissions.",
            ],
            st,
        )
    )

    story.append(Paragraph("1.2 Create / confirm the bucket", st["h3"]))
    story.append(
        bullets(
            [
                "Console → <b>Storage → Buckets → Create Bucket</b> (or reuse an existing bucket).",
                "Note the bucket <b>name</b> exactly (case-sensitive).",
                "Note the <b>Object Storage namespace</b> (shown on the Bucket details page / Tenancy details). "
                "CLI: <font face='Courier'>oci os ns get</font>.",
                "Decide object naming (demo uses <font face='Courier'>835_{ST}_{timestamp}.json</font>).",
            ],
            st,
        )
    )

    story.append(Paragraph("1.3 IAM policy (minimum for PutObject)", st["h3"]))
    story.append(
        Paragraph(
            "Attach a policy to the group that contains the API-key user. Example (adjust compartment name):",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "Allow group PilotFishIntegrators to manage objects in compartment Integration<br/>"
            "Allow group PilotFishIntegrators to read buckets in compartment Integration",
            st["code"],
        )
    )
    story.append(
        Paragraph(
            "For least privilege, prefer <font face='Courier'>manage objects</font> (or "
            "<font face='Courier'>OBJECT_CREATE</font> / <font face='Courier'>OBJECT_OVERWRITE</font> "
            "style statements) scoped to one bucket if your org uses finer IAM.",
            st["note"],
        )
    )

    story.append(Paragraph("2. Create an API signing key (Console)", st["h2"]))
    story.append(
        bullets(
            [
                "Console → <b>Identity &amp; Security → Users</b> → select the integration user.",
                "<b>API Keys → Add API Key</b>.",
                "Choose <b>Generate API Key Pair</b> (easiest) or upload a public key you generated with OpenSSL.",
                "Download / save the <b>private key PEM</b> immediately (Oracle only stores the public key).",
                "Copy the <b>Configuration File Preview</b> values: user OCID, fingerprint, tenancy OCID, region.",
            ],
            st,
        )
    )
    story.append(
        Paragraph(
            "Store the PEM on the eiPlatform host in a protected path, e.g. "
            "<font face='Courier'>/opt/pilotfish/secrets/oci_api_key.pem</font> "
            "(readable by the Tomcat/eiPlatform OS user only; mode 600).",
            st["body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("3. Values to collect (checklist)", st["h2"]))
    rows = [
        [
            Paragraph("<b>Item</b>", st["bullet"]),
            Paragraph("<b>Where to find it</b>", st["bullet"]),
            Paragraph("<b>Transport field</b>", st["bullet"]),
        ],
        [
            Paragraph("Region", st["bullet"]),
            Paragraph("Console region selector / config preview (e.g. <font face='Courier'>us-ashburn-1</font>)", st["bullet"]),
            Paragraph("<font face='Courier'>OciRegion</font>", st["bullet"]),
        ],
        [
            Paragraph("Namespace", st["bullet"]),
            Paragraph("Tenancy / Bucket details; <font face='Courier'>oci os ns get</font>", st["bullet"]),
            Paragraph("<font face='Courier'>OciNamespace</font>", st["bullet"]),
        ],
        [
            Paragraph("Bucket name", st["bullet"]),
            Paragraph("Storage → Buckets", st["bullet"]),
            Paragraph("<font face='Courier'>OciBucket</font>", st["bullet"]),
        ],
        [
            Paragraph("Tenancy OCID", st["bullet"]),
            Paragraph("Profile → Tenancy → OCID / config preview", st["bullet"]),
            Paragraph("<font face='Courier'>OciTenancyOcid</font>", st["bullet"]),
        ],
        [
            Paragraph("User OCID", st["bullet"]),
            Paragraph("User details / config preview", st["bullet"]),
            Paragraph("<font face='Courier'>OciUserOcid</font>", st["bullet"]),
        ],
        [
            Paragraph("Fingerprint", st["bullet"]),
            Paragraph("API Keys list / config preview", st["bullet"]),
            Paragraph("<font face='Courier'>OciFingerprint</font>", st["bullet"]),
        ],
        [
            Paragraph("Private key PEM path", st["bullet"]),
            Paragraph("File you downloaded/generated on the PF host", st["bullet"]),
            Paragraph("<font face='Courier'>OciPrivateKeyPath</font>", st["bullet"]),
        ],
        [
            Paragraph("Service Endpoint Override", st["bullet"]),
            Paragraph("<b>Leave blank</b> for real OCI (demo only used floci URL)", st["bullet"]),
            Paragraph("<font face='Courier'>OciEndpoint</font> = empty", st["bullet"]),
        ],
    ]
    story.append(table(rows, [1.4 * inch, 3.2 * inch, 1.8 * inch]))
    story.append(Spacer(1, 0.12 * inch))

    story.append(Paragraph("4. Manual PilotFish / eiPlatform changes", st["h2"]))
    story.append(Paragraph("4.1 Confirm the custom module JAR is installed", st["h3"]))
    story.append(
        bullets(
            [
                "Ensure <font face='Courier'>modules-oci-object-storage.jar</font> is in "
                "<font face='Courier'>WEB-INF/lib</font> (or your licensed modules drop folder).",
                "Restart eiPlatform / Tomcat after placing the JAR.",
                "No floci container, throwaway key, or local emulator is required for real OCI.",
            ],
            st,
        )
    )

    story.append(Paragraph("4.2 Edit the route Transport (eiConsole or route.xml)", st["h3"]))
    story.append(
        Paragraph(
            "On route <b>2 – Split ST JSON And OCI</b>, open the "
            "<b>OCI Object Storage PutObject</b> transport and set:",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "OciRegion          = us-ashburn-1          # your region<br/>"
            "OciNamespace       = &lt;your-namespace&gt;<br/>"
            "OciBucket          = &lt;your-bucket&gt;<br/>"
            "OciObjectName      = {ognl:getAttribute('OciObjectName')}   # keep as-is if demo processors set it<br/>"
            "OciContentType     = application/json<br/>"
            "OciEndpoint        =                      # CLEAR / empty for real Oracle<br/>"
            "OciAuthMode        = API Key<br/>"
            "OciTenancyOcid     = ocid1.tenancy.oc1..aaaa...<br/>"
            "OciUserOcid        = ocid1.user.oc1..aaaa...<br/>"
            "OciFingerprint     = aa:bb:cc:...<br/>"
            "OciPrivateKeyPath  = /opt/pilotfish/secrets/oci_api_key.pem<br/>"
            "OciPrivateKeyPem   =                      # leave empty when using file path",
            st["code"],
        )
    )
    story.append(
        Paragraph(
            "Also update any “display only” processors that still embed the floci URL "
            "(e.g. Set OCI Object URL attribute) so ops dashboards don’t show the emulator host.",
            st["note"],
        )
    )

    story.append(Paragraph("4.3 Networking / egress", st["h3"]))
    story.append(
        bullets(
            [
                "eiPlatform host must reach Oracle Object Storage HTTPS endpoints for the region "
                "(typically <font face='Courier'>https://objectstorage.&lt;region&gt;.oraclecloud.com</font>).",
                "Allow outbound 443 through corporate proxies/firewalls; if an HTTPS proxy is required, "
                "JVM proxy system properties (or a future transport proxy setting) must be configured.",
                "TLS trust store must trust public CA certs used by Oracle (default JVM cacerts is usually fine).",
            ],
            st,
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("5. Validate outside PilotFish first (recommended)", st["h2"]))
    story.append(
        Paragraph(
            "Before changing the route, prove credentials with OCI CLI or a tiny SDK script on the same host:",
            st["body"],
        )
    )
    story.append(
        Paragraph(
            "# ~/.oci/config pointing at the same user/key/region<br/>"
            "oci os ns get<br/>"
            "oci os object put -ns &lt;namespace&gt; -bn &lt;bucket&gt; "
            "--file ./test.json --name smoke-test.json",
            st["code"],
        )
    )
    story.append(
        Paragraph(
            "If CLI PutObject fails (401/404/403), fix IAM/credentials/namespace/bucket before debugging PilotFish.",
            st["warn"],
        )
    )

    story.append(Paragraph("6. PilotFish smoke checklist", st["h2"]))
    story.append(
        bullets(
            [
                "Drop a multi-ST 835 through the existing SFTP → split → JSON pipeline.",
                "Confirm transport stage <font face='Courier'>OCI Object Storage PutObject</font> completes without retries.",
                "In Console → Bucket → Objects, verify one object per ST (or expected object names).",
                "Optional: inspect TX attributes set by the module: "
                "<font face='Courier'>com.pilotfish.oci.requestId</font>, "
                "<font face='Courier'>com.pilotfish.oci.eTag</font>, "
                "<font face='Courier'>com.pilotfish.oci.objectName</font>.",
            ],
            st,
        )
    )

    story.append(Paragraph("7. Demo → real OCI: what to stop using", st["h2"]))
    rows2 = [
        [
            Paragraph("<b>Demo piece</b>", st["bullet"]),
            Paragraph("<b>Action for real OCI</b>", st["bullet"]),
        ],
        [
            Paragraph("floci-oci Docker service (:4599)", st["bullet"]),
            Paragraph("Stop / remove from compose; not used", st["bullet"]),
        ],
        [
            Paragraph("<font face='Courier'>oci-config/floci_key.pem</font> throwaway key", st["bullet"]),
            Paragraph("Replace with real API private key; do not reuse floci OCIDs", st["bullet"]),
        ],
        [
            Paragraph("<font face='Courier'>OciEndpoint=http://floci-oci:4599</font>", st["bullet"]),
            Paragraph("<b>Clear this field</b> so the SDK uses regional Oracle endpoints", st["bullet"]),
        ],
        [
            Paragraph("floci-init bucket bootstrap", st["bullet"]),
            Paragraph("Create bucket/policies in Oracle Console (or Terraform) instead", st["bullet"]),
        ],
    ]
    story.append(table(rows2, [2.8 * inch, 3.6 * inch]))
    story.append(Spacer(1, 0.12 * inch))

    story.append(Paragraph("8. Security recommendations", st["h2"]))
    story.append(
        bullets(
            [
                "Never commit private keys to git; mount secrets via volume / secret store.",
                "Prefer file path over <font face='Courier'>OciPrivateKeyPem</font> inline in route.xml.",
                "Rotate API keys periodically; revoke old fingerprints in Console.",
                "Scope IAM to one compartment/bucket; avoid tenancy-wide <font face='Courier'>manage all-resources</font>.",
                "This demo module currently supports <b>API Key</b> auth only — instance/resource principals would be a follow-on enhancement for OKE/Compute.",
            ],
            st,
        )
    )

    story.append(Paragraph("9. Common failures", st["h2"]))
    rows3 = [
        [
            Paragraph("<b>Symptom</b>", st["bullet"]),
            Paragraph("<b>Likely cause</b>", st["bullet"]),
        ],
        [
            Paragraph("401 / NotAuthenticated", st["bullet"]),
            Paragraph("Wrong fingerprint, wrong private key, clock skew, or user OCID mismatch", st["bullet"]),
        ],
        [
            Paragraph("404 BucketNotFound / NamespaceNotFound", st["bullet"]),
            Paragraph("Wrong namespace or bucket name/region", st["bullet"]),
        ],
        [
            Paragraph("403 NotAuthorizedOrNotFound", st["bullet"]),
            Paragraph("IAM policy missing object write on that compartment/bucket", st["bullet"]),
        ],
        [
            Paragraph("Connection timeout", st["bullet"]),
            Paragraph("Egress/firewall/proxy blocking regional Object Storage HTTPS", st["bullet"]),
        ],
        [
            Paragraph("Still writing to floci", st["bullet"]),
            Paragraph("<font face='Courier'>OciEndpoint</font> still set to emulator URL", st["bullet"]),
        ],
    ]
    story.append(table(rows3, [2.4 * inch, 4.0 * inch]))
    story.append(Spacer(1, 0.15 * inch))

    story.append(Paragraph("Bottom line", st["h2"]))
    story.append(
        Paragraph(
            "The custom module already speaks real OCI PutObject via the official Java SDK. "
            "To go from the local emulator to production Oracle: create bucket + IAM + API key in Console, "
            "place the PEM on the eiPlatform host, clear <font face='Courier'>OciEndpoint</font>, "
            "and paste the real region/namespace/bucket/tenancy/user/fingerprint into the transport. "
            "No Amazon S3 settings are involved.",
            st["body"],
        )
    )

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
