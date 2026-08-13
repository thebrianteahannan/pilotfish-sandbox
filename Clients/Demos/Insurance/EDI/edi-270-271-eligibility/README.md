# EDI 270/271 Eligibility

Clinic front-desk story: build real X12 **270** → mock payer **271** → parse AAA or benefits.

## Ports

| Service | Port |
|---------|------|
| Demo Web UI | 8107 |
| PilotFish EIP | 8106 |
| Mock payer | 8210 |

Local: http://127.0.0.1:8107/  
LAN: http://192.168.68.62:8107/  
EIP: http://127.0.0.1:8106/eip/  
Eligibility API: http://127.0.0.1:8106/eip/rest/eligibility/  
Mock payer: http://127.0.0.1:8210/x12/270  

Same links live on the Info tab Access list.

## Run

```bash
cd Clients/Demos/Insurance/EDI/edi-270-271-eligibility
docker compose --profile full up -d --build
```

Demo tab: Jane Doe / FAIL001 → AAA 72 theater; John Smith / OK001 → active EB benefits.

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-270-271-eligibility --wait
```
