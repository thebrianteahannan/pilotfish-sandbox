"""Classify a change-plan with local Ollama. Does not invent file edits."""

from __future__ import annotations

import json
from pathlib import Path

import client_catalog
import hub_llm

SYSTEM = """You plan PilotFish eiPlatform change requests for a client sandbox.
PHI stays on this machine. Do not invent XSLT or file paths.
Return JSON only with keys:
partition (HAL, NGP, ARA, SPG, PPA, PPS, GLF, or empty),
feed_name, kind (hl7_field | strip_locations | other),
intent (change | strip), codes (string array of location codes only, never account numbers),
summary (one sentence), ask (one or two sentences), risks (string array),
previous_email_done (boolean).
Pick the feed from the provided catalog. Prefer the latest ask in a thread.
If the email is about IN1/GT1/self-pay/payer mapping, kind is hl7_field and codes must be [].
If it is a location-abbreviation strip/add table, kind is strip_locations.
Do not treat 8+ digit account numbers as location codes.
Do not assume Halifax unless the catalog match is Halifax."""


def _cards(catalog: dict) -> list[dict]:
    cards = []
    seen = set()
    for rec in list(catalog.get("xslt") or []) + list(catalog.get("feeds") or []):
        key = ((rec.get("partition") or ""), (rec.get("name") or ""))
        if key in seen or not key[0]:
            continue
        seen.add(key)
        cards.append(
            {
                "partition": rec.get("partition"),
                "name": rec.get("name"),
                "software_id": rec.get("software_id") or "",
                "aliases": (rec.get("aliases") or [])[:8],
            }
        )
        if len(cards) >= 48:
            break
    return cards


def classify(email: str, subject: str, catalog: dict, heuristic: dict) -> dict:
    st = hub_llm.status()
    if not st.get("ok"):
        return {"ok": False, "error": st.get("error") or "Ollama is not running", "guess": {}}
    if st.get("error") and not st.get("model_present"):
        return {"ok": False, "error": st["error"], "guess": {}}
    user = {
        "subject": subject or "",
        "email": (email or "")[:8000],
        "heuristic": heuristic,
        "feeds": _cards(catalog),
    }
    try:
        guess = hub_llm.chat_json(
            [
                {"role": "system", "content": SYSTEM},
                {"role": "user", "content": json.dumps(user)},
            ]
        )
    except Exception as exc:
        return {"ok": False, "error": str(exc)[:400], "guess": {}}
    if not guess:
        return {"ok": False, "error": "Ollama returned empty JSON", "guess": {}}
    return {"ok": True, "error": "", "guess": guess, "model": hub_llm.OLLAMA_MODEL}


def _resolve_feed(catalog: dict, guess: dict) -> dict | None:
    blob = " ".join(
        str(guess.get(k) or "") for k in ("partition", "feed_name", "summary", "ask")
    )
    return client_catalog.match(catalog, blob)


def apply(dive: dict, classified: dict, catalog: dict) -> dict:
    guess = classified.get("guess") or {}
    if not classified.get("ok") or not guess:
        dive.setdefault("plan_trace", {})["llm"] = {
            "ok": False,
            "error": classified.get("error") or "skipped",
            "model": hub_llm.OLLAMA_MODEL,
        }
        return dive
    kind = str(guess.get("kind") or "")
    part = str(guess.get("partition") or "").strip().upper()
    feed = _resolve_feed(catalog, guess)
    if feed:
        dive["feed"] = {
            "partition": feed.get("partition") or part,
            "name": feed.get("name") or guess.get("feed_name") or "",
            "software_id": feed.get("software_id") or "",
            "xslt": feed.get("xslt") or "",
        }
        part = dive["feed"]["partition"]
    elif part:
        dive.setdefault("feed", {})["partition"] = part
        if guess.get("feed_name"):
            dive["feed"]["name"] = guess["feed_name"]
    if guess.get("summary"):
        dive["summary"] = str(guess["summary"]).strip()
    if guess.get("ask"):
        dive["ask"] = str(guess["ask"]).strip()
    if guess.get("intent") in {"change", "strip"}:
        dive["intent"] = guess["intent"]
    risks = [str(r).strip() for r in (guess.get("risks") or []) if str(r).strip()]
    if risks:
        dive["risks"] = list(dict.fromkeys(list(dive.get("risks") or []) + risks))[:8]
    if kind == "hl7_field":
        dive["codes"] = []
        dive["edits"] = [e for e in (dive.get("edits") or []) if e.get("action") != "remove_when"]
    elif kind == "strip_locations":
        codes = [str(c).strip() for c in (guess.get("codes") or []) if str(c).strip()]
        codes = [c for c in codes if not c.isdigit() or len(c) < 8]
        if codes:
            dive["codes"] = codes
    dive.setdefault("plan_trace", {})["llm"] = {
        "ok": True,
        "model": classified.get("model") or hub_llm.OLLAMA_MODEL,
        "kind": kind,
        "partition": part,
        "previous_email_done": bool(guess.get("previous_email_done")),
    }
    return dive


def refine(root: Path, dive: dict, email: str, subject: str, catalog: dict, heuristic: dict) -> dict:
    _ = root
    classified = classify(email, subject, catalog, heuristic)
    return apply(dive, classified, catalog)
