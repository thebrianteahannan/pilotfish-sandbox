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
| Test plan | `documents/FHIR_R4_Platform_Test_Plan.pdf` | http://127.0.0.1:8111/documents/test-plan.pdf |
| Test results | `documents/test-results.html` | http://127.0.0.1:8111/documents/test-results.html |

Regenerate:

```bash
python3 tools/export_stakeholder_brief.py
python3 tools/export_route_diagrams.py --config changed
python3 tools/export_test_plan_pdf.py
python3 tools/run_interface_tests.py --wait
# or after compose:
./tools/post_up_tests.sh
# while building:
python3 tools/run_interface_tests.py --watch
```

See Web UI **Tests** tab for the pass/fail list.
## Bulk export

```bash
TOKEN=... # client_credentials from Keycloak :8112
curl -sD- -H "Authorization: Bearer $TOKEN" \
  'http://127.0.0.1:8110/eip/rest/fhir/$export?_type=Patient,Observation'
# Poll Content-Location then download /$export-file/{job}?_type=Patient
```

See `DESIGN.md`.
