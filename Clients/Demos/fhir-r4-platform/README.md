# FHIR R4 Expandable Platform (Phase 5)

Multi-resource **FHIR R4 REST** on PilotFish with SQL store, search, Bundle transaction/batch, HAPI validation, and **Keycloak OAuth2 Bearer on writes**.

## Quick start

```bash
cd "Clients/Demos/fhir-r4-platform"
docker compose up -d --build
./tools/smoke.sh
```

| Where | URL |
|-------|-----|
| Web UI | http://127.0.0.1:8111/ |
| FHIR base | http://127.0.0.1:8110/eip/rest/fhir |
| Keycloak | http://127.0.0.1:8112/ (admin / admin) |

## Auth (writes)

POST/PUT/DELETE require:

```http
Authorization: Bearer <access_token>
```

```bash
TOKEN=$(curl -s -X POST http://127.0.0.1:8112/realms/fhir-demo/protocol/openid-connect/token \
  -d grant_type=client_credentials \
  -d client_id=fhir-r4-platform \
  -d client_secret=fhir-demo-secret | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')

curl -sS -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/fhir+json' \
  --data-binary @samples/Patient_alice.json \
  http://127.0.0.1:8110/eip/rest/fhir/Patient
```

GET metadata / read / search remain open for the demo. See `DESIGN.md`.
