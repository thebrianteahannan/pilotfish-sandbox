# DESIGN.md — FHIR R4 Expandable Platform (Phase 1–5)

## Purpose

Expandable **HL7 FHIR R4** PilotFish platform with SQL store, search, Bundle execution, HAPI validation, and **Phase 5 Keycloak OAuth2 Bearer auth on writes**.

## Honest scope

| In Phase 1–5 | Explicitly deferred |
|--------------|---------------------|
| CRUD + soft delete | Full search grammar / `_include` / history |
| Token search (core-6) | US Core IG packages |
| Bundle transaction/batch | CapStatement `$validate` |
| HAPI base-R4 validation → HTTP 400 OO | Full SMART EHR launch / patient context |
| **Keycloak JWT on POST/PUT/DELETE** | Bulk `$export` |
| Open GET metadata/read/search (demo) | Fine-grained SMART scopes enforcement |

## Phased roadmap

1–4 done · **5 SMART/OAuth (this cut)** · 6 Bulk export

## Phase 5 auth

```text
Keycloak (port 8112) realm=fhir-demo
  client fhir-r4-platform / secret fhir-demo-secret
POST|PUT|DELETE → FhirJwtAuthProcessor (JWKS) → AuthStatus PASS|FAIL
  FAIL → HTTP 401 OperationOutcome + WWW-Authenticate
GET metadata/read/search → open (demo convenience)
```

Token (client credentials):

```bash
curl -s -X POST http://127.0.0.1:8112/realms/fhir-demo/protocol/openid-connect/token \
  -d grant_type=client_credentials \
  -d client_id=fhir-r4-platform \
  -d client_secret=fhir-demo-secret
```

## Ops

| Service | Host port |
|---------|-----------|
| SQL Server | 14338 |
| EIP | 8110 |
| Web UI | 8111 |
| Keycloak | 8112 |

Admin: `admin` / `admin` · Demo user: `fhiruser` / `FhirDemo1!`
