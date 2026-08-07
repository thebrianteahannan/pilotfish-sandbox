# EDI 837 Claim Scrub — pre-clearinghouse rejection reduction

SQL Server claims → PilotFish payer-profile edits (missing referring NPI / invalid POS) → **kickout work queue** or clean **837 + SNIP**. Edit outcomes land in `output/bi/`. Demo for opportunity “Claims rejection reduction before the clearinghouse.”

## Prerequisites

- `pilotfish-eip:23R1` Docker image
- Docker Desktop / Compose
- Repo-root `EDI/TableData/x12` (compose-mounted)

## Run

```bash
cd "Clients/Demos/edi-837-claim-scrub"
LAN_IP=$(ipconfig getifaddr en0)   # macOS; expect 192.*
# set LAN_HINT in docker-compose.yml webui env if needed
docker compose up -d --build
```

## Ports

| Service | Host port |
|---------|-----------|
| SQL Server | 14341 |
| PilotFish EIP | 8114 |
| Web UI | 8115 |

## URLs

- Local UI: http://localhost:8115/
- LAN UI: http://192.x.x.x:8115/ (from `LAN_HINT`)
- EIP: http://localhost:8114/eip/

## Review PDFs (browser)

- Capability: http://localhost:8115/documents/capability-brief.pdf
- Route diagrams: http://localhost:8115/documents/route-diagrams.pdf
- Test plan: http://localhost:8115/documents/test-plan.pdf
- **Test results:** http://localhost:8115/documents/test-results.pdf  
  (also Info tab; catch-all serves `documents/EDI837_Claim_Scrub_Test_Results.pdf`)

## Smoke

```bash
# UI health
curl -sS http://localhost:8115/api/health

# After ~30s seed processing — expect kickouts for 5002/5003 and clean EDI for 5001/5004
curl -sS http://localhost:8115/api/kickouts | head
curl -sS http://localhost:8115/api/edi | head
ls output/kickouts output/edi output/bi

# Tests + regenerate test-results PDF
python3 tools/export_test_plan_pdf.py
python3 tools/run_interface_tests.py --wait
```

## Demo only

Synthetic payer rules and sample NPIs — not production payer policy. SNIP runs on the clean path only; rule table in SQL is mirrored in XSLT for evaluate (see `DESIGN.md` Risks).
