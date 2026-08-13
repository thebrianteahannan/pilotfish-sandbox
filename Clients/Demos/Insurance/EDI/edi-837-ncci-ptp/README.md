# EDI 837 NCCI PTP

Directory-drop X12 837P → fork each ST → SQL PTP catalog (column 1 / column 2 + modifier indicator) → pass / kickout.

There is no stock PilotFish NCCI module. Med Rec covers MUE units on HL7 DFT; this demo is the procedure-pair half for 837 claims.

## Ports

| Service | Port |
|---------|------|
| Demo Web UI | 8133 |
| PilotFish EIP | 8132 |
| SQL Server | 14343 |

Local: http://127.0.0.1:8133/  
LAN: http://192.168.68.62:8133/  
EIP: http://127.0.0.1:8132/eip/  
SQL: `127.0.0.1:14343` (`sa` / `PilotFish_Demo1!` · `Edi837NcciPtp`)

Same links live on the Info tab Access list.

## Run

```bash
cd Clients/Demos/Insurance/EDI/edi-837-ncci-ptp
docker compose --profile full up -d --build
```

Demo tab: inject `samples/sample_837p_ptp.edi`. Expect PTPCLM001/003 pass, PTPCLM002/004 kickout (`PTP_NCCI_PAIR`).

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837-ncci-ptp --wait
```
