"""Mock X12 eligibility payer — accepts a 270, returns AAA or success 271."""
from __future__ import annotations

import re
import time

from flask import Flask, Response, jsonify, request

app = Flask(__name__)
HISTORY: list[dict] = []


def _seg(edi: str, name: str) -> list[str]:
    parts = re.split(r"[~\r\n]+", edi)
    return [p for p in parts if p.startswith(f"{name}*") or p.startswith(f"{name}|")]


def _elem(segment: str, idx: int) -> str:
    delim = "*" if "*" in segment else "|"
    bits = segment.split(delim)
    return bits[idx] if len(bits) > idx else ""


def parse_270(edi: str) -> dict:
    member_id = last = first = dob = gender = trace = ""
    for nm1 in _seg(edi, "NM1"):
        if _elem(nm1, 1) == "IL":
            last = _elem(nm1, 3)
            first = _elem(nm1, 4)
            member_id = _elem(nm1, 9)
    for dmg in _seg(edi, "DMG"):
        dob = _elem(dmg, 2)
        gender = _elem(dmg, 3)
    for trn in _seg(edi, "TRN"):
        if _elem(trn, 1) == "1":
            trace = _elem(trn, 2)
    if not trace:
        for bht in _seg(edi, "BHT"):
            trace = _elem(bht, 3)
    return {
        "memberId": member_id.strip(),
        "lastName": last.strip(),
        "firstName": first.strip(),
        "birthDate": dob.strip(),
        "gender": gender.strip(),
        "trace": trace.strip() or f"T{int(time.time())}",
    }


def wrap_271(body_segments: list[str], control: str = "0001") -> str:
    today = time.strftime("%Y%m%d")
    yymmdd = time.strftime("%y%m%d")
    hhmm = time.strftime("%H%M")
    isa13 = f"{int(control):09d}"
    se_count = len(body_segments) + 2
    return "".join(
        [
            f"ISA*00*          *00*          *ZZ*MOCKPAYER      *ZZ*CLINICDEMO     *{yymmdd}*{hhmm}*^*00501*{isa13}*0*T*:~",
            f"GS*HB*MOCKPAYER*CLINICDEMO*{today}*{hhmm}*1*X*005010X279A1~",
            f"ST*271*{control}*005010X279A1~",
            *body_segments,
            f"SE*{se_count}*{control}~",
            "GE*1*1~",
            f"IEA*1*{isa13}~",
        ]
    )


def build_aaa_271(info: dict, code: str = "72") -> str:
    body = [
        f"BHT*0022*11*{info['trace']}*{time.strftime('%Y%m%d')}*1200~",
        "HL*1**20*1~",
        "NM1*PR*2*MOCK PAYER*****PI*MOCKPAYER~",
        "HL*2*1*21*1~",
        "NM1*1P*2*PILOTFISH DEMO CLINIC*****XX*1234567893~",
        "HL*3*2*22*0~",
        f"TRN*2*{info['trace']}*11234567893~",
        f"NM1*IL*1*{info['lastName'] or 'UNKNOWN'}*{info['firstName'] or 'MEMBER'}****MI*{info['memberId'] or 'MISSING'}~",
        f"AAA*N**{code}*C~",
    ]
    return wrap_271(body)


def build_success_271(info: dict) -> str:
    body = [
        f"BHT*0022*11*{info['trace']}*{time.strftime('%Y%m%d')}*1200~",
        "HL*1**20*1~",
        "NM1*PR*2*MOCK PAYER*****PI*MOCKPAYER~",
        "HL*2*1*21*1~",
        "NM1*1P*2*PILOTFISH DEMO CLINIC*****XX*1234567893~",
        "HL*3*2*22*0~",
        f"TRN*2*{info['trace']}*11234567893~",
        f"NM1*IL*1*{info['lastName']}*{info['firstName']}****MI*{info['memberId']}~",
        f"DMG*D8*{info['birthDate'] or '19800515'}*{info['gender'] or 'M'}~",
        "EB*1*IND*30**HEALTH BENEFIT PLAN COVERAGE~",
        "EB*C*IND*30***23*500~",
        "EB*A*IND*98***27*25~",
        "LS*2120~",
        "NM1*P3*1*PRIMARY*CARE****XX*1999999998~",
        "LE*2120~",
    ]
    return wrap_271(body)


@app.get("/health")
def health():
    return jsonify({"ok": True, "service": "mock-payer-270-271"})


@app.get("/history")
def history():
    return jsonify({"ok": True, "items": HISTORY[-30:]})


@app.post("/x12/270")
def eligibility_270():
    edi = request.get_data(as_text=True) or ""
    info = parse_270(edi)
    mid = (info["memberId"] or "").upper()
    if mid in {"FAIL001", "BADID", ""}:
        code, out, outcome = "72", build_aaa_271(info, "72"), "aaa"
    elif mid in {"UNKNOWN", "NOTFOUND"}:
        code, out, outcome = "75", build_aaa_271(info, "75"), "aaa"
    else:
        code, out, outcome = "", build_success_271(info), "success"
    HISTORY.append(
        {
            "ts": int(time.time()),
            "memberId": mid,
            "outcome": outcome,
            "aaaCode": code,
            "trace": info["trace"],
        }
    )
    return Response(out, status=200, mimetype="text/plain; charset=utf-8")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8210, debug=False)
