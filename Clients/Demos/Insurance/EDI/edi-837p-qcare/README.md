# EDI 837P → QCare

Directory-poll X12 **837P**, fork each `ST` with TableData `837-Q1`, and map to a 2100-byte QCare `OT`/`B837` record.

## Run

```bash
python3 tools/list_sandbox_demo_docker.py
cd "Clients/Demos/Insurance/EDI/edi-837p-qcare"
docker compose --profile full up -d --build
```

| Where | URL |
|-------|-----|
| Web UI | http://127.0.0.1:8125/ |
| LAN | http://192.168.68.62:8125/ |
| EIP | http://127.0.0.1:8123/eip/ |
| Inbound drop | `input/inbound` |

Demo tab **Inject 837P** copies `samples/MCQRQ74837PS803.TXT` (STONE / SHARON / 70487).

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837p-qcare --wait
```
