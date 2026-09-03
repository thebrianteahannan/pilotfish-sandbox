"""1–3 client questions to attach to a change plan."""

from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path

import client_dive
import client_halifax_strip_followup_plan
import client_irl_expanse_g3_plan
import client_ngp_accession_plan
import client_nsp_pps_mue_plan


def _qid(text: str) -> str:
    return hashlib.sha1((text or "").encode("utf-8")).hexdigest()[:10]


def _q(text: str, why: str) -> dict:
    return {"id": _qid(text), "text": text, "why": why, "status": "open", "answer": ""}


def curate(dive: dict, email: str = "") -> list[dict]:
    blob = f"{dive.get('summary') or ''} {dive.get('ask') or ''} {email or ''}"
    feed = dive.get("feed") or {}
    out: list[dict] = []

    def add(text: str, why: str) -> None:
        if len(out) >= 3:
            return
        rec = _q(text, why)
        if rec["id"] in {q["id"] for q in out}:
            return
        out.append(rec)

    if client_irl_expanse_g3_plan.is_ask(email, str(dive.get("subject") or "")):
        add(
            "Confirm we should change MedReceivables_NewFacilityInfo_IRL_CEX.xlsx SOFTWAREID from 524 to 528 before 88a (524 is already NHL CAT in H2).",
            "The Sept 1 CEX workbook still says 524. CLIENT_CODES is per SOFTWARE_ID, so loading it as-is would attach Monroe split codes to CAT.",
        )
        return out

    if client_halifax_strip_followup_plan.is_ask(email, str(dive.get("subject") or "")):
        add(
            "Did TEST load MedRec_TEST_Deploy_20260825_halifax-stripping-location.zip before the 14:38 HAX0825d rerun?",
            "That zip already has the four-code strip_data hardcode. If TEST never loaded it, this is a deploy miss, not a new XSLT.",
        )
        add(
            "After that zip is live, re-drop the Aug 26 20260802 files — do CONVERY 30101805251 and TANNER 30101976049 leave HAX ADT?",
            "If they still stay, dump the joined Group and read admLocationAbbr. Empty abbr is the only new XSLT hole.",
        )
        return out

    if client_nsp_pps_mue_plan.is_ask(email, str(dive.get("subject") or "")):
        add(
            "Are HAL and NGP Healthfirst MUEs splitting on TEST (2659 + kickout), or only NSP and PPS broken?",
            "The DFT $CDM Orig hole is the same pattern. This plan only changes NSP and PPS.",
        )
        add(
            "Does TEST MUE_EDITS already have software 760 / 761 rows from New_MUE_Edits_NSP and New_MUE_Edits_PPS?",
            "If the table is empty, re-drop those two workbooks after the XSLT. That is not a second code change.",
        )
        return out

    if client_ngp_accession_plan.is_ask(email, str(dive.get("subject") or "")):
        add(
            "Confirm this is NGP Healthfirst (CAQ, software 652) only — not NGP AP (651).",
            "Accession log already triggers for CAQ. The blank columns are from the Healthfirst Charge map.",
        )
        add(
            "Should Pathologist NPI (Referring Provider NPI CER) stay off the accession log, or do you want a new column?",
            "Karen listed that header. The sheet today only has SpecimenNo and Pathologist.",
        )
        return out

    if client_dive.is_nhl_cat_lc_dft_ask(email, str(dive.get("subject") or "")):
        already = bool(dive.get("edits")) and all(e.get("already_applied") for e in (dive.get("edits") or []))
        if already:
            add(
                "On the TEST DFT after the zip, are L000434101 / L000191801 / L000452701 still present, or only Johar / Hebert / Gasper / Winter with their remaining CMCH charges?",
                "If the LC CDMs are gone, the deploy took and she is seeing the charge-only leftover. If those CDMs are still on DFT, TEST is not running the new XSLT.",
            )
        else:
            add(
                "Should LC strip stay charge-only (LabCorp send-outs off DFT, in-house CMCH stay), or should the whole account drop off DFT?",
                "Yesterday's example accounts are mixed: one LC send-out plus many CMCH charges.",
            )
        return out

    if client_dive.is_ntx_pv12_pos24_ask(email, str(dive.get("subject") or "")):
        add(
            "Is BE.LABSOLI the Weatherford mnemonic as written, or BE.LABSOLIS (the OCR line looks cut off)?",
            "The plan matches both plus BE.SOLIS under WEA so Implement is not blocked.",
        )
        add(
            "Anything else we should not change (FRI/SAC E.SOLIS concat, DFT, other partitions)?",
            "Default scope check when the ask looks contained.",
        )
        return out

    if re.search(r"after the update|now we are missing", blob, re.I):
        add(
            "Should we keep the earlier Primary Payer → IN1.4 change and only fix this follow-up (self-pay IN1), or do you still see blanks on the original insured accounts too?",
            "The thread looks like a regression after a change that is already in place.",
        )
    if re.search(r"self[\s-]?pay", blob, re.I) and re.search(r"\bIN1\b", blob, re.I):
        if not re.search(r"relationship|IN1\.17", blob, re.I) and not re.search(r"Healthfirst|missing.{0,40}IN1", blob, re.I):
            add(
                "For self-pay, should the ADT keep the old PPP IN1 (plan PPP, patient as subscriber), or should IN1.4 show the raw self-pay payer name?",
                "Those two shapes are not the same on the wire.",
            )
    acct = re.search(r"\b(?:CC)?(\d{8,})\b", blob)
    if acct and re.search(r"example|acct|account", blob, re.I):
        if not re.search(r"halifax", blob, re.I) or not re.search(r"\bbug\b|not splitting", blob, re.I):
            if not re.search(r"\bMUE", blob, re.I):
                add(
                    f"Is account {acct.group(1)} the only example we should prove, or are there more accounts in a later raw file we do not have yet?",
                    "The plan is only as good as the sample we can replay.",
                )
    if not feed.get("partition"):
        add(
            "Which facility / feed is this for (for example NGP Healthfirst, Halifax, Ariana)?",
            "The email did not clearly match a CLIENT_SPLITS row.",
        )
    elif feed.get("partition") == "NGP" and re.search(r"health\s*first|caq", blob, re.I):
        add(
            "Confirm this is NGP Healthfirst (CAQ, software 652) only — not the other NextGen Pathology splits (AP / 651).",
            "NGP has more than one software id in CLIENT_SPLITS.",
        )
    if (dive.get("intent") == "strip" or re.search(r"\bstrip\b", blob, re.I)) and not re.search(
        r"\b\d{3}\s+(NHL|HAL|ARA|FPS|NGP)\b", blob
    ):
        add(
            "Which SOFTWARE_ID / partition should these locations strip under, and is this TEST only or TEST and live?",
            "Strip rules are per software id; applying the wrong one hits the wrong client.",
        )
    if not (dive.get("edits") or []):
        add(
            "Can you send a before/after HL7 snippet plus the raw file for one account so we can pin the exact field?",
            "The hub could not propose an automatic edit from this email alone.",
        )
    if not out:
        add(
            "Anything else we should not change (other facilities, DFT vs ADT, kickout reports)?",
            "Default scope check when the ask looks contained.",
        )
    return out[:3]


def merge(new: list[dict], prev: list[dict] | None) -> list[dict]:
    old = {str(q.get("id")): q for q in (prev or []) if isinstance(q, dict) and q.get("id")}
    out = []
    seen = set()
    for q in new:
        prior = old.get(q["id"]) or {}
        rec = dict(q)
        if prior.get("answer") or prior.get("status") == "closed":
            rec["status"] = prior.get("status") or rec["status"]
            rec["answer"] = prior.get("answer") or ""
            rec["answered_at"] = prior.get("answered_at") or ""
        out.append(rec)
        seen.add(q["id"])
    for qid, prior in old.items():
        if qid in seen:
            continue
        if prior.get("status") == "closed" or prior.get("answer"):
            out.append(prior)
    return out[:6]


def attach(dive: dict, email: str, prev: dict | None) -> dict:
    dive["questions"] = merge(curate(dive, email), list((prev or {}).get("questions") or []))
    return dive


def load_dive(folder: Path) -> dict:
    path = folder / "dive.json"
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def save_dive(folder: Path, dive: dict) -> None:
    (folder / "dive.json").write_text(json.dumps(dive, indent=2) + "\n", encoding="utf-8")


def answer(folder: Path, qid: str, answer: str = "", close: bool = True) -> dict:
    dive = load_dive(folder)
    found = None
    for q in dive.get("questions") or []:
        if str(q.get("id")) == str(qid):
            found = q
            break
    if not found:
        raise FileNotFoundError(qid)
    text = (answer or "").strip()
    if text:
        found["answer"] = text
        found["answered_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    found["status"] = "closed" if close else "open"
    if close and not found.get("answer"):
        found["answer"] = "(closed with no reply)"
        found["answered_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    save_dive(folder, dive)
    return found
