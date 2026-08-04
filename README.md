# pilotfish-sandbox

Local PilotFish eiPlatform demos and client interface work.

## Building interfaces

Agents constructing any interface under `Clients/` must follow:

- Markdown: [docs/INTERFACE_CONSTRUCTION_PLAYBOOK.md](docs/INTERFACE_CONSTRUCTION_PLAYBOOK.md)
- PDF: [docs/INTERFACE_CONSTRUCTION_PLAYBOOK.pdf](docs/INTERFACE_CONSTRUCTION_PLAYBOOK.pdf)

**Module / catalog sources (required):**

- [`PilotFish_Documentation/`](PilotFish_Documentation/) — tracker + deep-dive module docs
- [`PilotFish_V2/`](PilotFish_V2/) — shared EIP module source + `modules.conf` (same modules V1 uses)

(Also enforced via `.cursor/rules/pilotfish-interface-construction.mdc` when working under `Clients/**`.)

## Reference demos

| Demo | Path |
|------|------|
| EDI 837 + SNIP + SQL Server | `Clients/Demos/edi-837-snip-sqlserver/` |
| HL7 Healthcare Automation | `Clients/Demos/hl7-healthcare-automation/` |
| Medical Lab HL7 LLP → MEDITECH | `Clients/Demos/medical-lab-hl7-llp/` |
| Medical Device HL7 → EHR | `Clients/Demos/medical-device-hl7-ehr/` |
| FHIR Patient Exchange | `Clients/Demos/fhir-patient-exchange/` |
