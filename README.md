# pilotfish-sandbox

Local PilotFish eiPlatform demos and client interface work.

## Building interfaces

Agents constructing any interface under `Clients/` must follow:

- Markdown: [docs/INTERFACE_CONSTRUCTION_PLAYBOOK.md](docs/INTERFACE_CONSTRUCTION_PLAYBOOK.md) (**authoritative**; regenerate PDF when practical)
- PDF: [docs/INTERFACE_CONSTRUCTION_PLAYBOOK.pdf](docs/INTERFACE_CONSTRUCTION_PLAYBOOK.pdf)
- Build timing: `documents/build-timing.json` per demo (§4.1; schema `docs/templates/build-timing.example.json`)
- Demo Docker inventory: `python3 tools/list_sandbox_demo_docker.py` (§5.1)

**Module / catalog sources (required):**

- [`PilotFish_Documentation/DOCUMENTATION_LOCATION.txt`](PilotFish_Documentation/DOCUMENTATION_LOCATION.txt) — pointer to the external docs project (`/Users/brianhannan/Documents/PilotFish Documentation`); use `Documents/` there for tracker + deep dives
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
| EDI 270/271 Eligibility | `Clients/Demos/edi-270-271-eligibility/` |
| FHIR R4 Expandable Platform | `Clients/Demos/fhir-r4-platform/` |
| CSV to JSON | `Clients/Demos/csv-to-json/` |
| XML → EDI 834 | `Clients/Demos/xml-to-edi-834/` (`./docker-run-834.sh`) |
| FTP Named Download Trigger | `Clients/Demos/ftp-named-download-trigger/` |
| EDI 837P → QCare | `Clients/Demos/edi-837p-qcare/` |
