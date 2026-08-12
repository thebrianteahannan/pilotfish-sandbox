# EDI 837P → QCare Flat File

PilotFish Sandbox demo: directory-poll **837P** claims, parse with TableData `837-Q1`, map to QCare’s **2100-byte** `OT`/`B837` outpatient fixed-width record, write `output/qcare/`.

**Demo only** — golden-path fidelity against the three client samples. Not full WTX/ITX parity (REPOSHDR claim numbering approximated; custom `UB4_*` / prepaid CAS functions not ported).

## Ports

| Service | Host |
|---------|------|
| PilotFish EIP | **8123** |
| Demo Web UI | **8125** |

## URLs

- Local: http://localhost:8125/
- LAN: http://192.168.68.62:8125/ (re-detect with `ipconfig getifaddr en0`)

## Quick start

```bash
cd "Clients/Demos/edi-837p-qcare"
LAN_IP=$(ipconfig getifaddr en0)
# ensure docker-compose.yml LAN_HINT / EIP_PUBLIC_URL use $LAN_IP
docker compose up -d --build
# wait ~60–90s for EIP
cp samples/MCQRQ74837PS803.TXT input/inbound/
# or use Web UI → Submit 837P
ls -la output/qcare output/debug output/archive
```

## Pipeline

1. `DirectoryListener` polls `input/inbound` (`.txt`/`.edi`/`.837`), Move → `output/archive`
2. Format: `EDITransformationModule` + fork `//Transaction` (`edi-tabledata/837-Q1` @ 5010)
3. Debug EDI XML → `output/debug`
4. `transform-837p-to-qcare.xslt` → 2100-char QCare record
5. `DirectoryTransport` → `output/qcare/<CLM01>_qcare.txt`

## Samples

| File | Role |
|------|------|
| `samples/MCQRQ74837PS801.TXT` … `803.TXT` | Inbound 837P |
| `samples/expected/qcare…SEQF.staged` | Golden 3×2100-byte QCare lines |
| `samples/mapping/*.xlsx` | Client WTX field map |

## Docs

- `DESIGN.md`
- `documents/EDI837P_QCare_V2_Route_Diagrams.pdf`
- `documents/EDI837P_QCare_Capability_Brief.pdf`
- `documents/EDI837P_QCare_Test_Plan.pdf`

```bash
python3 tools/convert_routes_to_v2.py
python3 tools/export_route_diagrams.py --config compact
python3 tools/export_stakeholder_brief.py
python3 tools/export_test_plan_pdf.py
python3 tools/run_interface_tests.py --wait
```

## Limitations

- Golden-path field coverage (identity, DX, procedure, amounts, addresses) — not all 336 Excel leaf fields
- Claim-site / claim-number header (pos 7–25) is demo-stable, not byte-identical to staged REPOSHDR values
- One QCare record per `Transaction` (samples are single LX); multi-line fork is a follow-up
- Archive Move can succeed before QCare write (accepted demo risk)
