# Medical Lab HL7 LLP → MEDITECH — Design

## 1. Purpose
Demo slice of the [Large-Scale Laboratory Interoperability](https://healthcare.pilotfishtechnology.com/case-studies-medical-lab-integration/) case study: **lab ORU results inbound over HL7 LLP**, validate, then **forward to MEDITECH over HL7 LLP** with MLLP ACKs.

## 2. Context / actors
- Sources: Medical Lab (ORU^R01) via MLLP
- Destinations: MEDITECH (mock MLLP sink), audit files, SQL log
- Demo vs production: **Demo only** (shared SA password, mock MEDITECH, heuristic/HAPI parse validation — not partner certification)

## 3. Inbound contract
- Transport: **HL7 LLP** (`HL7TCPListener`) host port **2575**
- Format: HL7 v2.x ORU^R01 (pipe-delimited), MLLP framed
- Identity: MSH-10 control ID
- Samples: `samples/LAB_ORU_R01_glucose.hl7`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| MEDITECH (mock) | HL7 LLP `:2576` | Mock returns AA; message under `output/meditech-received/` |
| Audit file | Raw HL7 | File under `output/meditech-outbound/` |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.hl7.HL7TCPListener` | Port 2575, Engine=PilotFish, **async** AutogenerateSynchronousACK=true (immediate AA; sync ACK hung client in smoke test on 23R1) |
| Archive | `FileWriteProcessor` | `output/inbound/` |
| Validate | `com.pilotfish.eip.modules.hl7.HL7ValidationProcessor` | HAPI parse; ThrowException=true (fail-closed) |
| Audit outbound | `FileWriteProcessor` | `output/meditech-outbound/` |
| Router | `com.pilotfish.eip.modules.internal.NullRoutingModule` | All Targets — raw HL7 is not XML, so no XPath router |
| Transport | `com.pilotfish.eip.modules.hl7.HL7SimpleTransport` | Host `meditech-mock` Port 2576 |

**FQCN sources:** `PilotFish_Documentation` tracker (HL7 LLP / HL7 MLLP Simple) + `PilotFish_V2` `modules.conf` / `format-hl7` Java. No deep-dive PDF yet for LLP — config from V2 descriptors. Image: `pilotfish-eip:23R1` (possible skew vs 26R1 docs).

## 6. State & idempotency
- No SQL claim cycle; evidence is files + MLLP ACK
- Dedup: demo does **not** enforce unique ControlId (accepted risk)
- Poison: invalid HL7 throws in validation → sync AE ACK; nothing sent to MEDITECH

## 7. Validation
- What is checked: HAPI pipe parse (`HL7ValidationProcessor`)
- What is NOT checked: full lab ORU IG, ASTM, X12 billing from the case study
- Failure blocks outbound: **yes** (`ThrowException=true`)

## 8. Dual-write / side effects
- Order: archive → validate → outbound file → LLP to MEDITECH
- File audit + LLP are sequential processors then transport (not a fan-out dual-write)

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | Case study scope reduced | Full case study includes X12 837/835, CSV, positional, ACORD | Accepted — LLP ORU slice only |
| Med | 23R1 vs V2/26R1 module APIs | Config tags from V2 source | Smoke-test; fix tags if load fails |
| Med | Async AA before MEDITECH completes | Sync ACK did not return to client in smoke | Accepted demo risk; document in README |
| Low | No ControlId uniqueness | Resend duplicates | Accepted |

## 10. Ops
- Ports: EIP **8098**, Web UI **8099**, LLP in **2575**, MEDITECH mock **2576**
- Volumes: `./output`, `./logs`, `./samples`
- Heap: 2GB (no SNIP)
- Cold start: ~60–90s EIP

## 11. Observability
- Logs: `logs/eip.log`
- Artifacts: `output/inbound`, `output/meditech-outbound`, `output/meditech-received`
- debuggingTrace: true (demo)

## 12. Open questions
- None for this slice; future: ORM inbound, ASTM, X12 billing routes.
