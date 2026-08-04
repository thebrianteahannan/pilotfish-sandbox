# FHIR Patient REST Demo

PilotFish eiPlatform demo for **HL7 FHIR R4 REST** Patient create/read (synchronous HTTP), aligned with the research note:

- Browser/LAN: http://192.168.68.52:8103/documents/fhir-rest-research.pdf
- Local: http://localhost:8103/documents/fhir-rest-research.pdf

## What it does

1. FHIR clients call PilotFish at `/eip/rest/fhir/Patient` (POST create) and `/eip/rest/fhir/Patient/{id}` (GET read)
2. **Route 1 — FHIR Patient REST API**
   - `RESTfulWebServiceListener` (`SERVICE_NAME=fhir`, `Synchronous=true`)
   - Heuristic validation for create (resourceType, id, MRN, name)
   - Persist to SQL Server + `output/fhir-store/{id}.json`
   - `SynchronousResponseTransport` returns Patient or OperationOutcome with 201/200/404/400/405
3. Web UI is a **FHIR client** (not a directory dropper)

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` built from the Sandbox root

## Run

```bash
cd "Clients/Demos/fhir-patient-exchange"
docker compose up -d --build
```

Wait ~60–90s, then open the Web UI.

## Ports / URLs

| Service | Host port |
|---------|-----------|
| SQL Server | 14337 |
| PilotFish EIP | 8102 |
| Demo Web UI | 8103 |

- Web UI local: http://localhost:8103/
- Web UI LAN: http://192.168.68.52:8103/
- FHIR REST (LAN): http://192.168.68.52:8102/eip/rest/fhir/Patient
- Research PDF: http://192.168.68.52:8103/documents/fhir-rest-research.pdf
- Route design PDF: http://192.168.68.52:8103/documents/route-diagrams.pdf

## curl examples

```bash
curl -sS -D- -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/EHR-01_Patient_alice.json \
  http://192.168.68.52:8102/eip/rest/fhir/Patient

curl -sS -D- http://192.168.68.52:8102/eip/rest/fhir/Patient/pat-alice-001
```

## Demo only

- Heuristic validation — not full StructureDefinition / IG validation
- Patient create + read only (no search/transaction yet)
- Shared `sa` password for local convenience

See `DESIGN.md`.
