# DOC Healthcare Workflow Automation → HL7 ADT

PilotFish eiPlatform demo based on the [Government Healthcare Workflow Automation](https://healthcare.pilotfishtechnology.com/healthcare-workflow-automation-hl7/) case study.

## What it does

1. **SQL Server** seeds legacy operational events from Oracle OMS + SQL Server Housing
2. **PilotFish Route 1** polls `PENDING` events and expands `MULTI` packages into single healthcare transactions
3. **PilotFish Route 2** forks each event (`XPathForkingModule`) and generates an HL7 ADT message for MyAvatar
4. HL7 files land in `output/hl7/`

### Event → HL7 trigger map

| Operational event | HL7 |
|-------------------|-----|
| ADMIT | ADT^A01 |
| TRANSFER | ADT^A02 |
| BED_ASSIGN | ADT^A02 |
| DISCHARGE | ADT^A03 |
| DEMO_UPDATE | ADT^A08 |
| MULTI | Split into child events, then mapped above |

Seed data includes two MULTI packages:

- `1002` → ADMIT + BED_ASSIGN + DEMO_UPDATE
- `1006` → TRANSFER + BED_ASSIGN

So **7 DB rows** become **10 HL7 messages**.

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built from the PilotFish Sandbox root

## Run

```bash
cd "Clients/Demos/doc-healthcare-hl7-workflow"
docker compose up -d --build
```

Wait ~45–90s for SQL init + PilotFish startup + first 15s poll, then:

```bash
ls -la output/hl7/
for f in output/hl7/*.hl7; do echo "===== $f ====="; cat -v "$f"; echo; done
cat output/events/expanded_events.xml
```

## Useful commands

```bash
docker compose logs -f pilotfish
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d DocHealthcare \
  -Q "SELECT EventId, SourceSystem, EventType, ChildEventTypes, OffenderId, Status FROM dbo.OperationalEvents ORDER BY EventId"
docker compose down -v
```

## Ports

| Service    | Host port |
|------------|-----------|
| SQL Server | 14334     |
| PilotFish  | 8091      |
| Demo Web UI| 8092      |

- Route visualizer + event injector: http://localhost:8092/ (LAN: http://192.168.x.x:8092/)
- PilotFish UI: http://localhost:8091/eip/
