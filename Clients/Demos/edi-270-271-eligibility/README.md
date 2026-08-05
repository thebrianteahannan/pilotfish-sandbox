# EDI 270/271 Eligibility Demo

Clinic front-desk story: **build real X12 270 → mock payer 271 → parse AAA or benefits**.

Based on the Sandbox pitch idea “Eligibility 270/271 — mock payer, clinic UI, AAA error theater, then success.”

## What it does

1. Clinic Web UI posts `EligibilityRequest` XML to PilotFish  
   `POST /eip/rest/eligibility/build`
2. PilotFish XSLT → EDI XML → **`EDITransformationProcessor` (XML→EDI)** → returns X12 **270**
3. UI posts that 270 to the **mock payer** (`POST /x12/270`)
4. Mock payer returns X12 **271**:
   - `FAIL001` / empty → **AAA\*N\*\*72\*C** (invalid/missing subscriber)
   - `UNKNOWN` → **AAA\*N\*\*75\*C** (not found)
   - `OK001` → active **EB** benefits
5. UI posts the 271 to PilotFish  
   `POST /eip/rest/eligibility/parse`
6. PilotFish **EDI→XML** → XSLT JSON summary → clinic banner (AAA theater or success)

## Quick start

```bash
cd "Clients/Demos/edi-270-271-eligibility"
docker compose up -d --build
```

Wait ~60–90s for EIP, then open:

| Where | URL |
|-------|-----|
| Clinic Web UI (localhost) | http://127.0.0.1:8107/ |
| Clinic Web UI (LAN) | http://192.168.68.52:8107/ |
| PilotFish eligibility API | http://127.0.0.1:8106/eip/rest/eligibility/ |
| Mock payer health | http://127.0.0.1:8210/health |
| Route diagrams PDF | http://127.0.0.1:8107/documents/route-diagrams.pdf |

## Demo script

1. Leave preset **Jane Doe — FAIL001** → **Check eligibility** → red AAA reject theater.
2. Switch to **John Smith — OK001** → **Check eligibility** → green active benefits.
3. Open **Routes** tab for the V2 diagram; **XSLT** tab for the transforms.

## Ports

| Service | Host port |
|---------|-----------|
| PilotFish EIP | 8106 → 8080 |
| Clinic Web UI | 8107 |
| Mock payer | 8210 |

## Docs

- `DESIGN.md` — architecture, FQCNs, risks
- `documents/EDI270_271_V2_Route_Diagrams.pdf` — regenerate with Web UI up:  
  `python3 tools/export_route_diagrams.py --config changed`

## Smoke (CLI)

```bash
# After compose is healthy:
curl -s http://127.0.0.1:8210/health
curl -s -X POST http://127.0.0.1:8107/api/check-eligibility \
  -H 'Content-Type: application/json' \
  -d '{"MemberId":"FAIL001","LastName":"DOE","FirstName":"JANE","BirthDate":"19800115","Gender":"F"}' | head -c 400
```
