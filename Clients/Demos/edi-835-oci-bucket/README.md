# EDI 835 → OCI Object Storage Demo

Runnable PilotFish demo of Brian Wolfe’s pattern:

**SFTP poll EDI 835 → split each ST (Transaction) → JSON → real local floci-oci Object Storage via custom OciObjectStorageTransport**

Today’s product gap (no native OCI Transport) is demonstrated with `HttpPostTransport` against a local OCI Object Storage mock, and documented with a recommendation PDF for a custom Java `OciObjectStorageTransport`.

## Quick start

```bash
cd "Clients/Demos/edi-835-oci-bucket"
docker compose up -d --build
```

Wait ~60–90s for EIP, then open:

| Where | URL |
|-------|-----|
| Web UI (localhost) | http://127.0.0.1:8105/ |
| Web UI (LAN) | http://192.168.68.52:8105/ |
| EIP | http://127.0.0.1:8104/eip/ |
| floci-oci | http://127.0.0.1:4599/_floci-oci/health |
| SFTP | `localhost:2222` user `demo` / `demo`, dir `upload` |

Gaps PDF: http://127.0.0.1:8105/documents/PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf

Real OCI connect guide: http://127.0.0.1:8105/documents/Connect_OciObjectStorageTransport_To_Real_Oracle_OCI.pdf

## What happens

1. **Route 1** – `FTPListener` (JSCH SFTP) polls `upload`, archives raw EDI, stages to `output/staged/`.
2. **Route 2** – `DirectoryListener` + format **Split 835 Transactions** (`EDITransformationModule` → `XPathForkingModule` `//Transaction`).
3. Each Transaction → XSLT JSON → file under `output/json/` → `HttpPostTransport` to mock  
   `POST /n/demo/b/edi-835-payments/o/{object}.json`.

Seed file is mounted at `sftp-seed/upload/sample_multi_st_835.edi` (two ST segments). Use the Web UI **Upload sample via SFTP** for a fresh drop.

## Docs

- `DESIGN.md` — contracts, risks, ops
- `documents/PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf` — flaws / bottlenecks / custom Java modules
- `custom-modules/oci-object-storage-transport/` — Java transport skeleton
- Route diagram PDF (after Web UI is up):

```bash
python3 tools/convert_routes_to_v2.py
python3 tools/export_route_diagrams.py --config changed
```

## Notes

See `DESIGN.md` for risks (POST vs OCI PUT, signing, ST XPath fragility). Demo-only credentials; mock ≠ real OCI IAM.
