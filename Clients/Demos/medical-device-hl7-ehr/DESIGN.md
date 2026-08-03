# Medical Device HL7 → EHR — Design

Case study: [Medical Device HL7 EHR Integration Platform](https://healthcare.pilotfishtechnology.com/medical-device-integration-case-study/)

## 1. Purpose
Demo slice: **two mocked bedside devices** send HL7 ORU observations into PilotFish over LLP; EIP validates and forwards **HL7 2.x** to a mocked EHR LLP endpoint.

## 2. Context / actors
- Sources (mocked):
  1. **Bedside Vital Signs Monitor** (`VITALMON`) — HR, SpO2, NIBP
  2. **Continuous Glucose Monitor** (`CGM01`) — interstitial glucose
- Destination: Hospital EHR mock (`EHR_MOCK`) via HL7 LLP
- Demo vs production: **Demo only**

## 3. Inbound contract
- Transport: HL7 LLP (`HL7TCPListener`) host **2580**
- Format: HL7 v2.5.1 `ORU^R01`
- Identity: MSH-10; device id in MSH-3
- Samples: `samples/VITALS_ORU_*.hl7`, `samples/CGM_ORU_*.hl7`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| EHR mock LLP `:2581` | HL7 ORU | Mock AA + file in `output/ehr-received/` |
| Audit | Raw HL7 | `output/ehr-outbound/` |
| Inbound archive | Raw HL7 | `output/inbound/` |

## 5. Pipeline
| Stage | Module | Notes |
|-------|--------|-------|
| Listener | `HL7TCPListener` | :2580, PilotFish, async auto-ACK |
| Archive | `FileWriteProcessor` | inbound |
| Validate | `HL7ValidationProcessor` | ThrowException=true |
| Audit | `FileWriteProcessor` | ehr-outbound |
| Router | `NullRoutingModule` | All Targets (raw HL7) |
| Transport | `HL7SimpleTransport` | `ehr-mock:2581` |

FQCNs from `PilotFish_Documentation` tracker + `PilotFish_V2` `format-hl7` / `modules.conf`. Runtime V1 on `pilotfish-eip:23R1`.

## 6–8. State / validation / side effects
- Fail-closed HAPI parse before EHR send
- Async AA (same 23R1 sync-ACK limitation as lab demo)
- No SQL; evidence is files + ACK
- Scope excludes PDF reports, FHIR, demographics enrollment from the case-study diagram

## 9. Risks
| Sev | Risk | Accepted? |
|-----|------|-----------|
| High | Case study broader than demo | Yes — ORU LLP slice + 2 devices |
| Med | Async ACK before EHR durable | Yes |
| Low | Device sims are software emitters, not real IoT | Yes |

## 10. Ops
- EIP **8100**, Web UI **8101**, device LLP **2580**, EHR mock **2581**
