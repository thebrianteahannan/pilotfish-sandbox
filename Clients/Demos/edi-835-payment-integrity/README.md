# EDI 835 Payment Integrity Demo

Runnable PilotFish demo of opportunity idea **2.5 — Payment integrity / 835 that finance can trust**:

**Directory drop EDI 835 → split ST → match Open AR (SQL) → matched vs exception buckets + underpay alert CSV**

Separate from the OCI Object Storage 835 demo — this one focuses on remittance enrichment and exception theater for finance.

## What it does

1. **SQL Server** seeds `OpenAR` claim lineage (expected paid amounts)
2. **Route 1** polls `input/inbound/` for `.edi` / `.835`, splits each ST, looks up Open AR, scores underpay, stages `RemitDecision` XML
3. **Route 2** routes staged decisions to:
   - `output/matched/` (paid within $0.01 of expected)
   - `output/exceptions/` (underpay or no AR)
   - `output/underpay/underpay_alerts.csv` (underpay rows)
4. Updates Open AR `Status` (`MATCHED` / `UNDERPAY` / `EXCEPTION`)

Sample outcomes for `samples/sample_835_underpays.edi`:

| Claim | Result |
|-------|--------|
| PATCLAIM001 | Exception + underpay CSV (expected 500, paid 400.25) |
| PATCLAIM002 | Matched (88.00) |
| PATCLAIM003 | Matched (200.00) |
| PATCLAIM999 | Exception `NO_AR` (not in OpenAR) |

## Prerequisites

- Docker Desktop running
- Local image `pilotfish-eip:23R1` already built from the PilotFish Sandbox root

## Run

```bash
cd "Clients/Demos/edi-835-payment-integrity"
docker compose up -d --build
```

Wait ~60–90s for SQL + EIP, then open the Web UI.

## Ports

| Service | Host port |
|---------|-----------|
| SQL Server | 14339 |
| PilotFish EIP | 8110 |
| Demo Web UI | 8111 |

- Web UI (local): http://localhost:8111/
- Web UI (LAN): http://192.168.68.52:8111/
- PilotFish EIP: http://localhost:8110/eip/
- Route diagrams: http://localhost:8111/documents/route-diagrams.pdf · http://192.168.68.52:8111/documents/route-diagrams.pdf
- Capability brief: http://localhost:8111/documents/capability-brief.pdf · http://192.168.68.52:8111/documents/capability-brief.pdf

## Useful commands

```bash
docker compose logs -f pilotfish
ls -la output/matched output/exceptions output/underpay
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'PilotFish_Demo1!' -C -d Edi835PaymentIntegrity \
  -Q "SELECT ClaimControlNumber, ExpectedPaid, Status FROM dbo.OpenAR ORDER BY ClaimControlNumber"
./tools/post_up_tests.sh
docker compose down -v
```

## Docs

- `DESIGN.md` — contracts, risks, ops
- `documents/EDI835_Payment_Integrity_V2_Route_Diagrams.pdf`
- `documents/EDI835_Payment_Integrity_Capability_Brief.pdf`

## Notes

Demo-only credentials (`PilotFish_Demo1!`). No PM/EHR posting, no full 835 SNIP. Underpay threshold is $0.01 absolute variance.
