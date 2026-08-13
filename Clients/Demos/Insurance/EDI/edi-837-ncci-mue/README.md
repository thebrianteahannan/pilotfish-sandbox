# EDI 837 NCCI MUE

Directory-drop X12 837P → fork each ST → SQL MUE catalog (CPT max units, same shape as Med Rec `MUE_EDITS`) → pass / kickout.

There is no stock PilotFish NCCI module. This is a CMS-shaped lookup plus stock processors.

## Ports

| Service | Port |
|---------|------|
| Demo Web UI | 8131 |
| PilotFish EIP | 8130 |
| SQL Server | 14342 |

Local: http://127.0.0.1:8131/  
LAN: http://192.168.68.62:8131/  
EIP: http://127.0.0.1:8130/eip/  
SQL: `127.0.0.1:14342` (`sa` / `PilotFish_Demo1!` · `Edi837NcciMue`)

Same links live on the Info tab Access list.

## Run

```bash
cd Clients/Demos/Insurance/EDI/edi-837-ncci-mue
docker compose --profile full up -d --build
```

Demo tab: inject `samples/sample_837p_mue.edi`. Expect MUECLM001/003 pass, MUECLM002/004 kickout (`MUE_UNITS_EXCEEDED`).

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837-ncci-mue --wait
```
