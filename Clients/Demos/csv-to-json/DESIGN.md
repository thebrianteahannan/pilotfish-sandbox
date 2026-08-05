# CSV to JSON — Design

## 1. Purpose

Simple PilotFish demo that polls a folder for CSV files, converts them to JSON, and writes the JSON into an output folder.

## 2. Context / actors

- Sources: Operators / Web UI dropping `.csv` into `input/inbound`
- Destinations: JSON files under `output/json`; archived CSV under `output/archive`
- Demo vs production: **Demo only**

## 3. Inbound contract

- Transport: `DirectoryListener` polling `$$CSV_INBOUND_DIRECTORY`
- Format: comma-delimited CSV with a header row (Dialect A via CSV Transformation)
- Identity fields: source filename (`com.pilotfish.FileName`)
- Samples path: `samples/*.csv`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| `output/json` | `.json` (XML→JSON of CSV Dialect A) | File written with same basename |
| `output/archive` | Original `.csv` | Listener Move post-process |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.file.DirectoryListener` | `.csv` only; Move → archive |
| Source processor | `com.pilotfish.eip.modules.transform.CSVTransformationProcessor` | CSV → XML (Dialect A `XCSData`) |
| FormatProfile | Relay | Pass-through |
| Router | `com.pilotfish.eip.modules.routing.XPathRoutingModule` | Always `true()` on XML → Write JSON |
| Target processor | `com.pilotfish.eip.modules.transform.XSLTProcessor` (`csv-xml-to-json.xslt`) | Dialect A XML → `{"records":[…]}` JSON text; after route so XPath router sees XML |
| Transport | `com.pilotfish.eip.modules.file.DirectoryTransport` | `.json` → `$$JSON_OUTPUT_DIRECTORY` |

## 6. State & idempotency

- Status model: file presence only (no SQL)
- When state advances: listener Moves CSV to archive after pick-up; JSON overwrite by basename
- Dedup keys: none (demo overwrite)
- Retry / poison: kickout path not implemented (documented)

## 7. Validation

- What is checked: file extension `.csv` only
- What is NOT checked: schema, column presence, quote/escaping edge cases, JSON schema
- Does failure block outbound? No dedicated kickout — bad CSV may fail the transaction (see `logs/eip.log`)

## 8. Dual-write / side effects

- Order of commits: archive Move (listener) then JSON write
- Compensation: none — accepted demo risk that archive can succeed while JSON write fails

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation / accepted? |
|----------|------|------------------------|
| Med | Archive-before-JSON (listener Move) | Accepted demo risk; labeled in README |
| Med | No schema validation / kickout | Explicitly not implemented |
| Low | Native `JSONTransformationProcessor` emits duplicate sibling keys for Dialect A | Prefer XSLT `{"records":[…]}` for valid multi-row JSON |
| Low | Docs/V2 may be newer than `23R1` | Modules present in `modules-csv` / `modules-json` 23R1 jars |

## 10. Ops

- Ports: EIP **8108**, Web UI **8109** (no SQL)
- LAN: `LAN_HINT=http://192.168.68.52:8109/`
- Cold start ~60–90s for EIP

## 11. Observability

- `logs/eip.log`
- Web UI Results tab lists `output/json` and `output/archive`
- Route design PDF under `documents/CSV_to_JSON_V2_Route_Diagrams.pdf`

## 12. Open questions

- Optional kickout directory for malformed CSV
- Optional XSLT polish for flatter `{ "records": [ … ] }` JSON
