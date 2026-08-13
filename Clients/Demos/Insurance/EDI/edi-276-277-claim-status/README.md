# EDI 276/277 Claim Status

Directory-poll X12 **276**, catalog lookup by trace number, emit a real **277** plus found / not-found / error buckets.

## Run

```bash
python3 tools/list_sandbox_demo_docker.py
cd "Clients/Demos/Insurance/EDI/edi-276-277-claim-status"
docker compose --profile full up -d --build
```

| Where | URL |
|-------|-----|
| Web UI | http://127.0.0.1:8127/ |
| LAN | http://192.168.68.62:8127/ |
| EIP | http://127.0.0.1:8126/eip/ |
| Inbound drop | `input/inbound` |

Demo tab **Inject 276** copies `samples/X212-276-claim-request.edi` (trace ABCXYZ1).

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-276-277-claim-status --wait
```
