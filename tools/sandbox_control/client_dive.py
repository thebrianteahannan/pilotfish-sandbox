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
# Gmail Gemini / Outlook Copilot chip. OCR often reads the sparkle as € © * | etc.
JUNK_SUBJ = re.compile(
    r"[\s|/\-–—:]*"
    r"(?:[\u20ac€©®™*✦✧⭐✨●•·♦+|~]{1,3}\s*)?"
    r"summariz[se]\s+this\s+(?:e-?mail|message)\b.*$",
    re.I,
)
WHEN = re.compile(r"[ \t]*<xsl:when\b[\s\S]*?</xsl:when>\s*", re.I)
MAPS_TO = re.compile(r"<xsl:value-of\s+select=\"'([^']+)'\"", re.I)
FACILITY_TAIL = re.compile(r"\s+\d{3}\s+[A-Z]{3}\s+[A-Z]{3}\s*$", re.I)
LOC_HEAD = re.compile(
    r"^((?:[A-Z]{1,3}\.)[A-Z0-9.]+|[A-Z]{2,10}(?:\s+[A-Z0-9]{1,8})?)",
    re.I,
)
LOC_SKIP = {
    "CODE", "DESCRIPTION", "SOFTWARE", "SOFTWARE_ID", "PARTITION", "FACILITY",
    "LOCATION", "LOCATION2", "STRIP", "FLG", "PLEASE", "EXAMPLE", "RAW",
    "RELATIONSHIP", "GUARANTOR", "SUBSCRIBER", "THIS", "COULD", "THANK",
}
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
    if re.search(r"subscriber relationship|insured.?relationship|IN1[.\-]?17", blob, re.I):
        out.extend(["IN1.17", "adminsinsuredrel"])
    if re.search(r"\bariana\b", blob, re.I):
        out.append("$partitionName = 'ARA'")
    if re.search(r"\bhalifax\b", blob, re.I):
        out.append("$partitionName = 'HAL'")
    return list(dict.fromkeys(out))


ARA_A04 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate ADT A04 HL7/transform.xslt"
)
NGP_HF = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client/"
    "transform-ngp-healthfirst-flatfilexml-to-canconicalxml.xslt"
)
HAL_MAP = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/1 - Incoming Flat Files by Partition and Client/"
    "transform-halifax-flatfilexml-to-canconicalxml.xslt"
)
STRIP_DATA = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/strip_data.xslt"
)
STRIP_ROUTE = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/route.xml"
)
CAT_HUGGINS = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/transform-CAT-huggins-monadnock-strip.xslt"
)
DFT_P03 = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Generate DFT DPT P03 HL7/transform.xslt"
)
SITE_STRIP = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "routes/2 - Stripping and Tweaking/transform-filter-strip-site-locations.xslt"
)
ADD_MUE = (
    "eip-root/interfaces/Flat File to HL7 and Kickout Reports/"
    "formats/Add MUE_EDITS SQLXML/transform-add-mue-edits.xslt"
)
ADD_MUE_OLD = (
    "      <xsl:for-each select=\"XCSExcelSheet/XCSExcelRow[string-length(SOFTWAREID) &gt; 0]\">\n"
    "        <ns1:Insert>\n"
    "          <MUE_EDITS>\n"
    "            <SOFTWARE_ID>\n"
    "              <xsl:value-of select=\"SOFTWAREID\" />\n"
    "            </SOFTWARE_ID>\n"
    "            <CPT>\n"
    "              <xsl:value-of select=\"CPT\" />\n"
    "            </CPT>\n"
    "            <CDM>\n"
    "              <xsl:value-of select=\"CDM\" />\n"
    "            </CDM>\n"
    "            <MAX_VALUE_PER_LINE>\n"
    "              <xsl:value-of select=\"MAX_VALUE_PER_LINE\" />\n"
    "            </MAX_VALUE_PER_LINE>\n"
    "          </MUE_EDITS>\n"
    "        </ns1:Insert>\n"
    "      </xsl:for-each>"
)
ADD_MUE_NEW = (
    "      <xsl:for-each-group select=\"XCSExcelSheet/XCSExcelRow[string-length(normalize-space((CDM, CPT)[1])) &gt; 0]\" "
    "group-starting-with=\"*[normalize-space((SOFTWAREID, SOFTWAREID__)[1])]\">\n"
    "        <xsl:variable name=\"sw\" select=\"normalize-space((SOFTWAREID, SOFTWAREID__)[1])\" />\n"
    "        <xsl:for-each select=\"current-group()[string-length($sw) &gt; 0]\">\n"
    "          <ns1:Insert>\n"
    "            <MUE_EDITS>\n"
    "              <SOFTWARE_ID>\n"
    "                <xsl:value-of select=\"$sw\" />\n"
    "              </SOFTWARE_ID>\n"
    "              <CPT>\n"
    "                <xsl:value-of select=\"CPT\" />\n"
    "              </CPT>\n"
    "              <CDM>\n"
    "                <xsl:value-of select=\"CDM\" />\n"
    "              </CDM>\n"
    "              <MAX_VALUE_PER_LINE>\n"
    "                <xsl:value-of select=\"normalize-space((MAX_VALUE_PER_LINE, Max_Value_Per_Line)[1])\" />\n"
    "              </MAX_VALUE_PER_LINE>\n"
    "            </MUE_EDITS>\n"
    "          </ns1:Insert>\n"
    "        </xsl:for-each>\n"
    "      </xsl:for-each-group>"
)
NTX_PV12_OLD = (
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'ANC' and PatientDemographics/admLocation = 'BB.SOLIS'\">\n"
    "                  <xsl:value-of select=\"concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'FTW' and PatientDemographics/admLocation = 'M.ASC'\">\n"
    "                  <xsl:value-of select=\"concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and ($facilityName = 'PLA' or $facilityName = 'FRI' or $facilityName = 'SAC') and (PatientDemographics/admLocation = 'E.SOLIS' or PatientDemographics/admLocation = 'E.DS')\">\n"
    "                  <xsl:value-of select=\"concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$facilityName = 'CLO' and PatientDemographics/admLocation = 'G.BASC'\">\n"
    "                  <xsl:value-of select=\"concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'ARL' and PatientDemographics/admLocation = 'I.TPC'\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>"
)
NTX_PV12_NEW = (
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'ANC' and PatientDemographics/admLocation = 'BB.SOLIS'\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'ARL' and (PatientDemographics/admLocation = 'I.TPC' or PatientDemographics/admLocation = 'LTPC' or PatientDemographics/admLocation = 'I.SOLIS')\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'DEN' and (PatientDemographics/admLocation = 'G.SOLIS' or PatientDemographics/admLocation = 'G.ASC')\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'FTW' and (PatientDemographics/admLocation = 'M.ASC' or PatientDemographics/admLocation = 'M.ASC ALLI')\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'LAS' and PatientDemographics/admLocation = 'AF.SOLIS'\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'LEW' and PatientDemographics/admLocation = 'L.SOLIS'\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'MCK' and PatientDemographics/admLocation = 'Q.SOLIS'\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'MED' and (PatientDemographics/admLocation = 'H.SOLIS' or PatientDemographics/admLocation = 'H.ASC')\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'PLA' and PatientDemographics/admLocation = 'E.SOLIS'\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and $facilityName = 'WEA' and (PatientDemographics/admLocation = 'BE.SOLIS' or PatientDemographics/admLocation = 'BE.LABSOLI' or PatientDemographics/admLocation = 'BE.LABSOLIS')\">\n"
    "                  <xsl:value-of select=\"'24'\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$partitionName = 'NTX' and ($facilityName = 'PLA' or $facilityName = 'FRI' or $facilityName = 'SAC') and (PatientDemographics/admLocation = 'E.SOLIS' or PatientDemographics/admLocation = 'E.DS')\">\n"
    "                  <xsl:value-of select=\"concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)\" />\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"$facilityName = 'CLO' and PatientDemographics/admLocation = 'G.BASC'\">\n"
    "                  <xsl:value-of select=\"concat(PatientDemographics/admpatienttype,PatientDemographics/admLocation)\" />\n"
    "                </xsl:when>"
)
HAL_STRIP_OLD = (
    "select=\"count(/XCSData/query_results/LOCATION/LOCATION[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) "
    "+ (if ($Partition = 'HAL' and (admLocationAbbr, ../PatientDemographics/admLocationAbbr) = "
    "('HMC 201','HH IPM','TL GI','TLGI','OR TL')) then 1 else 0) "
    "+ (if ($Partition = 'NHL' and $SoftwareID = '513' and $admLocation = ('R.EH','R.LABND')) then 1 else 0)\""
)
HAL_STRIP_NEW = (
    "select=\"count(/XCSData/query_results/LOCATION/LOCATION[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) "
    "+ (if (($Partition = 'HAL' or $SoftwareID = '750') and translate(upper-case(normalize-space("
    "(admLocationAbbr, ../PatientDemographics/admLocationAbbr, $admLocation)[1])), ' ', '') = "
    "('HMC201','HHIPM','TLGI','ORTL')) then 1 else 0) "
    "+ (if ($Partition = 'NHL' and $SoftwareID = '513' and $admLocation = ('R.EH','R.LABND')) then 1 else 0)\""
)


def is_ara_in117_rel_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    return bool(
        re.search(r"self[\s-]?pay", blob, re.I)
        and re.search(r"subscriber relationship|IN1[.\-]?17|InsuredRelationship", blob, re.I)
    )


def is_ara_in116_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if is_ara_in117_rel_ask(email, subject):
        return False
    return bool(re.search(r"IN1[.\-]?16|subscriber name", blob, re.I) and re.search(r"self[\s-]?pay", blob, re.I))


def is_ngp_selfpay_in1_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    return bool(
        re.search(r"self[\s-]?pay", blob, re.I)
        and re.search(r"missing.{0,60}IN1|IN1.{0,60}missing", blob, re.I)
        and re.search(r"NGP|Healthfirst", blob, re.I)
    )


def is_hal_strip_bug_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"\bhalifax\b|\bHAL\b", blob, re.I):
        return False
    if not re.search(r"HMC 201|HH IPM|OR TL|TLGI|TL GI", blob, re.I):
        return False
    return bool(
        re.search(r"\bbug\b", blob, re.I)
        or re.search(r"not working|not splitting|still.{0,40}(split|strip)", blob, re.I)
    )


def is_nhl_cat_guarantor_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"\bNHL\b", blob, re.I) or not re.search(r"\bCAT\b", blob):
        return False
    if re.search(r"demo file|charge file|R\.LABND|R\.EH", blob, re.I):
        return False
    return bool(re.search(r"guarantor|GT1\.11|relationship", blob, re.I))


def is_nhl_cat_lc_dft_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if is_nhl_cat_guarantor_ask(email, subject):
        return False
    if not re.search(r"\bNHL\b", blob, re.I) or not re.search(r"\bCAT\b", blob):
        return False
    if re.search(r"demo file|charge file", blob, re.I):
        return False
    return bool(re.search(r"\bDFT\b", blob, re.I) and re.search(r"strip", blob, re.I))


def is_nhl_cat_bug_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if is_nhl_cat_guarantor_ask(email, subject) or is_nhl_cat_lc_dft_ask(email, subject):
        return False
    if not re.search(r"\bNHL\b", blob, re.I) or not re.search(r"\bCAT\b", blob):
        return False
    return bool(
        re.search(r"\bbug\b", blob, re.I)
        or re.search(r"not working|demo file|charge file", blob, re.I)
    )


def is_hal_flg_change_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if is_hal_strip_bug_ask(email, subject):
        return False
    if not re.search(r"\bhalifax\b|\bHAL\b", blob, re.I):
        return False
    if not re.search(r"HMC 201|HH IPM|OR TL|TLGI|TL GI", blob, re.I):
        return False
    return bool(re.search(r"FLG|Strip Location|add these", blob, re.I))


def is_mue_bug_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"\bMUE", blob, re.I):
        return False
    return bool(
        re.search(r"\bbug\b", blob, re.I)
        or re.search(r"only mapping|re-upload|software id", blob, re.I)
    )


def is_ntx_pv12_pos24_ask(email: str, subject: str) -> bool:
    blob = f"{subject}\n{email}"
    if not re.search(r"\bNTX\b", blob, re.I):
        return False
    if not re.search(r"PV1", blob, re.I):
        return False
    if not re.search(r"\b24\b", blob):
        return False
    return bool(
        re.search(r"BB\.SOLIS|I\.SOLIS|I\.TPC|LTPC|SOLIS", blob, re.I)
        or re.search(r"location code", blob, re.I)
    )


def propose_ntx_pv12_pos24(root: Path) -> list[dict]:
    path = root / ARA_A04
    if not path.is_file():
        return []
    rec = _replace_ed(
        ARA_A04,
        "Set NTX Solis/ASC PV1.2 to 24 (same as ARL I.TPC)",
        "TEST ADT for BB.SOLIS (account 8383414) concatenates patient type + location into PV1.2 "
        "(OCR CBB2SOLES). ARL I.TPC already emits 24. Switch the existing NTX concat branches to 24 "
        "and add the rest of Karen’s location table.",
        NTX_PV12_OLD,
        NTX_PV12_NEW,
        path.read_text(encoding="utf-8", errors="replace"),
    )
    return [rec] if rec else []


def propose_mue_bug(root: Path) -> list[dict]:
    path = root / ADD_MUE
    if not path.is_file():
        return []
    rec = _replace_ed(
        ADD_MUE,
        "Fill SOFTWAREID down the MUE Excel so every CPT inserts",
        "88e currently skips any row with a blank SOFTWAREID, so only the first CPT (80048) "
        "lands in MUE_EDITS. Inherit SOFTWAREID from the last filled row, and read MAX VALUE PER LINE "
        "whether the Excel column is MAX_VALUE_PER_LINE or Max_Value_Per_Line.",
        ADD_MUE_OLD,
        ADD_MUE_NEW,
        path.read_text(encoding="utf-8", errors="replace"),
    )
    return [rec] if rec else []


def propose_ngp_selfpay_in1(root: Path) -> list[dict]:
    out: list[dict] = []
    hf = root / NGP_HF
    if hf.is_file():
        text = hf.read_text(encoding="utf-8", errors="replace")
        old = (
            '                <xsl:when test="string-length(normalize-space(PRIMARY_PAYER)) != 0 and not(contains(upper-case(translate(normalize-space(PRIMARY_PAYER), \'-\', \' \')), \'SELF PAY\') or upper-case(normalize-space(PRIMARY_PAYER)) = \'SELFPAY\' or upper-case(normalize-space(PRIMARY_PAYER)) = \'NOT APPLICABLE\')">\n'
            "                  <xsl:value-of select=\"normalize-space(PRIMARY_PAYER)\" />\n"
            "                </xsl:when>\n"
            '                <xsl:when test="string-length(normalize-space(PRIMARY_CVG_PAYER)) != 0 and not(contains(upper-case(translate(normalize-space(PRIMARY_CVG_PAYER), \'-\', \' \')), \'SELF PAY\') or upper-case(normalize-space(PRIMARY_CVG_PAYER)) = \'SELFPAY\' or upper-case(normalize-space(PRIMARY_CVG_PAYER)) = \'NOT APPLICABLE\')">\n'
        )
        new = (
            '                <xsl:when test="string-length(normalize-space(PRIMARY_PAYER)) != 0 and not(contains(upper-case(translate(normalize-space(PRIMARY_PAYER), \'-\', \' \')), \'SELF PAY\') or upper-case(normalize-space(PRIMARY_PAYER)) = \'SELFPAY\' or upper-case(normalize-space(PRIMARY_PAYER)) = \'NOT APPLICABLE\' or contains(upper-case(normalize-space(PRIMARY_PAYER)), \'NO PAYER\'))">\n'
            "                  <xsl:value-of select=\"normalize-space(PRIMARY_PAYER)\" />\n"
            "                </xsl:when>\n"
            '                <xsl:when test="string-length(normalize-space(PRIMARY_CVG_PAYER)) != 0 and not(contains(upper-case(translate(normalize-space(PRIMARY_CVG_PAYER), \'-\', \' \')), \'SELF PAY\') or upper-case(normalize-space(PRIMARY_CVG_PAYER)) = \'SELFPAY\' or upper-case(normalize-space(PRIMARY_CVG_PAYER)) = \'NOT APPLICABLE\' or contains(upper-case(normalize-space(PRIMARY_CVG_PAYER)), \'NO PAYER\'))">\n'
        )
        rec = _replace_ed(
            NGP_HF,
            "Do not copy “No payer found” into admInsName",
            "SELF PAY is already skipped. TEST still has no IN1 because Primary Payer is often “No payer found”, which filled the name and skipped the PPP fallback.",
            old,
            new,
            text,
        )
        if rec:
            out.append(rec)
    a04 = root / ARA_A04
    if a04.is_file():
        text = a04.read_text(encoding="utf-8", errors="replace")
        old = (
            "          <xsl:if test=\"($partitionName = 'SPG' or $partitionName = 'PPA' or $partitionName = 'NGP' or $partitionName = 'HAL') and Insurance1[(string-length(adminsmne) = 0 or adminsmne = 'BLANK') and (string-length(admInsName) = 0 or ($partitionName = 'NGP' and (contains(upper-case(translate(normalize-space(admInsName), '-', ' ')), 'SELF PAY') or upper-case(normalize-space(admInsName)) = 'SELFPAY' or upper-case(normalize-space(admInsName)) = 'NOT APPLICABLE')))] and Insurance2[string-length(adminsmne) = 0]\">"
        )
        new = (
            "          <xsl:if test=\"($partitionName = 'SPG' or $partitionName = 'PPA' or $partitionName = 'NGP' or $partitionName = 'HAL') and Insurance1[(string-length(adminsmne) = 0 or adminsmne = 'BLANK') and (string-length(admInsName) = 0 or ($partitionName = 'NGP' and (contains(upper-case(translate(normalize-space(admInsName), '-', ' ')), 'SELF PAY') or upper-case(normalize-space(admInsName)) = 'SELFPAY' or upper-case(normalize-space(admInsName)) = 'NOT APPLICABLE' or contains(upper-case(normalize-space(admInsName)), 'NO PAYER'))))] and Insurance2[string-length(adminsmne) = 0]\">"
        )
        rec = _replace_ed(
            ARA_A04,
            "Still emit the NGP PPP IN1 when the name is “No payer found”",
            "Same PPP path as blank/self-pay. If a leftover name reaches ADT, treat No payer found like an empty name.",
            old,
            new,
            text,
        )
        if rec:
            out.append(rec)
    return out


def propose_hal_strip_bug(root: Path) -> list[dict]:
    out: list[dict] = []
    hal = root / HAL_MAP
    if hal.is_file():
        text = hal.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            HAL_MAP,
            "Normalize Halifax Location_ABBR before the strip can see it",
            "TEST still has OR TL / HMC 201 in HAX ADT because the raw field is padded. "
            "Collapse whitespace when copying Location_ABBR onto the record.",
            "              <xsl:variable name=\"locationAbbr\" select=\"Demographics/XCSRecord[1]/LOCATION_ABBR\" />",
            "              <xsl:variable name=\"locationAbbr\" select=\"normalize-space(Demographics/XCSRecord[1]/LOCATION_ABBR)\" />",
            text,
        )
        if rec:
            out.append(rec)
        rec = _replace_ed(
            HAL_MAP,
            "Store the trimmed Location_ABBR on admLocationAbbr",
            "The strip route reads this field. Write the same normalized value the map uses.",
            "              <xsl:value-of select=\"Demographics/XCSRecord[1]/LOCATION_ABBR\" />",
            "              <xsl:value-of select=\"normalize-space(Demographics/XCSRecord[1]/LOCATION_ABBR)\" />",
            text,
        )
        if rec:
            out.append(rec)
    strip = root / STRIP_DATA
    if strip.is_file():
        text = strip.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            STRIP_DATA,
            "Match padded and TLGI/TL GI Halifax locations when stripping",
            "The first strip used an exact string match. Karen’s _20260802 accounts "
            "(30101805251 OR TL, 30101976049 HMC 201) still go to HAX. Compare a "
            "space-stripped uppercase abbr, and also $admLocation so AP_Halifax rows "
            "that never got admLocationAbbr still strip.",
            HAL_STRIP_OLD,
            HAL_STRIP_NEW,
            text,
        )
        if rec:
            rec["replace_all"] = True
            out.append(rec)
    return out


NHL_CAT_HAL = (
    "count(/XCSData/query_results/LOCATION/LOCATION[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) "
    "+ (if (($Partition = 'HAL' or $SoftwareID = '750') and translate(upper-case(normalize-space("
    "(admLocationAbbr, ../PatientDemographics/admLocationAbbr, $admLocation)[1])), ' ', '') = "
    "('HMC201','HHIPM','TLGI','ORTL')) then 1 else 0) "
)
NHL_CAT_CHARGE_OLD = (
    "    <xsl:variable name=\"admLocation\" select=\"../PatientDemographics/admLocation\" />\n"
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])\" />\n"
    f"    <xsl:variable name=\"stripLocationsCount\" select=\"{NHL_CAT_HAL}"
    "+ (if ($Partition = 'NHL' and $SoftwareID = '513' and $admLocation = ('R.EH','R.LABND')) then 1 else 0)\" />"
)
NHL_CAT_CHARGE_NEW = (
    "    <xsl:variable name=\"admLocation\" select=\"../PatientDemographics/admLocation\" />\n"
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])\" />\n"
    f"    <xsl:variable name=\"stripLocationsCount\" select=\"{NHL_CAT_HAL}"
    "+ (if ($Partition = 'NHL' and ($Client = 'CAT' or $SoftwareID = ('513','524')) and "
    "(translate(upper-case(normalize-space($admLocation)), '.', '') = ('REH','RLABND') or "
    "(normalize-space(../PatientDemographics/Filler2) = 'CMCEH' and $admLocation = ('R.EH','R.LAB','R.LABND','RG.LAB')))) "
    "then 1 else 0)\" />"
)
NHL_CAT_DEMO_OLD = (
    "    <xsl:variable name=\"admLocation\" select=\"admLocation\" />\n"
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])\" />\n"
    f"    <xsl:variable name=\"stripLocationsCount\" select=\"{NHL_CAT_HAL}"
    "+ (if ($Partition = 'NHL' and $SoftwareID = '513' and $admLocation = ('R.EH','R.LABND')) then 1 else 0)\" />"
)
NHL_CAT_DEMO_NEW = (
    "    <xsl:variable name=\"admLocation\" select=\"admLocation\" />\n"
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])\" />\n"
    f"    <xsl:variable name=\"stripLocationsCount\" select=\"{NHL_CAT_HAL}"
    "+ (if ($Partition = 'NHL' and ($Client = 'CAT' or $SoftwareID = ('513','524')) and "
    "(translate(upper-case(normalize-space($admLocation)), '.', '') = ('REH','RLABND') or "
    "(normalize-space(Filler2) = 'CMCEH' and $admLocation = ('R.EH','R.LAB','R.LABND','RG.LAB')))) "
    "then 1 else 0)\" />"
)
NHL_CAT_2NDRY_OLD = (
    "+ (if ($SoftwareID = '513' and (($location1 = 'R.EH' and $location2 = 'CMCEH') or "
    "($location1 = 'R.LAB' and $location2 = 'CMCEH') or ($location1 = 'R.LABND' and $location2 = 'CMCEH') or "
    "($location1 = 'RG.LAB' and $location2 = 'CMCEH'))) then 1 else 0)\""
)
NHL_CAT_2NDRY_NEW = (
    "+ (if ($Partition = 'NHL' and ($Client = 'CAT' or $SoftwareID = ('513','524')) and "
    "(($location1 = 'R.EH' and $location2 = 'CMCEH') or ($location1 = 'R.LAB' and $location2 = 'CMCEH') or "
    "($location1 = 'R.LABND' and $location2 = 'CMCEH') or ($location1 = 'RG.LAB' and $location2 = 'CMCEH'))) "
    "then 1 else 0)\""
)
NHL_CAT_ROUTE_OLD = (
    "          <XSLTPath>strip_data.xslt</XSLTPath>\n"
    "          <CacheXSLTToXML>false</CacheXSLTToXML>\n"
    "          <XSLTEngine>Saxon</XSLTEngine>\n"
    "          <XSLTParameters>[eip_pair:SoftwareID:eip_name:{ognl:getAttribute('SoftwareID')}:eip_value]"
    "[eip_pair:Client:eip_name:{ognl:getAttribute('Client')}:eip_value]"
    "[eip_pair:Partition:eip_name:{ognl:getAttribute('Partition')}:eip_value]</XSLTParameters>\n"
    "          <SaxonConverterHandling>Throw Exception</SaxonConverterHandling>\n"
    "          <SaxonConverterEncoding>UTF-8</SaxonConverterEncoding>\n"
    "        </ModuleConfig>\n"
    "      </Processor>\n"
    "      <Processor class=\"com.pilotfish.eip.modules.transform.XSLTProcessor\" name=\"Strip Charges If radExamServeDate Before DATE_RANGE from DB\">\n"
)
NHL_CAT_ROUTE_NEW = (
    "          <XSLTPath>strip_data.xslt</XSLTPath>\n"
    "          <CacheXSLTToXML>false</CacheXSLTToXML>\n"
    "          <XSLTEngine>Saxon</XSLTEngine>\n"
    "          <XSLTParameters>[eip_pair:SoftwareID:eip_name:{ognl:getAttribute('SoftwareID')}:eip_value]"
    "[eip_pair:Client:eip_name:{ognl:getAttribute('Client')}:eip_value]"
    "[eip_pair:Partition:eip_name:{ognl:getAttribute('Partition')}:eip_value]</XSLTParameters>\n"
    "          <SaxonConverterHandling>Throw Exception</SaxonConverterHandling>\n"
    "          <SaxonConverterEncoding>UTF-8</SaxonConverterEncoding>\n"
    "        </ModuleConfig>\n"
    "      </Processor>\n"
    "      <Processor class=\"com.pilotfish.eip.modules.transform.XSLTProcessor\" name=\"Apply Stripping - NHL CAT - Huggins Monadnock Charges\">\n"
    "        <ModuleConfig>\n"
    "          <ExecuteProcessor>{ognl:getAttribute('Partition') == 'NHL' &amp;&amp; getAttribute('Client') == 'CAT'}</ExecuteProcessor>\n"
    "          <XSLTPath>transform-CAT-huggins-monadnock-strip.xslt</XSLTPath>\n"
    "          <CacheXSLTToXML>false</CacheXSLTToXML>\n"
    "          <XSLTEngine>Saxon</XSLTEngine>\n"
    "          <XSLTParameters>null</XSLTParameters>\n"
    "          <SaxonConverterHandling>Throw Exception</SaxonConverterHandling>\n"
    "          <SaxonConverterEncoding>UTF-8</SaxonConverterEncoding>\n"
    "        </ModuleConfig>\n"
    "      </Processor>\n"
    "      <Processor class=\"com.pilotfish.eip.modules.transform.XSLTProcessor\" name=\"Strip Charges If radExamServeDate Before DATE_RANGE from DB\">\n"
)


GT1_CAT_OLD = (
    "                <xsl:when test=\"($partitionName = 'NGP' or $partitionName = 'SPG' or $partitionName = 'GLF' "
    "or ($partitionName = 'IRL' and $softwareID = ('517','514','515','516','518','519','520','521','522','523')) "
    "or ($partitionName = 'FPS' and $softwareID = ('314','315','316','317','318','319','320')) "
    "or $softwareID = ('524')  or ($partitionName = 'NHL' and ($clientName = 'CAT' or $softwareID = ('513','524')))) "
    "and string-length(Guarantor/admGuarRel) = 0\">"
)
GT1_CAT_NEW = (
    "                <xsl:when test=\"$partitionName = 'NHL' and ($clientName = 'CAT' or $softwareID = ('513','524')) "
    "and string-length(normalize-space(Guarantor/admGuarRel)) = 0\">\n"
    "                  <xsl:choose>\n"
    "                    <xsl:when test=\"mr:relName(Guarantor/admGuarName) = mr:relName(PatientDemographics/admname)\">\n"
    "                      <xsl:value-of select=\"'SE'\" />\n"
    "                    </xsl:when>\n"
    "                    <xsl:when test=\"number($PatientAge) &lt; 18\">\n"
    "                      <xsl:value-of select=\"'CH'\" />\n"
    "                    </xsl:when>\n"
    "                    <xsl:otherwise>\n"
    "                      <xsl:value-of select=\"'UN'\" />\n"
    "                    </xsl:otherwise>\n"
    "                  </xsl:choose>\n"
    "                </xsl:when>\n"
    "                <xsl:when test=\"($partitionName = 'NGP' or $partitionName = 'SPG' or $partitionName = 'GLF' "
    "or ($partitionName = 'IRL' and $softwareID = ('517','514','515','516','518','519','520','521','522','523')) "
    "or ($partitionName = 'FPS' and $softwareID = ('314','315','316','317','318','319','320')) "
    "or $softwareID = ('524')) and string-length(Guarantor/admGuarRel) = 0\">"
)
IN1_CAT_OLD = (
    "                      <xsl:when test=\"($partitionName = 'SPG' or $partitionName = 'NGP' or $partitionName = 'HAL' "
    "or ($partitionName = 'NHL' and ($clientName = 'CAT' or $softwareID = ('513','524')))) "
    "and string-length(Insurance1/adminsinsuredrel) = 0\">"
)
IN1_CAT_NEW = (
    "                      <xsl:when test=\"$partitionName = 'NHL' and ($clientName = 'CAT' or $softwareID = ('513','524')) "
    "and string-length(normalize-space(Insurance1/adminsinsuredrel)) = 0\">\n"
    "                        <xsl:choose>\n"
    "                          <xsl:when test=\"mr:relName((Insurance1/subscribername, Insurance1/adminsinsuredname, "
    "Guarantor/admGuarName)[normalize-space(.)][1]) = mr:relName(PatientDemographics/admname)\">\n"
    "                            <xsl:value-of select=\"'SE'\" />\n"
    "                          </xsl:when>\n"
    "                          <xsl:when test=\"number($PatientAge) &lt; 18\">\n"
    "                            <xsl:value-of select=\"'CH'\" />\n"
    "                          </xsl:when>\n"
    "                          <xsl:otherwise>\n"
    "                            <xsl:value-of select=\"'UN'\" />\n"
    "                          </xsl:otherwise>\n"
    "                        </xsl:choose>\n"
    "                      </xsl:when>\n"
    "                      <xsl:when test=\"($partitionName = 'SPG' or $partitionName = 'NGP' or $partitionName = 'HAL') "
    "and string-length(Insurance1/adminsinsuredrel) = 0\">"
)
RELNAME_OLD = "  <!-- Template to calculate age -->\n  <xsl:template name=\"calculateAge\">"
RELNAME_NEW = (
    "  <xsl:function name=\"mr:relName\" as=\"xs:string\">\n"
    "    <xsl:param name=\"n\" as=\"item()*\" />\n"
    "    <xsl:sequence select=\"translate(upper-case(normalize-space(string(($n[normalize-space(string(.))])[1]))), ' ,.^', '')\" />\n"
    "  </xsl:function>\n"
    "  <!-- Template to calculate age -->\n"
    "  <xsl:template name=\"calculateAge\">"
)
HAL_FLG_CHARGE_OLD = (
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT"
    "[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])\" />\n"
    "    <xsl:variable name=\"stripLocationsCount\" select=\"count(/XCSData/query_results/LOCATION/LOCATION"
    "[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) + (if (($Partition = 'HAL' or $SoftwareID = '750') "
    "and translate(upper-case(normalize-space((admLocationAbbr, ../PatientDemographics/admLocationAbbr, $admLocation)[1])), "
    "' ', '') = ('HMC201','HHIPM','TLGI','ORTL')) then 1 else 0) + (if ($Partition = 'NHL' and ($Client = 'CAT' "
    "or $SoftwareID = ('513','524')) and (translate(upper-case(normalize-space($admLocation)), '.', '') = ('REH','RLABND') "
    "or (normalize-space(../PatientDemographics/Filler2) = 'CMCEH' and $admLocation = ('R.EH','R.LAB','R.LABND','RG.LAB')))) "
    "then 1 else 0)\" />"
)
HAL_FLG_CHARGE_NEW = (
    "    <xsl:variable name=\"locAbbr\" select=\"normalize-space((../PatientDemographics/admLocationAbbr, admLocationAbbr)"
    "[normalize-space(.)][1])\" />\n"
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT"
    "[SOFTWARE_ID = $SoftwareID and (CODE = $admLocation or ($locAbbr != '' and translate(upper-case(normalize-space(CODE)), "
    "' .', '') = translate(upper-case($locAbbr), ' .', '')))])\" />\n"
    "    <xsl:variable name=\"stripLocationsCount\" select=\"count(/XCSData/query_results/LOCATION/LOCATION"
    "[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) + (if (($Partition = 'HAL' or $SoftwareID = '750') "
    "and translate(upper-case($locAbbr), ' ', '') = ('HMC201','HHIPM','TLGI','ORTL')) then 1 else 0) + (if ($Partition = 'NHL' "
    "and ($Client = 'CAT' or $SoftwareID = ('513','524')) and (translate(upper-case(normalize-space($admLocation)), '.', '') "
    "= ('REH','RLABND') or (normalize-space(../PatientDemographics/Filler2) = 'CMCEH' and $admLocation = "
    "('R.EH','R.LAB','R.LABND','RG.LAB')))) then 1 else 0)\" />"
)
HAL_FLG_DEMO_OLD = (
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT"
    "[CODE = $admLocation and SOFTWARE_ID = $SoftwareID])\" />\n"
    "    <xsl:variable name=\"stripLocationsCount\" select=\"count(/XCSData/query_results/LOCATION/LOCATION"
    "[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) + (if (($Partition = 'HAL' or $SoftwareID = '750') "
    "and translate(upper-case(normalize-space((admLocationAbbr, ../PatientDemographics/admLocationAbbr, $admLocation)[1])), "
    "' ', '') = ('HMC201','HHIPM','TLGI','ORTL')) then 1 else 0) + (if ($Partition = 'NHL' and ($Client = 'CAT' "
    "or $SoftwareID = ('513','524')) and (translate(upper-case(normalize-space($admLocation)), '.', '') = ('REH','RLABND') "
    "or (normalize-space(Filler2) = 'CMCEH' and $admLocation = ('R.EH','R.LAB','R.LABND','RG.LAB')))) then 1 else 0)\" />"
)
HAL_FLG_DEMO_NEW = (
    "    <xsl:variable name=\"locAbbr\" select=\"normalize-space((admLocationAbbr, ../PatientDemographics/admLocationAbbr)"
    "[normalize-space(.)][1])\" />\n"
    "    <xsl:variable name=\"flaggedCount\" select=\"count(/XCSData/query_results/FLAGGED_ACCOUNT/FLAGGED_ACCOUNT"
    "[SOFTWARE_ID = $SoftwareID and (CODE = $admLocation or ($locAbbr != '' and translate(upper-case(normalize-space(CODE)), "
    "' .', '') = translate(upper-case($locAbbr), ' .', '')))])\" />\n"
    "    <xsl:variable name=\"stripLocationsCount\" select=\"count(/XCSData/query_results/LOCATION/LOCATION"
    "[LOC_MNEMONIC = $admLocation and SOFTWARE_ID = $SoftwareID]) + (if (($Partition = 'HAL' or $SoftwareID = '750') "
    "and translate(upper-case($locAbbr), ' ', '') = ('HMC201','HHIPM','TLGI','ORTL')) then 1 else 0) + (if ($Partition = 'NHL' "
    "and ($Client = 'CAT' or $SoftwareID = ('513','524')) and (translate(upper-case(normalize-space($admLocation)), '.', '') "
    "= ('REH','RLABND') or (normalize-space(Filler2) = 'CMCEH' and $admLocation = "
    "('R.EH','R.LAB','R.LABND','RG.LAB')))) then 1 else 0)\" />"
)


def propose_nhl_cat_guarantor(root: Path) -> list[dict]:
    out: list[dict] = []
    a04 = root / ARA_A04
    if not a04.is_file():
        return out
    text = a04.read_text(encoding="utf-8", errors="replace")
    rec = _replace_ed(
        ARA_A04,
        "Add mr:relName so CAT compares folded guarantor/subscriber names",
        "TEST still leaves GT1.11 blank when FLEMING,BRIANA vs FLEMING, BRIANNA fail an exact string match, "
        "or when age is not a number so none of the CH/UN branches fire.",
        RELNAME_OLD,
        RELNAME_NEW,
        text,
    )
    if rec:
        out.append(rec)
    rec = _replace_ed(
        ARA_A04,
        "Fill blank NHL CAT GT1.11 with folded names and never leave it empty",
        "Rachael: the guarantor issue is still not working. CAT is software 524. Fold case/punctuation, "
        "treat missing age as UN, and trim a whitespace-only relationship.",
        GT1_CAT_OLD,
        GT1_CAT_NEW,
        text,
    )
    if rec:
        out.append(rec)
    rec = _replace_ed(
        ARA_A04,
        "Fill blank NHL CAT IN1.17 from subscriber name, not only guarantor",
        "IN1.17 was comparing Guarantor/admGuarName. Use subscribername / adminsinsuredname first.",
        IN1_CAT_OLD,
        IN1_CAT_NEW,
        text,
    )
    if rec:
        out.append(rec)
    rec = _replace_ed(
        ARA_A04,
        "Fill blank NHL CAT IN1.17 on the PPP / self-pay IN1 as well",
        "Second IN1.17 copy (fewer leading spaces) needs the same CAT subscriber compare.",
        IN1_CAT_OLD.replace("                      <xsl:when", "                    <xsl:when"),
        IN1_CAT_NEW.replace("                      <xsl:when", "                    <xsl:when").replace(
            "\n                        ", "\n                      "
        ),
        text,
    )
    if rec:
        out.append(rec)
    return out


def propose_hal_flg_change(root: Path) -> list[dict]:
    out: list[dict] = []
    strip = root / STRIP_DATA
    if not strip.is_file():
        return out
    text = strip.read_text(encoding="utf-8", errors="replace")
    rec = _replace_ed(
        STRIP_DATA,
        "Match Halifax FLG_LOCATIONS codes to LocationAbbreviation on charges",
        "Karen asked to add HMC 201 / HH IPM / TL GI / OR TL to Strip Location FLG for software 750 HAX. "
        "FLG_LOCATIONS.CODE is compared to admLocation, but the CP map already rewrote those abbrs to HAX, "
        "so a FLG row never hits. Also skip an empty Charge/admLocationAbbr node.",
        HAL_FLG_CHARGE_OLD,
        HAL_FLG_CHARGE_NEW,
        text,
    )
    if rec:
        out.append(rec)
    rec = _replace_ed(
        STRIP_DATA,
        "Match Halifax FLG_LOCATIONS codes to LocationAbbreviation on demographics",
        "Same FLG CODE vs LocationAbbreviation compare for PatientDemographics.",
        HAL_FLG_DEMO_OLD,
        HAL_FLG_DEMO_NEW,
        text,
    )
    if rec:
        out.append(rec)
    return out


def propose_nhl_cat_bug(root: Path) -> list[dict]:
    out: list[dict] = []
    strip = root / STRIP_DATA
    if strip.is_file():
        text = strip.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            STRIP_DATA,
            "Strip NHL CAT charges by Client=CAT, not software 513",
            "TEST looks up SoftwareID from CLIENT_SPLITS. CAT is not 513 (that is FPS Central Lab), "
            "so the first R.EH / R.LABND charge strip never fires on PTH5.CMC. Key it on Client CAT, "
            "accept RLLABND without the dot, and also strip the CMCEH 2ndry pairs on Charge nodes.",
            NHL_CAT_CHARGE_OLD,
            NHL_CAT_CHARGE_NEW,
            text,
        )
        if rec:
            out.append(rec)
        rec = _replace_ed(
            STRIP_DATA,
            "Strip NHL CAT demographics by Client=CAT, not software 513",
            "Same CAT gate for PatientDemographics so R.EH / R.LABND / CMCEH still leave ADT. "
            "Do not strip Huggins/Monadnock demos here — those stay and only lose charges.",
            NHL_CAT_DEMO_OLD,
            NHL_CAT_DEMO_NEW,
            text,
        )
        if rec:
            out.append(rec)
        rec = _replace_ed(
            STRIP_DATA,
            "Match NHL CAT 2ndry CMCEH pairs on Client=CAT",
            "The 2ndry template was gated on SoftwareID 513, so RG.LAB/CMCEH (and the other pairs) "
            "only stripped when someone passed 513 in a demo run.",
            NHL_CAT_2NDRY_OLD,
            NHL_CAT_2NDRY_NEW,
            text,
        )
        if rec:
            out.append(rec)
    a04 = root / ARA_A04
    if a04.is_file():
        text = a04.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            ARA_A04,
            "Fill blank GT1.11 on NHL CAT by client name",
            "Fleming 27148042 still has a blank guarantor relationship because the default was "
            "gated on software 513. Use clientName CAT (software 513/524 still accepted).",
            "or $softwareID = ('524')  or ($partitionName = 'NHL' and $softwareID = '513'))",
            "or $softwareID = ('524')  or ($partitionName = 'NHL' and ($clientName = 'CAT' or $softwareID = ('513','524'))))",
            text,
        )
        if rec:
            out.append(rec)
        rec = _replace_ed(
            ARA_A04,
            "Fill blank IN1.17 on NHL CAT by client name",
            "Same CAT client gate for subscriber relationship. Fleming’s IN1.17 is still blank on TEST.",
            "or ($partitionName = 'NHL' and $softwareID = '513'))",
            "or ($partitionName = 'NHL' and ($clientName = 'CAT' or $softwareID = ('513','524'))))",
            text,
        )
        if rec:
            rec["replace_all"] = True
            out.append(rec)
    route = root / STRIP_ROUTE
    if route.is_file() and (root / CAT_HUGGINS).is_file():
        text = route.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            STRIP_ROUTE,
            "Run the Huggins/Monadnock charge-only strip on NHL CAT",
            "transform-CAT-huggins-monadnock-strip.xslt already strips HUGGINSHOS / MONCOMHOS charges "
            "and keeps demos (868 write-off, XXX.X if ICD blank). It was never on route 2, so the "
            "charge file never saw it.",
            NHL_CAT_ROUTE_OLD,
            NHL_CAT_ROUTE_NEW,
            text,
        )
        if rec:
            out.append(rec)
    return out


DFT_CHARGE_GROUP_OLD = (
    'group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,'
    'radExamBillingCode,radAcctNum)" select="Charge"'
)
DFT_CHARGE_GROUP_NEW = (
    'group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,'
    'radExamBillingCode,radAcctNum)" select="Charge[not(@stripped = \'true\')]"'
)
SITE_STRIP_LC_OLD = (
    "    <xsl:variable name=\"performingSite\" select=\"./performingSite\" />\n"
    "    <xsl:variable name=\"performingSiteCount\" select=\"count(/XCSData/query_results/"
    "STRIP_PERFORMING_SITES/STRIP_PERFORMING_SITES[MNEMONIC = $performingSite])\" />"
)
SITE_STRIP_LC_NEW = (
    "    <xsl:variable name=\"performingSite\" select=\"normalize-space(./performingSite)\" />\n"
    "    <xsl:variable name=\"performingSiteCount\" select=\"count(/XCSData/query_results/"
    "STRIP_PERFORMING_SITES/STRIP_PERFORMING_SITES[normalize-space(MNEMONIC) = $performingSite])\" />"
)


def propose_nhl_cat_lc_dft(root: Path) -> list[dict]:
    out: list[dict] = []
    dft = root / DFT_P03
    if dft.is_file():
        text = dft.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            DFT_P03,
            "Skip stripped charges when writing NHL CAT DFT FT1s",
            "ADT already uses Charge[not(@stripped='true')]. DFT grouped every Charge, so LabCorp "
            "(LC) performing-site strips still became FT1s when demographics stayed.",
            DFT_CHARGE_GROUP_OLD,
            DFT_CHARGE_GROUP_NEW,
            text,
        )
        if rec:
            out.append(rec)
    site = root / SITE_STRIP
    if site.is_file():
        text = site.read_text(encoding="utf-8", errors="replace")
        rec = _replace_ed(
            SITE_STRIP,
            "Trim performing-site mnemonic before STRIP_PERFORMING_SITES lookup",
            "PTH5.CMC performingSite is a 16-character padded field. LC (LabCorp) is stored as "
            "'LC' in STRIP_PERFORMING_SITES, so MNEMONIC = $performingSite never matched.",
            SITE_STRIP_LC_OLD,
            SITE_STRIP_LC_NEW,
            text,
        )
        if rec:
            out.append(rec)
    return out


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


def propose_ara_selfpay_in117(root: Path) -> list[dict]:
    path = root / ARA_A04
    if not path.is_file():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    old = (
        "                    <xsl:otherwise>\n"
        "                      <xsl:value-of select=\"Insurance2/adminsinsuredrel\" />\n"
        "                    </xsl:otherwise>\n"
        "                  </xsl:choose>\n"
        "                </IN1.17>"
    )
    new = (
        "                    <!-- ARA self-pay: Insurance1 IN1 is skipped; relationship lives on Insurance1. -->\n"
        "                    <xsl:when test=\"$partitionName = 'ARA' and Insurance1/adminsmne = 'SELFPAY'\">\n"
        "                      <xsl:choose>\n"
        "                        <xsl:when test=\"string-length(normalize-space(Insurance2/adminsinsuredrel)) != 0\">\n"
        "                          <xsl:value-of select=\"Insurance2/adminsinsuredrel\" />\n"
        "                        </xsl:when>\n"
        "                        <xsl:otherwise>\n"
        "                          <xsl:value-of select=\"Insurance1/adminsinsuredrel\" />\n"
        "                        </xsl:otherwise>\n"
        "                      </xsl:choose>\n"
        "                    </xsl:when>\n"
        "                    <xsl:otherwise>\n"
        "                      <xsl:value-of select=\"Insurance2/adminsinsuredrel\" />\n"
        "                    </xsl:otherwise>\n"
        "                  </xsl:choose>\n"
        "                </IN1.17>"
    )
    rec = _replace_ed(
        ARA_A04,
        "Fill IN1.17 subscriber relationship on the promoted self-pay IN1",
        "The SELFPAY IN1 is skipped, so the outgoing IN1 reads Insurance2/adminsinsuredrel, which is empty. Copy 18 from Insurance1 (InsuredRelationship on the SELFPAY row).",
        old,
        new,
        text,
    )
    return [rec] if rec else []


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
    if is_ara_in117_rel_ask(body, subj):
        extra = propose_ara_selfpay_in117(root)
        edits.extend(extra)
        if extra:
            summary = (
                "Fill blank IN1.17 (subscriber relationship) on Ariana self-pay HL7. "
                "Use InsuredRelationship from the SELFPAY row (18 in Karen’s sample)."
            )
            files = [f for f in files if "Generate ADT A04 HL7" in f["path"]]
            for rec in files:
                rec["hits"] = [h for h in rec.get("hits") or [] if h.get("code") in ("IN1.17", "SELFPAY", "adminsinsuredrel")][:12]
            risks.extend(
                [
                    "IN1.16 subscriber name from the earlier Ariana request stays as-is.",
                    "Self-pay with a real secondary still sends Insurance2 as IN1.1=0001; IN1.17 then uses Insurance2’s relationship when it is present.",
                    "This is the ADT A04 IN1. DFT does not emit IN1.17.",
                ]
            )
    elif is_ara_in116_ask(body, subj):
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
    elif not dive_data.get("build_plan"):
        lines.append("- No matching lines found under eip-root.")
    if dive_data.get("build_plan"):
        for sec in dive_data["build_plan"]:
            lines += ["", f"## {sec.get('title') or 'Section'}"]
            for p in sec.get("paras") or []:
                lines.append(p)
                lines.append("")
            for b in sec.get("bullets") or []:
                lines.append(f"- {b}")
            if sec.get("bullets"):
                lines.append("")
    if dive_data.get("edits") or not dive_data.get("build_plan"):
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
    elif not dive_data.get("build_plan"):
        lines.append("- Nothing the hub can apply automatically yet. Review the hits above in eiConsole.")
    if dive_data.get("risks"):
        lines += ["", "## Watch-outs", *[f"- {r}" for r in dive_data["risks"]]]
    already = any(e.get("already_applied") for e in dive_data.get("edits") or [])
    start = dive_data.get("start_work") or (
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
        path.write_text(
            text.replace(old, new) if ed.get("replace_all") else text.replace(old, new, 1),
            encoding="utf-8",
        )
        n = text.count(old) if ed.get("replace_all") else 1
        applied.append({"path": rel, "replaced": n})
    return applied
