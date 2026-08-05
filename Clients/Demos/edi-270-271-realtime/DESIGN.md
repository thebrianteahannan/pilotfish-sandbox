# DESIGN.md — EDI 270/271 Realtime Eligibility Demo

## Business goal

Show a **true real-time eligibility integration**: the clinic (or EHR) posts once, and **PilotFish owns the full synchronous 270 → payer → 271 round-trip**, returning clinic-ready JSON on the same HTTP request.

Built for Gary Beatty’s real-time eligibility demo request. Sibling of `edi-270-271-eligibility` (UI-orchestrated wiring demo).

## Actors

| Actor | Role |
|-------|------|
| Clinic Web UI | Front desk; **single** POST to PilotFish `/eligibility/check` |
| PilotFish eiPlatform | Build 270, HttpPost to payer, parse 271, sync JSON reply |
| Mock payer | Accepts raw X12 270; returns canned AAA or success 271 |

## Demo narrative

1. Select **Jane Doe / FAIL001** → Check eligibility → AAA reject theater from one round-trip.
2. Select **John Smith / OK001** → Check eligibility → active coverage + EB lines.
3. Open **vs Orig demo PDF** to contrast UI orchestration vs PF-owned round-trip.

## Architecture

```text
Clinic UI (:8121)
  │  POST EligibilityRequest XML (ONE call)
  ▼
PilotFish Route — Realtime Eligibility Check (sync REST)
  POST /eip/rest/eligibility/check
    → XSLT → EDI XML → XML→EDI 270
    → HttpPostTransport → mock payer /x12/270
    → PostProcessors: wrap 271 → XSLT JSON → SynchronousResponseProcessor
  │
  ▼
Clinic UI banner + wire artifacts from output/
```

**Key pattern:** Same as FHIR Route `0 - Keycloak JWT Auth` — `HttpPostTransport` with **PostProcessors** (including `SynchronousResponseProcessor`) continues after the HTTP response and replies to the original sync REST listener.

## Differences vs `edi-270-271-eligibility`

| | Orig (`edi-270-271-eligibility`) | Realtime (this demo) |
|--|----------------------------------|----------------------|
| Clinic HTTP calls | **3** (PF `/build` → payer → PF `/parse`) | **1** (PF `/check`) |
| Who calls the payer | Clinic Web UI | PilotFish `HttpPostTransport` |
| Sync reply | `SynchronousResponseTransport` on build/parse | `SynchronousResponseProcessor` after payer PostProcessors |
| Best for | Teaching wire steps / teaching REST pieces | Production-shaped real-time integration |
| Ports | 8106 / 8107 / 8210 | 8120 / 8121 / 8211 |

See `documents/EDI270_271_Orig_vs_Realtime_Differences.pdf`.

## Module / FQCN choices

| Stage | Module | FQCN |
|-------|--------|------|
| Inbound API | RESTful Web Service Listener | `…http.rest.RESTfulWebServiceListener` `Synchronous=true` resource `check` |
| Map to EDI XML | XSLT Processor | `…transform.XSLTProcessor` |
| XML→EDI | EDI Transformation | `…transform.EDITransformationProcessor` `UseInternalData=false` |
| Payer call | HTTP Post | `…http.HttpPostTransport` |
| Parse 271 | XSLT (structural) | same honesty as orig (23R1 tables) |
| Sync reply | Synchronous Response Processor | `…other.SynchronousResponseProcessor` |

## Preset members (mock payer)

| Member ID | Result |
|-----------|--------|
| `FAIL001` | AAA\*N\*\*72\*C |
| `UNKNOWN` | AAA\*N\*\*75\*C |
| `OK001` | EB active benefits |

## Risks / honesty

- Same 23R1 trial table limits as orig: XML→EDI 270 may omit `ST*270`; mock payer matches on `NM1*IL` and does not require ST. Parse uses structural Saxon XSLT over wrapped raw 271 (not EDI→XML).
- Demo credentials / mock payer only.
- UI still builds `EligibilityRequest` XML for convenience; production could POST the same XML from any clinic system.

## Ports

| Service | Host |
|---------|------|
| PilotFish EIP | 8120 → 8080 |
| Clinic Web UI | 8121 |
| Mock payer | 8211 → 8210 |

LAN hint: `http://192.168.68.52:8121/`
