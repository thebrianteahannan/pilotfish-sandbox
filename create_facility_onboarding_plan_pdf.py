#!/usr/bin/env python3
"""Generate PDF plan for NHL CAT + IRL GAN Expanse facility onboarding."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
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

OUT = Path(__file__).resolve().parent / "Facility_Onboarding_Plan_NHL_IRL_Expanse.pdf"


def styles():
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Heading1"],
            fontSize=16,
            leading=20,
            spaceAfter=8,
            textColor=colors.HexColor("#1a2332"),
        ),
        "h2": ParagraphStyle(
            "h2",
            parent=base["Heading2"],
            fontSize=12,
            leading=15,
            spaceBefore=14,
            spaceAfter=6,
            textColor=colors.HexColor("#1a2332"),
        ),
        "h3": ParagraphStyle(
            "h3",
            parent=base["Heading3"],
            fontSize=10.5,
            leading=13,
            spaceBefore=10,
            spaceAfter=4,
            textColor=colors.HexColor("#2c3e50"),
        ),
        "body": ParagraphStyle(
            "body",
            parent=base["BodyText"],
            fontSize=9.5,
            leading=12.5,
            spaceAfter=6,
            alignment=TA_LEFT,
        ),
        "small": ParagraphStyle(
            "small",
            parent=base["BodyText"],
            fontSize=8.5,
            leading=11,
            textColor=colors.HexColor("#444444"),
            spaceAfter=4,
        ),
        "bullet": ParagraphStyle(
            "bullet",
            parent=base["BodyText"],
            fontSize=9.5,
            leading=12.5,
            leftIndent=8,
        ),
        "code": ParagraphStyle(
            "code",
            parent=base["Code"],
            fontSize=8,
            leading=10.5,
            backColor=colors.HexColor("#f4f6f8"),
            spaceBefore=2,
            spaceAfter=6,
        ),
        "warn": ParagraphStyle(
            "warn",
            parent=base["BodyText"],
            fontSize=9.5,
            leading=12.5,
            textColor=colors.HexColor("#8a4b08"),
            backColor=colors.HexColor("#fff6e5"),
            borderPadding=6,
            spaceAfter=8,
        ),
    }


def bullets(items, style):
    return ListFlowable(
        [ListItem(Paragraph(i, style), leftIndent=12, value="•") for i in items],
        bulletType="bullet",
        start="•",
    )


def table(data, col_widths):
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a2332")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("LEADING", (0, 0), (-1, -1), 10),
                ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#fafbfc")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#fafbfc"), colors.HexColor("#eef2f6")]),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c5ced6")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return t


def build():
    s = styles()
    story = []

    story.append(Paragraph("Facility Onboarding Plan — NHL Catholic Medical &amp; IRL N Gainesville (Expanse)", s["title"]))
    story.append(
        Paragraph(
            "Implementation plan for adding two expanded-Expanse facilities into MedReceivables / eiPlatform "
            "(Flat File to HL7 and Kickout Reports). Covers H2 database updates, route 1 listeners/processors, "
            "downstream strip/split config, and ADT/DFT mapping rules from the request.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "<b>Scope:</b> NHL – Catholic Medical Center (CLIENT CAT) and IRL N – HCA FL Gainesville Hospital "
            "(CLIENT GAN). Source folders referenced in request: <i>Expanded expanse\\NHL-Catholic</i> and "
            "<i>Expanded expanse\\IRL N-Gainsville</i>.",
            s["small"],
        )
    )

    story.append(Paragraph("1. Summary of the request", s["h2"]))
    story.append(
        Paragraph(
            "Add new facilities to the Expanse expanded-CDM intake path so the same flat-file feed can be "
            "picked up, converted to canonical XML in route 1, stripped/split using CLIENT_SPLITS + CLIENT_CODES, "
            "then generate ADT/DFT with the new mapping rules.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "<b>Decision:</b> The request listed SOFTWAREID <b>513</b> for Catholic Medical (CAT / NHL), but "
            "513 remains assigned to FPS / Central Lab (CLIENT CNL). CAT will use SOFTWAREID <b>524</b> instead. "
            "GAN (Gainesville / IRL) uses SOFTWAREID <b>523</b> as requested.",
            s["warn"],
        )
    )

    story.append(Paragraph("2. Target database records (from request)", s["h2"]))
    story.append(Paragraph("2.1 CLIENT_SPLITS (facility / partition registry)", s["h3"]))
    story.append(
        Paragraph(
            "Table columns in current H2 DB: SOFTWAREID, CLIENTNAME, PARTITION, CLIENT, FACILITY, "
            "FACILITY_CODE, DEFAULT_PERF_DR, ACCOUNT_NUM_ALPHA, DATE_RANGE, IS_DEFAULT. "
            "FILE_HEADER_FACILITY_NAME from the email is <b>not</b> a CLIENT_SPLITS column — it maps to route 1 "
            "listener attribute <b>FacilityNameShouldBe</b>.",
            s["body"],
        )
    )
    story.append(
        table(
            [
                ["Field", "NHL Catholic Medical", "IRL N Gainesville"],
                ["SOFTWAREID", "524 (assigned; was 513 in request)", "523 (free)"],
                ["CLIENTNAME", "Catholic Medical", "HCA FL Gainesville Hospital"],
                ["FILE HEADER / FacilityNameShouldBe", "Catholic Medical Center", "HCA FL Gainesville Hospital"],
                ["PARTITION", "NHL", "IRL"],
                ["CLIENT", "CAT", "GAN"],
                ["FACILITY", "CAT", "GAN"],
                ["FACILITY_CODE", "HK", "PT"],
                ["DEFAULT_PERF_DR", "CP9", "CN1"],
                ["ACCOUNT_NUM_ALPHA", "HK", "PT"],
                ["DATE_RANGE", "20260611", "20260505"],
                ["IS_DEFAULT", "1 (recommended)", "1 (recommended)"],
            ],
            [1.55 * inch, 2.55 * inch, 2.55 * inch],
        )
    )
    story.append(Spacer(1, 8))
    story.append(
        Paragraph(
            "<b>NHL note:</b> Exclude locations Monodock and Huggins (X.HH) from split/strip config when loading "
            "CLIENT_CODES / strip tables from the Catholic feed workbook.",
            s["body"],
        )
    )

    story.append(Paragraph("2.2 CLIENT_CODES (split codes)", s["h3"]))
    story.append(
        Paragraph(
            "CLIENT_CODES columns: FACILITY, CODE, COMPARATOR, SOFTWARE_ID. These define how one input "
            "file forks into multiple related output sets in route 3. Source the location/code rows from the "
            "request workbooks (excluding Monodock / Huggins for NHL). Mirror recent Expanse inserts "
            "(e.g. IRL GUX/CAX or NHL POT/FRK/PAT) for structure.",
            s["body"],
        )
    )
    story.append(
        bullets(
            [
                "Insert one CLIENT_SPLITS default row per facility (above).",
                "Insert CLIENT_CODES rows for each included split location for that SOFTWARE_ID.",
                "Optional / if used by strip logic: STRIP_LOCATIONS, STRIP_PERFORMING_SITES already has LC (LabCorp) globally; verify apply-list includes CAT/GAN.",
                "Preferred ops path already in eiConsole: route <b>88a – Add New Facility</b> + Excel "
                "<i>MedReceivables_NewFacilityInfo.xlsx</i> via format New Facility SQLXML.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("3. End-to-end flow (what happens after DB is wired)", s["h2"]))
    story.append(
        table(
            [
                ["Route", "Purpose for new facilities"],
                ["1 – Incoming Flat Files…", "Listener + attribute stamp + expanded-CDM flatfile→canonical XML"],
                ["2 – Stripping and Tweaking", "Loads CLIENT_SPLITS; resolves SoftwareID; applying strip rules incl. PerfSite LC"],
                ["3 – Splitting Records by Facility", "Uses CLIENT_SPLITS + CLIENT_CODES to fork output streams"],
                ["3b – Generate HL7 Files", "ADT (Generate ADT A04) + DFT (Generate DFT DPT P03) XSLTs"],
            ],
            [2.2 * inch, 4.5 * inch],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("4. Route 1 work — listeners &amp; canonical conversion", s["h2"]))
    story.append(
        Paragraph(
            "In route 1, each pickup is a DirectoryListener. SOFTWAREID is <b>not</b> set here — route 2 looks "
            "it up from CLIENT_SPLITS using Partition + Client. Route 1 must set PartitionName/ClientName "
            "(then Partition/Client) and convert the flat file into canonical XML via the "
            "<b>Transform Flat File to XML-New-Expanse-Expanded-CDM</b> path "
            "(raw-flat-file-specification-expanded-cdm.xml).",
            s["body"],
        )
    )

    story.append(Paragraph("4.1 Copy-from templates", s["h3"]))
    story.append(
        table(
            [
                ["New facility", "Best copy-from", "Why"],
                ["NHL CAT", "NHL POT / FRK / PAT", "Same NHL Expanse expanded-CDM listener pattern"],
                ["IRL GAN", "IRL GUX / CAX", "Most recent IRL EXP Expanse listeners"],
            ],
            [1.4 * inch, 2.0 * inch, 3.3 * inch],
        )
    )

    story.append(Paragraph("4.2 Checklist per new software / client", s["h3"]))
    story.append(
        bullets(
            [
                "<b>Source listener:</b> Clone <i>Pickup Flat Files – {PARTITION} – {CLIENT}</i> with "
                "<i>1 – Incoming Raw File – Dir Listener – {PARTITION} – {CLIENT}</i>. "
                "PollingDirectory=$$FLAT_FILE_INPUT_DIRECTORY; archive=$$FLAT_FILE_ARCHIVE_DIRECTORY; "
                "FileExtensionRestriction per feed (txt for NHL-style). Set FileNameRestriction from sample "
                "file names in the Expanded expanse folders (TBD from samples).",
                "<b>Set Facility Name – {CLIENT}:</b> TransactionAttributePopulationProcessor setting "
                "FacilityNameShouldBe, PartitionName, ClientName (use FILE_HEADER values / CAT / GAN).",
                "<b>Target processors:</b> Add <i>Set Partition and Client Name-NHL-CAT</i> and "
                "<i>…-IRL-GAN</i> (ExecuteProcessor on PartitionName+ClientName; set Partition/Client).",
                "<b>Expanded-CDM processor allowlist:</b> Add CAT and GAN to OGNL on "
                "<i>Transform Flat File to XML-New-Expanse-Expanded-CDM</i>; keep them excluded from the legacy "
                "Flat File to XML processor.",
                "SOFTWAREIDs 524 (CAT) and 523 (GAN) are brand-new: each requires a new listener. "
                "If it were an existing software ID with only a new split facility, listener may already exist — not the case for CAT/GAN today.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("5. Route 2 / 3 work", s["h2"]))
    story.append(
        bullets(
            [
                "Route 2 already reads all CLIENT_SPLITS and XPaths SoftwareID / DefaultPerfDr / DateRange — "
                "no SQL change if DB rows are correct.",
                "Add CAT and GAN to <i>Apply Stripping – SPECIFIC CLIENTS ONLY – Site Locations</i> OGNL so "
                "PerfSite kickouts (including strip <b>LC</b>) apply.",
                "Confirm strip location tables / secondary strip rows for excluded NHL locations (Monodock, Huggins X.HH).",
                "Route 3 split query uses partition + client; CAT/GAN rows must exist so SplitCount &gt; 0 when expected.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("6. ADT / DFT XSLT updates (route 3b)", s["h2"]))
    story.append(
        Paragraph(
            "Most rules already exist for peer Expanse facilities. Prefer copying the IRL softwareID / facility "
            "guard lists and NHL partition branches rather than inventing new logic.",
            s["body"],
        )
    )
    story.append(
        table(
            [
                ["Rule from request", "Where it lives today", "Action for CAT / GAN"],
                [
                    "PerfSite kickout — strip LC",
                    "STRIP_PERFORMING_SITES + route 2 transform-filter-strip-site-locations.xslt",
                    "Add CAT/GAN to Apply Stripping Site Locations client list",
                ],
                [
                    "PID marital status default U",
                    "ADT transform — IRL softwareID list (514–522…), FPS/GLF lists; NHL not in force-U list",
                    "Add new IRL software ID for GAN to marital-U list; decide whether NHL CAT should force U",
                ],
                [
                    "PV1-8 Attending (NPI/Name)",
                    "ADT — NHL partition branch uses first charge ordering physician; IRL expanses by facility list",
                    "NHL CAT covered by partition=NHL; add GAN (+ split facility codes) to IRL facility list",
                ],
                [
                    "PV1-44 / PV1-45 admit &amp; discharge (inpatient; blank admit → 1st charge date; blank discharge OK)",
                    "ADT PV1.44 / related; blank-admit fill also in GLF-only route 1 XSLT today",
                    "Verify inpatient path for CAT/GAN; if blank-admit must be upstream, clone GLF blank-admit processor for NHL/IRL expanse clients",
                ],
                [
                    "PV2-28 ARSA date (blank admit → 1st charge date)",
                    "ADT PV2.28 (pairs with admit / first DOS logic)",
                    "Reuse same admit/first-charge sourcing once CAT/GAN are in the right branches",
                ],
                [
                    "Guarantor name blank → patient name",
                    "ADT GT1 — already global",
                    "No change expected",
                ],
                [
                    "Subscriber name blank → patient name",
                    "ADT IN1 — NHL has special empty-subscriber handling",
                    "CAT inherits NHL; confirm IRL GAN expected behavior vs peers",
                ],
                [
                    "Relationship blank → SE / CH / UN",
                    "ADT GT1/IN1 — IRL list today only includes some software IDs (e.g. 514–517), not all later expanses",
                    "Extend SE/CH/UN softwareID lists for GAN; decide NHL CAT inclusion",
                ],
            ],
            [1.7 * inch, 2.4 * inch, 2.6 * inch],
        )
    )
    story.append(Spacer(1, 6))
    story.append(
        Paragraph(
            "DFT template mainly carries charge/MUE logic; demographic/PV1 rules are predominantly in "
            "<b>Generate ADT A04 HL7/transform.xslt</b>. Still scan <b>Generate DFT DPT P03 HL7/transform.xslt</b> "
            "for any partition/client/softwareID allowlists that need CAT/GAN or the new IDs.",
            s["small"],
        )
    )

    story.append(Paragraph("7. Suggested implementation sequence", s["h2"]))
    story.append(
        bullets(
            [
                "<b>0. SOFTWAREIDs locked:</b> CAT=524, GAN=523.",
                "<b>1. Gather sample files</b> from Expanded expanse folders; lock FileNameRestriction patterns and validate expanded-CDM columns.",
                "<b>2. Database:</b> insert CLIENT_SPLITS + CLIENT_CODES (+ strip tables as needed) via 88a Excel path or SQL; export/backup H2 first.",
                "<b>3. Route 1:</b> clone listeners/processors; update expanded-CDM OGNL allowlists.",
                "<b>4. Route 2:</b> add CAT/GAN to PerfSite strip client list.",
                "<b>5. ADT/DFT XSLT:</b> extend guard lists per section 6.",
                "<b>6. Rebuild/redeploy</b> local Docker image (or server eip-root) with updated eip-root + DB.",
                "<b>7. Test:</b> drop one NHL Catholic file and one IRL Gainesville file; verify canonical attrs "
                "(Partition/Client/SoftwareID), split outputs, ADT PID/PV1/PV2/GT1/IN1, DFT charges, LC kickouts, "
                "and that Monodock/Huggins are excluded.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("8. Test plan (acceptance)", s["h2"]))
    story.append(
        bullets(
            [
                "Listener picks files by FileNameRestriction only for the intended facility.",
                "Route 2 attributes: SoftwareID / DefaultPerfDr / DateRange match CLIENT_SPLITS.",
                "Split outputs created only for included CLIENT_CODES (no Monodock / Huggins for NHL).",
                "ADT: PID-16 = U when required; PV1-8 populated from attending/ordering rules; "
                "admit/discharge/PV2-28 follow inpatient + blank-admit rules; guarantor/subscriber name &amp; "
                "relationship defaults match request.",
                "PerfSite LC charges stripped / reported as kickouts.",
                "No regressions for existing NHL POT/FRK/PAT and IRL GUX/CAX peers.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("9. Open questions", s["h2"]))
    story.append(
        bullets(
            [
                "Exact FileNameRestriction regexes from sample feed names.",
                "Full CLIENT_CODES / strip-location row lists from the workbooks (beyond the single default CLIENT_SPLITS row).",
                "Whether NHL CAT must force marital U and SE/CH/UN the same way later IRL expanses do.",
                "Whether blank-admit → first charge date must be applied in route 1 (GLF-style) or only in ADT PV1/PV2.",
            ],
            s["bullet"],
        )
    )

    story.append(Spacer(1, 12))
    story.append(
        Paragraph(
            "Generated for PilotFish Sandbox / MedReceivables eiPlatform planning. "
            "Validated against current eip-root and H2 medreceivables.mv.db schema.",
            s["small"],
        )
    )

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=letter,
        leftMargin=0.7 * inch,
        rightMargin=0.7 * inch,
        topMargin=0.65 * inch,
        bottomMargin=0.65 * inch,
        title="Facility Onboarding Plan — NHL CAT & IRL GAN Expanse",
        author="Cursor Agent",
    )
    doc.build(story)
    print(OUT)


if __name__ == "__main__":
    build()
