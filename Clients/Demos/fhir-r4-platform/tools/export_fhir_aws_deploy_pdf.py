#!/usr/bin/env python3
"""AWS deployment guide PDF for the FHIR R4 Expandable Platform demo."""
from __future__ import annotations

from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    Preformatted,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "documents" / "FHIR_R4_Platform_AWS_Deployment_Guide.pdf"
NAVY = colors.HexColor("#0b3d5c")
TEAL = colors.HexColor("#0e7490")
LIGHT = colors.HexColor("#f0f9ff")
WARN = colors.HexColor("#fef3c7")
OK = colors.HexColor("#ecfdf5")
MUTED = colors.HexColor("#f8fafc")
BORDER = colors.HexColor("#cbd5e1")
CODE_BG = colors.HexColor("#0f172a")


def styles():
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle(
            "ct", parent=base["Title"], fontSize=20, textColor=NAVY, spaceAfter=8, leading=24
        ),
        "cover_sub": ParagraphStyle(
            "cs",
            parent=base["Normal"],
            fontSize=11,
            textColor=TEAL,
            alignment=TA_CENTER,
            spaceAfter=6,
            leading=14,
        ),
        "h1": ParagraphStyle(
            "h1", parent=base["Heading1"], fontSize=13, textColor=NAVY, spaceBefore=12, spaceAfter=5
        ),
        "h2": ParagraphStyle(
            "h2", parent=base["Heading2"], fontSize=10.5, textColor=TEAL, spaceBefore=9, spaceAfter=3
        ),
        "body": ParagraphStyle(
            "body", parent=base["Normal"], fontSize=9, leading=12, alignment=TA_JUSTIFY, spaceAfter=5
        ),
        "small": ParagraphStyle(
            "small",
            parent=base["Normal"],
            fontSize=8,
            leading=10.5,
            textColor=colors.HexColor("#334155"),
        ),
        "tiny": ParagraphStyle(
            "tiny",
            parent=base["Normal"],
            fontSize=7.5,
            leading=9.5,
            textColor=colors.HexColor("#475569"),
            fontName="Courier",
        ),
        "bullet": ParagraphStyle("bu", parent=base["Normal"], fontSize=8.5, leading=11),
        "callout": ParagraphStyle(
            "co", parent=base["Normal"], fontSize=8.5, leading=11, textColor=colors.HexColor("#78350f")
        ),
        "ok_callout": ParagraphStyle(
            "ok", parent=base["Normal"], fontSize=8.5, leading=11, textColor=colors.HexColor("#065f46")
        ),
        "th": ParagraphStyle(
            "th",
            parent=base["Normal"],
            fontSize=8,
            leading=10,
            textColor=colors.white,
            fontName="Helvetica-Bold",
        ),
        "code": ParagraphStyle(
            "code",
            parent=base["Code"],
            fontSize=7.5,
            leading=9.5,
            textColor=colors.HexColor("#e2e8f0"),
            backColor=CODE_BG,
            leftIndent=4,
            rightIndent=4,
            spaceBefore=4,
            spaceAfter=6,
        ),
    }


def callout(text: str, s, kind="warn") -> Table:
    if kind == "ok":
        bg, border, style = OK, colors.HexColor("#059669"), s["ok_callout"]
    else:
        bg, border, style = WARN, colors.HexColor("#d97706"), s["callout"]
    t = Table([[Paragraph(text, style)]], colWidths=[6.5 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), bg),
                ("BOX", (0, 0), (-1, -1), 0.5, border),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return t


def bullets(items, s):
    return ListFlowable(
        [ListItem(Paragraph(i, s["bullet"]), leftIndent=10, value="•") for i in items],
        bulletType="bullet",
        start="•",
    )


def table(rows, col_widths, s, header=True):
    data = []
    for r_i, row in enumerate(rows):
        cells = []
        for cell in row:
            style = s["th"] if header and r_i == 0 else s["small"]
            cells.append(Paragraph(str(cell), style))
        data.append(cells)
    t = Table(data, colWidths=col_widths, repeatRows=1 if header else 0)
    style_cmds = [
        ("GRID", (0, 0), (-1, -1), 0.35, BORDER),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("ROWBACKGROUNDS", (0, 1 if header else 0), (-1, -1), [colors.white, LIGHT]),
    ]
    if header:
        style_cmds.append(("BACKGROUND", (0, 0), (-1, 0), NAVY))
    t.setStyle(TableStyle(style_cmds))
    return t


def code_block(text: str, s) -> Table:
    pre = Preformatted(text.rstrip() + "\n", s["code"])
    t = Table([[pre]], colWidths=[6.5 * inch])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), CODE_BG),
                ("BOX", (0, 0), (-1, -1), 0.4, colors.HexColor("#334155")),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def build():
    s = styles()
    story = []

    # Cover
    story.append(Spacer(1, 1.1 * inch))
    story.append(Paragraph("AWS Deployment Guide", s["cover_title"]))
    story.append(
        Paragraph(
            "Taking the PilotFish FHIR R4 Expandable Platform<br/>from local Docker Compose to a real AWS environment",
            s["cover_sub"],
        )
    )
    story.append(Spacer(1, 0.15 * inch))
    story.append(
        Paragraph(
            f"Implementation-oriented · CapabilityStatement 0.6.0 · {date.today().isoformat()}",
            s["cover_sub"],
        )
    )
    story.append(Spacer(1, 0.3 * inch))
    story.append(
        callout(
            "<b>Audience.</b> Platform engineers, DevOps, and FHIR integration leads who would "
            "open a ticket titled “stand up the FHIR R4 PilotFish demo in AWS.” This is a "
            "deployability map — not an automatic production certification. Keep the companion "
            "<i>Expert Due Diligence</i> PDF in scope for FHIR feature gaps.",
            s,
        )
    )
    story.append(Spacer(1, 0.12 * inch))
    story.append(
        callout(
            "<b>Recommended compute path for first AWS env:</b> ECS Fargate (EIP + Web UI) + "
            "RDS for SQL Server + Application Load Balancer (ACM TLS) + Secrets Manager + "
            "EFS (shared bulk-export / file dirs) + Keycloak on ECS <i>or</i> Amazon Cognito "
            "as token issuer. EC2 single-host Docker Compose is acceptable for a sandboxed "
            "staging box only.",
            s,
            kind="ok",
        )
    )

    story.append(PageBreak())

    # 1 What you are deploying
    story.append(Paragraph("1. What you are actually deploying", s["h1"]))
    story.append(
        Paragraph(
            "The local demo is four containers (+ one SQL init job). Your AWS design must "
            "preserve those roles, even if services move to managed AWS equivalents.",
            s["body"],
        )
    )
    story.append(
        table(
            [
                ["Demo service", "Role", "Local port", "AWS-managed destination"],
                [
                    "pilotfish",
                    "eiPlatform Tomcat + custom FHIR JARs (JWT, HAPI validate, Bulk)",
                    "8110 → 8080",
                    "ECS Fargate service (or EC2) behind internal/public ALB",
                ],
                [
                    "sqlserver",
                    "FhirR4PlatformDemo DB (resources, search, export jobs)",
                    "14338 → 1433",
                    "Amazon RDS for SQL Server (Multi-AZ for prod)",
                ],
                [
                    "keycloak",
                    "OIDC issuer + JWKS for Bearer on writes/$export",
                    "8112 → 8080",
                    "Keycloak on ECS/EC2 <b>or</b> Cognito User Pool / Enterprise IdP",
                ],
                [
                    "webui",
                    "Demo operator UI (optional in prod)",
                    "8111",
                    "ECS task on private ALB, or omit and use API-only",
                ],
                [
                    "host volumes output/, input/, logs/",
                    "Bulk NDJSON, outbound queue, Tomcat logs",
                    "bind mounts",
                    "EFS mount + CloudWatch Logs (+ S3 lifecycle for exports)",
                ],
            ],
            [1.15 * inch, 2.15 * inch, 0.95 * inch, 2.25 * inch],
            s,
        )
    )
    story.append(Spacer(1, 0.08 * inch))
    story.append(Paragraph("Critical filesystem contract inside the EIP container:", s["body"]))
    story.append(
        code_block(
            "/opt/pilotfish/output/fhir-store\n"
            "/opt/pilotfish/output/outbound-responses\n"
            "/opt/pilotfish/output/bulk-export/{jobId}/\n"
            "/opt/pilotfish/input/outbound\n"
            "/usr/local/tomcat/webapps/eip/eip-root/   # routes + environment-settings.conf",
            s,
        )
    )
    story.append(
        callout(
            "<b>PilotFish license reality:</b> the demo image is built <font face='Courier'>FROM "
            "pilotfish-eip:23R1</font>. AWS deployments need a licensed eiPlatform runtime and "
            "an agreed image distribution path (customer registry vs PilotFish-provided base). "
            "Do not assume the sandbox demo image is redistribution-cleared for production.",
            s,
        )
    )

    # 2 Target architecture
    story.append(Paragraph("2. Reference architecture (first real AWS environment)", s["h1"]))
    story.append(Paragraph("Network", s["h2"]))
    story.append(
        bullets(
            [
                "<b>VPC</b> with 2+ AZs; public subnets (ALB) + private app subnets (ECS) + private data subnets (RDS).",
                "<b>ALB</b> internet-facing (or internal-only for VPN/PrivateLink partners) with ACM certificate.",
                "Optional <b>AWS WAF</b> on ALB for FHIR API abuse controls / IP allowlists.",
                "No public security-group ingress to RDS, Keycloak admin, or SQL ports.",
                "Nat Gateway(s) so private tasks can pull from ECR and call JWKS / outbound FHIR.",
            ],
            s,
        )
    )
    story.append(Paragraph("Logical request path", s["h2"]))
    story.append(
        code_block(
            "Client\n"
            "  → ALB :443  path /eip/*        → Target group: EIP tasks :8080\n"
            "  → ALB :443  path /auth/*         → Target group: Keycloak (if self-hosted)\n"
            "  → ALB :443  path / (ops UI)      → Target group: Web UI :8111  [optional]\n"
            "EIP task\n"
            "  → RDS SQL Server :1433 (SG-locked)\n"
            "  → EFS /opt/pilotfish/output & /input\n"
            "  → OIDC JWKS (Keycloak SG or Cognito public HTTPS)\n"
            "Bulk client\n"
            "  → kickoff /$export → poll status → GET /$export-file (same ALB host)",
            s,
        )
    )
    story.append(Paragraph("Sizing starting points (non-prod)", s["h2"]))
    story.append(
        table(
            [
                ["Component", "Starter size", "Notes"],
                ["EIP task", "2 vCPU / 4 GB (Fargate)", "Raise heap via CATALINA_OPTS; Bulk jobs are memory-/IO-heavy"],
                ["Web UI task", "0.25 vCPU / 0.5 GB", "Omit for API-only prod"],
                ["Keycloak task", "1 vCPU / 2 GB + RDS/Aurora Postgres", "Never use start-dev in AWS"],
                ["RDS SQL Server", "db.r6i.large Multi-AZ (prod)", "db.t3.medium OK for demo/staging only"],
                ["EFS", "General Purpose, bursting→elastic", "Mandatory if EIP task count > 1 for Bulk files"],
            ],
            [1.4 * inch, 2.2 * inch, 2.9 * inch],
            s,
        )
    )

    story.append(PageBreak())

    # 3 Decision matrix
    story.append(Paragraph("3. Compute & auth decision matrix", s["h1"]))
    story.append(
        table(
            [
                ["Choice", "Use when", "Avoid when"],
                [
                    "ECS Fargate + RDS + ALB",
                    "You want AWS-native ops, autoscale later, clean SG boundaries",
                    "Team cannot containerize licensed EIP base image yet",
                ],
                [
                    "EC2 + Docker Compose (lift)",
                    "48-hour private staging; learning env; migration workshop",
                    "Anything customer-facing or HA; demo passwords persist",
                ],
                [
                    "EKS",
                    "Org standard is Kubernetes + GitOps already",
                    "First FHIR stand-up — overhead usually not worth it yet",
                ],
                [
                    "Self-hosted Keycloak",
                    "You need realm parity with demo / custom claims soon",
                    "You lack Keycloak ops skill — prefer Cognito/Okta/Entra",
                ],
                [
                    "Amazon Cognito (or Entra/Okta)",
                    "Enterprise IdP already exists; JWT validation only needs issuer/JWKS",
                    "You must stay byte-identical to demo realm without mapping work",
                ],
            ],
            [1.7 * inch, 2.5 * inch, 2.3 * inch],
            s,
        )
    )
    story.append(Spacer(1, 0.08 * inch))
    story.append(
        callout(
            "<b>Issuer / JWKS gotcha (this demo):</b> environment-settings.conf currently has "
            "<font face='Courier'>fhir.oauth.jwks=http://keycloak:8080/...</font> and "
            "<font face='Courier'>fhir.oauth.issuer=http://localhost:8112/...</font>. In AWS you "
            "must set a single public issuer URL that matches access-token <font face='Courier'>iss</font>, "
            "and a JWKS URL the EIP task can reach. Mismatched issuer is the #1 Bearer 401 cause after lift.",
            s,
        )
    )

    # 4 Phased tickets
    story.append(Paragraph("4. Phased implementation tickets", s["h1"]))
    story.append(Paragraph("Phase A — Foundation (ticket-sized)", s["h2"]))
    story.append(
        table(
            [
                ["ID", "Work item", "Done when"],
                ["A1", "VPC + subnets + NAT + VPC Flow Logs", "2 AZ skeleton exists in account/region"],
                ["A2", "ACM cert for fhir.example.com (+ auth host if split)", "ACM Issued; DNS validated"],
                ["A3", "ECR repos for eip + webui (+ keycloak if used)", "Push IAM for CI role works"],
                ["A4", "Secrets Manager secrets (see §6)", "No plaintext passwords in task defs"],
                ["A5", "RDS SQL Server + security group + parameter group", "Private endpoint; encrypted at rest"],
                ["A6", "Run sql/*.sql migration job (ECS one-shot or SSM)", "FhirR4PlatformDemo schema Phase 1–6 present"],
            ],
            [0.45 * inch, 3.25 * inch, 2.8 * inch],
            s,
        )
    )
    story.append(Paragraph("Phase B — Runtime", s["h2"]))
    story.append(
        table(
            [
                ["ID", "Work item", "Done when"],
                ["B1", "Build EIP image FROM licensed base + custom modules", "Image in ECR; SBOM/scan attached"],
                ["B2", "EFS + access point; mount output/input paths", "Write test file visible across tasks"],
                ["B3", "ECS service EIP (desired count 1 initially)", "GET /eip/rest/fhir/metadata → 200 CapStatement"],
                ["B4", "ALB listener rules + target health", "Public HTTPS FHIR base URL works"],
                ["B5", "Wire PublicFhirBase + CapStatement url to ALB HTTPS host", "export Content-Location uses public host"],
                ["B6", "IdP: Keycloak prod mode or Cognito app client", "JWKS fetch OK from EIP task; Bearer write succeeds"],
                ["B7", "Optional Web UI task (private)", "Ops can invoke without localhost tunnels"],
            ],
            [0.45 * inch, 3.25 * inch, 2.8 * inch],
            s,
        )
    )
    story.append(Paragraph("Phase C — Hardening & ops", s["h2"]))
    story.append(
        table(
            [
                ["ID", "Work item", "Done when"],
                ["C1", "CloudWatch Logs + metrics + alarms (5xx, CPU, RDS)", "Pager/slack on ALB 5xx + RDS storage"],
                ["C2", "Close anonymous reads if required; enforce Bearer broadly", "Policy matches CapStatement & security model"],
                ["C3", "Backup: RDS snapshots + EFS backup / S3 export copy", "Restore drill documented"],
                ["C4", "WAF / private connectivity for B2B clients", "Threat model signed by security"],
                ["C5", "Run living test plan against AWS base URL", "documents/test-results.html green from CI"],
                ["C6", "Multi-AZ RDS + EIP desiredCount≥2 only after EFS proven", "Bulk file download works mid-failover test"],
            ],
            [0.45 * inch, 3.25 * inch, 2.8 * inch],
            s,
        )
    )

    story.append(PageBreak())

    # 5 Security groups
    story.append(Paragraph("5. Security group matrix", s["h1"]))
    story.append(
        table(
            [
                ["SG", "Ingress", "Egress"],
                [
                    "sg-alb",
                    "443 from Internet or corp CIDR / PrivateLink",
                    "to sg-eip:8080, sg-webui:8111, sg-kc:8080",
                ],
                [
                    "sg-eip",
                    "8080 from sg-alb only",
                    "1433→sg-rds; 443→JWKS/ECR/S3; NFS→EFS; DNS",
                ],
                [
                    "sg-webui",
                    "8111 from sg-alb (or VPN CIDR)",
                    "1433→sg-rds; 8080→sg-eip; 8080→sg-kc; HTTPS out",
                ],
                [
                    "sg-kc",
                    "8080 from sg-alb + sg-eip (+ admin from break-glass CIDR)",
                    "5432→KC DB if used; HTTPS out",
                ],
                ["sg-rds", "1433 from sg-eip + sg-webui (+ migrate task SG)", "None required"],
                ["sg-efs", "2049 from sg-eip (+ webui if it mounts)", "—"],
            ],
            [0.9 * inch, 3.0 * inch, 2.6 * inch],
            s,
        )
    )

    # 6 Secrets & env
    story.append(Paragraph("6. Secrets Manager & configuration mapping", s["h1"]))
    story.append(
        Paragraph(
            "Replace every demo credential. Prefer injecting Secrets Manager ARNs into the ECS "
            "task definition rather baking values into environment-settings.conf in the image.",
            s["body"],
        )
    )
    story.append(Paragraph("6.1 Secrets to create", s["h2"]))
    story.append(
        table(
            [
                ["Secret name (example)", "Keys", "Used by"],
                [
                    "fhir/rds/app",
                    "username, password, host, port, dbname, jdbc_url",
                    "EIP environment-settings / task env; Web UI DB_*",
                ],
                [
                    "fhir/oauth/client",
                    "client_id, client_secret",
                    "Backend services / Web UI token fetch",
                ],
                [
                    "fhir/oauth/issuer",
                    "issuer_url, jwks_url",
                    "EIP JWT processor + CapStatement security",
                ],
                [
                    "fhir/keycloak/admin",
                    "admin_user, admin_password",
                    "Keycloak bootstrap only (break-glass)",
                ],
            ],
            [1.6 * inch, 2.6 * inch, 2.3 * inch],
            s,
        )
    )
    story.append(Paragraph("6.2 Demo → AWS configuration map", s["h2"]))
    story.append(
        table(
            [
                ["Demo setting", "Demo value (do not ship)", "AWS target"],
                [
                    "sqlserver.url",
                    "jdbc:sqlserver://sqlserver:1433;databaseName=FhirR4PlatformDemo;encrypt=true;trustServerCertificate=true",
                    "RDS endpoint; <b>encrypt=true</b>; prefer proper trust (not trustServerCertificate=true) once CA known",
                ],
                [
                    "sqlserver.username/password",
                    "sa / PilotFish_Demo1!",
                    "Least-privilege SQL login (not sa); from Secrets Manager",
                ],
                [
                    "fhir.oauth.jwks / issuer",
                    "http://keycloak:8080 … / http://localhost:8112 …",
                    "https://auth.example.com/realms/… or Cognito JWKS/issuer HTTPS URLs",
                ],
                [
                    "PublicFhirBase (Bulk module)",
                    "http://localhost:8110/eip/rest/fhir",
                    "https://fhir.example.com/eip/rest/fhir",
                ],
                [
                    "CapabilityStatement.url",
                    "http://localhost:8110/eip/rest/fhir/metadata",
                    "Same public HTTPS base + /metadata",
                ],
                [
                    "OAUTH_* in Web UI",
                    "fhir-demo-secret / FhirDemo1!",
                    "Secrets; rotate; remove password-grant for prod UIs",
                ],
                [
                    "FHIR_PUBLIC_BASE_URL / LAN_HINT",
                    "192.168.x.x",
                    "Public or VPN hostname",
                ],
                [
                    "Keycloak command",
                    "start-dev --import-realm",
                    "kc.sh start (prod) + Postgres; hostname-strict HTTPS",
                ],
                [
                    "is_debug",
                    "true",
                    "false in prod",
                ],
            ],
            [1.45 * inch, 2.45 * inch, 2.6 * inch],
            s,
        )
    )
    story.append(Paragraph("6.3 Example ECS task environment (EIP)", s["h2"]))
    story.append(
        code_block(
            "# Inject via secrets / env — then render environment-settings.conf at entrypoint\n"
            "SQLSERVER_JDBC_URL=jdbc:sqlserver://fhir-rds....amazonaws.com:1433;\n"
            "  databaseName=FhirR4PlatformDemo;encrypt=true;loginTimeout=30\n"
            "SQLSERVER_USER=fhir_app\n"
            "SQLSERVER_PASSWORD={{resolve:secretsmanager:fhir/rds/app:SecretString:password}}\n"
            "FHIR_OAUTH_JWKS=https://auth.example.com/realms/fhir/protocol/openid-connect/certs\n"
            "FHIR_OAUTH_ISSUER=https://auth.example.com/realms/fhir\n"
            "PUBLIC_FHIR_BASE=https://fhir.example.com/eip/rest/fhir\n"
            "CATALINA_OPTS=-Xms1024M -Xmx3072M -server -XX:+UseG1GC\n"
            "JAVA_OPTS=-Djava.security.egd=file:///dev/urandom",
            s,
        )
    )
    story.append(
        Paragraph(
            "Recommended pattern: keep a templated environment-settings.conf and have "
            "demo-entrypoint.sh (or a thin wrapper) substitute $$/env values before Tomcat starts. "
            "Avoid rebuilding the image to change JDBC URLs.",
            s["body"],
        )
    )

    story.append(PageBreak())

    # 7 IAM
    story.append(Paragraph("7. IAM roles & policies (checklist)", s["h1"]))
    story.append(
        table(
            [
                ["Role", "Attach / allow", "Purpose"],
                [
                    "ecsTaskExecutionRole",
                    "AmazonECSTaskExecutionRolePolicy + secretsmanager:GetSecretValue on fhir/* + kms:Decrypt if CMK",
                    "Pull ECR image; inject secrets; write CW logs",
                ],
                [
                    "ecsTaskRole-eip",
                    "elasticfilesystem:ClientMount/Write on access point; optional s3:PutObject on export bucket; logs",
                    "Runtime AWS API calls from EIP (if any)",
                ],
                [
                    "ecsTaskRole-webui",
                    "Minimal; usually none beyond CW logs",
                    "Web UI should not need broad AWS power",
                ],
                [
                    "ci-deploy-role",
                    "ecr:PutImage, ecs:UpdateService, iam:PassRole (scoped), s3 sync docs optional",
                    "GitHub Actions / CodePipeline deploys",
                ],
                [
                    "rds-monitoring / enhanced",
                    "AWS managed monitoring roles",
                    "Ops visibility",
                ],
            ],
            [1.45 * inch, 3.0 * inch, 2.05 * inch],
            s,
        )
    )
    story.append(Spacer(1, 0.06 * inch))
    story.append(
        callout(
            "<b>Least privilege tip:</b> do not give the EIP task AdministratorAccess “temporarily.” "
            "Bulk export today writes local NDJSON under EFS — S3 permissions are only needed if "
            "you add a copy/lifecycle job.",
            s,
            kind="ok",
        )
    )

    # 8 Data & Bulk
    story.append(Paragraph("8. Data plane: SQL migrations, Bulk files, CapStatement URLs", s["h1"]))
    story.append(Paragraph("8.1 Schema", s["h2"]))
    story.append(
        bullets(
            [
                "Apply in order: <font face='Courier'>sql/01_init.sql</font> → "
                "<font face='Courier'>02_phase2_search.sql</font> → "
                "<font face='Courier'>03_phase3_bundle.sql</font> → "
                "<font face='Courier'>04_phase6_bulk.sql</font>.",
                "Run as a one-shot ECS task / CodeBuild / SSM session against RDS — same as compose’s sqlserver-init.",
                "Create an app login with rights only on FhirR4PlatformDemo objects (not sysadmin).",
            ],
            s,
        )
    )
    story.append(Paragraph("8.2 Bulk $export files", s["h2"]))
    story.append(
        bullets(
            [
                "Jobs metadata: <font face='Courier'>dbo.FhirExportJobs</font>; files: "
                "<font face='Courier'>/opt/pilotfish/output/bulk-export/{jobId}/</font>.",
                "With desiredCount &gt; 1, <b>EFS (or equivalent shared FS) is required</b> so status/file GETs can hit any task.",
                "Set Bulk module <font face='Courier'>PublicFhirBase</font> to the ALB HTTPS FHIR base or Content-Location links break for clients.",
                "Optional hardening: cron copy completed NDJSON to S3 + lifecycle expire EFS after N days.",
            ],
            s,
        )
    )
    story.append(Paragraph("8.3 CapabilityStatement / metadata host", s["h2"]))
    story.append(
        Paragraph(
            "Update capability-statement.json (or the XSLT that emits it) so "
            "<font face='Courier'>url</font> and any absolute links use the public HTTPS base. "
            "Clients and Inferno-like suites fingerprint this. Re-run metadata tests after DNS cutover.",
            s["body"],
        )
    )

    # 9 Image build / CI
    story.append(Paragraph("9. Image build & CI/CD sketch", s["h1"]))
    story.append(
        code_block(
            "# Build (on CI runner with access to licensed pilotfish-eip base)\n"
            "docker build -f pilotfish/Dockerfile -t $ECR/fhir-eip:$GIT_SHA .\n"
            "docker build -t $ECR/fhir-webui:$GIT_SHA ./webui\n"
            "docker push $ECR/fhir-eip:$GIT_SHA && docker push $ECR/fhir-webui:$GIT_SHA\n"
            "\n"
            "# Deploy\n"
            "aws ecs update-service --cluster fhir --service eip \\\n"
            "  --force-new-deployment  # task def already pinned to :$GIT_SHA\n"
            "\n"
            "# Post-deploy acceptance (from CI runner in VPC or via public ALB)\n"
            "export FHIR_BASE=https://fhir.example.com/eip/rest/fhir\n"
            "export WEBUI=https://fhir-ops.example.com   # if exposed\n"
            "python3 tools/run_interface_tests.py --wait",
            s,
        )
    )
    story.append(
        bullets(
            [
                "Pin digests in task definitions; avoid floating <font face='Courier'>:latest</font> in prod.",
                "Scan images (ECR enhanced scanning / Trivy) — custom JARs + Tomcat surface matter.",
                "Separate AWS accounts or at least separate clusters for sandbox vs prod.",
            ],
            s,
        )
    )

    story.append(PageBreak())

    # 10 Cognito path
    story.append(Paragraph("10. Swapping Keycloak for Amazon Cognito (optional)", s["h1"]))
    story.append(
        Paragraph(
            "The EIP JWT processor needs a reachable JWKS and tokens whose "
            "<font face='Courier'>iss</font> matches configured issuer. Cognito satisfies that "
            "without running Keycloak:",
            s["body"],
        )
    )
    story.append(
        bullets(
            [
                "Create User Pool + App client (client_credentials and/or auth code+PKCE).",
                "Issuer: <font face='Courier'>https://cognito-idp.{region}.amazonaws.com/{userPoolId}</font>",
                "JWKS: <font face='Courier'>{issuer}/.well-known/jwks.json</font>",
                "Point <font face='Courier'>fhir.oauth.*</font> at those URLs; remove Keycloak ECS service.",
                "Re-test write + /$export with Cognito access tokens; update Web UI OAUTH_* accordingly.",
                "Scopes/claims: map Cognito groups/custom attributes if you later enforce patient compartments.",
            ],
            s,
        )
    )
    story.append(
        callout(
            "Cognito is <b>not</b> full SMART App Launch by itself. If the buyer requires SMART EHR launch, "
            "plan that as a separate workstream (see Expert Due Diligence PDF).",
            s,
        )
    )

    # 11 EC2 lift path
    story.append(Paragraph("11. Fast path: single EC2 Docker Compose (staging only)", s["h1"]))
    story.append(
        bullets(
            [
                "EC2 (m6i.xlarge+), Amazon Linux 2023, Docker Engine, 100GB+ gp3.",
                "Open SG: 443 (ALB or host nginx) only; SSH via SSM Session Manager (no 22/world).",
                "Clone demo; replace passwords; set PublicFhirBase + OAuth issuer to the EC2/ALB hostname.",
                "Put nginx/Caddy with Let’s Encrypt or ACM via ALB in front of 8110/8111/8112.",
                "Stop-gap for demos — promote to ECS+RDS before any PHI or external partner traffic.",
            ],
            s,
        )
    )

    # 12 Acceptance
    story.append(Paragraph("12. Go-live acceptance checklist", s["h1"]))
    story.append(
        table(
            [
                ["#", "Check", "Pass criteria"],
                ["1", "TLS", "fhir + auth hosts serve valid certs; HTTP→HTTPS redirect"],
                ["2", "metadata", "GET /metadata returns CapStatement; url host is public"],
                ["3", "CRUD + search", "Living test plan CRUD/search suites green"],
                ["4", "AuthN", "Write without Bearer → 401; with valid token → 2xx"],
                ["5", "Validation", "Invalid Patient rejected by HAPI validator path"],
                ["6", "Bundle", "transaction atomic failure case tested"],
                ["7", "Bulk", "kickoff 202 → status 200 → NDJSON downloadable via public URL"],
                ["8", "Secrets", "No demo passwords in env, images, or Terraform state plaintext"],
                ["9", "Backups", "RDS snapshot restore tested in last 30 days"],
                ["10", "Observability", "ALB 5xx + RDS CPU/storage alarms page a human"],
                ["11", "Scale safety", "If count≥2, Bulk file fetch works against both tasks"],
                ["12", "Scope honesty", "CapStatement deferred items still accurate for this release"],
            ],
            [0.35 * inch, 1.5 * inch, 4.65 * inch],
            s,
        )
    )

    # 13 Cost
    story.append(Paragraph("13. Rough monthly cost envelope (order-of-magnitude, us-east-1)", s["h1"]))
    story.append(
        Paragraph(
            "Numbers move with commitment discounts and traffic. Use for planning conversations only:",
            s["body"],
        )
    )
    story.append(
        table(
            [
                ["Stack", "Ballpark", "Includes"],
                [
                    "Staging (ECS light + RDS SQL Server Express/Web + ALB + NAT)",
                    "$350–900 / mo",
                    "Single AZ RDS; low traffic; Keycloak optional",
                ],
                [
                    "Prod-ish (Multi-AZ RDS + 2 EIP tasks + EFS + WAF + dual NAT)",
                    "$1.5k–4k+ / mo",
                    "Before PilotFish license; SQL Server license edition matters a lot",
                ],
                [
                    "EC2 Compose sandbox",
                    "$80–250 / mo",
                    "One box + ALB optional; not HA",
                ],
            ],
            [2.4 * inch, 1.5 * inch, 2.6 * inch],
            s,
        )
    )

    story.append(PageBreak())

    # 14 What must change from demo
    story.append(Paragraph("14. Demo defaults you must not carry into AWS", s["h1"]))
    story.append(
        table(
            [
                ["Demo default", "Risk", "Production action"],
                ["sa / PilotFish_Demo1!", "Trivial DB compromise", "App login + Secrets Manager + rotation"],
                ["Keycloak admin/admin + start-dev", "Realm takeover", "Prod mode, strong admin, no public admin"],
                ["fhir-demo-secret client secret", "Token minting by attackers", "New clients; rotate; secret in SM"],
                ["Open reads (no Bearer)", "Data exposure", "Decide policy; often require auth on all verbs"],
                ["trustServerCertificate=true", "MITM on JDBC", "Install RDS CA; disable trust-all"],
                ["localhost PublicFhirBase", "Broken Bulk clients", "Set HTTPS public FHIR base"],
                ["is_debug=true", "Verbose leakage", "false"],
                ["Bind-mount host folders", "Lost on task replace", "EFS + log drivers"],
                ["Single-node assumption", "Broken Bulk w/ scale-out", "Shared FS before desiredCount&gt;1"],
            ],
            [1.7 * inch, 1.7 * inch, 3.1 * inch],
            s,
        )
    )

    # 15 Ticket template
    story.append(Paragraph("15. Copy-paste implementation ticket (Epic)", s["h1"]))
    story.append(
        code_block(
            "Title: Deploy FHIR R4 PilotFish platform to AWS (ECS + RDS)\n"
            "Context: Lift Clients/Demos/fhir-r4-platform beyond Docker Compose.\n"
            "Scope: Phase A–C in AWS Deployment Guide; API + Bulk + OIDC; Web UI optional.\n"
            "Out of scope: US Core IG packaging, full SMART launch, full search grammar,\n"
            "  Group/Patient $export, CapStatement $validate (see Expert Due Diligence).\n"
            "Acceptance: §12 checklist green; living test plan against https://fhir…;\n"
            "  no demo secrets; CapStatementurl uses public host; Bulk NDJSON via HTTPS.\n"
            "Deps: Licensed pilotfish-eip base in ECR; DNS zone; ACM; VPC.\n"
            "Artifacts: Terraform/CDK stack, task defs, secrets ARNs, runbook link, test-results.html.",
            s,
        )
    )

    story.append(Paragraph("16. Related demo artifacts", s["h1"]))
    story.append(
        bullets(
            [
                "DESIGN.md — honest Phase 1–6 scope",
                "FHIR_R4_Platform_Expert_Due_Diligence.pdf — FHIR viability questions",
                "FHIR_R4_Platform_Capability_Brief.pdf — stakeholder outcomes",
                "FHIR_R4_Platform_Test_Plan.pdf + tools/run_interface_tests.py — acceptance automation",
                "docker-compose.yml — source of truth for local service graph",
                "pilotfish/demo-eip-root/environment-settings.conf — JDBC + OAuth knobs",
                "sql/01–04_*.sql — schema migrations",
            ],
            s,
        )
    )
    story.append(Spacer(1, 0.15 * inch))
    story.append(
        callout(
            "<b>Bottom line:</b> AWS viability for this solution is straightforward as an "
            "ECS + RDS + ALB + Secrets + EFS service if you treat OAuth issuer URLs, "
            "PublicFhirBase, shared Bulk storage, and secret hygiene as first-class work. "
            "It is not a blind Compose lift. Pair this guide with the Expert Due Diligence "
            "PDF so infrastructure success is not mistaken for full FHIR-server parity.",
            s,
            kind="ok",
        )
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.gray)
        canvas.drawString(0.75 * inch, 0.45 * inch, "PilotFish FHIR R4 · AWS Deployment Guide")
        canvas.drawRightString(letter[0] - 0.75 * inch, 0.45 * inch, f"Page {doc.page}")
        canvas.restoreState()

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.75 * inch,
        rightMargin=0.75 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.7 * inch,
        title="FHIR R4 AWS Deployment Guide — PilotFish Platform",
        author="PilotFish Sandbox Demo",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    build()
