# EDI 276/277 Claim Status — Design

Status: **WORKING**

## 1. Purpose

Ingest X12 **276** claim status requests, look up a demo catalog by trace number (no SQL), stage a `ClaimStatusDecision`, then emit an X12 **277** response and file buckets (`found` / `not-found` / `error`). Demo only — not a clearinghouse.

## 2. Context / actors

- Source: provider drop folder `input/inbound/*.edi`
- Destinations: `output/found`, `output/not-found`, `output/error`, `output/responses/*.edi` (277), debug XML
- Catalog is in-XSLT by `TraceNumber` — no claim master, no FHIR

## 3. Inbound contract

- Transport: `DirectoryListener`
- Format: X12 **276** (005010X212), TableData `276-A1`
- Identity: first `TRN02` (fallback `BHT03`) → `TraceNumber`; `NM1*IL*NM109` → `MemberId`; `REF*EJ` → `ClaimId`
- Samples: `samples/X212-276-claim-request.edi` (ABCXYZ1/2/3 in one ST — fork is `//Transaction`, first TRN wins)

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Found / not-found / error | XML `ClaimStatusDecision` | File under matching `output/<bucket>/` |
| 277 response | Real X12 from `EDITransformationProcessor` | `ST*277` under `output/responses/{TraceNumber}_277_response.edi` |

## 5. Pipeline

| Stage | Module | Notes |
|-------|--------|-------|
| R1 Listener | `DirectoryListener` | Poll inbound; Move → archive |
| R1 Format | TableData `276-A1` + fork `//Transaction` | Extract is a **target** processor |
| R1 | Pretty-print → debug txn XML → XSLT catalog → pretty-print → debug decision | Unique Pretty-Print names |
| R1 Transport | `DirectoryTransport` | Stage `output/staged-decisions/` |
| R2 Listener | `DirectoryListener` | Poll staged XML; Delete |
| R2 Router | `XPathRoutingModule` accumulate=true | 277 when `DecisionBucket` present; buckets by value |
| R2 277 | XSLT → XCSData → pretty debug XML → **XML to EDI** `277-A1` | Do not hardcode `ISA*` as text |
| R2 buckets | Pretty-print then DirectoryTransport | Unique names per bucket |

**Catalog:** `ABCXYZ1` found/F1; `ABCXYZ2` found/P1; `ABCXYZ3` not-found/E1; incomplete identity → error/`MISSING_IDENTITY`.

**FQCN sources:** `edi-278-prior-auth` directory + XPath router + XML-to-EDI; `edi-835-payment-integrity` EDI fork. Image: `pilotfish-eip:23R1`.

## 6–9. State / validation / risks

File theater only. Unparseable EDI fails closed. First TRN per ST only. Synthetic 277 is not clearinghouse-certified.

## 10. Ops

- Ports: EIP **8126**, Web UI **8127** (no SQL)
- LAN: `http://192.168.68.62:8127/`
- TableData: `../../../../../EDI/TableData/x12` → `edi-tabledata`
- Heap: 512M–2G
