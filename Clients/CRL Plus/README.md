# CRL Plus

Implements the AIL electronic-order programming request using the Ladder / FGL client pattern.

## Design

- PDF: [`AIL_Programming_Design.pdf`](./AIL_Programming_Design.pdf)
- Regenerate: `python3 create_ail_design_pdf.py` (venv with reportlab)

## Interface changes

Under `eip-root/interfaces/Clients/interfaces/AmericanIncomeLife/`:

| Route | Role |
|-------|------|
| `1 - 121 Incoming` | HTTP POST path `ail` + basic auth; `sourceClient=AIL` |
| `2 - 121 Response` | Sync 121 response |
| `3 - 1122 Status or Result POST` | Listener `AIL 1122 Status` |
| `4 - 1122 POST Response` | Archive / mark sent |
| `ProcessStatus` | Retained for compatibility |

Status routing update in `eip-root/interfaces/Status/routes/4 - Route to client specific/route.xml`:

- `sourceClient=AIL` → ServiceName **`AIL 1122 Status`** (was `AmericanIncomeLife 122 Status`)

Sandbox TEST credentials (rotate for real TEST/PROD):

```
ail=AilSandbox$Test1
AIL=AilSandbox$Test1
```

External URL pattern: `https://plus.intg.crlcorp.com/http-post/ail`

## Sandbox (LAN web UI)

```bash
cd "Clients/CRL Plus/sandbox"
docker compose up -d --build
```

- UI: http://localhost:8094/ (LAN: http://&lt;your-lan-ip&gt;:8094/)
- POST orders: `http://&lt;lan-ip&gt;:8094/http-post/ail` with Basic auth above

```bash
curl -u 'ail:AilSandbox$Test1' \
  -H 'Content-Type: text/xml' \
  --data-binary @sample-data/ail-121-order.xml \
  "http://localhost:8094/http-post/ail"
```
