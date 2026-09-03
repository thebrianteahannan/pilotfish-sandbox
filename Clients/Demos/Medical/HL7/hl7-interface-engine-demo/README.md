# eiConsole for Healthcare – HL7 Demo

Sandbox copy of the public [HL7 Interface Demo](https://cms.pilotfishtechnology.com/hl7-interface-engine-demo/).

Hospital ADT arrives over **HL7 LLP**. Source Transform is **HL7 2.x to XML**, then a Data Mapper keeps last name, first name, and date of birth (`PID.7` `yyyyMMdd` → `yyyy-MM-dd`). One Target maps that XML to a SQL insert and the Database transport writes `dbo.Patients`.

## Ports

| Service | Host port |
|---------|-----------|
| Web UI | 8142 |
| EIP | 8141 |
| HL7 LLP | 2578 |
| SQL Server | 14342 |

- Local Web UI: http://127.0.0.1:8142/
- LAN Web UI: http://192.168.68.62:8142/
- EIP: http://127.0.0.1:8141/eip/
- SQL: `127.0.0.1:14342`  `sa` / `PilotFish_Demo1!`

## Run

```bash
docker compose --profile full up -d --build
```

## Tests

```bash
python3 tools/run_interface_tests.py --root hl7-interface-engine-demo --wait
```
