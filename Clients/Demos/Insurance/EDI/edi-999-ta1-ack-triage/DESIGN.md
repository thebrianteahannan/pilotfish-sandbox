# EDI 999 / TA1 Acknowledgment Triage

Status: **IN PROGRESS** (progressive build — pitch §3)

## 1. Purpose
Ingest inbound X12 **999** (implementation acknowledgment) and **TA1** (interchange acknowledgment) files, classify accept vs reject vs error, and bucket results with a human-readable exception report. Shows production-ops maturity after “files out” demos (837/835).

## 2. Actors
- Clearinghouse / payer (sends 999/TA1)
- Provider RCM / billing ops (consumes triage buckets)
- PilotFish (normalize, classify, route)

## 3. Pipeline

| Stage | Module | Role |
|-------|--------|------|
| Listen | Directory / File Listener | Poll `input/` for `.edi` / `.999` / `.ta1` |
| Transform | EDI (source format or processor) | EDI → XML (999-A1 tables) |
| Fork | XPath Fork | Split `//Transaction` when multi-ST |
| Extract | XPath Evaluation | AK9 / IK5 / TA1 codes → attributes |
| Decide | XSLT | Build `AckDecision` XML |
| Route | Conditional Node Router | accepted / rejected / error |
| Emit | Directory transports | Bucket files + ops report |

## 4. Kickouts
- **accepted** — AK9=`A` or all IK5=`A` / TA1=`A`
- **rejected** — AK9=`R`/`E`/`P` with rejects, or TA1 reject codes
- **error** — unparseable / unknown ST

## 5. Samples
- `samples/999-partial-accept.edi` (TableData X231 example)
- `samples/999-all-accept.edi`
- `samples/ta1-accept.edi`

## 6. Ops
- Web UI (stage): http://localhost:8129/
- LAN: http://192.168.68.62:8129/
- EIP (planned): http://localhost:8128/eip/
- Pitch source: `docs/pitches/Healthcare_Insurance_PilotFish_Opportunity_Ideas.pdf` §3 (277CA / 999 / TA1)

## 10. Risks
- Full EDI tabledata path must match runtime mount when EIP is added
- TA1 vs 999 classification uses XPath heuristics suitable for demo, not full SNIP
