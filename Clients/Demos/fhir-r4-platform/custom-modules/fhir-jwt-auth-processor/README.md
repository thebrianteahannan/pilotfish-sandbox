# fhir-jwt-auth-processor (reference only — NOT baked into the image)

This custom module was the Phase 5 JWKS/local JWT validator. Auth is now implemented as a
PilotFish callout route:

- `eip-root/.../routes/0 - Keycloak JWT Auth/route.xml` (diagrams)
- `pilotfish/demo-eip-root/routes/0 - Keycloak JWT Auth/route.xml` (runtime)
- Parent `1 - FHIR R4 REST Platform` uses **Call Route** (synchronous) → Keycloak
  **token introspection** via stock **HTTP Post** + attribute processors.

Sources remain here for historical comparison only. Do not re-add the JAR to
`pilotfish/Dockerfile` unless a concrete gap forces a custom module (see playbook
§3.4 Prefer PF routes over custom modules).
