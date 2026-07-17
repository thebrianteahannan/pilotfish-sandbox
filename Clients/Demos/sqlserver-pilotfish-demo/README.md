# SQL Server + PilotFish XML Export Demo

Spins up:

1. **SQL Server 2022** in Docker with a seeded `Captures` table
2. **PilotFish eiPlatform** in a second Docker image with one route that:
   - polls SQL Server every 15 seconds via `DatabaseSqlListener` + SQLXML
   - writes `/opt/pilotfish/output/captures_export.xml`

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built (from PilotFish Sandbox)

## Run

```bash
cd "Clients/Demos/sqlserver-pilotfish-demo"
docker compose up -d --build
```

Wait ~30–60s for SQL Server init + PilotFish startup, then:

```bash
cat output/captures_export.xml
```

## Useful commands

```bash
docker compose logs -f pilotfish
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d PilotFishDemo \
  -Q "SELECT * FROM dbo.Captures"
docker compose down -v
```

## Ports

| Service    | Host port |
|------------|-----------|
| SQL Server | 14333     |
| PilotFish  | 8090      |

PilotFish UI: http://localhost:8090/eip/
