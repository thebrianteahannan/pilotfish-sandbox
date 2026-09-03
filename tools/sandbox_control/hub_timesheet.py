"""Estimate a 40-hour week from screenshot meetings, client requests, and files."""

from __future__ import annotations

import re
from collections import defaultdict
from datetime import date, timedelta

import client_requests
import clients
import hub_calendar

NON_BILL = "Non-Billable: Meetings, Email, AI"
TARGET = 40.0
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri"]

TITLE_FIX = [
    (re.compile(r"^medreceivables\s*&\s*pil.*", re.I), "MedReceivables & PilotFish"),
    (re.compile(r"^weekly crl plus mee.*", re.I), "Weekly CRL Plus meeting"),
    (re.compile(r"^unites?\s*1\.0.*", re.I), "United 1.0 PilotFish"),
    (re.compile(r"^reminder:\s*submit.*", re.I), "Reminder: Submit timesheet"),
    (re.compile(r"^submit your timest.*", re.I), "Submit Your Timesheet"),
]
SKIP_HOURS = re.compile(
    r"\breminder\b|timesheet|submit your timest",
    re.I,
)
INTERNAL = re.compile(
    r"resource allocation|internal meeting|catch up|united 1\.0|unites 1\.0",
    re.I,
)
ALIASES = [
    (["medreceivable", "med receivable", "medrec", "med rec", "halifax"], "Med Rec"),
    (["crlplus", "crl plus", "crl"], "CRL Plus"),
]


def _clients() -> list[dict]:
    return [{"name": c["name"], "slug": c["slug"], "title": c.get("title") or c["name"]} for c in clients.list_clients()]


def _compact(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", (text or "").lower())


def repair_title(title: str) -> str:
    t = re.sub(r"\s+", " ", title or "").strip()
    for pat, fixed in TITLE_FIX:
        if pat.match(t):
            return fixed
    return t


def _match_customer(text: str, rows: list[dict] | None = None) -> str:
    blob = (text or "").lower()
    compact = _compact(text)
    for needles, name in ALIASES:
        for n in needles:
            if _compact(n) and _compact(n) in compact:
                return name
            if " " in n and n in blob:
                return name
    for row in rows or _clients():
        for key in (row["name"], row.get("title") or "", row["slug"].replace("-", " ")):
            k = key.lower().strip()
            if len(k) >= 4 and (k in blob or _compact(k) in compact):
                return row["name"]
    return ""


def classify_meeting(subject: str) -> tuple[str, str]:
    title = repair_title(subject)
    if SKIP_HOURS.search(title):
        return "skip", ""
    if INTERNAL.search(title):
        return "internal", NON_BILL
    cust = _match_customer(title)
    if cust:
        return "client", cust
    return "internal", NON_BILL


def annotate_events(events: list[dict]) -> list[dict]:
    out = []
    for ev in events:
        row = dict(ev)
        title = repair_title(str(row.get("subject") or ""))
        kind, cust = classify_meeting(title)
        row["subject"] = title
        row["kind"] = kind
        row["customer"] = cust or ("Ignored" if kind == "skip" else NON_BILL)
        hrs = float(row.get("hours") or 0)
        if kind == "skip":
            row["hours"] = 0.0
        elif kind == "client" and hrs <= 0.5:
            row["hours"] = 1.0
        out.append(row)
    return out


def _iso_day(val: str) -> str:
    s = str(val or "")[:10]
    return s if len(s) == 10 else ""


def _req_day(row: dict) -> str:
    for key in ("updated_at", "received_at", "created_at"):
        s = _iso_day(row.get(key) or "")
        if s:
            return s
    rid = str(row.get("id") or "")
    if len(rid) >= 8 and rid[:8].isdigit():
        return f"{rid[:4]}-{rid[4:6]}-{rid[6:8]}"
    return ""


def _requests(start: date, end: date) -> list[dict]:
    out = []
    for row in _clients():
        for req in client_requests.list_requests(row["slug"]):
            done = _req_day(req)
            recv = _iso_day(req.get("received_at") or "") or done
            if not done:
                continue
            try:
                d = date.fromisoformat(done)
            except ValueError:
                continue
            if d < start or d > end:
                if recv:
                    try:
                        d = date.fromisoformat(recv)
                    except ValueError:
                        continue
                    if d < start or d > end:
                        continue
                    done = recv
                else:
                    continue
            hrs = float(req.get("billable_hours") or 0) or 1.0
            out.append(
                {
                    "customer": row["name"],
                    "day": done,
                    "received": recv,
                    "hours": hrs,
                    "subject": req.get("subject") or req.get("id") or "request",
                    "id": req.get("id") or "",
                }
            )
    return out


def _weights(start: date, end: date) -> tuple[dict, dict, dict]:
    events = annotate_events(hub_calendar.fetch_events(start, end))
    reqs = _requests(start, end)
    w: dict[str, list[float]] = defaultdict(lambda: [0.0] * 5)
    evidence: dict[str, list[str]] = defaultdict(list)

    def add(cust: str, day_s: str, amt: float, note: str) -> None:
        if not cust or amt <= 0:
            return
        try:
            d = date.fromisoformat(day_s[:10])
        except ValueError:
            return
        if d < start or d > end or d.weekday() > 4:
            return
        w[cust][d.weekday()] += amt
        evidence[cust].append(f"{day_s[:10]} · {note}")

    for ev in events:
        if ev.get("kind") == "skip":
            continue
        cust = ev.get("customer") or NON_BILL
        hrs = float(ev.get("hours") or 0) or 0.5
        add(cust, ev.get("day") or "", hrs, f"Meeting: {ev.get('subject')} ({hrs:.2f}h)")
    for r in reqs:
        add(
            r["customer"],
            r["day"],
            r["hours"],
            f"Request: {r['subject']} ({r['hours']:.2f}h)",
        )
        recv = r.get("received") or ""
        if recv and recv != r["day"]:
            add(r["customer"], recv, r["hours"] * 0.35, f"Started: {r['subject']}")

    meta = {
        "meetings": events,
        "requests": reqs,
    }
    return w, evidence, meta


def _largest_remainder(weights: dict[str, float], target: int) -> dict[str, int]:
    if target <= 0 or not weights:
        return {}
    total = sum(weights.values()) or 1.0
    exact = {k: target * (v / total) for k, v in weights.items()}
    floors = {k: int(exact[k]) for k in exact}
    leftover = target - sum(floors.values())
    order = sorted(exact, key=lambda k: exact[k] - floors[k], reverse=True)
    i = 0
    while leftover > 0 and order:
        floors[order[i % len(order)]] += 1
        leftover -= 1
        i += 1
    return {k: n for k, n in floors.items() if n > 0}


def _smear(raw: list[float]) -> list[float]:
    w = [0.4] * 5
    for i, v in enumerate(raw):
        if v <= 0:
            continue
        w[i] += v
        if i > 0:
            w[i - 1] += v * 0.7
        if i > 1:
            w[i - 2] += v * 0.4
        if i < 4:
            w[i + 1] += v * 0.25
    return w


def _place(n: int, weights: list[float], cap: list[int]) -> list[int]:
    placed = [0] * 5
    remain = max(0, int(n))
    seed = 3 if remain >= 15 else (2 if remain >= 10 else 0)
    if seed:
        for i in range(5):
            take = min(seed, remain, cap[i])
            placed[i] += take
            cap[i] -= take
            remain -= take
    w = list(weights)
    for _ in range(remain):
        best = -1
        best_score = -1.0
        for i in range(5):
            if cap[i] <= 0:
                continue
            score = w[i] / (1.0 + placed[i] * 0.2)
            if score > best_score:
                best_score = score
                best = i
        if best < 0:
            break
        placed[best] += 1
        cap[best] -= 1
    return placed


WEEK_CAP = {
    "Med Rec": 20,
}


def _cap_week(name: str, n: int) -> int:
    top = WEEK_CAP.get(name)
    if top is None:
        return int(n)
    if n <= 0:
        return 0
    return min(int(n), top)


def _hours_week(w: dict[str, list[float]]) -> dict[str, list[int]]:
    bill = {k: sum(v) for k, v in w.items() if k != NON_BILL and sum(v) > 0}
    nb = sum(w.get(NON_BILL) or [0] * 5)
    raw = sum(bill.values()) + nb
    if raw <= 0:
        return {NON_BILL: [8] * 5}
    bill_target = min(32, int(round(TARGET * sum(bill.values()) / raw)))
    totals = _largest_remainder(bill, bill_target)
    totals = {k: _cap_week(k, n) for k, n in totals.items()}
    cap = [8] * 5
    out: dict[str, list[int]] = {}
    for name, n in sorted(totals.items(), key=lambda kv: -kv[1]):
        if n <= 0:
            continue
        out[name] = _place(n, _smear(list(w.get(name) or [0.0] * 5)), cap)
    billed = [0] * 5
    for row in out.values():
        for i in range(5):
            billed[i] += row[i]
    out[NON_BILL] = [max(0, 8 - billed[i]) for i in range(5)]
    return out


def _service(name: str) -> str:
    if name == NON_BILL:
        return "Meetings, Email, AI"
    if name == "Med Rec":
        return "Interface / HL7 / EDI"
    if "CRL" in name:
        return "ACORD / AIL interface"
    return "Integration services"


def _work_bits(name: str, meta: dict) -> list[str]:
    bits: list[str] = []
    seen: set[str] = set()

    def add(text: str) -> None:
        t = re.sub(r"\s+", " ", text or "").strip(" .;")
        t = re.sub(r"^re:\s*", "", t, flags=re.I)
        key = t.lower()
        if len(t) < 8 or key in seen:
            return
        seen.add(key)
        bits.append(t)

    for r in meta.get("requests") or []:
        if r.get("customer") != name:
            continue
        add(str(r.get("subject") or ""))
    if bits:
        return bits
    for ev in meta.get("meetings") or []:
        if ev.get("kind") == "skip":
            continue
        cust = ev.get("customer") or NON_BILL
        if cust != name:
            continue
        add(str(ev.get("subject") or ""))
    return bits


def _description(name: str, meta: dict) -> str:
    bits = _work_bits(name, meta)
    if name == NON_BILL:
        if bits:
            return "Internal: " + "; ".join(bits) + "."
        return "Internal meetings, email, and AI-assisted interface work."
    if bits:
        return "; ".join(bits) + "."
    return _service(name) + "."


def apply_manual(sheet: dict, rows: list[dict]) -> dict:
    start = date.fromisoformat(str(sheet.get("start") or "")[:10])
    start = start - timedelta(days=start.weekday())
    end = start + timedelta(days=4)
    sat, pay_end = hub_calendar.payroll_sat_fri(start)
    days = [start + timedelta(days=i) for i in range(5)]
    out_rows = []
    copy_bits = []
    for rec in rows or []:
        name = str(rec.get("customer") or "").strip()
        if not name:
            continue
        daily_in = rec.get("daily") or {}
        vals = [max(0, int(daily_in.get(d) or 0)) for d in DAYS]
        total = int(sum(vals))
        bill = bool(rec.get("bill")) if "bill" in rec else name != NON_BILL
        service = str(rec.get("service") or "") or _service(name)
        daily = {DAYS[i]: vals[i] for i in range(5)}
        desc = str(rec.get("description") or "").strip() or _service(name) + "."
        out_rows.append(
            {
                "customer": name,
                "service": service,
                "bill": bill,
                "daily": daily,
                "dates": {DAYS[i]: days[i].isoformat() for i in range(5)},
                "wk1_total": total,
                "wk2_total": 0,
                "grand": total,
                "description": desc,
            }
        )
        copy_bits.append(desc)
    return {
        "worker": sheet.get("worker") or "Hannan, Brian - Employee",
        "start": start.isoformat(),
        "end": end.isoformat(),
        "payroll_start": sat.isoformat(),
        "payroll_end": pay_end.isoformat(),
        "total": int(sum(r["grand"] for r in out_rows)),
        "rows": out_rows,
        "copy_block": "\n\n".join(copy_bits),
        "evidence": sheet.get("evidence") or {},
        "meta": sheet.get("meta") or {},
    }


def build(start: date, end: date) -> dict:
    w, evidence, meta = _weights(start, end)
    hours = _hours_week(w)
    sat, pay_end = hub_calendar.payroll_sat_fri(start)
    days = [start + timedelta(days=i) for i in range(5)]
    rows = []
    copy_bits = []
    for name, vals in sorted(hours.items(), key=lambda kv: (kv[0] == NON_BILL, kv[0])):
        total = int(sum(vals))
        if total <= 0:
            continue
        bill = name != NON_BILL
        daily = {DAYS[i]: int(vals[i]) for i in range(5)}
        desc = _description(name, meta)
        rows.append(
            {
                "customer": name,
                "service": _service(name),
                "bill": bill,
                "daily": daily,
                "dates": {DAYS[i]: days[i].isoformat() for i in range(5)},
                "wk1_total": total,
                "wk2_total": 0,
                "grand": total,
                "description": desc,
            }
        )
        copy_bits.append(desc)
    copy_block = "\n\n".join(copy_bits)
    return {
        "worker": "Hannan, Brian - Employee",
        "start": start.isoformat(),
        "end": end.isoformat(),
        "payroll_start": sat.isoformat(),
        "payroll_end": pay_end.isoformat(),
        "total": int(sum(r["grand"] for r in rows)),
        "rows": rows,
        "copy_block": copy_block,
        "evidence": {k: v[:40] for k, v in evidence.items()},
        "meta": {
            "meetings": len(meta["meetings"]),
            "requests": len(meta["requests"]),
        },
        "meetings": meta["meetings"],
        "requests": meta["requests"],
    }
