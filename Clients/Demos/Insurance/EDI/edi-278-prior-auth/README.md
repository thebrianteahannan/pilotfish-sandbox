# EDI 278 Prior Auth

Directory-drop X12 **278** prior-auth requests. PilotFish forks each `ST`, looks up `AuthCatalog` in SQL Server, scores completeness, then writes decision buckets plus a **278 response** and an EHR **HL7 ORU**.

## Run

```bash
python3 tools/list_sandbox_demo_docker.py
# stop other Clients/ demo stacks first (compose down, never -v)
cd "Clients/Demos/Insurance/EDI/edi-278-prior-auth"
docker compose --profile full up -d --build
```

Web UI (open in Cursor, not Chrome): `http://127.0.0.1:8121/`
LAN: `http://192.168.68.62:8121/`
EIP: `http://127.0.0.1:8120/eip/`
SQL: `127.0.0.1:14340` (`sa` / `PilotFish_Demo1!` · `Edi278PriorAuth`)

Demo tab **Inject 278** copies `samples/sample_278_prior_auths.edi` into `input/inbound`.

| Trace | Result |
|-------|--------|
| PACOMPLETE01 | Approved |
| PAINCOMPLETE01 | Incomplete (missing diagnosis) |
| PADENY01 | Denied (catalog DENY) |
| PAPEND01 | Pended (catalog PEND) |

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-278-prior-auth --wait
```
