"""Coverage of CLIENT_SPLITS from a Med Rec regression run's ADT/DFT outputs."""

from __future__ import annotations

import csv
import json
import re
from pathlib import Path

PREFIX = re.compile(r"^([A-Za-z]{2,8})")


def _pct(hit: int, total: int) -> float:
    if not total:
        return 0.0
    return round(100.0 * hit / total, 1)


def _cat(label: str, hit: int, total: int, missed: list[str] | None = None) -> dict:
    return {
        "label": label,
        "hit": hit,
        "total": total,
        "pct": _pct(hit, total),
        "missed": (missed or [])[:40],
        "missed_more": max(0, len(missed or []) - 40),
    }


def _prefixes(names: list[str]) -> set[str]:
    out: set[str] = set()
    for name in names:
        m = PREFIX.match(Path(name).stem.replace(".", "_"))
        if m:
            out.add(m.group(1).upper())
    return out


def _splits_csv(root: Path) -> list[dict]:
    path = root / "reports" / "CLIENT_SPLITS_full.csv"
    if not path.is_file():
        return []
    with path.open(newline="", encoding="utf-8", errors="replace") as fh:
        return list(csv.DictReader(fh))


def build(root: Path, results: list[dict]) -> dict:
    rows = _splits_csv(root)
    hit_codes: set[str] = set()
    ran_ok = 0
    for ran in results or []:
        names = list(ran.get("files") or []) + list(ran.get("last_files") or []) + list(ran.get("baseline") or [])
        hit_codes |= _prefixes(names)
        if ran.get("ok") and names:
            ran_ok += 1
        cid = ran.get("id") or ""
        if cid:
            last = root / "regression" / "cases" / cid / "last"
            if last.is_dir():
                hit_codes |= _prefixes([p.name for p in last.iterdir() if p.is_file()])
            base = root / "regression" / "cases" / cid / "baseline"
            if base.is_dir() and not names:
                hit_codes |= _prefixes([p.name for p in base.iterdir() if p.is_file()])

    parts = sorted({str(r.get("PARTITION") or "").strip().upper() for r in rows if r.get("PARTITION")})
    clients = sorted(
        {
            (str(r.get("PARTITION") or "").strip().upper(), str(r.get("SPLIT_CODE") or "").strip().upper())
            for r in rows
            if r.get("PARTITION") and r.get("SPLIT_CODE")
        }
    )
    sids = sorted({str(r.get("SOFTWAREID") or "").strip() for r in rows if str(r.get("SOFTWAREID") or "").strip()})
    facs = sorted({str(r.get("FACILITY") or "").strip().upper() for r in rows if str(r.get("FACILITY") or "").strip()})

    hit_part: set[str] = set()
    hit_cli: set[tuple[str, str]] = set()
    hit_sid: set[str] = set()
    hit_fac = {c for c in hit_codes if c in set(facs)}
    hit_split_keys: set[str] = set()
    client_rows: list[dict] = []
    grouped: dict[tuple[str, str, str], dict] = {}
    for r in rows:
        part = str(r.get("PARTITION") or "").strip().upper()
        cli = str(r.get("SPLIT_CODE") or "").strip().upper()
        sid = str(r.get("SOFTWAREID") or "").strip()
        fac = str(r.get("FACILITY") or "").strip().upper()
        name = str(r.get("CLIENT_SPLIT") or "").strip()
        key = (part, cli, sid)
        rec = grouped.get(key)
        if not rec:
            rec = {
                "name": name,
                "partition": part,
                "client": cli,
                "software_id": sid,
                "facilities": [],
                "facilities_hit": [],
                "splits_total": 0,
                "splits_hit": 0,
            }
            grouped[key] = rec
        rec["splits_total"] += 1
        if fac and fac not in rec["facilities"]:
            rec["facilities"].append(fac)
        codes = {fac, cli, str(r.get("FACILITY_CODE") or "").strip().upper()} - {""}
        if codes & hit_codes:
            rec["splits_hit"] += 1
            hit_split_keys.add(f"{sid}|{part}|{cli}|{fac}")
            hit_part.add(part)
            hit_cli.add((part, cli))
            if sid:
                hit_sid.add(sid)
            if fac and fac not in rec["facilities_hit"]:
                rec["facilities_hit"].append(fac)
        if name and not rec["name"]:
            rec["name"] = name
    client_rows = sorted(grouped.values(), key=lambda x: (x["partition"], x["client"], x["software_id"]))
    covered = [c for c in client_rows if c["splits_hit"]]
    missed_cli = [f"{p}/{c}" for p, c in clients if (p, c) not in hit_cli]
    missed_fac = [f for f in facs if f not in hit_fac]
    missed_part = [p for p in parts if p not in hit_part]
    missed_sid = [s for s in sids if s not in hit_sid]
    coding = _coding_coverage(root, results or [], hit_codes)
    cats = [
        _cat("Partitions", len(hit_part), len(parts), missed_part),
        _cat("Clients", len(hit_cli), len(clients), missed_cli),
        _cat("Software ids", len(hit_sid), len(sids), missed_sid),
        _cat("Facilities", len(hit_fac), len(facs), missed_fac),
        _cat("Splits", len(hit_split_keys), len(rows), None),
        _cat("Custom coding rules", coding["hit"], coding["total"], coding.get("missed")),
    ]
    cats[-1]["missed_more"] = coding.get("missed_more") or 0
    return {
        "cases_ok": ran_ok,
        "cases_ran": len(results or []),
        "output_codes": sorted(hit_codes),
        "clients": covered,
        "categories": cats,
        "coding": coding,
    }


FEED_RULES = {
    "set-partition-client",
    "xml-to-ged",
    "inbound-filename",
    "flat-file-to-xml",
    "incoming-route-gate",
    "adt-map",
    "dft-map",
    "apply-stripping-specific-clients",
    "append-patient-type-cdm",
    "tweak-ins-plans",
    "account-number-format",
    "empty-after-strip",
}
QUOTED_TOK = re.compile(r"['\"]([A-Za-z0-9._-]{2,24})['\"]")
LOC_TOK = re.compile(r"\b[A-Z]\.[A-Z0-9]{1,10}\b")
HL7_HINT = {
    "blank-gt1-relationship": ("gt1|", "gt1"),
    "blank-in1-relationship": ("in1|", "in1"),
    "mue-split": ("ft1|", "mue"),
    "self-pay-or-uninsured": ("self", "uninsur", "selfpay"),
    "marital-status": ("marital", "pid|"),
    "patient-type": ("patient type", "admpatienttype"),
    "accession-report": ("accession",),
}


def _read_blob(folder: Path, limit: int = 180_000) -> str:
    if not folder.is_dir():
        return ""
    chunks: list[str] = []
    budget = limit
    for p in sorted(folder.iterdir()):
        if not p.is_file() or p.name.startswith(".") or budget <= 0:
            continue
        data = p.read_bytes()[:budget]
        chunks.append(data.decode("utf-8", errors="replace"))
        budget -= len(data)
    return "\n".join(chunks).lower()


def _case_blob(root: Path, cid: str) -> str:
    case = root / "regression" / "cases" / cid
    return "\n".join(_read_blob(case / sub) for sub in ("in", "last", "baseline"))


def _coding_coverage(root: Path, results: list[dict], hit_codes: set[str]) -> dict:
    import client_custom_coding as coding
    import clients as clients_mod

    try:
        data = coding.snapshot(clients_mod.slug_for(root.name))
    except Exception:
        data = {}
    groups = data.get("groups") or []
    ok_ids = {str(r.get("id") or "") for r in results if r.get("ok") and (r.get("files") or r.get("baseline"))}
    metas: list[dict] = []
    for r in results:
        cid = str(r.get("id") or "")
        extra = {}
        meta_path = root / "regression" / "cases" / cid / "case.json"
        if meta_path.is_file():
            try:
                extra = json.loads(meta_path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                extra = {}
        metas.append(
            {
                **r,
                "partition": str(extra.get("partition") or "").strip().upper(),
                "client": str(extra.get("client") or "").strip().upper(),
                "software_id": str(extra.get("software_id") or "").strip(),
                "facilities": extra.get("facilities") or [],
            }
        )
    blobs: dict[str, str] = {}
    types: dict[str, dict] = {}
    by_client: list[dict] = []
    missed: list[str] = []
    hit = total = 0
    for g in groups:
        part = str(g.get("partition") or "").strip().upper()
        cli = str(g.get("client") or "").strip().upper()
        sid = str(g.get("software_id") or "").strip()
        ident = {part, cli, sid} - {""}
        cases = [
            r
            for r in metas
            if (cli and r.get("client") == cli and (not part or r.get("partition") == part))
            or (sid and r.get("software_id") == sid)
            or (cli and cli in {str(x).upper() for x in (r.get("facilities") or [])})
        ]
        feed_ran = bool(cases and any(str(r.get("id") or "") in ok_ids or r.get("ok") for r in cases)) or bool(
            ident & hit_codes
        )
        blob = ""
        for r in cases[:8]:
            cid = str(r.get("id") or "")
            if cid not in blobs:
                blobs[cid] = _case_blob(root, cid)
            blob += blobs.get(cid) or ""
        if feed_ran and not blob:
            blob = " ".join(sorted(hit_codes)).lower()
        chit = ctot = 0
        for rule in g.get("rules") or []:
            total += 1
            ctot += 1
            rid = str(rule.get("rule_id") or "other")
            title = str(rule.get("title") or rid)
            text = str(rule.get("text") or "")
            extra = [t for t in QUOTED_TOK.findall(text) if t.upper() not in ident and t.upper() not in coding.SKIP_TOKEN]
            extra += [t for t in LOC_TOK.findall(text.upper()) if t not in ident]
            covered = feed_ran
            if rid not in FEED_RULES and extra:
                covered = feed_ran and any(t.lower() in blob for t in extra)
            elif rid in HL7_HINT:
                covered = feed_ran and any(h in blob for h in HL7_HINT[rid])
            bag = types.setdefault(title, {"title": title, "hit": 0, "total": 0})
            bag["total"] += 1
            if covered:
                hit += 1
                chit += 1
                bag["hit"] += 1
            else:
                missed.append(f"{part}/{cli} · {title}")
        by_client.append(
            {
                "name": g.get("title") or cli,
                "partition": part,
                "client": cli,
                "software_id": sid,
                "hit": chit,
                "total": ctot,
                "pct": _pct(chit, ctot),
            }
        )
    type_rows = sorted(types.values(), key=lambda x: (-x["total"], x["title"]))
    for row in type_rows:
        row["pct"] = _pct(row["hit"], row["total"])
    return {
        "hit": hit,
        "total": total,
        "pct": _pct(hit, total),
        "missed": missed[:40],
        "missed_more": max(0, len(missed) - 40),
        "by_type": type_rows,
        "by_client": [c for c in by_client if c["total"]],
    }
