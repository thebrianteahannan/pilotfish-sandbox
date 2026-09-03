"""Thorough Med Rec change-plan: identify the feed first, then search eip-root."""

from __future__ import annotations

import re
from pathlib import Path

import client_catalog
import client_dive
import client_halifax_strip_followup_plan
import client_irl_expanse_g3_plan
import client_ngp_accession_plan
import client_nsp_pps_mue_plan
import client_plan_llm

HL7_HINT = re.compile(
    r"\b(IN1|GT1|MSH|ADT|DFT|HL7|self[\s-]?pay|subscriber|payer|policy|IN1\.\d+)\b",
    re.I,
)
STRIP_HINT = re.compile(
    r"locationabbreviation|strip locations|flg location|\bLOCATION2\b|\bstrip\b.+\blocation",
    re.I,
)
CODE_JUNK = {
    "KM", "UNITED", "HEALTH", "HF", "ADT", "MSH", "IN1", "GT1", "PPP", "RAW",
    "FILE", "NAME", "INS", "PRIMARY", "PAYER", "PLEASE", "AFTER", "UPDATE",
    "BELOW", "NOW", "BEFORE", "ACCT", "NGP", "CAQ", "OCR",
}


def split_thread(email: str) -> list[str]:
    text = email or ""
    chunks = re.split(r"\n---+\n|(?=^Hi Brian,)", text, flags=re.I | re.M)
    parts = [c.strip() for c in chunks if c and c.strip()]
    return parts or [text.strip()]


def latest_ask(email: str) -> str:
    parts = split_thread(email)
    follow = [p for p in parts if re.search(r"after the update|now we are missing", p, re.I)]
    return follow[-1] if follow else parts[-1]


def is_location_table(email: str) -> bool:
    return bool(STRIP_HINT.search(email or "")) or bool(
        re.search(r"\b\d{3}\s+(NHL|HAL|ARA|FPS|PPA|NGP)\s+[A-Z]{3}\b", email or "")
    )


def _progress(cb, step: int, steps: int, msg: str) -> None:
    if cb:
        cb(msg, step, steps)


def plan(root: Path, email: str, subject: str, comments: str = "", on_progress=None) -> dict:
    steps = 8
    _progress(on_progress, 1, steps, "Loading Med Rec feeds from CLIENT_SPLITS…")
    catalog = client_catalog.refresh(root)
    body = client_dive.clean_email(email)
    subj = client_dive.clean_subject(subject)
    blob = f"{subj}\n{body}"

    _progress(on_progress, 2, steps, "Splitting the email thread and picking the latest ask…")
    focus = latest_ask(body)
    work = f"{subj}\n{focus}"

    _progress(on_progress, 3, steps, "Matching NGP / Ariana / Halifax / other feeds…")
    feed = client_catalog.match(catalog, blob)
    part = (feed or {}).get("partition") or ""
    feed_name = (feed or {}).get("name") or ""
    if feed:
        label = f"{feed.get('partition')} {feed_name} (software {feed.get('software_id') or '?'})"
        _progress(on_progress, 3, steps, f"Matched feed: {label}")
    else:
        _progress(on_progress, 3, steps, "No CLIENT_SPLITS name in the email — not assuming Halifax.")

    _progress(on_progress, 4, steps, "Classifying the request (HL7 field vs strip locations)…")
    hl7 = bool(HL7_HINT.search(work))
    table = is_location_table(work)
    if hl7 and not table:
        codes: list[str] = []
        intent = "change"
    else:
        codes = [c for c in client_dive.extract_codes(focus) if c.upper() not in CODE_JUNK]
        intent = client_dive.intent_of(focus)

    _progress(on_progress, 5, steps, "Reading eip-root against this feed only…")
    dive = client_dive.dive(root, body, subj)
    dive["intent"] = intent
    dive["codes"] = codes if not (hl7 and not table) else dive.get("codes") or []
    if hl7 and not table:
        dive["edits"] = [e for e in (dive.get("edits") or []) if e.get("action") != "remove_when"]
        dive["codes"] = []
    if feed:
        dive["feed"] = {
            "partition": part,
            "name": feed_name,
            "software_id": feed.get("software_id") or "",
            "xslt": feed.get("xslt") or "",
        }
        extra = [f"$partitionName = '{part}'"] if part else []
        if part == "NGP":
            extra += ["NGP", "Healthfirst", "PRIMARY_PAYER"]
        dive["needles"] = extra

    _progress(on_progress, 6, steps, "Asking local Ollama to classify the request…")
    dive = client_plan_llm.refine(
        root,
        dive,
        body,
        subj,
        catalog,
        {
            "feed": dive.get("feed"),
            "hl7": hl7,
            "location_table": table,
            "heuristic_intent": intent,
        },
    )
    feed = dive.get("feed") or feed
    part = (feed or {}).get("partition") or part
    feed_name = (feed or {}).get("name") or feed_name

    _progress(on_progress, 7, steps, "Checking special HL7 cases and whether an earlier email is already done…")
    if client_irl_expanse_g3_plan.is_ask(body, subj):
        dive = client_irl_expanse_g3_plan.apply(dive, root, body, subj)
    elif client_halifax_strip_followup_plan.is_ask(body, subj):
        dive = client_halifax_strip_followup_plan.apply(dive, root, body, subj)
    elif client_ngp_accession_plan.is_ask(body, subj):
        dive = client_ngp_accession_plan.apply(dive, root, body, subj)
    elif client_nsp_pps_mue_plan.is_ask(body, subj):
        dive = client_nsp_pps_mue_plan.apply(dive, root, body, subj)
    elif client_dive.is_ngp_selfpay_in1_ask(body, subj) or (
        part == "NGP" and re.search(r"missing the IN1|missing IN1", work, re.I)
    ):
        extra_ed = client_dive.propose_ngp_selfpay_in1(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "NGP Healthfirst self-pay still has no IN1 on TEST. Skip “No payer found” the same way as SELF PAY "
            "so the ADT PPP IN1 comes back."
        )
        dive["ask"] = (
            "Karen retested: self-pay accounts still have no IN1. Keep Primary Payer → IN1.4 for real payers. "
            "Treat “No payer found” / SELF PAY as empty so ADT emits IN1 PPP + patient name."
        )
        dive["codes"] = []
        dive["feed"] = {
            "partition": "NGP",
            "name": "NGP Healthfirst",
            "software_id": "652",
            "xslt": client_dive.NGP_HF,
        }
        dive["files"] = [
            {
                "path": client_dive.NGP_HF,
                "hits": [{"code": "admInsName", "line": 417, "text": "Primary Payer → IN1.4; skip SELF PAY and No payer found."}],
            },
            {
                "path": client_dive.ARA_A04,
                "hits": [{"code": "PPP", "line": 1233, "text": "NGP blank-plan fallback IN1 (PPP)."}],
            },
        ]
        dive["risks"] = [
            "Do not undo Primary Payer → IN1.4 for real insured names (UNITED HEALTHCARE MEDICARE, etc.).",
            "The earlier SELF PAY skip is already on disk; this request is the leftover “No payer found” hole.",
            "NGP AP (software 651) is a different split — do not change that map.",
        ]
    elif client_dive.is_ara_in117_rel_ask(body, subj):
        extra_ed = client_dive.propose_ara_selfpay_in117(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "Fill blank IN1.17 (subscriber relationship) on Ariana self-pay. "
            "IN1.16 from the earlier request is already working."
        )
        dive["ask"] = (
            "The subscriber name in IN1.16 is good. For self-pay, IN1.17 is still blank; "
            "it should be 18 from InsuredRelationship on the SELFPAY row."
        )
        dive["codes"] = []
        dive["feed"] = {
            "partition": "ARA",
            "name": "Ariana LigoLab",
            "software_id": "801",
            "xslt": client_dive.ARA_A04,
        }
        dive["risks"] = [
            "Do not re-apply the IN1.16 subscriber-name change. That is already on TEST.",
            "Self-pay with a real secondary still sends Insurance2 as the only IN1; keep that row’s relationship when it is present.",
            "This is ADT IN1.17 only. DFT does not emit that field.",
        ]
    elif client_dive.is_nhl_cat_guarantor_ask(body, subj):
        extra_ed = client_dive.propose_nhl_cat_guarantor(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "NHL CAT guarantor/subscriber relationship is still blank on TEST. Fold names, "
            "never leave GT1.11 / IN1.17 empty, and compare IN1.17 to the subscriber name. "
            "CAT is software 524 in CLIENT_SPLITS."
        )
        dive["ask"] = (
            "Rachael: the guarantor issue is still not working. Example and files are in the "
            "NHL CAT output folder. Same SE / CH / UN rules as the Aug 13 request for "
            "Huggins / Monadnock / employee (Fleming 27148042)."
        )
        dive["intent"] = "hl7_field"
        dive["codes"] = ["GT1.11", "IN1.17"]
        dive["feed"] = {
            "partition": "NHL",
            "name": "NHL CAT",
            "software_id": "524",
            "xslt": client_dive.ARA_A04,
        }
        dive["files"] = [
            {
                "path": client_dive.ARA_A04,
                "hits": [
                    {
                        "code": "GT1.11",
                        "line": 898,
                        "text": "Exact name match + empty age leaves CAT GT1.11 blank.",
                    }
                ],
            }
        ]
        dive["risks"] = [
            "Do not re-apply the Aug 17 strip / Huggins charge XSLT. That is already on main.",
            "Do not gate this on software 513. CAT is 524.",
            "Name fold is case, spaces, comma, caret, and period only. Briana vs Brianna still will not match.",
            "Proof is CAT ADT GT1.11 / IN1.17 for the account in Rachael’s NHL CAT output folder, not the XSLT.",
        ]
        dive["start_work"] = (
            "Start work adds mr:relName and the CAT-only GT1.11 / IN1.17 branches. "
            "Capture Regression Baseline first. Proof is outgoing CAT ADT."
        )
    elif client_dive.is_hal_flg_change_ask(body, subj):
        extra_ed = client_dive.propose_hal_flg_change(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "Add HMC 201 / HH IPM / TL GI / OR TL to Strip Location FLG for Halifax software 750 (HAX). "
            "FLG_LOCATIONS.CODE must match LocationAbbreviation because the CP map already set admLocation to HAX."
        )
        dive["ask"] = (
            "Karen: add these to the Strip Location FLG. Primary stripping by LocationAbbreviation: "
            "HMC 201, HH IPM, TL GI, OR TL. SOFTWARE_ID 750, PARTITION HAL, FACILITY HAX."
        )
        dive["intent"] = "strip"
        dive["codes"] = ["HMC 201", "HH IPM", "TL GI", "OR TL"]
        dive["feed"] = {
            "partition": "HAL",
            "name": "Halifax HAX",
            "software_id": "750",
            "xslt": client_dive.STRIP_DATA,
        }
        dive["files"] = [
            {
                "path": client_dive.STRIP_DATA,
                "hits": [
                    {
                        "code": "HMC 201",
                        "line": 58,
                        "text": "FLG lookup uses CODE = admLocation (HAX), so a FLG row for HMC 201 never matches.",
                    }
                ],
            }
        ]
        dive["risks"] = [
            "Do not delete the HAX map lines. Those still split to HAX; FLG stripping is a later step.",
            "Do not strip every HAX row. Only the four LocationAbbreviation codes.",
            "Software 750 is HAX (MedReceivables_Charges). AP_Halifax HAA is 751.",
            "Also drop MedReceivables_New_FLG_Locations.xlsx for 750 so TEST FLG_LOCATIONS has the four codes.",
            "Proof is HAX ADT/DFT missing those LocationAbbreviation accounts, not the XSLT.",
        ]
        already = bool(extra_ed) and all(e.get("already_applied") for e in extra_ed)
        if already and re.search(r"\bDFT\b", f"{subj}\n{body}", re.I):
            dive["summary"] = (
                "Karen wants HMC 201 / HH IPM / TLGI / OR TL charges off the Halifax DFT. "
                "Those LocationAbbreviation strips are already on disk for software 750 HAX, "
                "and DFT already skips @stripped charges."
            )
            dive["ask"] = (
                "Strip location FLG: take HMC 201 / HH IPM / TLGI / OR TL charges off the DFT. "
                "Example accounts 30101805251 (OR TL) and 30101976049 (HMC 201) from "
                "New mapping\\Halifax MedReceivables_Demographic_20260802. SOFTWARE_ID 750 HAL HAX."
            )
            dive["start_work"] = (
                "Do not Re-Implement the same strip_data edits. Capture Regression Baseline first, "
                "then prove HAX DFT has no FT1s for 30101805251 / 30101976049. Those accounts "
                "should land on the FLG Location Charges kickout."
            )
        else:
            dive["start_work"] = (
                "Start work points FLG_LOCATIONS.CODE at LocationAbbreviation and keeps the 750 hardcode. "
                "Capture Regression Baseline first. Then drop the FLG workbook for software 750."
            )
    elif client_dive.is_hal_strip_bug_ask(body, subj):
        extra_ed = client_dive.propose_hal_strip_bug(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "Halifax stripping still misses HMC 201 / OR TL on TEST. Normalize Location_ABBR and "
            "match the space-stripped code so those accounts leave HAX ADT/DFT and land on FLG Location Charges."
        )
        dive["ask"] = (
            "Karen retested: accounts 30101805251 (OR TL) and 30101976049 (HMC 201) from raw file "
            "_20260802 are still not pulled off those locations. Keep the HAX facility map. Make the "
            "existing strip see padded / TLGI vs TL GI Location_ABBR."
        )
        dive["intent"] = "strip"
        dive["codes"] = ["HMC 201", "HH IPM", "TLGI", "OR TL"]
        dive["feed"] = {
            "partition": "HAL",
            "name": "Halifax HAX",
            "software_id": "750",
            "xslt": client_dive.HAL_MAP,
        }
        dive["files"] = [
            {
                "path": client_dive.HAL_MAP,
                "hits": [
                    {
                        "code": "LOCATION_ABBR",
                        "line": 70,
                        "text": "HAX CP map — trim Location_ABBR so the strip can see HMC 201 / OR TL.",
                    }
                ],
            },
            {
                "path": client_dive.STRIP_DATA,
                "hits": [
                    {
                        "code": "HMC 201",
                        "line": 59,
                        "text": "Existing exact-match strip; replace with space-stripped uppercase compare.",
                    }
                ],
            },
        ]
        dive["risks"] = [
            "Do not delete the HMC 201 / HH IPM / TL GI / OR TL map lines. Those still split to HAX; stripping is a separate step.",
            "Do not strip every HAX row. Only the four Location_ABBR codes.",
            "The first request already added admLocationAbbr and an exact-match strip. This follow-up only hardens that match.",
            "AP_Halifax (HAA / 751) is a different listener. Karen’s table is software 750 HAX (MedReceivables_Charges). If TEST only dropped AP_Halifax, say so before Implement.",
        ]
    elif client_dive.is_mue_bug_ask(body, subj):
        extra_ed = client_dive.propose_mue_bug(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "MUE Excel load only inserted the first CPT (80048) because later rows have a blank SOFTWAREID. "
            "Fill SOFTWAREID down in route 88e, then re-drop the updated New_MUE_Edits workbooks."
        )
        dive["ask"] = (
            "Karen retested: only CPT 80048 from the MUE log is mapping. Later lines leave SOFTWAREID and "
            "CLIENTNAME blank (example 80051). She updated the logs for HAL, NGP Healthfirst, NSP, and PPS "
            "and asked to re-upload them. Do not re-do the DFT HAL/NGP/NSP/PPS when-tests; those are already on TEST."
        )
        dive["intent"] = "change"
        dive["codes"] = ["80048", "80051"]
        dive["feed"] = {
            "partition": "HAL",
            "name": "Halifax HAX",
            "software_id": "750",
            "xslt": client_dive.ADD_MUE,
        }
        dive["files"] = [
            {
                "path": client_dive.ADD_MUE,
                "hits": [
                    {
                        "code": "SOFTWAREID",
                        "line": 5,
                        "text": "88e skips XCSExcelRow when SOFTWAREID is empty — only 80048 inserts.",
                    }
                ],
            }
        ]
        dive["risks"] = [
            "Do not re-apply the DFT MUE when-tests for HAL / NGP 652 / NSP / PPS. Those are already on TEST.",
            "CLIENTNAME is not stored in MUE_EDITS. Empty client name is fine; empty SOFTWAREID is not.",
            "After the XSLT change, drop New_MUE_Edits_HAL.xlsx, New_MUE_Edits_NGP HF.xlsx, New_MUE_Edits_NSP.xlsx, and New_MUE_Edits_PPS.xlsx into data/in so 88e reloads the table.",
            "NGP AP (software 651) stays on the CPT path. Software 751 HAA is out of scope.",
        ]
        dive["start_work"] = (
            "Start work applies the 88e fill-down, then copies the four updated New_MUE_Edits_*.xlsx "
            "into data/in so TEST reloads every CPT (80048 and 80051+)."
        )
    elif client_dive.is_ntx_pv12_pos24_ask(body, subj):
        extra_ed = client_dive.propose_ntx_pv12_pos24(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "NTX PV1.2 must be 24 for the listed Solis/ASC locations. ARL I.TPC already does that; "
            "BB.SOLIS / M.ASC / E.SOLIS currently concatenate type+location, and the rest of the table "
            "falls through to patient type."
        )
        dive["ask"] = (
            "Set ADT PV1.2 to 24 only for Karen’s NTX location table (BB.SOLIS ANC, I.SOLIS ARL, "
            "G.SOLIS/G.ASC DEN, M.ASC / M.ASC ALLI FTW, AF.SOLIS LAS, L.SOLIS LEW, Q.SOLIS MCK, "
            "H.SOLIS/H.ASC MED, E.SOLIS PLA, BE.SOLIS / BE.LABSOLI WEA). Keep the existing ARL I.TPC → 24 "
            "rule (OCR called it LTPC). Example: account 8383414 Ramos,Evette, loc BB.SOLIS, raw ntxarl080626."
        )
        dive["intent"] = "change"
        dive["codes"] = [
            "BB.SOLIS",
            "I.TPC",
            "I.SOLIS",
            "G.SOLIS",
            "G.ASC",
            "M.ASC",
            "M.ASC ALLI",
            "AF.SOLIS",
            "L.SOLIS",
            "Q.SOLIS",
            "H.SOLIS",
            "H.ASC",
            "E.SOLIS",
            "BE.LABSOLI",
            "BE.SOLIS",
        ]
        dive["feed"] = {
            "partition": "NTX",
            "name": "NTX (Solis / ASC locations)",
            "software_id": "400",
            "xslt": client_dive.ARA_A04,
        }
        dive["files"] = [
            {
                "path": client_dive.ARA_A04,
                "hits": [
                    {
                        "code": "PV1.2",
                        "line": 405,
                        "text": "NTX BB.SOLIS / M.ASC / E.SOLIS concat type+location; ARL I.TPC already emits 24.",
                    }
                ],
            }
        ]
        dive["risks"] = [
            "This is ADT PV1.2 only. Do not change DFT, stripping, or facility split maps.",
            "Do not edit LTPC as a new ARL location. The working ARL rule is I.TPC → 24; keep that and copy it.",
            "FRI/SAC E.SOLIS and PLA E.DS keep the old type+location concat. Only PLA E.SOLIS becomes 24.",
            "TPH D.TPATH, RIO H.LIND, and CLO G.BASC concat rules stay as they are.",
            "BE.LABSOLI is likely OCR for BE.LABSOLIS; match both plus BE.SOLIS under WEA.",
            "Proof is outgoing ANC ADT PV1-2 = 24 for 8383414 / BB.SOLIS, not an XSLT diff.",
        ]
        dive["start_work"] = (
            "Start work applies the ADT A04 PV1.2 when-tests. Capture Regression Baseline first. "
            "Proof is the ANC ADT for account 8383414 (BB.SOLIS) showing PV1-2 24."
        )
    elif client_dive.is_nhl_cat_lc_dft_ask(body, subj):
        extra_ed = client_dive.propose_nhl_cat_lc_dft(root)
        if extra_ed:
            dive["edits"] = extra_ed
        already = bool(extra_ed) and all(e.get("already_applied") for e in extra_ed)
        followup = bool(re.search(r"not working|still|again", f"{subj}\n{body}", re.I))
        dive["intent"] = "strip"
        dive["codes"] = ["LC"]
        dive["feed"] = {
            "partition": "NHL",
            "name": "NHL CAT",
            "software_id": "524",
            "xslt": client_dive.DFT_P03,
        }
        dive["files"] = [
            {
                "path": client_dive.SITE_STRIP,
                "hits": [
                    {
                        "code": "LC",
                        "line": 11,
                        "text": (
                            "Already trims performingSite / MNEMONIC with normalize-space (PTH5.CMC pads LC to 16 chars)."
                            if already
                            else "STRIP_PERFORMING_SITES compare is exact; PTH5.CMC performingSite is 16-char padded."
                        ),
                    }
                ],
            },
            {
                "path": client_dive.DFT_P03,
                "hits": [
                    {
                        "code": "Charge",
                        "line": 195,
                        "text": (
                            "Already skips Charge[@stripped='true'] when writing FT1s."
                            if already
                            else "DFT for-each-group selects every Charge; ADT already skips @stripped."
                        ),
                    }
                ],
            },
            {
                "path": client_dive.STRIP_DATA,
                "hits": [
                    {
                        "code": "R.LABND",
                        "line": 59,
                        "text": "Location strip (R.EH / R.LABND) is already on Client=CAT. Do not re-do that.",
                    }
                ],
            },
        ]
        if already and followup:
            dive["summary"] = (
                "Karen says LC strip accounts still load to DFT after the TEST deploy. The two "
                "XSLT fixes are already on disk and only strip the LabCorp send-out. Those four "
                "accounts are mixed, so they still appear on DFT with their CMCH charges. That "
                "matches her follow-up if TEST has the zip."
            )
            dive["ask"] = (
                "Its not working. The charges for the LC Strip accounts are loading to the DFT. "
                "Same accounts as yesterday: HK027123503 Johar, HK027124411 Hebert, "
                "HK027124488 Gasper, HK027127932 Winter."
            )
            dive["build_plan"] = [
                {
                    "title": "Why it can still look broken after TEST has the zip",
                    "paras": [
                        "Yesterday’s change was charge-only, same pattern as Huggins/Monadnock: mark the LC performing-site charge @stripped, skip it in DFT FT1s, keep the account. "
                        "Her first subject was “Strip account loading to DFT but shouldn't.” If she searches Johar / Hebert / Gasper / Winter on the new DFT, they are still there.",
                    ],
                    "bullets": [
                        "What the zip actually removes: Johar L000434101, Hebert L000191801, Gasper L000452701, Winter L000191801. Those should be on the performing-site kickout sheet.",
                        "What still loads to DFT: every CMCH charge on those same four accounts. That is the current sandbox proof, not a missed copy.",
                        "If those four LC CDMs are still on the TEST DFT, then TEST is not running the new DFT select or the site-strip XSLT. If only the account numbers are still there, the deploy took and she wants account-level strip.",
                    ],
                }
            ]
            dive["risks"] = [
                "Do not Re-Implement the same two files unless TEST DFT still contains L000434101 / L000191801 / L000452701.",
                "Dropping the whole account from DFT is a new edit — do not do that unless she confirms the remaining CMCH charges should go too.",
                "Do not re-gate R.EH / R.LABND on software 513.",
                "Villa 27017720 (CMCH, not LC) must stay on CAT DFT.",
                "Proof is the outgoing CAT DFT CDMs, not the XSLT diff.",
            ]
            dive["start_work"] = (
                "Do not Re-Implement the same two files. Confirm whether TEST DFT still has the "
                "four LC CDMs or only the mixed-account CMCH FT1s. Implement again only if she "
                "wants those whole accounts off the DFT."
            )
        else:
            dive["summary"] = (
                "NHL CAT LabCorp (LC) performing-site charges still load to DFT. Trim the padded "
                "performingSite before STRIP_PERFORMING_SITES, and skip @stripped charges in the DFT "
                "FT1 group the same way ADT already does."
            )
            dive["ask"] = (
                "The charges for the LC Strip accounts are loading to the DFT. Fix today — month-end. "
                "Raw PTH5.CMC from Expanded expanse\\NHL-Catholic (PTH5.CMC..07141). Example accounts: "
                "HK027123503 Johar^Abdalla, HK027124411 Hebert^Marc A, HK027124488 Gasper^John, "
                "HK027127932 Winter^Deborah."
            )
            dive["risks"] = [
                "LC is LabCorp performing site (STRIP_PERFORMING_SITES), not a new FLG location and not NGP.",
                "Do not re-gate R.EH / R.LABND on software 513. That CAT location strip is already on disk.",
                "Huggins / Monadnock stay charge-only: keep the ADT, omit those charges from DFT.",
                "Villa 27017720 (CMCH, not LC) must stay on CAT DFT.",
                "Proof is outgoing CAT DFT from PTH5.CMC, not the XSLT diff.",
            ]
            dive["start_work"] = (
                "Start work trims the performing-site lookup and skips stripped charges in DFT. "
                "Do not recapture pth5-cmc baseline. Proof is CAT DFT omitting LC performing-site "
                "charges (Johar / Hebert / Gasper / Winter when the 07141 file is present) and "
                "keeping Villa."
            )
    elif client_dive.is_nhl_cat_bug_ask(body, subj):
        extra_ed = client_dive.propose_nhl_cat_bug(root)
        if extra_ed:
            dive["edits"] = extra_ed
        dive["summary"] = (
            "NHL CAT stripping and relationship defaults never ran on the PTH5.CMC charge file "
            "because they were keyed to software 513 (FPS Central Lab). Gate them on Client CAT, "
            "strip the CMCEH 2ndry pairs on charges as well as demos, and wire the existing "
            "Huggins/Monadnock charge-only transform."
        )
        dive["ask"] = (
            "Karen retested PTH5.CMC..07141: stripping hits the demo file, not the charge file "
            "(acct 27148026 Moreau / R.LABND). FLG still R.EH and R.LABND. 2ndry pairs still "
            "R.EH/R.LAB/R.LABND/RG.LAB + CMCEH. Fill blank GT1.11 and IN1.17 when the account "
            "is Huggins, Monadnock, or employee (acct 27148042 Fleming)."
        )
        dive["intent"] = "strip"
        dive["codes"] = [
            "R.EH",
            "R.LABND",
            "R.EH/CMCEH",
            "R.LAB/CMCEH",
            "R.LABND/CMCEH",
            "RG.LAB/CMCEH",
        ]
        dive["feed"] = {
            "partition": "NHL",
            "name": "NHL CAT",
            "software_id": "",
            "xslt": client_dive.STRIP_DATA,
        }
        dive["files"] = [
            {
                "path": client_dive.STRIP_DATA,
                "hits": [
                    {
                        "code": "R.LABND",
                        "line": 59,
                        "text": "Charge strip still requires SoftwareID 513 — CAT lookup is not 513.",
                    }
                ],
            },
            {
                "path": client_dive.CAT_HUGGINS,
                "hits": [
                    {
                        "code": "HUGGINSHOS",
                        "line": 15,
                        "text": "Charge-only Huggins/Monadnock strip exists but is not on route 2.",
                    }
                ],
            },
            {
                "path": client_dive.ARA_A04,
                "hits": [
                    {
                        "code": "GT1.11",
                        "line": 898,
                        "text": "Relationship default gated on software 513, so Fleming stays blank.",
                    }
                ],
            },
            {
                "path": client_dive.STRIP_ROUTE,
                "hits": [
                    {
                        "code": "Huggins",
                        "line": 298,
                        "text": "Route 2 never runs transform-CAT-huggins-monadnock-strip.xslt.",
                    }
                ],
            },
        ]
        dive["risks"] = [
            "Do not keep gating NHL CAT on software 513. That ID is FPS Central Lab in CLIENT_SPLITS.",
            "Huggins / Monadnock (Filler2 HUGGINSHOS / MONCOMHOS) strip charges only. Keep the ADT.",
            "Employee-health 2ndry pairs (*/CMCEH) must strip Charge and PatientDemographics.",
            "Do not re-add R.EH / R.LABND as a software-513-only FLG. Use Client CAT.",
            "Proof is PTH5.CMC..07141: 27148026 off DFT (and ADT if FLG), 27148042 GT1.11/IN1.17 filled.",
        ]
        dive["start_work"] = (
            "Start work applies the CAT client gate, the charge 2ndry strip, and hooks "
            "transform-CAT-huggins-monadnock-strip.xslt on route 2. Capture Regression Baseline first. "
            "Proof is the CAT ADT/DFT from PTH5.CMC..07141, not the XSLT diff."
        )
    elif part == "HAL" and codes and table:
        dive["summary"] = (
            f"{'Strip' if intent == 'strip' else 'Change'} {len(codes)} location code(s) for "
            f"Halifax ({feed.get('software_id') or '750'}): " + ", ".join(codes)
        )
    elif codes and part and part != "HAL":
        dive["summary"] = (
            f"{intent.title()} for {feed_name or part} ({part}"
            + (f" software {feed.get('software_id')}" if feed and feed.get("software_id") else "")
            + "): "
            + ", ".join(codes)
        )
    elif not dive.get("summary") or "Location_ABBR" in (dive.get("summary") or "") and part != "HAL":
        dive["summary"] = dive.get("ask") or subj or "Client interface change"
        if feed:
            dive["summary"] = f"{feed_name or part}: {dive['summary']}"

    if "Location_ABBR code(s) in Halifax" in (dive.get("summary") or "") and part != "HAL":
        dive["summary"] = (dive.get("ask") or subj or dive["summary"]).replace(
            "Location_ABBR code(s) in Halifax", f"change for {feed_name or part or 'this feed'}"
        )

    _progress(on_progress, 8, steps, "Writing the change plan…")
    llm_trace = (dive.get("plan_trace") or {}).get("llm")
    dive["plan_trace"] = {
        "feed": dive.get("feed"),
        "thread_parts": len(split_thread(body)),
        "used_latest_followup": bool(re.search(r"after the update|now we are missing", focus, re.I)),
        "hl7": hl7,
        "location_table": table,
        "catalog_updated": catalog.get("updated"),
        "catalog_feeds": len(catalog.get("feeds") or []),
        "llm": llm_trace,
    }
    return dive
