# HL7 Healthcare Integration Automation Demo

PilotFish eiPlatform demo based on the [HL7 Healthcare Integration Automation Platform](https://healthcare.pilotfishtechnology.com/healthcare-integration-hl7-automation-solutions/) case study (Primary Insurer–style flow).

## What it does

1. **Hospitals** submit HL7 2.x ADT (single message or FHS/BHS batch) via the web UI
2. UI wraps each message and drops it into `input/inbound/`
3. **Route 1 — Process Hospital HL7**:
   - DirectoryListener (hospital feed)
   - Basic Validation (MSH / PID structure)
   - Split Batch marker (when batch envelope detected)
   - Advanced Validation (business rules)
   - Router → kickout **or** dual transports:
     - SQL Server insert (BI source)
     - Clearinghouse `.hl7` file
4. Web UI shows SQL rows, clearinghouse files, validation snapshots, and a **Routes** tab with V2 diagrams

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built from the PilotFish Sandbox root

## Run

```bash
cd "Clients/Demos/Medical/HL7/hl7-healthcare-automation"
docker compose up -d --build
```

Wait ~45–60s for SQL init + PilotFish, then open the web UI.

## Ports

| Service    | Host port |
|------------|-----------|
| SQL Server | 14336     |
| PilotFish  | 8096      |
| Demo Web UI| 8097      |

- Web UI: http://localhost:8097/
- PilotFish EIP: http://localhost:8096/eip/

## Useful commands

```bash
docker compose logs -f pilotfish
ls -la output/clearinghouse output/validation
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d Hl7AutomationDemo \
  -Q "SELECT MessageId, HospitalCode, MessageType, TriggerEvent, PatientId, ValidationStatus FROM dbo.Hl7Messages ORDER BY MessageId"
docker compose down -v
```

## V2 routes

After editing `route.xml`, regenerate:

```bash
python3 tools/convert_routes_to_v2.py
# copies into eip-root for the Routes tab volume
```
