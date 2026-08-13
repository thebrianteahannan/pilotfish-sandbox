# EDI 835 → OCI Object Storage

FTP-poll X12 **835**, fork each `ST`, map to JSON, and post each object to a local Object Storage mock.

## Run

```bash
python3 tools/list_sandbox_demo_docker.py
cd "Clients/Demos/Insurance/EDI/edi-835-oci-bucket"
docker compose --profile full up -d --build
```

| Where | URL |
|-------|-----|
| Web UI | http://127.0.0.1:8105/ |
| LAN | http://192.168.68.62:8105/ |
| EIP | http://127.0.0.1:8104/eip/ |
| Mock Object Storage | http://127.0.0.1:4599/health |
| FTP | `127.0.0.1:2222` user `demo` / `demo`, dir `upload` |

Demo tab **Upload via FTP** copies `samples/sample_multi_st_835.edi` (two ST: PATCLAIM001, PATCLAIM002).

Spoken **FTP** in construction narration even though the listener is JSCH SFTP.

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-835-oci-bucket --wait
```
