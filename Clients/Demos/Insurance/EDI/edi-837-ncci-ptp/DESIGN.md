# EDI 837 NCCI PTP — Design

Status: **WORKING**

## 1. Purpose

Show that PilotFish can apply **CMS Procedure-to-Procedure (PTP)** NCCI edits as a business-rule layer on X12 **837P** claims: look up two procedure codes on the same encounter against an external PTP table and kick out pairs that should not be billed together unless an allowed modifier is present. There is **no stock PilotFish NCCI/PTP module**. Med Rec already does **MUE** (units per CPT) for HL7 DFT; this demo is the pair half of that same catalog-plus-processor pattern, pointed at 837.

## 2. Context / actors

- Sources: Directory-drop 837P (`input/inbound/*.edi`)
- Destinations: `output/pass/` (no pair, or modifier allowed), `output/kickout/` (NCCI pair without a valid exception)
- Demo vs production: **Demo only** — two synthetic PTP rows (not official CMS quarterly files). Production would load CMS PTP CSVs into SQL on the CMS publish cycle.
- Sibling demo: `edi-837-ncci-mue` (units vs max). Same 837 intake pattern.

## 3. Inbound contract

- Transport: Directory / File (`DirectoryListener`)
- Format / envelope: X12 **837P** 005010X222A1, `//Transaction` fork
- Identity fields: `CLM01`; first two `SV1` CPT codes; modifier on the second SV1 (`SV101-03` / `HC:cpt:59`)
- Samples path: `samples/sample_837p_ptp.edi`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Pass bucket | Pretty-printed `PtpDecision` XML | File under `output/pass/` when no pair, modifier allowed (indicator 1), or indicator 9 |
| Kickout bucket | Pretty-printed `PtpDecision` XML | File under `output/kickout/` when indicator 0, or indicator 1 without 59/XE/XP/XS/XU |
| PTP catalog SQL | Seeded `dbo.PtpEdits` | Web UI `/api/ptp-edits` shows Column1/Column2/ModifierIndicator |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `com.pilotfish.eip.modules.file.DirectoryListener` | Poll inbound. Skeleton: `edi-837-ncci-mue` |
| R1 Format | `EDITransformationModule` + `XPathForkingModule` `//Transaction` | TableData `edi-tabledata/837-Q1` (5010) |
| R1 Target processors | XPath identity → XSLT pair extract → `DatabaseSqlProcessor` `PtpEdits` → XSLT decision | Symmetric Column1/Column2 lookup |
| R1 Transport | `DirectoryTransport` + XML Formatting on the transport | Stage under `output/staged-decisions/` |
| R2 Listener | `DirectoryListener` | Poll staged decisions |
| R2 Router | `XPathRoutingModule` accumulate=true | `//MatchBucket` = `pass` / `kickout` |
| R2 Transports | `DirectoryTransport` | Unique Pretty-Print names per target |

**FQCN sources:** `edi-837-ncci-mue`, `edi-835-payment-integrity`, CMS PTP modifier indicator (0/1/9). Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Status model: none (stateless file buckets). Catalog is read-only seed.
- When state advances: after `PtpDecision` is staged and routed
- Dedup keys: `CLM01` (overwrite same filename on resubmit)
- Retry / poison: unparseable 837 fails at EDI→XML (fail-closed)

## 7. Validation

- What is checked: EDI parses; first two SV1 CPTs looked up in `PtpEdits`; modifier indicator vs modifier 59/X{E,P,S,U}
- What is NOT checked: SNIP 1–7, MUE units (sibling demo), full CMS PTP file, later-line combinations beyond the first two SV1s, medically necessary exception documentation
- Does failure block outbound? yes for unparseable EDI; kickout theater for PTP hits

## 8. Dual-write / side effects

- Order: decision XML → route to pass or kickout file
- Compensation: none
- Demo shortcuts: two synthetic pairs; original 837 is not re-emitted

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | No stock NCCI module | Product has SNIP, not CMS PTP tables | Honest: catalog + stock processors. No extra PilotFish NCCI SKU. |
| Med | 23R1 trial X12 tables expired | Sandbox mounts `EDI/TableData/x12` | Named-segment EDI XML via Sandbox TableData |
| Med | Official CMS quarterly files not loaded | Demo seed only | Document production ingest (CSV → SQL) |
| Med | Duplicate processor names | EIP refuses the route | Unique Pretty-Print names |
| Low | Em-dash / non-ASCII in SQL Description | XML Formatting + XPath router reject `0x14` | ASCII hyphens in catalog text |
| Low | Only first two SV1s evaluated | Multi-line claims | Sample is 1-2 lines per ST |

## 10. Ops

- Ports: SQL **14343**, EIP **8132**, Web UI **8133**
- Volumes: `./input`, `./output`, `./logs`, `./samples`, `./documents`, TableData mount
- Heap: 512M–2GB
- Dependencies / cold start: SQL health + seed ~30–60s, EIP ~60–90s
- Credentials: `sa` / `PilotFish_Demo1!` · `Edi837NcciPtp`

## 11. Observability

- Logs: `logs/eip.log`
- Kickout dir: `output/kickout/`
- debuggingTrace: true (demo)

## 12. Open questions

- Load a real CMS PTP quarterly extract in a later pass?
- Evaluate all SV1 combinations, not just the first two lines?

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837-ncci-ptp --wait
```

15/15 passing (2026-08-13).
