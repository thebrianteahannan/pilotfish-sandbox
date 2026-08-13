"""Read a client email against eip-root and propose concrete file edits."""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

SKIP_DIR = {".venv", "lib", "icons", "__pycache__", "node_modules", ".git", "requests", "deploy", "backups"}
SKIP_NAME = {"route.xml", "pools.xml", "test-config.xml"}
OK_SUFFIX = {".xslt", ".xsl", ".xml", ".sql", ".txt"}
JUNK_LINE = re.compile(
    r"summarize this email|locationabbreviation\s+software|"
    r"^\s*km(\s+to:.*)?$|"
    r"^\s*(to|cc|bcc)\s*:|"
    r"confidentiality notice|privileged information|"
    r"^\s*\d{1,2}:\d{2}\b|\bmessages\b|direct line|"
    r"^email:\s|^url:\s|"
    r"^karen j\.?\s+munoz|^data analytics manager",
    re.I,
)
JUNK_SUBJ = re.compile(r"[\u20ac€©]\s*summarize this email", re.I)
WHEN = re.compile(r"[ \t]*<xsl:when\b[\s\S]*?</xsl:when>\s*", re.I)
MAPS_TO = re.compile(r"<xsl:value-of\s+select=\"'([^']+)'\"", re.I)
FACILITY_TAIL = re.compile(r"\s+\d{3}\s+[A-Z]{3}\s+[A-Z]{3}\s*$", re.I)
STRIP_VERB = re.compile(r"\b(strip|remove|delete|drop|take out)\b", re.I)
ADD_VERB = re.compile(r"\b(add|insert|include|new)\b", re.I)


def clean_subject(text: str) -> str:
    return JUNK_SUBJ.sub("", text or "").strip(" \t-–—|") or (text or "").strip()


def clean_email(text: str) -> str:
    lines = []
    for raw in (text or "").replace("\r\n", "\n").splitlines():
        line = raw.strip()
        if not line or JUNK_LINE.search(line):
            continue
        if re.match(r"^[A-Z][a-z]+ [A-Z][a-z]+<.+@.+>$", line):
            continue
        lines.append(line)
    return "\n".join(lines).strip()


def variants(code: str) -> list[str]:
    s = " ".join((code or "").split())
    if not s:
        return []
    out = [s]
    compact = s.replace(" ", "")
    if compact != s:
        out.append(compact)
    if len(compact) >= 4 and " " not in s:
        out.append(compact[:-2] + " " + compact[-2:])
    seen: list[str] = []
    for item in out:
        if item not in seen:
            seen.append(item)
    return seen


def extract_codes(email: str) -> list[str]:
    codes: list[str] = []
    for raw in (email or "").splitlines():
        line = raw.strip()
        if not line or line.lower().startswith("hi "):
            continue
        if FACILITY_TAIL.search(line):
            loc = FACILITY_TAIL.sub("", line).strip()
            if loc:
                codes.append(loc)
    if not codes:
        codes = re.findall(r"\$locationAbbr\s*=\s*'([^']+)'", email or "")
    seen: list[str] = []
    for code in codes:
        if code not in seen:
            seen.append(code)
    return seen[:40]


def intent_of(email: str) -> str:
    if STRIP_VERB.search(email or ""):
        return "strip"
    if ADD_VERB.search(email or ""):
        return "add"
    return "change"


STATUS_OPEN = re.compile(
    r"^(no change|still no change|no luck|fyi|quick update|still happening|same issue)\s*[.!]?\s*",
    re.I,
)


def ask_sentence(email: str) -> str:
    skip = re.compile(r"^(hi|hello|hey)\b|^(re|fw|fwd)\s*:|^(thank you)\b", re.I)
    chunks = []
    for raw in (email or "").splitlines():
        line = raw.strip()
        if not line or skip.search(line) or "@" in line or FACILITY_TAIL.search(line):
            continue
        if re.match(r"^[\d:<€]", line) or len(line) < 8:
            continue
        chunks.append(line)
    blob = STATUS_OPEN.sub("", " ".join(chunks), count=1).strip()
    parts = [p.strip() for p in re.split(r"(?<=[.!?])\s+", blob) if len(p.strip()) > 12]
    def score(p: str) -> int:
        n = 0
        if re.search(r"\b(blank|blanks|still getting|not working)\b", p, re.I):
            n += 3
        if re.search(r"IN1|self[\s-]?pay|subscriber|strip|location", p, re.I):
            n += 2
        if re.search(r"\b(need|implement|skip|logic|primary|secondary)\b", p, re.I):
            n += 2
        return n
    ranked = sorted(parts, key=score, reverse=True)
    main = next((p for p in ranked if score(p) >= 3), None) or (ranked[0] if ranked else "")
    if not main:
        return ""
    extra = next((p for p in parts if p != main and re.search(r"\b(need|implement)\b", p, re.I)), "")
    extra = extra.split(" For example")[0].strip()
    text = main.rstrip(".") + "."
    if extra:
        text = text + " " + extra.rstrip(".") + "."
    if len(text) > 420:
        text = text[:420].rsplit(" ", 1)[0].rstrip(".,;:") + "."
    return text


def extra_needles(email: str, subject: str) -> list[str]:
    blob = f"{subject}\n{email}"
    out: list[str] = []
    for m in re.finditer(r"\bIN1[.\-](\d{1,2})\b", blob, re.I):
        out.append(f"IN1.{m.group(1)}")
    if re.search(r"self[\s-]?pay", blob, re.I):
        out.append("SELFPAY")
    if re.search(r"\bariana\b", blob, re.I):
        out.append("$partitionName = 'ARA'")
    if re.search(r"\bhalifax\b", blob, re.I):
        out.append("$partitionName = 'HAL'")
    return list(dict.fromkeys(out))


ARA_A04 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate ADT A04 HL7/transform.xslt"
)


def is_ara_in116_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    return bool(re.search(r"IN1[.\-]?16|subscriber name", blob, re.I) and re.search(r"self[\s-]?pay", blob, re.I))


def _replace_ed(rel: str, title: str, why: str, old: str, new: str, text: str) -> dict | None:
    if old in text:
        applied = False
    elif new in text:
        applied = True
    else:
        return None
    return {
        "path": rel,
        "action": "replace_block",
        "title": title,
        "why": why,
        "old": old,
        "new": new,
        "already_applied": applied,
    }


def propose_ara_selfpay_in116(root: Path) -> list[dict]:
    path = root / ARA_A04
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    ins2 = (
        "                <IN1.16>\n                  <xsl:choose>\n"
        "                    <xsl:when test=\"$partitionName = 'NHL'\">\n"
        "                      <XCN.1>\n"
        "                        <xsl:value-of select=\"normalize-space(substring-before(Insurance2/subscribername, ','))\" />"
    )
    old15 = "                <IN1.15>\n                  <xsl:text>S</xsl:text>\n                </IN1.15>\n" + ins2
    new15 = (
        "                <IN1.15>\n                  <xsl:choose>\n"
        "                    <xsl:when test=\"$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY'\">\n"
        "                      <xsl:text>P</xsl:text>\n                    </xsl:when>\n"
        "                    <xsl:otherwise>\n                      <xsl:text>S</xsl:text>\n"
        "                    </xsl:otherwise>\n                  </xsl:choose>\n                </IN1.15>\n" + ins2
    )
    old16 = (
        "                    <xsl:when test=\"$partitionName = 'HAL' and string-length(Insurance2/adminsinsuredname) = 0\">\n"
        "                      <XPN.1>\n                        <xsl:value-of select=\"normalize-space(substring-before(Guarantor/admGuarName, ','))\" />\n"
        "                      </XPN.1>\n                      <XPN.2>\n"
        "                        <xsl:value-of select=\"normalize-space(substring-after(Guarantor/admGuarName, ','))\" />\n"
        "                      </XPN.2>\n                    </xsl:when>\n                    <xsl:otherwise>\n"
        "                      <XCN.1>\n                        <xsl:value-of select=\"normalize-space(substring-before(Insurance2/adminsinsuredname, ','))\" />\n"
        "                      </XCN.1>\n                      <XCN.2>\n"
        "                        <xsl:value-of select=\"normalize-space(substring-after(Insurance2/adminsinsuredname, ','))\" />\n"
        "                      </XCN.2>\n                    </xsl:otherwise>"
    )
    new16 = (
        "                    <xsl:when test=\"$partitionName = 'HAL' and string-length(Insurance2/adminsinsuredname) = 0\">\n"
        "                      <XPN.1>\n                        <xsl:value-of select=\"normalize-space(substring-before(Guarantor/admGuarName, ','))\" />\n"
        "                      </XPN.1>\n                      <XPN.2>\n"
        "                        <xsl:value-of select=\"normalize-space(substring-after(Guarantor/admGuarName, ','))\" />\n"
        "                      </XPN.2>\n                    </xsl:when>\n"
        "                    <!-- ARA self-pay: Insurance1 IN1 is skipped, so this is the IN1 we send. Fill IN1.16. -->\n"
        "                    <xsl:when test=\"$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY'\">\n"
        "                      <xsl:choose>\n"
        "                        <xsl:when test=\"string-length(normalize-space(Insurance2/adminsinsuredname)) != 0\">\n"
        "                          <XCN.1>\n                            <xsl:value-of select=\"normalize-space(substring-before(Insurance2/adminsinsuredname, ','))\" />\n"
        "                          </XCN.1>\n                          <XCN.2>\n"
        "                            <xsl:value-of select=\"normalize-space(substring-after(Insurance2/adminsinsuredname, ','))\" />\n"
        "                          </XCN.2>\n                        </xsl:when>\n"
        "                        <xsl:when test=\"string-length(normalize-space(Insurance1/adminsinsuredname)) != 0\">\n"
        "                          <XCN.1>\n                            <xsl:value-of select=\"normalize-space(substring-before(Insurance1/adminsinsuredname, ','))\" />\n"
        "                          </XCN.1>\n                          <XCN.2>\n"
        "                            <xsl:value-of select=\"normalize-space(substring-after(Insurance1/adminsinsuredname, ','))\" />\n"
        "                          </XCN.2>\n                        </xsl:when>\n                        <xsl:otherwise>\n"
        "                          <XCN.1>\n                            <xsl:value-of select=\"normalize-space(substring-before(PatientDemographics/admname, ','))\" />\n"
        "                          </XCN.1>\n                          <XCN.2>\n"
        "                            <xsl:value-of select=\"normalize-space(substring-after(PatientDemographics/admname, ','))\" />\n"
        "                          </XCN.2>\n                        </xsl:otherwise>\n                      </xsl:choose>\n"
        "                    </xsl:when>\n                    <xsl:otherwise>\n"
        "                      <XCN.1>\n                        <xsl:value-of select=\"normalize-space(substring-before(Insurance2/adminsinsuredname, ','))\" />\n"
        "                      </XCN.1>\n                      <XCN.2>\n"
        "                        <xsl:value-of select=\"normalize-space(substring-after(Insurance2/adminsinsuredname, ','))\" />\n"
        "                      </XCN.2>\n                    </xsl:otherwise>"
    )
    out = []
    rec = _replace_ed(
        ARA_A04,
        "Mark the promoted self-pay IN1 as primary (IN1.15 = P)",
        "When Ariana primary is SELFPAY, this IN1 is already written as 0001. It was still tagged secondary (S).",
        old15,
        new15,
        text,
    )
    if rec:
        out.append(rec)
    rec = _replace_ed(
        ARA_A04,
        "Fill IN1.16 subscriber name on that same IN1",
        "Insurance1 IN1 is skipped for Ariana SELFPAY, so the patient-name fallback on Insurance1 never runs. This IN1.16 used only Insurance2 subscriber name, which is empty for self-pay.",
        old16,
        new16,
        text,
    )
    if rec:
        out.append(rec)
    return out


def iter_search_files(root: Path) -> list[Path]:
    eip = root / "eip-root"
    if not eip.is_dir():
        return []
    found: list[Path] = []
    for path in eip.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in OK_SUFFIX:
            continue
        if any(p in SKIP_DIR for p in path.parts):
            continue
        if path.name.lower() in SKIP_NAME:
            continue
        if "-test" in path.name.lower() or path.name.lower().endswith("test.xml"):
            continue
        if path.stat().st_size > 900_000:
            continue
        found.append(path)
    return found


def quoted_in(block: str, code: str) -> bool:
    return f"'{code}'" in block or f'"{code}"' in block


def maps_to(block: str) -> str:
    m = MAPS_TO.search(block)
    return m.group(1) if m else ""


def find_whens(text: str, code: str) -> list[dict]:
    hits = []
    for m in WHEN.finditer(text):
        block = m.group(0)
        if not quoted_in(block, code):
            continue
        line = text[: m.start()].count("\n") + 1
        hits.append({"line": line, "block": block, "maps_to": maps_to(block), "text": block.strip().splitlines()[0][:160]})
    return hits


def search_lines(text: str, code: str, limit: int = 8) -> list[dict]:
    hits = []
    for i, raw in enumerate(text.splitlines(), start=1):
        if code in raw:
            hits.append({"line": i, "text": raw.strip()[:180]})
            if len(hits) >= limit:
                break
    return hits


def dive(root: Path, email: str, subject: str) -> dict:
    body = clean_email(email)
    subj = clean_subject(subject)
    codes = extract_codes(body)
    intent = intent_of(body)
    ask = ask_sentence(body)
    files: list[dict] = []
    edits: list[dict] = []
    needles = []
    for code in codes:
        needles.extend(variants(code))
    needles.extend(extra_needles(body, subj))
    needles = list(dict.fromkeys(needles))
    for path in iter_search_files(root):
        text = path.read_text(encoding="utf-8", errors="replace")
        rel = path.relative_to(root).as_posix()
        file_hits: list[dict] = []
        for code in needles:
            whens = find_whens(text, code) if path.suffix.lower() in {".xslt", ".xsl"} else []
            if whens:
                for hit in whens:
                    file_hits.append({"code": code, **{k: hit[k] for k in ("line", "text", "maps_to")}})
                    if intent == "strip":
                        edits.append(
                            {
                                "path": rel,
                                "action": "remove_when",
                                "code": code,
                                "line": hit["line"],
                                "maps_to": hit["maps_to"],
                                "remove_blocks": [hit["block"]],
                            }
                        )
            elif code in text:
                file_hits.extend({"code": code, **h} for h in search_lines(text, code))
        if file_hits:
            files.append({"path": rel, "hits": file_hits[:20]})
    files.sort(key=lambda rec: -len({h.get("code") for h in rec.get("hits") or []}))
    files = files[:8]
    risks = []
    if intent == "strip" and any(e.get("maps_to") == "HAX" for e in edits):
        risks.append(
            "These mappings currently send the location to HAX. The stylesheet otherwise already defaults unknown locations to HAX, so deleting the when-branches does not change Halifax output unless you also change that default."
        )
    if intent == "strip" and not edits:
        risks.append("No xsl:when Location_ABBR branches matched. The codes may live in a database lookup or a different spelling.")
    summary = ask or subj or "Client interface change"
    if codes:
        summary = f"{'Strip' if intent == 'strip' else 'Change'} {len(codes)} Location_ABBR code(s) in Halifax: " + ", ".join(codes)
    if is_ara_in116_ask(body, subj):
        extra = propose_ara_selfpay_in116(root)
        edits.extend(extra)
        if extra:
            summary = (
                "Fill blank IN1.16 (subscriber name) on Ariana self-pay HL7. "
                "Skip self-pay when there is a real secondary; if the name is still blank, use the patient name."
            )
            files = [f for f in files if "Generate ADT A04 HL7" in f["path"]]
            for rec in files:
                rec["hits"] = [h for h in rec.get("hits") or [] if h.get("code") in ("IN1.16", "SELFPAY")][:12]
            risks.extend(
                [
                    "Self-pay with a real secondary already skips the SELFPAY IN1 and writes Insurance2 as IN1.1=0001. IN1.16 on that row was blank; that is what this fills.",
                    "Self-pay with no secondary still sends SELFPAY as the only IN1; IN1.16 then uses the patient name instead of leaving it empty.",
                ]
            )
    return {
        "summary": summary,
        "intent": intent,
        "ask": ask,
        "subject": subj,
        "codes": codes,
        "files": files,
        "edits": edits,
        "risks": risks,
    }


def write_markdown(folder: Path, meta: dict, dive_data: dict) -> str:
    lines = [
        f"# Change plan — {meta.get('client')}",
        "",
        dive_data.get("summary") or "",
        "",
        f"From: {meta.get('from') or '(not set)'}",
        f"Subject: {dive_data.get('subject') or meta.get('subject')}",
        "",
        "## What the email is asking",
        dive_data.get("ask") or "(see email.txt)",
        "",
    ]
    if dive_data.get("codes"):
        lines += ["## Codes", *[f"- `{c}`" for c in dive_data["codes"]], ""]
    lines.append("## Where it lives in eip-root")
    if dive_data.get("files"):
        for rec in dive_data["files"]:
            lines.append(f"- `{rec['path']}`")
            for hit in rec.get("hits") or []:
                extra = f" → {hit['maps_to']}" if hit.get("maps_to") else ""
                lines.append(f"  - L{hit.get('line')}: `{hit.get('code')}`{extra} — {hit.get('text')}")
    else:
        lines.append("- No matching lines found under eip-root.")
    lines += ["", "## Proposed edits"]
    if dive_data.get("edits"):
        for ed in dive_data["edits"]:
            if ed.get("action") == "replace_block":
                flag = " (already in eip-root)" if ed.get("already_applied") else ""
                lines.append(f"- {ed.get('title') or 'Replace'} in `{ed.get('path')}`{flag}")
                if ed.get("why"):
                    lines.append(f"  {ed['why']}")
                if ed.get("old"):
                    lines += ["  Before:", "```xml", ed["old"].rstrip(), "```"]
                if ed.get("new"):
                    lines += ["  After:", "```xml", ed["new"].rstrip(), "```"]
            else:
                lines.append(
                    f"- Remove `xsl:when` for `{ed.get('code')}` in `{ed.get('path')}` (line {ed.get('line')}"
                    + (f", currently maps to {ed['maps_to']}" if ed.get("maps_to") else "")
                    + ")"
                )
    else:
        lines.append("- Nothing the hub can apply automatically yet. Review the hits above in eiConsole.")
    if dive_data.get("risks"):
        lines += ["", "## Watch-outs", *[f"- {r}" for r in dive_data["risks"]]]
    already = any(e.get("already_applied") for e in dive_data.get("edits") or [])
    start = (
        "These edits are already on disk in eip-root. Start work will load the sandbox and run tests; it will not re-apply them."
        if already
        else "The PDF is the review copy. Click Start work in the hub to apply the proposed edits on eip-root (a .bak-req copy is kept beside each file)."
    )
    lines += ["", "## Start work", start, ""]
    text = "\n".join(lines) + "\n"
    (folder / "changes-needed.md").write_text(text, encoding="utf-8")
    (folder / "dive.json").write_text(json.dumps(dive_data, indent=2) + "\n", encoding="utf-8")
    return text


def _bak_req(path: Path) -> None:
    bak = path.with_name(path.name + ".bak-req")
    if not bak.is_file():
        shutil.copy2(path, bak)


def apply_edits(root: Path, dive_data: dict) -> list[dict]:
    applied: list[dict] = []
    grouped: dict[str, list[str]] = {}
    for ed in dive_data.get("edits") or []:
        if ed.get("action") != "remove_when":
            continue
        grouped.setdefault(ed["path"], []).extend(ed.get("remove_blocks") or [])
    for rel, blocks in grouped.items():
        path = root / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        new = text
        n = 0
        for block in blocks:
            if block and block in new:
                new = new.replace(block, "", 1)
                n += 1
        if new == text:
            continue
        _bak_req(path)
        path.write_text(new, encoding="utf-8")
        applied.append({"path": rel, "removed": n})
    for ed in dive_data.get("edits") or []:
        if ed.get("action") != "replace_block":
            continue
        rel, old, new = ed.get("path") or "", ed.get("old") or "", ed.get("new") or ""
        path = root / rel
        if not path.is_file() or not old or not new:
            continue
        text = path.read_text(encoding="utf-8")
        if new in text and old not in text:
            applied.append({"path": rel, "replaced": 0, "already": True})
            continue
        if old not in text:
            continue
        _bak_req(path)
        path.write_text(text.replace(old, new, 1), encoding="utf-8")
        applied.append({"path": rel, "replaced": 1})
    return applied
