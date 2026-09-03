# EDI 834 CSV Excel Conversion — Design

Status: **READY**

Public tutorial this demo recreates: [X12 EDI 834 Data Conversion](https://healthcare.pilotfishtechnology.com/videos/edi-csv-excel-834-conversion-tutorial/)

## 1. Purpose

Enrollment teams often have CSV, tab-delimited TXT, or Excel — not X12. This demo picks up those files, maps them to HIPAA 834 enrollment XML, and writes a flat 834. The same mapping runs in reverse so an 834 becomes CSV for analytics.

## 2. Context / actors

- Sources: enrollment CSV / TXT (Excel is normalized to CSV in the Web UI on 23R1)
- Destinations: X12 834 file; reverse path writes CSV
- Demo vs production: synthetic members only. No SNIP gate, no real payer.

## 3. Inbound contract

- Transport: Directory / File listener
- Format: header row + member columns (`MemberId`, `LastName`, `FirstName`, `BirthDate`, `GenderCode`, `RelationshipCode`, `MaintenanceTypeCode`, `PlanId`, `CoverageStartDate`, sponsor/payer ids)
- Identity fields: `MemberId` (REF*0F)
- Samples path: `samples/`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| `output/834/` | X12 834 (`005010X220A1`) | File contains `ST*834` and member `NM1*IL` |
| `output/csv/` | CSV (reverse) | Header + one row per Loop 2000 |
| `output/kickout/` | original / note | Empty or unmappable inbound |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener (fwd) | `com.pilotfish.eip.modules.file.DirectoryListener` | Polls `input/inbound` for `.csv` / `.txt` |
| Processors (fwd) | `EDITransformationProcessor` | Format XSLT writes 834 XML; processor renders flat 834 |
| Router (fwd) | `XPathRoutingModule` | Members present → 834; else kickout |
| Transports (fwd) | `DirectoryTransport` | Write `.edi` or kickout |
| Listener (rev) | `DirectoryListener` | Polls `input/edi` for `.edi` / `.834` |
| Processors (rev) | (none — EDI parse + XSLT + CSV are Formats) | 834 → XML → CSV |
| Transports (rev) | `DirectoryTransport` | Write `.csv` |

FQCNs are from PilotFish Documentation / `PilotFish_V2` `modules.conf`. Runtime is V1 `route.xml` on `pilotfish-eip:23R1`.

X12 table data: `EDI/TableData/x12/834-A1` mounted at `eip-root/edi-tabledata/834-A1`, `UseInternalData=false`, version `5010`.

## 6. State & idempotency

- Status model: file archive after poll (Move)
- Dedup keys: inbound filename
- Retry / poison: kickout folder; no automatic retry

## 7. Validation

- What is checked: at least one member row with `MemberId` or `LastName`
- What is NOT checked: SNIP 1–7, full 834 situational rules
- Does failure block outbound?: yes (kickout instead of 834)

## 8. Dual-write / side effects

- Order of commits: archive inbound, then write 834 or CSV
- Compensation: none
- Demo shortcuts: Excel `.xlsx` is converted to CSV in the Web UI. `ExcelSheetProcessor` is documented for 26R1.11 and is not assumed on the 23R1 image.

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| Med | 23R1 vs 26R1 Excel module | Excel Sheet Converter deep-dive is 26R1.11 | Web UI normalizes xlsx → CSV; accepted |
| Med | Trial X12 tables expired | Internal table data fails parse/render | Mount `834-A1`, `UseInternalData=false` |
| Low | Friendly names on large 834s | Tutorial mentions turning them off | `FriendlyNamesLevel=None`, `CODE_DEFS=false` |

## 10. Ops

- Ports: Web UI **8140**, EIP **8139**
- Compose project: `edi-csv-excel-834`
- Volumes: `input/`, `output/`, `logs/`, `EDI/TableData/x12` → `edi-tabledata`
- Heap: 512M–2048M (no SNIP)
- Cold start: ~60–90s for EIP

## 11. Observability

- Logs: `logs/eip.log`
- Kickout dir: `output/kickout`
- Transaction / debug tracing: off

## 12. Open questions

- None for the first cut. SNIP-after-map can be added later like the tutorial mentions.
