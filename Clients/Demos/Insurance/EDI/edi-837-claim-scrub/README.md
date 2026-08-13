# EDI 837 Claim Scrub — pre-clearinghouse rejection reduction

SQL Server claims → payer-profile edits (missing referring NPI / invalid POS) → kickout work queue or clean 837 + SNIP.

## Run

```bash
python3 tools/list_sandbox_demo_docker.py
cd "Clients/Demos/Insurance/EDI/edi-837-claim-scrub"
docker compose --profile full up -d --build
```

| Where | URL |
|-------|-----|
| Web UI | http://127.0.0.1:8115/ |
| LAN | http://192.168.68.62:8115/ |
| EIP | http://127.0.0.1:8114/eip/ |
| SQL | `127.0.0.1:14341` (`sa` / `PilotFish_Demo1!` · `Edi837ClaimScrub`) |

Seed: 5001/5004 clean; 5002 missing referring NPI; 5003 invalid POS.

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837-claim-scrub --wait
```
