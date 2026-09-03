"""Named systems and missing-hop cues in the live feed."""

from __future__ import annotations

import re
from collections import defaultdict
from typing import Any

CATALOG = [
    ("Mirth / NextGen Connect", "engine", [r"\bmirth\b", r"nextgen connect"]),
    ("Rhapsody", "engine", [r"\brhapsody\b"]),
    ("Cloverleaf", "engine", [r"\bcloverleaf\b"]),
    ("Corepoint", "engine", [r"\bcorepoint\b"]),
    ("HealthShare / Ensemble", "engine", [r"\bhealthshare\b", r"\bensemble\b"]),
    ("Epic", "ehr", [r"\bepic\b"]),
    ("Oracle Health / Cerner", "ehr", [r"\bcerner\b", r"oracle health"]),
    ("MEDITECH", "ehr", [r"\bmeditech\b"]),
    ("athenahealth", "ehr", [r"\bathena(?:health)?\b"]),
    ("eClinicalWorks", "ehr", [r"\beclinicalworks\b", r"\becw\b"]),
    ("Waystar", "rcm", [r"\bwaystar\b"]),
    ("Availity", "rcm", [r"\bavaility\b"]),
    ("Change Healthcare", "rcm", [r"change healthcare", r"\bchangehc\b"]),
    ("Optum", "rcm", [r"\boptum\b"]),
    ("Guidewire", "insurance", [r"\bguidewire\b", r"\bpolicycenter\b", r"\bclaimcenter\b"]),
    ("Duck Creek", "insurance", [r"duck creek"]),
    ("ACORD / TxLife", "insurance", [r"\bacord\b", r"\btxlife\b", r"\btx life\b"]),
]

MISSING = [
    (r"\bno (?:interface|engine|integration|api)\b", "No engine / interface / API"),
    (r"\bstill (?:manual|in excel|spreadsheet|re-?key)", "Still manual / Excel / re-key"),
    (r"\blooking for (?:an? )?(?:engine|interface|integrator|vendor|consultant)\b", "Looking for an engine or integrator"),
    (r"\bwe don'?t have\b", "They said they do not have it"),
    (r"\bcan'?t (?:connect|integrat|exchange|send|receive)\b", "Cannot connect / exchange"),
    (r"\bportal (?:rework|login|download)\b", "Portal rework instead of a feed"),
]


def _blob(post: dict[str, Any]) -> str:
    return " ".join(str(post.get(k) or "") for k in ("title", "selftext", "why", "product_name"))


def extract_systems(posts: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    in_use: dict[str, dict[str, Any]] = {}
    for name, kind, pats in CATALOG:
        rec = {"name": name, "kind": kind, "count": 0, "samples": []}
        for post in posts:
            blob = _blob(post)
            if any(re.search(p, blob, re.I) for p in pats):
                rec["count"] += 1
                if len(rec["samples"]) < 2:
                    rec["samples"].append({"id": post.get("id"), "title": post.get("title") or ""})
        if rec["count"]:
            in_use[name] = rec
    used = sorted(in_use.values(), key=lambda r: -r["count"])

    missing_map: dict[str, dict[str, Any]] = defaultdict(lambda: {"label": "", "count": 0, "samples": []})
    for post in posts:
        blob = _blob(post)
        for pat, label in MISSING:
            if re.search(pat, blob, re.I):
                rec = missing_map[label]
                rec["label"] = label
                rec["count"] += 1
                if len(rec["samples"]) < 2:
                    rec["samples"].append({"id": post.get("id"), "title": post.get("title") or ""})
    missing = sorted(missing_map.values(), key=lambda r: -r["count"])
    return {"in_use": used[:12], "missing": missing[:8]}
