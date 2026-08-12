# FTP Named Download Trigger

Demo of the **Jules / Eugene workaround**: FTP Operation has **no Download**, so a mid-route “get file named X” uses a **separate route** with an **FTP / SFTP Listener** fired by **Listener Trigger (Run One Cycle)**.

## What it does

1. Drop a `.ctl` into `input/control` (body = remote filename, e.g. `invoice-20260407.dat`)
2. **Route 1 — Parse Control And Trigger Download**
   - DirectoryListener moves control → `output/archive`
   - Data Attribute Swapper + Attribute Population → `demo.ftp.RemoteFullPath`
   - Listener Trigger `RUN_ONCE` → Route 2 FTP listener
3. **Route 2 — Download Named File From SFTP**
   - Triggerable FTPListener (JSCH SFTP), `UseFullFilePath` = computed path
   - DirectoryTransport → `output/downloaded/`
4. SFTP seed includes the target file **and** a decoy that must not be fetched

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` built from the Sandbox root

## Run

```bash
cd "Clients/Demos/ftp-named-download-trigger"
docker compose up -d --build
```

Wait ~60–90s for EIP, then open the Web UI.

## Ports / URLs

| Service | Host port |
|---------|-----------|
| SFTP | 2223 (`demo` / `demo`, dir `upload`) |
| PilotFish EIP | 8112 |
| Demo Web UI | 8113 |

- Web UI local: http://localhost:8113/
- Web UI LAN: http://192.168.68.62:8113/
- Route design PDF: http://192.168.68.62:8113/documents/route-diagrams.pdf
- Local PDF: http://localhost:8113/documents/route-diagrams.pdf
- Module deep-dives (Info tab): http://localhost:8113/ → Info, or `documents/module-docs/` (re-sync: `python3 tools/sync_module_docs.py`)

## Smoke test

```bash
cp samples/control/fetch-invoice.ctl input/control/
# wait ~20s
ls output/downloaded/
cat output/downloaded/invoice-20260407.dat
```

Or use **Trigger named download** in the Web UI.

## Docs

- `DESIGN.md` — contracts, FQCNs, risks
- PilotFish Documentation: FTP Operation (no Download), Listener Trigger, FTP/SFTP Listener

## Demo only

- Listener Trigger is async; control route finishes before download completes
- Control archived before download succeeds (accepted demo risk)
- SFTP credentials are demo-only

See `DESIGN.md`.
