# EDI 270/271 Realtime Eligibility

Real-time clinic eligibility: **one** sync REST call to PilotFish. PF builds X12 **270**, posts to a mock payer, parses the **271**, and returns clinic JSON on the same HTTP request.

For Gary Beatty’s real-time eligibility demo. Sibling of [`../edi-270-271-eligibility`](../edi-270-271-eligibility) (UI orchestrates three calls). Differences PDF: [`documents/EDI270_271_Orig_vs_Realtime_Differences.pdf`](documents/EDI270_271_Orig_vs_Realtime_Differences.pdf).

## Quick start

```bash
cd Clients/Demos/edi-270-271-realtime
docker compose up -d --build
# wait ~60–90s for EIP
open http://127.0.0.1:8121/
# LAN
open http://192.168.68.52:8121/
```

## Demo script

1. Preset **Jane Doe / FAIL001** → **Check eligibility (realtime)** → AAA reject.
2. Preset **John Smith / OK001** → success + EB benefits.
3. Note status line shows single-round-trip elapsed ms.
4. Open **vs Orig demo PDF** for the architecture contrast.

## Ports

| Service | Host |
|---------|------|
| PilotFish EIP | **8120** |
| Web UI | **8121** |
| Mock payer | **8211** |

Sync check URL (host): `http://127.0.0.1:8120/eip/rest/eligibility/check`

## Smoke

```bash
curl -sS -X POST http://127.0.0.1:8120/eip/rest/eligibility/check \
  -H 'Content-Type: application/xml' \
  -d '<EligibilityRequest><MemberId>OK001</MemberId><LastName>SMITH</LastName><FirstName>JOHN</FirstName><BirthDate>19800515</BirthDate><Gender>M</Gender></EligibilityRequest>'
```

## Docs

- `DESIGN.md`
- `documents/EDI270_271_Orig_vs_Realtime_Differences.pdf`
- `documents/EDI270_271_Realtime_V2_Route_Diagrams.pdf` (after export)
- `documents/EDI270_271_Realtime_Capability_Brief.pdf` (after export)
