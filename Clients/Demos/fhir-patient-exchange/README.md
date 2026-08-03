# FHIR Patient Exchange Demo

PilotFish eiPlatform demo for HL7 **FHIR R4** Patient / Bundle exchange (inspired by [FHIR Integration & CMS interoperability](https://healthcare.pilotfishtechnology.com/fhir-integration-cms-0057-f-compliance/)).

## What it does

1. **EHR systems** submit FHIR R4 Patient or Bundle JSON via the web UI
2. UI wraps each resource in a `<FhirMessage>` envelope and drops it into `input/inbound/`
3. **Route 1 — Process FHIR Patient**:
   - DirectoryListener (FHIR feed)
   - Basic Validation (resourceType / id / RawFhir markers)
   - Bundle Flag Snapshot (audit file — not a true fork)
   - Advanced Validation (MRN, name, Bundle entries)
   - Router → kickout **or** dual transports:
     - SQL Server insert (BI source)
     - Mock FHIR store `.json` file
4. Web UI shows SQL rows, FHIR store files, validation snapshots, and a **Routes** tab with V2 diagrams

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built from the PilotFish Sandbox root

## Run

```bash
cd "Clients/Demos/fhir-patient-exchange"
docker compose up -d --build
```

Wait ~60–90s for SQL init + PilotFish, then open the web UI.

## Ports

| Service     | Host port |
|-------------|-----------|
| SQL Server  | 14337     |
| PilotFish   | 8102      |
| Demo Web UI | 8103      |

- Web UI: http://localhost:8103/
- PilotFish EIP: http://localhost:8102/eip/
- Route design PDF: `documents/FHIR_V2_Route_Diagrams.pdf`

## Useful commands

```bash
docker compose logs -f pilotfish
ls -la output/fhir-store output/validation output/kickout
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d FhirPatientExchangeDemo \
  -Q "SELECT ResourceRowId, SourceCode, ResourceType, ResourceId, PatientId, ValidationStatus FROM dbo.FhirResources ORDER BY ResourceRowId"
python3 tools/convert_routes_to_v2.py
python3 tools/export_route_diagrams.py --config changed
docker compose down -v
```

## Demo only

- Heuristic XSLT validation — **not** full FHIR StructureDefinition / terminology validation
- Inbound is directory-mediated (Web UI envelope), not a live FHIR REST server
- Shared `sa` password for local convenience — never production
- Dual-write SQL + file without outbox compensation (accepted demo risk)

See `DESIGN.md`.
