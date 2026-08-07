# EDI assets (Sandbox)

## `TableData/` — canonical X12 IG table data + examples

Repo path: `EDI/TableData/x12/`

Washington Publishing Company (WPC) implementation-guide table data used by PilotFish EDI Transformation for **enhanced context** (named segments, loops, code context), plus:

| Asset | Examples |
|-------|----------|
| Per-IG table files | `sethead.txt`, `seghead.txt`, `eledetl.txt`, … |
| XSDs | `835-W1.xsd`, `270-A1` → `270-B1.xsd`, … |
| IG PDFs | `X221A1_Consolidated.pdf`, … |
| Wire examples | `<IG>/examples/*.edi` |
| Shared filters | `composite-elements.xml`, `condition-rules.xml`, `snip5-date-filter.xml` |

### Demo wiring (required for EDI interfaces)

Sandbox demos **do not** use the expired 23R1 trial tables (`UseInternalData=false`). Instead they mount this tree into EIP:

```text
EDI/TableData/x12  →  /usr/local/tomcat/webapps/eip/eip-root/edi-tabledata  (compose volume, read-only)
```

EDI Transformation / format modules set:

- `USE_ENHANCED_CONTEXT=true`
- `UseInternalData=false`
- `TransactionDataWithVersion` → `…/edi-tabledata/<IG>` with version `5010`  
  (via `PilotFishUtils.getWorkingDirectory()+'/edi-tabledata/<IG>'`)

Pick the IG folder that matches the interchange (e.g. `835-W1`, `278-A1` + `278-A3`, `270-A1` + `271-A1`, `837-Q1`).

Reference wire samples are also copied into each demo’s `samples/tabledata/` for UI/file drops; **story fixtures** under `samples/` remain the primary happy path.

See playbook **§3.6**.
