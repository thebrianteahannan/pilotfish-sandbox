# EDI 837P to QCare — Design

## 1. Purpose

Demo that polls a drop folder for X12 **837P** professional claims, parses them with PilotFish EDI TableData (`837-Q1`), and maps each transaction to QCare’s **2100-byte** fixed-width outpatient (`OT`/`B837`) flat-file record for downstream claims systems. Demo only — golden-path fidelity against client samples, not full WTX/ITX parity.

## 2. Context / actors

- Sources: Clearinghouse / operator dropping `*.txt` / `*.edi` 837P into `input/inbound`
- Destinations: QCare flat files under `output/qcare/`; archived EDI under `output/archive/`; debug EDI XML under `output/debug/`
- Demo vs production: **Demo only** — synthetic/client sample PHI; no SNIP gate; REPOSHDR claim numbering approximated

## 3. Inbound contract

- Transport: Directory / File (`DirectoryListener`)
- Format / envelope: X12 **837P** (005010X222A1), TableData IG `837-Q1`
- Identity fields: `CLM01` patient control number; `ST02` transaction control
- Samples path: `samples/MCQRQ74837PS801.TXT`, `…802.TXT`, `…803.TXT`
- Golden expected: `samples/expected/qcare…SEQF.staged` (3 × 2100-byte records)

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| `output/qcare` | Fixed-width text, **2100** chars/record + newline | File written; key golden slices match (member, names, NPI, CLM, DX, procedure) |
| `output/archive` | Original 837P | Listener Move post-process |
| `output/debug` | EDI XML | One XML snapshot per forked transaction |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.file.DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY`; Move → archive |
| Format | `com.pilotfish.eip.modules.transform.edi.EDITransformationModule` + `XPathForkingModule` `//Transaction` | `UseInternalData=false`, `USE_ENHANCED_CONTEXT=true`, `TransactionDataWithVersion` → `edi-tabledata/837-Q1` @ 5010 |
| Target processors | `FileWriteProcessor` → `XSLTProcessor` (`transform-837p-to-qcare.xslt`, method=text) | Fixed-width partner format (not X12 generation) |
| Transport | `com.pilotfish.eip.modules.file.DirectoryTransport` | `$$QCARE_OUTPUT_DIRECTORY` |

**FQCN sources:** Sandbox `edi-835-payment-integrity` FormatProfile + `csv-to-json` directory skeleton + playbook §3.6. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Status model: file presence only (no SQL)
- When state advances: listener Moves inbound to archive after pick-up; QCare overwrite by basename
- Dedup keys: none (demo overwrite)
- Retry / poison: unparseable EDI fails the transaction (see `logs/eip.log`); no separate kickout router in v1

## 7. Validation

- What is checked: EDI parses via TableData; outbound record length 2100; golden-path field slices in automated tests
- What is NOT checked: SNIP Types 1–7; full 336-field WTX parity; `REPOSHDR` / `RecordSequence#` claim-number identity vs staged; custom `UB4_*` / prepaid CAS lookups
- Does failure block outbound? Yes for unparseable EDI

## 8. Dual-write / side effects

- Order of commits: archive Move (listener) then QCare + debug writes
- Compensation: none — accepted demo risk that archive can succeed while map/write fails
- Demo shortcuts: claim-site / claim-number block (pos 7–25) derived from BHT/GS + demo sequence, not byte-identical to staged REPOSHDR values

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | Not full WTX parity | 336 leaf fields + undocumented custom funcs | Golden-path subset; Risks labeled |
| Med | REPOSHDR claim numbering | Not present on 837 wire | Demo-stable derivation; tests exclude exact header match |
| Med | Archive-before-QCare | Listener Move | Accepted demo risk |
| Med | Multi-LX claims | Fork is `//Transaction` only | Samples are 1 LX; follow-up to fork LX |
| Low | PHI in samples | Client zip content | Demo-only mounts; do not publish |

## 10. Ops

- Ports: EIP **8123**, Web UI **8125** (no SQL)
- Compose project: `edi-837p-qcare`
- LAN: `LAN_HINT=http://192.168.68.62:8125/` (re-detect on spin-up)
- Volumes: `./input`, `./output`, `./logs`, `EDI/TableData/x12` → `edi-tabledata`
- Heap: 512M–2G
- Cold start: EIP ~60–90s

## 11. Observability

- Logs: `logs/eip.log`
- Kickout: fail-closed via EIP log (no dedicated kickout dir router in v1)
- debuggingTrace: true (demo)

## 12. Open questions

- Fork per `LX` / 2400 service line for multi-line claims?
- Port remaining Excel map rows after golden-path acceptance?
