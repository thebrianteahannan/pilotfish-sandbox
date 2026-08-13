# EDI 837 + SNIP Validation (SQL Server) Demo

PilotFish eiPlatform demo: **SQL Server claims → EDI XML → EDI Transformation Module → SNIP → 837P files**, with a LAN web UI.

## What it does

1. **SQL Server** seeds professional claims (`Claims` / `ClaimLines` / `Patients` / `Providers`)
2. **Route 1** polls PENDING claims via `DatabaseSqlListener` + SQLXML (marks them PROCESSED)
3. **Route 2** forks each claim and:
   - XSLT → PilotFish **EDI XML** (`XCSData/Interchange/...`)
   - **`EDITransformationProcessor`** (XML → EDI) → `output/edi/*.edi`
   - **`EdiSNIPValidationProcessor`** (SNIP Types **1–3** at runtime) → `output/snip/*_snip.xml`  
     Types 4–7 wiring + `snip7-demo-rules.xml` are ready; flip flags when `EDISNIP` is licensed

## SNIP levels

| Type | Runtime | Notes |
|------|---------|--------|
| 1–3 | **on** | Integrity, HIPAA requirements, balancing |
| 4 | off | Inter-segment (`EDISNIP` license required) |
| 5 | off | External code sets (`EDISNIP`) |
| 6–7 | off | Customer rules in `snip7-demo-rules.xml` (`Snip7Validation`; no separate Type 6 toggle) |

**License note:** Enabling Types 4–7 without `EDISNIP` on `pflicense.key` aborts the SNIP stage (`Not licensed for SNIP 4 to 7 validations during runtime`) and leaves `output/snip/` empty. This Sandbox image lacks `EDISNIP`, so the demo runs **Types 1–3** so SNIP reports still appear. To go to Level 7: add `EDISNIP`, rebuild `pilotfish-eip:23R1`, set `Snip4/5/7Validation=true`.

## Heap

SNIP rule compile (especially with Types 4–5 enabled) needs a large heap (`OutOfMemoryError: GC overhead limit exceeded` otherwise). Compose sets:

`CATALINA_OPTS=-Xms1024M -Xmx6144M -XX:+UseG1GC`

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built from the PilotFish Sandbox root

## Run

```bash
cd "Clients/Demos/Insurance/EDI/edi-837-snip-sqlserver"
docker compose up -d --build
```

Wait ~60–90s for SQL init + first poll, then open the web UI.

## Ports

| Service    | Host port |
|------------|-----------|
| SQL Server | 14335     |
| PilotFish  | 8093      |
| Demo Web UI| 8095      |

- Web UI (LAN): http://192.168.68.62:8095/
- Web UI (local): http://localhost:8095/
- PilotFish EIP: http://localhost:8093/eip/

## Useful commands

```bash
docker compose logs -f pilotfish
ls -la output/edi output/snip
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d Edi837Demo \
  -Q "SELECT ClaimId, PatientId, ClaimAmount, Status FROM dbo.Claims ORDER BY ClaimId"
docker compose down -v
```

## X12 TableData

Mounts repo `EDI/TableData/x12` to `eip-root/edi-tabledata` with `TransactionDataWithVersion` → `837-Q1` (5010). See playbook §3.6.
