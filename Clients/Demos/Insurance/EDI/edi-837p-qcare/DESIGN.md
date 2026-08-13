# EDI 837P to QCare — Design

Status: **WORKING**

## 1. Purpose

Directory-poll X12 **837P** professional claims, parse with PilotFish EDI TableData (`837-Q1`), and map each `ST` to QCare’s **2100-byte** outpatient (`OT` / `B837`) flat-file record. Demo only — golden-path fidelity against client samples, not full WTX/ITX parity.

## 2. Context / actors

- Source: operator dropping `*.txt` / `*.edi` / `*.837` into `input/inbound`
- Destinations: QCare text under `output/qcare/`; archived EDI under `output/archive/`; debug EDI XML under `output/debug/`
- Demo vs production: synthetic/client sample PHI; no SNIP gate; REPOSHDR claim numbering is a demo-stable header, not byte-identical to staged WTX

## 3. Inbound contract

- Transport: Directory / File (`DirectoryListener`)
- Format: X12 **837P** (005010X222A1), TableData IG `837-Q1`
- Identity: `CLM01` patient control; `ST02` transaction control
- Samples: `samples/MCQRQ74837PS801.TXT`, `…802.TXT`, `…803.TXT` (803 = STONE / SHARON / procedure 70487)

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| `output/qcare` | Fixed-width text, **2100** chars/record + newline | File written; line contains STONE, SHARON, 70487 |
| `output/archive` | Original 837P | Listener Move post-process |
| `output/debug` | Pretty EDI XML | One snapshot per forked transaction |

## 5. Pipeline

| Stage | Module | Notes |
|-------|--------|-------|
| Listener | `DirectoryListener` | Poll `$$EDI_INBOUND_DIRECTORY`; Move → archive |
| Format | EDI TableData `837-Q1` + XPath fork `//Transaction` | `UseInternalData=false`; `USE_ENHANCED_CONTEXT=true` |
| Target | XPath Extract Claim Identity (after fork) | Source processors see raw EDI — do not extract on the source |
| Target | XML Formatting → FileWrite debug XML | Pretty-print **before** the XML write |
| Target | XSLT `transform-837p-to-qcare.xslt` `method=text` | No XML Formatting after the text map |
| Transport | `DirectoryTransport` | `{CLM01}_qcare.txt` |

**FQCN sources:** `edi-278-prior-auth` DirectoryListener + DirectoryTransport; `edi-835-payment-integrity` Split 835 format (IG swapped to `837-Q1`). Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

File presence only (no SQL). Listener Moves inbound to archive after pick-up; QCare overwrite by basename.

## 7. Validation

EDI parses via TableData; outbound record length 2100; golden-path slices in automated tests. Not checked: SNIP 1–7; full 336-field WTX parity; REPOSHDR identity vs staged.

## 8. Dual-write / side effects

Archive Move (listener) then debug XML + QCare. Accepted demo risk: archive can succeed while map/write fails.

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation / accepted? |
|----------|------|------------------------|
| High | Not full WTX parity | Golden-path subset |
| Med | REPOSHDR claim numbering | Demo-stable header; tests exclude exact header match |
| Med | Archive-before-QCare | Accepted demo risk |
| Med | Multi-LX claims | Fork is `//Transaction` only; samples are 1 LX |
| Low | PHI in samples | Demo-only; do not publish |

## 10. Ops

- Ports: EIP **8123**, Web UI **8125** (no SQL)
- LAN: `http://192.168.68.62:8125/`
- Heap: 512M–2G
- TableData: `../../../../../EDI/TableData/x12` → `edi-tabledata`

## 11. Observability

`logs/eip.log`. debuggingTrace true (demo).

## 12. Open questions

Fork per `LX` / 2400 service line for multi-line claims?
