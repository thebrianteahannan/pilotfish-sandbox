# FHIR R4 Expandable Platform (Phase 6)

Phases 1–6: CRUD · search · Bundle · HAPI validation · Keycloak writes · **async Bulk `$export`**.

```bash
docker compose up -d --build
./tools/smoke.sh
```

## Stakeholder docs

| Doc | Path | Browser |
|-----|------|---------|
| Capability Brief (shareable) | `documents/FHIR_R4_Platform_Capability_Brief.pdf` | http://127.0.0.1:8111/documents/capability-brief.pdf |
| Route diagrams (technical) | `documents/FHIR_R4_Platform_V2_Route_Diagrams.pdf` | http://127.0.0.1:8111/documents/route-diagrams.pdf |

Regenerate:

```bash
python3 tools/export_stakeholder_brief.py
python3 tools/export_route_diagrams.py --config changed
```

## Bulk export

```bash
TOKEN=... # client_credentials from Keycloak :8112
curl -sD- -H "Authorization: Bearer $TOKEN" \
  'http://127.0.0.1:8110/eip/rest/fhir/$export?_type=Patient,Observation'
# Poll Content-Location then download /$export-file/{job}?_type=Patient
```

See `DESIGN.md`.
