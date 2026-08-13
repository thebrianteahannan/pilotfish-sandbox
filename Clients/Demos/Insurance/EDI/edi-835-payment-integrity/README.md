# EDI 835 Payment Integrity

Directory-drop X12 835 → fork each ST → SQL Server OpenAR lookup → matched / exception buckets + underpay CSV.

## Ports

| Service | Port |
|---------|------|
| Demo Web UI | 8111 |
| PilotFish EIP | 8110 |
| SQL Server | 14339 |

Local: http://127.0.0.1:8111/  
LAN: http://192.168.68.62:8111/  
EIP: http://127.0.0.1:8110/eip/  
SQL: `127.0.0.1:14339` (`sa` / `PilotFish_Demo1!` · `Edi835PaymentIntegrity`)

Same links live on the Info tab Access list.

## Run

```bash
cd Clients/Demos/Insurance/EDI/edi-835-payment-integrity
docker compose --profile full up -d --build
```

Demo tab: inject `samples/sample_835_underpays.edi`. Expect PATCLAIM002/003 matched, PATCLAIM001 underpay exception + CSV row, PATCLAIM999 NO_AR exception.

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-835-payment-integrity --wait
```
