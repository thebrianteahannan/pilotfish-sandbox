# EDI 834 CSV Excel Conversion

New Sandbox demo for the public [CSV / Excel / TXT → X12 834 tutorial](https://healthcare.pilotfishtechnology.com/videos/edi-csv-excel-834-conversion-tutorial/).

This is **not** a reuse of `xml-to-edi-834`. Forward route: CSV or tab-delimited TXT → 834. Reverse route: 834 → CSV. Excel workbooks are converted to CSV in the Web UI (23R1 does not assume `ExcelSheetProcessor`).

## Run

```bash
cd Clients/Demos/Insurance/EDI/edi-csv-excel-834
docker compose --profile full up -d --build
```

- Local Web UI: http://127.0.0.1:8140/
- LAN Web UI: http://192.168.68.62:8140/
- EIP: http://127.0.0.1:8139/eip/

Same links are on the Info tab Access list.

## eiConsole walkthrough

YAML: `documents/eiconsole-walkthrough.yaml`  
Driver (Sandbox copy): `tools/swing-demo-auto` — the sibling Swing project is left untouched.

```bash
python3 tools/export_construction_video.py --root edi-csv-excel-834
```

That path records eiConsole (Swing Robot) and muxes AvaNeural narration.

Recorded output: `documents/construction-replay.mp4` plus `documents/construction-replay-transcript.{pdf,txt}`.

## Smoke

```bash
python3 tools/run_interface_tests.py --root edi-csv-excel-834 --wait
```
