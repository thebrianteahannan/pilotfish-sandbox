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
| Expert due diligence (hard questions) | `documents/FHIR_R4_Platform_Expert_Due_Diligence.pdf` | http://127.0.0.1:8111/documents/expert-due-diligence.pdf |
| AWS deployment guide | `documents/FHIR_R4_Platform_AWS_Deployment_Guide.pdf` | http://127.0.0.1:8111/documents/aws-deployment-guide.pdf |
| Route diagrams (technical) | `documents/FHIR_R4_Platform_V2_Route_Diagrams.pdf` | http://127.0.0.1:8111/documents/route-diagrams.pdf |
| Test plan | `documents/FHIR_R4_Platform_Test_Plan.pdf` | http://127.0.0.1:8111/documents/test-plan.pdf |
| Test results (PDF) | `documents/test-results.pdf` | http://127.0.0.1:8111/documents/test-results.pdf |
| Test results (HTML) | `documents/test-results.html` | http://127.0.0.1:8111/documents/test-results.html |

Regenerate:

```bash
python3 tools/export_stakeholder_brief.py
python3 tools/export_fhir_expert_critique_pdf.py
python3 tools/export_fhir_aws_deploy_pdf.py
python3 tools/export_route_diagrams.py --config compact
# Overview pages collapse Processor Groups; following pages expand each group.
python3 tools/export_test_plan_pdf.py
python3 tools/run_interface_tests.py --wait
# or after compose:
./tools/post_up_tests.sh
# while building:
python3 tools/run_interface_tests.py --watch
```

See Web UI **Tests** tab for the pass/fail list.

## Secrets / credentials (read this)

- **GitHub “Vault token in route PDF” alerts** are almost always **false positives**:
  compressed PNG streams randomly match `s.` + 24 alphanumerics. Route PDF
  export now scrubs that scanner pattern; you can also run
  `python3 tools/scrub_pdf_secret_false_positives.py --demos`. **No HashiCorp
  Vault is used in this demo** — nothing to rotate for those alerts.
- **Demo-only local credentials** (`PilotFish_Demo1!`, `fhir-demo-secret`,
  Keycloak `admin`) are intentionally checked in so `docker compose up` works
  offline. They are **not** production secrets — replace before any shared or
  cloud deploy. Route module XML keeps passwords as `$$…` refs; the Web UI
  redacts sensitive env values.
## Bulk export

```bash
TOKEN=... # client_credentials from Keycloak :8112
curl -sD- -H "Authorization: Bearer $TOKEN" \
  'http://127.0.0.1:8110/eip/rest/fhir/$export?_type=Patient,Observation'
# Poll Content-Location then download /$export-file/{job}?_type=Patient
```

See `DESIGN.md`.
