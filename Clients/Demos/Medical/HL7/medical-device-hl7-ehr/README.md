# Medical Device HL7 → EHR Demo

Focused slice of the [Medical Device HL7 EHR Integration](https://healthcare.pilotfishtechnology.com/medical-device-integration-case-study/) case study.

**Mocked devices**

1. **Bedside Vital Signs Monitor** (`VITALMON`) — HR, SpO2, NIBP ORU  
2. **Continuous Glucose Monitor** (`CGM01`) — glucose ORU  

Flow: device ORU → HL7 LLP → HAPI validate → EHR LLP (mock).

## Ports

| Service | Host port |
|---------|-----------|
| PilotFish EIP | 8100 |
| Demo Web UI | 8101 |
| Device LLP inbound | 2580 |
| EHR mock LLP | 2581 |

## Run

```bash
cd "Clients/Demos/Medical/HL7/medical-device-hl7-ehr"
docker compose up -d --build
```

Open http://localhost:8101/ and use **Simulate reading** for each device.

## Demo only

Async auto-ACK; HAPI parse validation only — not a full hospital IG. See `DESIGN.md`.
