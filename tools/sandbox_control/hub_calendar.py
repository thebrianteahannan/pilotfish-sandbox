"""Screenshot calendar + Ebility timesheet."""

from __future__ import annotations

from datetime import date, timedelta

from flask import jsonify, request, send_file

NON_BILL = "Non-Billable: Meetings, Email, AI"


def last_week_mon_fri(today: date | None = None) -> tuple[date, date]:
    today = today or date.today()
    this_mon = today - timedelta(days=today.weekday())
    last_mon = this_mon - timedelta(days=7)
    return last_mon, last_mon + timedelta(days=4)


def default_range() -> tuple[date, date]:
    import hub_cal_store

    days = []
    for row in hub_cal_store.load():
        try:
            days.append(date.fromisoformat(str(row.get("day") or "")[:10]))
        except ValueError:
            continue
    if days:
        last = max(days)
        mon = last - timedelta(days=last.weekday())
        return mon, mon + timedelta(days=4)
    return last_week_mon_fri()


def payroll_sat_fri(week_mon: date) -> tuple[date, date]:
    sat = week_mon - timedelta(days=2)
    return sat, sat + timedelta(days=13)


def fetch_events(start: date, end: date) -> list[dict]:
    import hub_cal_store

    return hub_cal_store.in_range(start, end)


def register(app) -> None:
    @app.get("/api/calendar")
    def api_calendar():
        start_s = (request.args.get("start") or "").strip()
        end_s = (request.args.get("end") or "").strip()
        if start_s and end_s:
            start = date.fromisoformat(start_s[:10])
            end = date.fromisoformat(end_s[:10])
        else:
            start, end = default_range()
        events = []
        err = ""
        try:
            import hub_timesheet

            events = hub_timesheet.annotate_events(fetch_events(start, end))
        except Exception as exc:
            err = str(exc)[:400]
        local_n = sum(1 for e in events if (e.get("source") or "") == "screenshot")
        return jsonify(
            {
                "ok": not err,
                "error": err,
                "linked": False,
                "user": "",
                "start": start.isoformat(),
                "end": end.isoformat(),
                "events": events,
                "local": local_n,
            }
        )

    @app.post("/api/calendar/screenshot")
    def api_calendar_screenshot():
        upload = request.files.get("file")
        if not upload:
            return jsonify({"ok": False, "error": "Paste or drop a calendar screenshot."}), 400
        data = upload.read()
        if not data:
            return jsonify({"ok": False, "error": "Empty image."}), 400
        import hub_cal_ocr

        try:
            parsed = hub_cal_ocr.ingest(data, upload.filename)
        except Exception as exc:
            return jsonify({"ok": False, "error": f"Could not read that screenshot: {exc}"[:400], "ocr": ""}), 500
        start, end = default_range()
        if parsed.get("days"):
            first = min(date.fromisoformat(d) for d in parsed["days"])
            start = first - timedelta(days=first.weekday())
            end = start + timedelta(days=4)
        events = fetch_events(start, end)
        import hub_timesheet

        events = hub_timesheet.annotate_events(events)
        parsed["start"] = start.isoformat()
        parsed["end"] = end.isoformat()
        parsed["events"] = events
        parsed["linked"] = False
        status = 200 if parsed.get("ok") else 422
        return jsonify(parsed), status

    @app.post("/api/calendar/clear")
    def api_calendar_clear():
        import hub_cal_store

        hub_cal_store.clear()
        start, end = last_week_mon_fri()
        return jsonify({"ok": True, "events": fetch_events(start, end), "start": start.isoformat(), "end": end.isoformat()})

    @app.post("/api/calendar/timesheet")
    def api_timesheet():
        body = request.get_json(silent=True) or {}
        start_s = str(body.get("start") or "").strip()
        end_s = str(body.get("end") or "").strip()
        if start_s and end_s:
            start = date.fromisoformat(start_s[:10])
            start = start - timedelta(days=start.weekday())
            end = start + timedelta(days=4)
        else:
            start, end = default_range()
        try:
            import hub_timesheet
            import hub_timesheet_pdf

            sheet = hub_timesheet.build(start, end)
            path = hub_timesheet_pdf.write(sheet)
        except Exception as exc:
            return jsonify({"ok": False, "error": str(exc)[:500]}), 400
        return jsonify(
            {
                "ok": True,
                "file": path.name,
                "url": f"/api/calendar/timesheet/file?name={path.name}",
                "sheet": {
                    "start": sheet["start"],
                    "end": sheet["end"],
                    "payroll_start": sheet["payroll_start"],
                    "payroll_end": sheet["payroll_end"],
                    "total": sheet["total"],
                    "rows": sheet["rows"],
                    "copy_block": sheet["copy_block"],
                    "worker": sheet.get("worker") or "",
                },
            }
        )

    @app.post("/api/calendar/timesheet/save")
    def api_timesheet_save():
        body = request.get_json(silent=True) or {}
        try:
            import hub_timesheet
            import hub_timesheet_pdf

            sheet = hub_timesheet.apply_manual(body.get("sheet") or body, body.get("rows") or (body.get("sheet") or {}).get("rows") or [])
            path = hub_timesheet_pdf.write(sheet)
        except Exception as exc:
            return jsonify({"ok": False, "error": str(exc)[:500]}), 400
        return jsonify(
            {
                "ok": True,
                "file": path.name,
                "url": f"/api/calendar/timesheet/file?name={path.name}",
                "sheet": {
                    "start": sheet["start"],
                    "end": sheet["end"],
                    "payroll_start": sheet["payroll_start"],
                    "payroll_end": sheet["payroll_end"],
                    "total": sheet["total"],
                    "rows": sheet["rows"],
                    "copy_block": sheet["copy_block"],
                    "worker": sheet.get("worker") or "",
                },
            }
        )

    @app.get("/api/calendar/timesheet/file")
    def api_timesheet_file():
        name = (request.args.get("name") or "").strip()
        import hub_timesheet_pdf

        path = hub_timesheet_pdf.OUT_DIR / name
        if not name or not path.is_file() or path.suffix.lower() != ".pdf":
            return jsonify({"ok": False, "error": "PDF not found"}), 404
        resp = send_file(path, mimetype="application/pdf", as_attachment=False, download_name=name)
        resp.headers["Cache-Control"] = "no-store"
        return resp
