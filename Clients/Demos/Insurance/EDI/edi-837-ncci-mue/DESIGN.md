# EDI 837 NCCI MUE — Design

Status: **WORKING**

## 1. Purpose

Show that PilotFish can apply **CMS Medically Unlikely Edits (MUE)** as a business-rule layer on X12 **837P** claims: look up each service line’s CPT/HCPCS against an external MUE table and kick out lines whose units exceed the max. There is **no stock PilotFish NCCI/MUE module** — this is the same catalog + XSLT pattern already used in **Med Rec** (`MUE_EDITS.CPT` / `MAX_VALUE_PER_LINE`), pointed at 837 instead of HL7 DFT.

## 2. Context / actors

- Sources: Directory-drop 837P (`input/inbound/*.edi`)
- Destinations: `output/pass/` (within MUE limit), `output/kickout/` (units exceeded)
- Demo vs production: **Demo only** — synthetic CMS-shaped table (not the official quarterly NCCI files). Production would load CMS MUE CSVs into SQL (or a file lookup) on the CMS publish cycle.
- Sibling demo: `edi-837-ncci-ptp` (procedure-to-procedure pairs). Med Rec does **not** implement PTP.

## 3. Inbound contract

- Transport: Directory / File (`DirectoryListener`)
- Format / envelope: X12 **837P** 005010X222A1, `//Transaction` fork (one `ST` per claim)
- Identity fields: `CLM01` claim control #; first `SV1` CPT (`SV101-02`) + units (`SV104`)
- Samples path: `samples/sample_837p_mue.edi`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Pass bucket | Pretty-printed `MueDecision` XML | File under `output/pass/` when units ≤ MUE max (or CPT not in catalog) |
| Kickout bucket | Pretty-printed `MueDecision` XML | File under `output/kickout/` when units > MUE max |
| MUE catalog SQL | Seeded `dbo.MueEdits` | Web UI `/api/mue-edits` shows CPT + MaxUnits |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `com.pilotfish.eip.modules.file.DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY`. Skeleton: `edi-837p-qcare` |
| R1 Format | `EDITransformationModule` + `XPathForkingModule` `//Transaction` | TableData `edi-tabledata/837-Q1` (5010). Playbook §3.6. Docs 26R1.11 vs image 23R1. |
| R1 Target processors | XPath identity → XSLT line extract → `DatabaseSqlProcessor` `MueEdits` → XSLT decision | Catalog shape matches Med Rec `MUE_EDITS` (CPT + max units per line). SQL processor skeleton: `edi-835-payment-integrity` |
| R1 Transport | `DirectoryTransport` + **XML Formatting on the transport** | Stage under `output/staged-decisions/` (playbook §1.4) |
| R2 Listener | `DirectoryListener` | Poll staged decisions |
| R2 Router | `XPathRoutingModule` accumulate=true | `//MatchBucket` = `pass` / `kickout` |
| R2 Transports | `DirectoryTransport` | Unique Pretty-Print names per target |

**FQCN sources:** `edi-837p-qcare`, `edi-835-payment-integrity`, Med Rec `MUE_EDITS` / DFT split XSLT, PilotFish Documentation 26R1.11. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Status model: none (stateless file buckets). Catalog is read-only seed.
- When state advances: after `MueDecision` is staged and routed
- Dedup keys: `CLM01` (overwrite same filename on resubmit)
- Retry / poison: unparseable 837 fails at EDI→XML (fail-closed)

## 7. Validation

- What is checked: EDI parses; first SV1 CPT looked up in `MueEdits`; billed units vs `MaxUnits`
- What is NOT checked: SNIP 1–7, MAI 2/3 date-of-service aggregation, multi-line MUE (demo is one SV1 per ST), official CMS file ingest, PTP (see sibling demo)
- Does failure block outbound? yes for unparseable EDI; kickout theater for MUE exceed

**Med Rec vs this demo:** Med Rec **splits** DFT FT1 charges so each line stays at `MAX_VALUE_PER_LINE` (provider billing). Karthik asked for a **payer/NCCI validation layer** on 837 — this demo **kickouts** instead of splitting. Same table, different outbound policy.

## 8. Dual-write / side effects

- Order: decision XML → route to pass or kickout file
- Compensation: none
- Demo shortcuts: one procedure line per claim; synthetic four-row catalog; pass-through of original 837 is not re-emitted (decision XML is the artifact)

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | No stock NCCI module | Product has SNIP, not CMS MUE/PTP tables | Honest: catalog + stock processors. No extra PilotFish NCCI SKU. |
| Med | 23R1 trial X12 tables expired | Sandbox mounts `EDI/TableData/x12` | Named-segment EDI XML via Sandbox TableData |
| Med | Official CMS quarterly files not loaded | Demo seed only | Document production ingest (CSV → SQL) |
| Med | Duplicate processor names | EIP refuses the route | Unique Pretty-Print names |
| Low | SQLXML tags UPPERCASE | `//MaxUnits` misses `MAXUNITS` | XPath matches both |
| Low | Em-dash / non-ASCII in SQL Description | XML Formatting + XPath router reject `0x14` | ASCII hyphens in catalog text |
| Low | Multi-SV1 claims | Extract uses first SV1 | Sample is one line per ST |

## 10. Ops

- Ports: SQL **14342**, EIP **8130**, Web UI **8131**
- Volumes: `./input`, `./output`, `./logs`, `./samples`, `./documents`, TableData mount
- Heap: 512M–2GB
- Dependencies / cold start: SQL health + seed ~30–60s, EIP ~60–90s
- Credentials: `sa` / `PilotFish_Demo1!` · `Edi837NcciMue`

## 11. Observability

- Logs: `logs/eip.log`
- Kickout dir: `output/kickout/`
- debuggingTrace: true (demo)

## 12. Open questions

- Load a real CMS MUE quarterly extract in a later pass?
- Split-to-limit (Med Rec DFT policy) as an optional pass-path rewrite?

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837-ncci-mue --wait
```

15/15 passing (2026-08-13).
