# SQL Server PilotFish XML Export

Poll `PilotFishDemo.dbo.Captures` every 15 seconds and overwrite `captures_export.xml`.

## URLs

- Local Web UI: http://127.0.0.1:8137/
- LAN Web UI: http://192.168.68.62:8137/
- EIP: http://127.0.0.1:8136/eip/
- SQL Server: `127.0.0.1:14342` (`sa` / `PilotFish_Demo1!` · `PilotFishDemo`)

## Run

```bash
# stage Web UI only
docker compose --profile stage up -d --build
# full stack (SQL + EIP + Web UI)
docker compose --profile full up -d --build
```

## Smoke

```bash
python3 tools/run_interface_tests.py --root sqlserver-pilotfish-demo --wait
```

PDFs live under `documents/` (capability brief, route diagrams, test plan). Construction video is on-demand from the Info tab.
