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

## Run (this Sandbox)

Needs the local image `pilotfish-eip:23R1` (build from the Sandbox repo root first). That tag is **not** on Docker Hub.

```bash
cd Clients/Demos/Insurance/EDI/edi-270-271-realtime
docker compose --profile full up -d --build
```

## Give this demo to someone (Windows)

They cannot `docker compose up --build` from the demo folder alone. Docker will try to pull `docker.io/library/pilotfish-eip:23R1` and fail with `pull access denied`.

On the Sandbox machine, save a **linux/amd64** image (do not `docker save pilotfish-eip:23R1` on Apple Silicon — that tar fails on Windows with `no match for platform in manifest`):

```bash
mkdir -p Clients/Demos/Insurance/EDI/edi-270-271-realtime/handoff
docker buildx build --platform linux/amd64 --provenance=false --sbom=false \
  -t pilotfish-eip:23R1-amd64 --load -f Dockerfile .
docker save pilotfish-eip:23R1-amd64 | gzip > \
  Clients/Demos/Insurance/EDI/edi-270-271-realtime/handoff/pilotfish-eip-23R1-amd64.tar.gz
```

Leave the local `pilotfish-eip:23R1` tag as arm64. The Windows zip they extract has `WINDOWS-RUN.cmd` and `pilotfish-eip-23R1-amd64.tar.gz` in the same folder (no `handoff\`). `docker load` cannot read a `.zip` — that fails with `invalid tar header`. If compose still queries Docker Hub, use `DOCKER_BUILDKIT=0` or `WINDOWS-RUN.cmd`.

Demo tab: Jane Doe / FAIL001 → AAA 72; John Smith / OK001 → active EB. Status line shows single-round-trip elapsed ms.

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-270-271-realtime --wait
```

