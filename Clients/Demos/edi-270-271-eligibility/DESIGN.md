# DESIGN.md — EDI 270/271 Eligibility Demo

## Business goal

Show a clinic front desk verifying member eligibility over **real X12 270/271** (005010X279A1): build a 270, call a mock payer, parse the 271, and demonstrate **AAA rejection theater** then a **successful benefits (EB)** response.

## Actors

| Actor | Role |
|-------|------|
| Clinic Web UI | Front desk; orchestrates build → payer call → parse |
| PilotFish eiPlatform | Builds 270 from request XML; parses 271 to clinic JSON |
| Mock payer | Accepts raw X12 270; returns canned AAA or success 271 |

## Demo narrative

1. Select **Jane Doe / FAIL001** → Check eligibility → UI shows **AAA\*N\*\*72\*C** (invalid/missing subscriber) theater.
2. Select **John Smith / OK001** → Check eligibility → UI shows active coverage + EB benefit lines.

## Architecture

```text
Clinic UI (Flask :8107)
  │ 1) POST EligibilityRequest XML
  ▼
PilotFish Route — Eligibility 270 271 API (sync REST)
  POST /eip/rest/eligibility/build  → XSLT → EDI XML → XML→EDI → sync 270
  POST /eip/rest/eligibility/parse  → EDI→XML → XSLT JSON → sync summary
  │ 2) POST raw 270 (text/plain)
  ▼
Mock payer (:8210/x12/270)
  │ 3) 271 X12 body
  ▼
Clinic UI → parse
```

**Why UI orchestration:** Sync REST needs `SynchronousResponseTransport`; `HttpPostTransport` is an end-of-route transport. Clinic UI owns the three visible wire steps for demo clarity while still carrying real X12 end-to-end.

## Module / FQCN choices

| Stage | Module | FQCN | Source |
|-------|--------|------|--------|
| Inbound API | RESTful Web Service Listener | `com.pilotfish.eip.modules.http.rest.RESTfulWebServiceListener` | V2 modules.conf / FHIR demo |
| Map to EDI XML | XSLT Processor | `com.pilotfish.eip.modules.transform.XSLTProcessor` | 837 demo |
| XML↔EDI | EDI Transformation | `com.pilotfish.eip.modules.transform.EDITransformationProcessor` | 837 demo; `UseInternalData=false` (23R1 trial tables expired) |
| Snapshots | File Write | `com.pilotfish.eip.modules.file.FileWriteProcessor` | demos |
| Sync HTTP reply | Synchronous Response | `com.pilotfish.eip.modules.internal.SynchronousResponseTransport` | FHIR demo |
| Status / headers | Http Response Status/Headers | `HttpResponseCodeProcessor`, `AddHttpResponseHeadersProcessor` | FHIR demo |

## Pipeline table

| Route | Stage | Notes |
|-------|-------|-------|
| 1 Build 270 | Listener `SERVICE_NAME=eligibility`, resource `build`, Synchronous=true | POST XML body |
| 1 | XSLT `transform-request-to-270-edi-xml.xslt` | DocType 270 / GS HS / 005010X279A1 |
| 1 | EDITransformation XML→EDI | Wire artifact |
| 1 | FileWrite under `output/270/` | Audit |
| 1 | SyncResponse `text/plain` | Returns 270 to UI |
| 2 Parse 271 | Listener resource `parse` | Raw 271 body |
| 2 | EDITransformation EDI→XML | |
| 2 | FileWrite `output/271/` | |
| 2 | XSLT → JSON summary | AAA vs EB |
| 2 | SyncResponse `application/json` | Clinic summary |

## Preset members (mock payer)

| Member ID | Result | AAA / EB |
|-----------|--------|----------|
| `FAIL001` | Reject | `AAA*N**72*C` Invalid/Missing Subscriber/Insured ID |
| `UNKNOWN` | Reject | `AAA*N**75*C` Subscriber Not Found |
| `OK001` | Success | `EB*1*IND*30` Health Benefit Plan Coverage active |

## Commit / success timing

UI does not claim success until parse JSON returns `status=active` (or shows AAA). Mock payer is demo-only; no AR posting.

## Risks / honesty

- 23R1 trial X12 code tables expired / incomplete for **271 EDI→XML**. Outbound **XML→EDI 270 works** for content but often **omits `ST*270`** without tables; clinic UI inserts `ST*270*0001*005010X279A1` before the payer call when missing. Inbound **EDI→XML 271 fails** with “Could not find matching table data for incoming 271”. Parse target therefore uses a **structural Saxon XSLT** over `<EdiPayload><![CDATA[raw 271]]></EdiPayload>` (still real X12 on the wire). With licensed tables, prefer `EDITransformationProcessor` EDI→XML and drop the ST shim.
- Sandbox mounts `EDI/TableData/x12` → `eip-root/edi-tabledata` with `USE_ENHANCED_CONTEXT=true` + `TransactionDataWithVersion` (5010); see playbook §3.6 / `EDI/README.md`.
- SNIP Types 1–3 not run in this slice (follow-on).
- Clinic UI orchestration is intentional demo shape (sync REST + HttpPost mismatch).
- Passwords / URLs are demo-only.

## Ports

| Service | Host |
|---------|------|
| PilotFish EIP | 8106 → 8080 |
| Clinic Web UI | 8107 |
| Mock payer | 8210 |

LAN hint: `http://192.168.68.52:8107/`
