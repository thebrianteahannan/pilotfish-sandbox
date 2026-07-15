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
            "(Flat File to HL7 and Kickout Reports). Covers sample-format validation, H2 database updates, "
            "route 1 listeners (no new massage path), strip/split config, and ADT/DFT mapping rules.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "<b>Scope:</b> NHL – Catholic Medical Center (CLIENT CAT) and IRL N – HCA FL Gainesville Hospital "
            "(CLIENT GAN). Samples under <i>data/archive/Expanded expanse/NHL-Catholic</i> and "
            "<i>…/IRL N-Gainesville</i> (plus facility workbooks).",
            s["small"],
        )
    )

    story.append(Paragraph("1. Summary of the request", s["h2"]))
    story.append(
        Paragraph(
            "Add CAT and GAN to the <b>existing</b> Expanse expanded-CDM intake path so the same PTH5 flat-file "
            "feed is picked up, converted to canonical XML in route 1, stripped/split via CLIENT_SPLITS + "
            "CLIENT_CODES, then ADT/DFT generated with the new mapping rules. "
            "<b>No separate upfront massage/transform is needed</b> — sample files match peer Expanded Expanse feeds.",
            s["body"],
        )
    )
    story.append(
        Paragraph(
            "<b>SOFTWAREID decision:</b> Request listed <b>513</b> for Catholic Medical, but 513 is already "
            "used by FPS / Central Lab (CLIENT CNL). <b>Use SOFTWAREID 524 for CAT</b> instead. "
            "IRL Gainesville keeps requested SOFTWAREID <b>523</b> (free).",
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
                ["SOFTWAREID", "524 (assigned; was 513 in request)", "523"],
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

    story.append(Paragraph("3. Sample-file validation (Expanded Expanse — confirmed)", s["h2"]))
    story.append(
        Paragraph(
            "Compared Catholic (<i>PTH5.CMC..</i>) and Gainesville (<i>PTH5.GA.1.</i>) samples against "
            "peer Expanded Expanse files (Chippenham <i>PTH5.CC.2.</i>, Henrico <i>PTH5.HR.2.</i>, "
            "Spotsylvania, TriCities, etc. under <i>Other expanded expanse samples</i>).",
            s["body"],
        )
    )
    story.append(
        table(
            [
                ["Check", "New samples (CMC / GA)", "Peer Expanded Expanse"],
                ["Format", "Fixed-width PTH5, CRLF, .txt", "Same"],
                ["Record types present", "H, P, I, G, C, Q, D, T", "Same set"],
                [
                    "Dominant record lengths",
                    "H=169, P=1641, I=550, C=546, G=331, Q=466",
                    "Identical modes on peers",
                ],
                [
                    "Field alignment (H/P/I/C)",
                    "Facility header, account, admit/disch, CDM, NEW/ADD/CAN1",
                    "Same column layout",
                ],
                [
                    "File-name family",
                    "PTH5.CMC..MMDD… / PTH5.GA.1.MMDD…",
                    "PTH5.&lt;site&gt;.[n.]MMDD… (e.g. CC.2, HR.2)",
                ],
            ],
            [1.6 * inch, 2.55 * inch, 2.55 * inch],
        )
    )
    story.append(Spacer(1, 6))
    story.append(
        Paragraph(
            "<b>Conclusion:</b> Reuse the existing "
            "<i>Transform Flat File to XML-New-Expanse-Expanded-CDM</i> processor "
            "(<i>raw-flat-file-specification-expanded-cdm.xml</i>). Do <b>not</b> build a new FlatFileProcessor "
            "spec or a facility-specific “massage” path. Work remaining is wiring: listeners, ClientName "
            "allowlists, and DB splits — not a new parser.",
            s["warn"],
        )
    )
    story.append(
        bullets(
            [
                "Sample H lines already match FacilityNameShouldBe targets: "
                "<i>Catholic Medical Center</i> / <i>HCA FL Gainesville Hospital</i>.",
                "Facility workbooks present beside samples: "
                "<i>MedReceivables_NewFacilityInfo_NHL Catholic Medical.xlsx</i> and "
                "<i>…_IRL N Gainesville.xlsx</i> (use with route 88a when loading splits/codes).",
                "NHL still excludes Monodock and Huggins (X.HH) when loading CLIENT_CODES / strip rows.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("4. End-to-end flow (after DB + wiring)", s["h2"]))
    story.append(
        table(
            [
                ["Route", "Purpose for new facilities"],
                ["1 – Incoming Flat Files…", "Listener + attribute stamp + existing Expanded-CDM → canonical XML"],
                ["2 – Stripping and Tweaking", "Loads CLIENT_SPLITS; resolves SoftwareID; strip rules incl. PerfSite LC"],
                ["3 – Splitting Records by Facility", "Uses CLIENT_SPLITS + CLIENT_CODES to fork output streams"],
                ["3b – Generate HL7 Files", "ADT (Generate ADT A04) + DFT (Generate DFT DPT P03) XSLTs"],
            ],
            [2.2 * inch, 4.5 * inch],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph("5. Route 1 work — listeners only (reuse Expanded-CDM)", s["h2"]))
    story.append(
        Paragraph(
            "SOFTWAREID is <b>not</b> set in route 1 — route 2 looks it up from CLIENT_SPLITS "
            "(Partition + Client). Route 1 only needs DirectoryListeners for the new file-name patterns, "
            "attribute stamps (PartitionName / ClientName / FacilityNameShouldBe), and the <b>existing</b> "
            "Expanded-CDM transform allowlist. No new massaging processors.",
            s["body"],
        )
    )

    story.append(Paragraph("5.1 Copy-from templates", s["h3"]))
    story.append(
        table(
            [
                ["New facility", "Best copy-from", "Sample FileNameRestriction"],
                ["NHL CAT", "NHL POT / FRK / PAT (or PTH5.CC-style listener)", "PTH5.CMC.*  (ext: txt)"],
                ["IRL GAN", "IRL GUX / CAX (or PTH5.HR/CC-style listener)", "PTH5.GA.*  (ext: txt)"],
            ],
            [1.3 * inch, 2.6 * inch, 2.8 * inch],
        )
    )
    story.append(
        Paragraph(
            "Peers already listening for Expanded Expanse PTH5 feeds include "
            "<i>PTH5.CC.*</i>, <i>PTH5.HR.*</i>, <i>PTH5.SAA.*</i>, etc. "
            "<b>PTH5.CMC</b> and <b>PTH5.GA</b> have <b>zero</b> listeners today — add them.",
            s["small"],
        )
    )

    story.append(Paragraph("5.2 Checklist per new client", s["h3"]))
    story.append(
        bullets(
            [
                "<b>Source listener:</b> Clone an Expanded Expanse PTH5 listener. "
                "PollingDirectory=$$FLAT_FILE_INPUT_DIRECTORY; archive=$$FLAT_FILE_ARCHIVE_DIRECTORY; "
                "FileExtensionRestriction=<b>txt</b>. "
                "FileNameRestriction: <b>PTH5.CMC.*</b> (CAT) and <b>PTH5.GA.*</b> (GAN).",
                "<b>Set Facility Name – {CLIENT}:</b> FacilityNameShouldBe = "
                "<i>Catholic Medical Center</i> / <i>HCA FL Gainesville Hospital</i>; "
                "PartitionName=NHL|IRL; ClientName=CAT|GAN.",
                "<b>Target processors:</b> Add <i>Set Partition and Client Name-NHL-CAT</i> and "
                "<i>…-IRL-GAN</i> (ExecuteProcessor on PartitionName+ClientName → Partition/Client).",
                "<b>Expanded-CDM allowlist:</b> Add CAT and GAN to OGNL on "
                "<i>Transform Flat File to XML-New-Expanse-Expanded-CDM</i> "
                "(current allowlist has POT/FRK/PAT/GUX/CAX/… — not CAT/GAN). "
                "Keep them excluded from the legacy Flat File to XML processor.",
                "<b>Do not:</b> add a new FlatFileProcessor XML spec, CSV transform, or client-specific "
                "pre-canonical massage — layout already matches Expanded-CDM.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("6. Route 2 / 3 work", s["h2"]))
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

    story.append(Paragraph("7. ADT / DFT XSLT updates (route 3b)", s["h2"]))
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
                ["PerfSite kickout — strip LC", "STRIP_PERFORMING_SITES + route 2 site-locations XSLT", "Add CAT/GAN to Apply Stripping Site Locations list"],
                ["PID marital status default U", "ADT — IRL/FPS/GLF softwareID lists; NHL not force-U", "Add GAN software ID to marital-U; decide CAT"],
                ["PV1-8 Attending (NPI/Name)", "ADT — NHL uses 1st-charge ordering MD; IRL by facility", "CAT via partition=NHL; add GAN to IRL facility list"],
                ["PV1-44/45 admit &amp; discharge", "ADT PV1.44; blank-admit also GLF-only in route 1 today", "Verify inpatient path; clone GLF blank-admit if needed upstream"],
                ["PV2-28 ARSA (blank admit → 1st charge)", "ADT PV2.28", "Reuse admit/first-charge once CAT/GAN are wired"],
                ["Guarantor name blank → patient", "ADT GT1 — global", "No change expected"],
                ["Subscriber name blank → patient", "ADT IN1 — NHL empty-subscriber handling", "CAT inherits NHL; confirm GAN vs IRL peers"],
                ["Relationship blank → SE / CH / UN", "ADT GT1/IN1 — partial IRL softwareID lists", "Extend for GAN; decide NHL CAT"],
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

    story.append(Paragraph("8. Suggested implementation sequence", s["h2"]))
    story.append(
        bullets(
            [
                "<b>0. SOFTWAREIDs locked:</b> CAT=<b>524</b>, GAN=<b>523</b> (513 left with FPS CNL).",
                "<b>1. Samples validated</b> — Expanded Expanse match confirmed (section 3). "
                "Use FileNameRestriction <b>PTH5.CMC.*</b> / <b>PTH5.GA.*</b>; "
                "load split/codes from the NewFacilityInfo workbooks beside the samples.",
                "<b>2. Database:</b> insert CLIENT_SPLITS + CLIENT_CODES (+ strip tables) via 88a Excel path or SQL; "
                "backup H2 first. Exclude Monodock / Huggins for NHL.",
                "<b>3. Route 1:</b> clone PTH5 Expanded Expanse listeners for CMC/GA; stamp CAT/GAN; "
                "add both to Expanded-CDM OGNL only (no new parser).",
                "<b>4. Route 2:</b> add CAT/GAN to PerfSite strip client list.",
                "<b>5. ADT/DFT XSLT:</b> extend guard lists per section 7.",
                "<b>6. Rebuild/redeploy</b> Docker / server eip-root + DB.",
                "<b>7. Test:</b> drop one CMC and one GA sample; verify canonical attrs, splits, "
                "ADT PID/PV1/PV2/GT1/IN1, DFT charges, LC kickouts, Monodock/Huggins exclusion.",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("9. Test plan (acceptance)", s["h2"]))
    story.append(
        bullets(
            [
                "Listener picks only PTH5.CMC.* (CAT) / PTH5.GA.* (GAN); peers untouched.",
                "Messages take Expanded-CDM path (not legacy Flat File → XML).",
                "Route 2 attributes: SoftwareID / DefaultPerfDr / DateRange match CLIENT_SPLITS.",
                "Split outputs only for included CLIENT_CODES (no Monodock / Huggins for NHL).",
                "ADT: PID-16 = U when required; PV1-8 from attending/ordering rules; "
                "admit/discharge/PV2-28 follow inpatient + blank-admit rules; guarantor/subscriber name &amp; "
                "relationship defaults match request.",
                "PerfSite LC charges stripped / reported as kickouts.",
                "No regressions for NHL POT/FRK/PAT and IRL GUX/CAX (and PTH5.CC/HR peers).",
            ],
            s["bullet"],
        )
    )

    story.append(Paragraph("10. Open questions", s["h2"]))
    story.append(
        bullets(
            [
                "Full CLIENT_CODES / strip-location lists from the NewFacilityInfo workbooks.",
                "Whether NHL CAT must force marital U and SE/CH/UN the same way later IRL expanses do.",
                "Whether blank-admit → first charge date must be applied in route 1 (GLF-style) or only in ADT PV1/PV2.",
                "Confirm ops is OK that request’s 513 for CAT will not be used (524 instead).",
            ],
            s["bullet"],
        )
    )

    story.append(Spacer(1, 12))
    story.append(
        Paragraph(
            "Generated for PilotFish Sandbox / MedReceivables eiPlatform planning. "
            "Validated against eip-root Expanded-CDM wiring, H2 CLIENT_SPLITS schema, and "
            "archive samples under Expanded expanse (NHL-Catholic, IRL N-Gainesville, Other samples).",
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
