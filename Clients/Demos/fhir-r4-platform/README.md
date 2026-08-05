# FHIR R4 Expandable Platform (Phase 6)

Phases 1–6: CRUD · search · Bundle · HAPI validation · Keycloak writes · **async Bulk `$export`**.

```bash
docker compose up -d --build
./tools/smoke.sh
```

## Bulk export

```bash
TOKEN=... # client_credentials from Keycloak :8112
curl -sD- -H "Authorization: Bearer $TOKEN" \
  'http://127.0.0.1:8110/eip/rest/fhir/$export?_type=Patient,Observation'
# Poll Content-Location then download /$export-file/{job}?_type=Patient
```

See `DESIGN.md`.
