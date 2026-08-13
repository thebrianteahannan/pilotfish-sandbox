# FHIR Profile Validation Processor (Phase 4)

Custom PilotFish `AbstractProcessor` wrapping **HAPI FHIR** instance validation (base R4 StructureDefinitions).

## Build

```bash
cd custom-modules/fhir-profile-validation-processor
docker build --target export --output type=local,dest=dist .
cp dist/modules-fhir-profile-validation.jar ../../pilotfish/custom-lib/
```

The demo `pilotfish/Dockerfile` copies `custom-lib/*.jar` into `WEB-INF/lib`.

## Route attributes

| Attribute | Meaning |
|-----------|---------|
| `fhir.ProfileValidationStatus` | `PASS` / `FAIL` / `SKIP` |
| `fhir.ValidationOutcome` | OperationOutcome JSON when validation fails (or structural pre-check fails) |
| `fhir.ValidationStatus` | Forced to `FAIL` when profile validation fails |

## Scope (honest)

- Base R4 profiles only (not US Core IG packages)
- Terminology / code-system checks relaxed for demo stability (`noTerminologyChecks`)
- Errors/fatal severities fail the interaction; warnings do not
