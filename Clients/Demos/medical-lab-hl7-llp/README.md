# Medical Lab HL7 LLP (ORU → MEDITECH) Demo

Focused slice of the [Laboratory Interoperability case study](https://healthcare.pilotfishtechnology.com/case-studies-medical-lab-integration/):

**Lab ORU inbound HL7 LLP → HAPI validate → MEDITECH outbound HL7 LLP** (mock sink + ACKs).

See `DESIGN.md` for risks and scope limits (no X12/ASTM/ACORD in this slice).

## Ports

| Service | Host port |
|---------|-----------|
| PilotFish EIP | 8098 |
| Demo Web UI | 8099 |
| Lab LLP inbound | 2575 |
| MEDITECH mock LLP | 2576 |

## Prerequisites

- Docker Desktop
- Local image `pilotfish-eip:23R1`

## Run

```bash
cd "Clients/Demos/medical-lab-hl7-llp"
docker compose up -d --build
```

Wait ~60–90s, then open http://localhost:8099/

## Smoke

```bash
# From Web UI: Send sample ORU
# Or:
python3 tools/mllp_send.py --host 127.0.0.1 --port 2575 samples/LAB_ORU_R01_glucose.hl7
ls -la output/inbound output/meditech-outbound output/meditech-received
docker compose logs -f meditech-mock pilotfish
```

Happy path writes all three artifact dirs and returns an MLLP `MSA|AA`. Invalid samples still get an immediate AA (async listener) but fail at HAPI validation and do not forward to MEDITECH — see `DESIGN.md`.

## Demo only

Shared PHI-shaped samples on bind mounts. Validation is HAPI parse only — not lab IG certification. Listener uses **async auto-ACK** (sync ACK did not return on this image during smoke).
