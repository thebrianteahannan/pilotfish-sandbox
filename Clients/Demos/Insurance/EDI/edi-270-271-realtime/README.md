# EDI 270/271 Realtime Eligibility

Clinic posts **once**. PilotFish builds X12 **270**, posts to a mock payer, parses the **271**, and returns JSON on the same HTTP request.

Sibling of [`../edi-270-271-eligibility`](../edi-270-271-eligibility) (UI orchestrates three calls).

## Ports

| Service | Port |
|---------|------|
| Demo Web UI | 8121 |
| PilotFish EIP | 8120 |
| Mock payer | 8211 |

Local: http://127.0.0.1:8121/  
LAN: http://192.168.68.62:8121/  
EIP: http://127.0.0.1:8120/eip/  
Eligibility check: http://127.0.0.1:8120/eip/rest/eligibility/check  
Mock payer: http://127.0.0.1:8211/x12/270  

Same links live on the Info tab Access list.

## Run

```bash
cd Clients/Demos/Insurance/EDI/edi-270-271-realtime
docker compose --profile full up -d --build
```

Demo tab: Jane Doe / FAIL001 → AAA 72; John Smith / OK001 → active EB. Status line shows single-round-trip elapsed ms.

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-270-271-realtime --wait
```
