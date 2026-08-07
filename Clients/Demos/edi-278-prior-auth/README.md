# EDI 278 Prior Auth Demo

Runnable PilotFish demo of opportunity idea **2.1 — Prior authorization that does not die in fax and portal hell**:

**Directory drop EDI 278 → completeness rules → simulated payer decision → 278 response + HL7 ORU EHR notice + decision buckets**

## What it does

1. **SQL Server** seeds `AuthCatalog` (CPT rules) and open `AuthRequest` traces
2. **Route 1** polls `input/inbound/` for `.edi` / `.278`, splits each ST, looks up catalog requirements, scores completeness, stages `AuthDecision` XML
3. **Route 2** routes staged decisions to:
   - `output/approved/` / `denied/` / `incomplete/` / `pended/`
   - `output/responses/{trace}_278_response.edi`
   - `output/ehr-notices/{trace}_auth_decided.oru.hl7`
4. Updates AuthRequest `Status` (`APPROVED` / `DENIED` / `INCOMPLETE` / `PENDED`)

Sample outcomes for `samples/sample_278_prior_auths.edi`:

| Trace | Result |
|-------|--------|
| PACOMPLETE01 | Approved (knee 27447 + dx + attachment) |
| PAINCOMPLETE01 | Incomplete (`MISSING_DIAGNOSIS`) |
| PADENY01 | Denied (MRI brain catalog disposition) |
| PAPEND01 | Pended (lumbar MRI catalog disposition) |

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built from the PilotFish Sandbox root

## Run

```bash
cd "Clients/Demos/edi-278-prior-auth"
docker compose up -d --build
```

Wait ~60–90s for SQL + EIP, then open the Web UI.

## Ports

| Service | Host port |
|---------|-----------|
| SQL Server | 14340 |
| PilotFish EIP | 8120 |
| Demo Web UI | 8121 |

- Web UI (local): http://localhost:8121/
- Web UI (LAN): http://192.168.68.52:8121/
- PilotFish EIP: http://localhost:8120/eip/
- Route diagrams: http://localhost:8121/documents/route-diagrams.pdf · http://192.168.68.52:8121/documents/route-diagrams.pdf
- Capability brief: http://localhost:8121/documents/capability-brief.pdf · http://192.168.68.52:8121/documents/capability-brief.pdf

## Useful commands

```bash
docker compose logs -f pilotfish
ls -la output/approved output/denied output/incomplete output/pended output/responses output/ehr-notices
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d Edi278PriorAuth \
  -Q "SELECT AuthTraceNumber, ProcedureCode, Status FROM dbo.AuthRequest ORDER BY AuthTraceNumber"
./tools/post_up_tests.sh
docker compose down -v
```

## Docs

- `DESIGN.md` — contracts, risks, ops
- `documents/EDI278_Prior_Auth_V2_Route_Diagrams.pdf`
- `documents/EDI278_Prior_Auth_Capability_Brief.pdf`

## Notes

Demo-only credentials (`PilotFish_Demo1!`). No FHIR Da Vinci PAS inbound in v1, no real payer API, ORU is a file drop (not LLP). Completeness checks member, patient name, procedure, diagnosis, and attachment when the catalog requires it. Outbound **278** uses `EDITransformationProcessor` (XML→EDI); outbound **ORU** uses `HL7TransformationProcessor` (XML→HL7)—no hardcoded ISA* or MSH| wire text.
