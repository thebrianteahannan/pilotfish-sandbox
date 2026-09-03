"""OCR an Outlook calendar screenshot into meeting rows."""

from __future__ import annotations

import re
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import client_ocr
import hub_cal_store

TZ = ZoneInfo("America/New_York")
SHOTS = hub_cal_store.DIR / "shots"
SKIP = re.compile(
    r"^(outlook|calendar|today|search|filter|week|work week|month|day|agenda|"
    r"new event|my calendars|weather|accepted|tentative|canceled|cancelled|"
    r"show as|busy|free|out of office|v)$",
    re.I,
)
MONTHS = {
    "january": 1, "jan": 1, "february": 2, "feb": 2, "march": 3, "mar": 3,
    "april": 4, "apr": 4, "may": 5, "june": 6, "jun": 6, "july": 7, "jul": 7,
    "august": 8, "aug": 8, "september": 9, "sep": 9, "sept": 9,
    "october": 10, "oct": 10, "november": 11, "nov": 11, "december": 12, "dec": 12,
}
WEEKDAYS = {
    "monday": 0, "mon": 0, "tuesday": 1, "tue": 1, "tues": 1, "wednesday": 2,
    "wed": 2, "thursday": 3, "thu": 3, "thur": 3, "thurs": 3, "friday": 4, "fri": 4,
    "saturday": 5, "sat": 5, "sunday": 6, "sun": 6,
}
DAY_LINE = re.compile(
    r"^(?:(?P<wd>mon(?:day)?|tue(?:s(?:day)?)?|wed(?:nesday)?|thu(?:rs(?:day)?)?|"
    r"fri(?:day)?|sat(?:urday)?|sun(?:day)?)\s*[.,]?\s*)?"
    r"(?:(?P<mon>jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|jul(?:y)?|"
    r"aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\s+)?"
    r"(?P<day>\d{1,2})(?:st|nd|rd|th)?"
    r"(?:,?\s+(?P<year>20\d{2}))?$",
    re.I,
)
TIME = re.compile(
    r"^(?P<h1>\d{1,2})(?::(?P<m1>\d{2}))?\s*(?P<p1>[ap]m)?"
    r"(?:\s*(?:[-–]|to)\s*(?P<h2>\d{1,2})(?::(?P<m2>\d{2}))?\s*(?P<pp2>[ap]m)?)?"
    r"\s*(?P<rest>.*)$",
    re.I,
)
AT_TIME = re.compile(r"@\s*(\d{1,2})(?::(\d{2}))?\s*([ap]m)", re.I)
WEEK_HDR = re.compile(
    r"(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|jul(?:y)?|"
    r"aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)"
    r"\s+(\d{1,2})\s*[-–]\s*(\d{1,2}),?\s*(20\d{2})",
    re.I,
)
HUB_UI = re.compile(
    r"drop or paste a screenshot|reading calendar|calendar from screenshot|"
    r"choose photo|generate timesheet",
    re.I,
)
YEAR = re.compile(r"\b(20\d{2})\b")
MONTH_WORD = re.compile(
    r"\b(january|february|march|april|may|june|july|august|september|october|"
    r"november|december|jan|feb|mar|apr|jun|jul|aug|sep|sept|oct|nov|dec)\b",
    re.I,
)
WD_ONLY = re.compile(
    r"^(mon(?:day)?|tue(?:s(?:day)?)?|wed(?:nesday)?|thu(?:rs(?:day)?)?|fri(?:day)?|"
    r"sat(?:urday)?|sun(?:day)?)$",
    re.I,
)


def _ampm(hour: int, minute: int, mer: str | None, hint: str | None) -> tuple[int, int]:
    mer = (mer or hint or "").lower()
    h = hour
    if mer == "pm" and h < 12:
        h += 12
    if mer == "am" and h == 12:
        h = 0
    if not mer and 1 <= h <= 6:
        h += 12
    return h, minute


def _iso(d: date, hour: int, minute: int) -> str:
    return datetime(d.year, d.month, d.day, hour, minute, tzinfo=TZ).strftime("%Y-%m-%dT%H:%M:%S")


def _event(day: date, title: str, start_hm: tuple[int, int], end_hm: tuple[int, int] | None) -> dict:
    title = re.sub(r"\s+", " ", title).strip(" ·|-›v~")
    if not title or SKIP.match(title) or title.isdigit():
        return {}
    st = start_hm
    en = end_hm
    if not en:
        eh, em = st[0], st[1] + 30
        if em >= 60:
            eh, em = eh + 1, em - 60
        en = (eh, em)
    sdt = _iso(day, st[0], st[1])
    edt = _iso(day, en[0], en[1])
    if edt <= sdt:
        edt = _iso(day, min(st[0] + 1, 23), st[1])
    hours = max(0.25, (datetime.fromisoformat(edt) - datetime.fromisoformat(sdt)).total_seconds() / 3600.0)
    return {
        "subject": title[:180],
        "start": sdt,
        "end": edt,
        "day": day.isoformat(),
        "hours": round(hours, 2),
        "organizer": "",
        "location": "",
        "preview": "From calendar screenshot",
        "source": "screenshot",
    }


def _week_from_header(text: str, today: date) -> dict[int, date]:
    m = WEEK_HDR.search(text or "")
    if not m:
        return {}
    month, d1, d2, year = MONTHS[m.group(1).lower()], int(m.group(2)), int(m.group(3)), int(m.group(4))
    out = {}
    cur = date(year, month, d1)
    end = date(year, month, d2) if d2 >= d1 else date(year, month + 1 if month < 12 else 1, d2)
    while cur <= end:
        out[cur.weekday()] = cur
        cur += timedelta(days=1)
    return out


def _time_from_title(text: str) -> tuple[int, int] | None:
    m = AT_TIME.search(text)
    if m:
        return _ampm(int(m.group(1)), int(m.group(2) or 0), m.group(3), "am")
    m = re.search(r"\b(\d{1,2})(?::(\d{2}))?\s*([ap]m)\b", text, re.I)
    if m:
        return _ampm(int(m.group(1)), int(m.group(2) or 0), m.group(3), "am")
    return None


def _hour_from_y(y: float) -> tuple[int, int]:
    hour = 8 + (0.85 - y) / 0.80 * 10
    hour = max(8.0, min(18.5, hour))
    h = int(hour)
    m = 0 if (hour - h) < 0.25 else (30 if (hour - h) < 0.75 else 0)
    if m == 0 and (hour - h) >= 0.75:
        h += 1
    return h, m


def parse_boxes(rows: list[tuple[float, float, float, float, str]], today: date | None = None) -> list[dict]:
    today = today or date.today()
    if not rows:
        return []
    blob = "\n".join(r[4] for r in rows)
    week = _week_from_header(blob, today)
    cols: list[tuple[float, date]] = []
    used = set()
    for x, y, w, h, text in rows:
        if y < 0.82:
            continue
        m = WD_ONLY.match(text.strip())
        if not m:
            continue
        wd = WEEKDAYS[m.group(1).lower()]
        day = week.get(wd)
        if not day:
            continue
        cols.append((x + w / 2, day))
        used.add(id((x, y, text)))
    if not cols:
        return []
    cols.sort(key=lambda c: c[0])
    bounds = []
    for i, (cx, day) in enumerate(cols):
        lo = 0.0 if i == 0 else (cols[i - 1][0] + cx) / 2
        hi = 1.0 if i == len(cols) - 1 else (cx + cols[i + 1][0]) / 2
        bounds.append((lo, hi, day))

    def col_day(cx: float) -> date:
        for lo, hi, day in bounds:
            if lo <= cx < hi:
                return day
        return bounds[-1][2]

    grouped: dict[str, list[tuple[float, str]]] = {}
    for x, y, w, h, text in rows:
        t = text.strip()
        if y > 0.82 or SKIP.match(t) or WD_ONLY.match(t) or re.fullmatch(r"\d{1,2}", t) or WEEK_HDR.search(t):
            continue
        day = col_day(x + 0.02)
        grouped.setdefault(day.isoformat(), []).append((y, x, t))
    events = []
    for day_s, bits in grouped.items():
        day = date.fromisoformat(day_s)
        bits.sort(key=lambda b: (-b[0], b[1]))
        clusters: list[list[tuple[float, float, str]]] = []
        for y, x, t in bits:
            if clusters and abs(clusters[-1][0][0] - y) < 0.09 and abs(clusters[-1][0][1] - x) < 0.07:
                clusters[-1].append((y, x, t))
            else:
                clusters.append([(y, x, t)])
        for cl in clusters:
            title = " ".join(t for _, _, t in cl)
            title = re.sub(r"\s*PilotFish Scheduling\s*", " ", title, flags=re.I).strip()
            start = _time_from_title(title) or _hour_from_y(sum(y for y, _, _ in cl) / len(cl))
            ev = _event(day, title, start, None)
            if ev:
                events.append(ev)
    events.sort(key=lambda e: e["start"])
    return events


def parse_calendar_text(text: str, today: date | None = None) -> list[dict]:
    today = today or date.today()
    week = _week_from_header(text, today)
    year, month = today.year, today.month
    m = YEAR.search(text or "")
    if m:
        year = int(m.group(1))
    mm = MONTH_WORD.search(text or "")
    if mm:
        month = MONTHS[mm.group(1).lower()]
    current: date | None = None
    pending_num: int | None = None
    events: list[dict] = []
    pending: dict | None = None
    last_mer = "am"

    def flush() -> None:
        nonlocal pending
        if not pending or not current:
            pending = None
            return
        start = pending["start_hm"]
        title_time = _time_from_title(pending["subject"])
        if title_time:
            start = title_time
        ev = _event(current, pending["subject"], start, pending.get("end_hm"))
        if ev:
            events.append(ev)
        pending = None

    def set_day(d: date | None) -> None:
        nonlocal current
        flush()
        if d:
            current = d

    for raw in (text or "").replace("\r\n", "\n").splitlines():
        line = re.sub(r"\s+", " ", raw).strip(" •·|-›~")
        if not line or SKIP.match(line) or WEEK_HDR.search(line):
            continue
        if re.fullmatch(r"\d{1,2}", line):
            pending_num = int(line)
            continue
        wd = WD_ONLY.match(line)
        if wd:
            idx = WEEKDAYS[wd.group(1).lower()]
            if week.get(idx):
                set_day(week[idx])
            elif pending_num:
                set_day(date(year, month, pending_num) if 1 <= pending_num <= 31 else None)
            pending_num = None
            continue
        dm = DAY_LINE.match(line)
        if dm and (dm.group("wd") or dm.group("mon")):
            if dm.group("mon"):
                month = MONTHS[dm.group("mon").lower()]
            if dm.group("year"):
                year = int(dm.group("year"))
            if dm.group("wd") and week.get(WEEKDAYS[dm.group("wd").lower()]):
                set_day(week[WEEKDAYS[dm.group("wd").lower()]])
            else:
                set_day(date(year, month, int(dm.group("day"))))
            continue
        tm = TIME.match(line)
        if tm and (tm.group("p1") or tm.group("pp2") or (":" in line[:8] and int(tm.group("h1")) <= 12)):
            rest = (tm.group("rest") or "").strip()
            p1, p2 = tm.group("p1"), tm.group("pp2")
            h1, m1 = _ampm(int(tm.group("h1")), int(tm.group("m1") or 0), p1, last_mer)
            if p1:
                last_mer = p1.lower()
            end_hm = None
            if tm.group("h2"):
                end_hm = _ampm(int(tm.group("h2")), int(tm.group("m2") or 0), p2, p1 or last_mer)
            flush()
            pending = {"start_hm": (h1, m1), "end_hm": end_hm, "subject": rest}
            continue
        if pending:
            pending["subject"] = (pending["subject"] + " " + line).strip()
        elif current:
            pending = {"start_hm": (9, 0), "end_hm": (9, 30), "subject": line}
    flush()
    return events


def _ocr(path: Path) -> str:
    vis = client_ocr.ocr_vision(path)
    tes = client_ocr.ocr_tesseract(path)
    return vis if len(vis) >= len(tes) else tes


def ingest(data: bytes, filename: str) -> dict:
    SHOTS.mkdir(parents=True, exist_ok=True)
    ext = Path(filename or "calendar.png").suffix.lower() or ".png"
    if ext not in client_ocr.ALLOWED:
        ext = ".png"
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    path = SHOTS / f"{stamp}{ext}"
    path.write_bytes(data)
    boxes = client_ocr.ocr_vision_boxes(path)
    text = "\n".join(b[4] for b in boxes) if boxes else _ocr(path)
    if HUB_UI.search(text or ""):
        return {
            "ok": False,
            "error": "That was the hub page, not Outlook. Paste a screenshot of your week in Outlook.",
            "ocr": (text or "")[:4000],
            "chars": len(text or ""),
            "count": 0,
            "days": [],
            "events": [],
            "path": str(path.relative_to(hub_cal_store.HERE)),
        }
    events = parse_boxes(boxes) if boxes else []
    if not events:
        text = text or _ocr(path)
        events = parse_calendar_text(text)
    if events:
        hub_cal_store.replace_days(events)
    days = sorted({e["day"] for e in events})
    return {
        "ok": bool(events),
        "error": "" if events else ("Could not read meetings from that screenshot." if text else "Could not read text from the screenshot."),
        "ocr": (text or "")[:4000],
        "chars": len(text or ""),
        "count": len(events),
        "days": days,
        "events": events,
        "path": str(path.relative_to(hub_cal_store.HERE)),
    }
