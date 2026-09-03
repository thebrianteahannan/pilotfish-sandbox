"""Med Rec feeds from CLIENT_SPLITS (H2 extract) plus route-1 transform names."""

from __future__ import annotations

import csv
import json
import re
from datetime import date
from pathlib import Path

CSV_REL = "reports/CLIENT_SPLITS_full.csv"
JSON_REL = "documents/medrec-feeds.json"
XSLT_DIR = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client"
)
PART_XSLT = {
    "halifax": ("HAL", ["Halifax", "HAL", "HAX", "HAA"]),
    "hal-haa": ("HAL", ["Halifax HAA", "HAA"]),
    "ngp-healthfirst": ("NGP", ["NGP Healthfirst", "NGP HealthFirst", "Healthfirst", "Health First", "CAQ"]),
    "ngp-ap": ("NGP", ["NGP AP", "NextGen AP"]),
    "ngp-": ("NGP", ["NGP", "NextGen Pathology", "NextGen"]),
    "ariana": ("ARA", ["Ariana", "ARA", "LigoLab"]),
    "travelers": ("ARA", ["Travelers"]),
    "stamford": ("SPG", ["Stamford", "SPG"]),
    "ppa": ("PPA", ["PPA"]),
    "pps": ("PPS", ["PPS", "NSP"]),
    "glf": ("GLF", ["Gulf", "GLF"]),
}


def csv_path(root: Path) -> Path:
    return root / CSV_REL


def json_path(root: Path) -> Path:
    return root / JSON_REL


def _aliases(*parts: str) -> list[str]:
    out: list[str] = []
    for part in parts:
        t = re.sub(r"\s+", " ", str(part or "")).strip()
        if t and t not in out:
            out.append(t)
    return out


def _from_csv(root: Path) -> list[dict]:
    path = csv_path(root)
    if not path.is_file():
        return []
    grouped: dict[tuple[str, str, str], dict] = {}
    with path.open(encoding="utf-8", errors="replace", newline="") as fh:
        for row in csv.DictReader(fh):
            part = (row.get("PARTITION") or "").strip()
            sw = (row.get("SOFTWAREID") or "").strip()
            name = (row.get("CLIENT_SPLIT") or "").strip()
            split = (row.get("SPLIT_CODE") or "").strip()
            fac = (row.get("FACILITY") or "").strip()
            if not (part and sw and name):
                continue
            key = (part, sw, name)
            rec = grouped.setdefault(
                key,
                {
                    "partition": part,
                    "software_id": sw,
                    "name": name,
                    "split_codes": [],
                    "facilities": [],
                    "aliases": _aliases(name, part, split, fac),
                },
            )
            if split and split not in rec["split_codes"]:
                rec["split_codes"].append(split)
            if fac and fac not in rec["facilities"]:
                rec["facilities"].append(fac)
            for a in _aliases(split, fac):
                if a not in rec["aliases"]:
                    rec["aliases"].append(a)
    return list(grouped.values())


def _xslt_hints(root: Path) -> list[dict]:
    folder = root / XSLT_DIR
    extra: list[dict] = []
    if not folder.is_dir():
        return extra
    for path in sorted(folder.glob("transform-*.xslt")):
        stem = path.name.lower()
        for needle, (part, aliases) in PART_XSLT.items():
            if needle in stem:
                extra.append(
                    {
                        "partition": part,
                        "software_id": "",
                        "name": path.stem.replace("transform-", "").replace("-flatfilexml-to-canconicalxml", ""),
                        "split_codes": [],
                        "facilities": [],
                        "aliases": aliases,
                        "xslt": path.relative_to(root).as_posix(),
                    }
                )
                break
    return extra


def refresh(root: Path) -> dict:
    feeds = _from_csv(root)
    xslt = _xslt_hints(root)
    for rec in xslt:
        specific = "healthfirst" in (rec.get("name") or "").lower()
        for feed in feeds:
            if feed["partition"] != rec["partition"]:
                continue
            aliases = list(rec["aliases"])
            if specific and "CAQ" not in (feed.get("split_codes") or []) and "CAQ" not in (feed.get("facilities") or []):
                aliases = [a for a in aliases if a.upper() in {"NGP", "NEXTGEN", "NEXTGEN PATHOLOGY"}]
            for a in aliases:
                if a not in feed["aliases"]:
                    feed["aliases"].append(a)
            if rec.get("xslt") and (
                not specific
                or "CAQ" in (feed.get("split_codes") or [])
                or "CAQ" in (feed.get("facilities") or [])
            ):
                feed["xslt"] = rec["xslt"]
    data = {
        "updated": date.today().isoformat(),
        "source": CSV_REL,
        "note": "Extract of H2 CLIENT_SPLITS. Re-run catalog refresh when the DB changes.",
        "feeds": feeds,
        "xslt": xslt,
        "partitions": sorted({f["partition"] for f in feeds}),
    }
    out = json_path(root)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return data


def load(root: Path) -> dict:
    path = json_path(root)
    if path.is_file():
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict) and data.get("feeds"):
                return data
        except (OSError, json.JSONDecodeError):
            pass
    return refresh(root)


def match(catalog: dict, text: str) -> dict | None:
    blob = text or ""
    best: dict | None = None
    best_n = 0
    for rec in list(catalog.get("feeds") or []) + list(catalog.get("xslt") or []):
        n = 0
        for alias in rec.get("aliases") or []:
            if len(alias) < 2:
                continue
            if re.search(r"\b" + re.escape(alias) + r"\b", blob, re.I):
                n += 4 if len(alias) > 4 else 1
                if re.search(r"health\s*first", alias, re.I):
                    n += 8
        if n > best_n:
            best_n = n
            best = rec
    if not best or best_n < 1:
        return None
    return dict(best, score=best_n)
