# Sandbox demos

Demos are grouped by audience. The **slug** (last folder name) is unchanged so Docker Compose project names stay the same. Tools resolve `--root <slug>`.

| Category | Path | Demos |
|----------|------|--------|
| **Insurance / EDI** | `Insurance/EDI/` | `edi-270-271-eligibility`, `edi-270-271-realtime`, `edi-276-277-claim-status`, `edi-278-prior-auth`, `edi-835-oci-bucket`, `edi-835-payment-integrity`, `edi-837-claim-scrub`, `edi-837-snip-sqlserver`, `edi-837p-qcare`, `edi-999-ta1-ack-triage`, `xml-to-edi-834` |
| **Medical / HL7** | `Medical/HL7/` | `doc-healthcare-hl7-workflow`, `hl7-healthcare-automation`, `medical-device-hl7-ehr`, `medical-lab-hl7-llp` |
| **Medical / FHIR** | `Medical/FHIR/` | `fhir-r4-platform` |
| **Other** | `Other/` | `csv-sftp-to-sql`, `csv-to-json`, `ftp-named-download-trigger`, `http-post-to-rabbitmq`, `sqlserver-pilotfish-demo`, `triggered-ftp-download` |
| Shared Web UI | `_shared/` | Info / Timing / build-live chrome copied into each demo |

New demo:

```bash
python3 tools/scaffold_demo_stage.py --slug my-new-demo --title "My New Demo" --port 8140
# category is inferred (edi-* → Insurance/EDI, *hl7* → Medical/HL7, fhir-* → Medical/FHIR, else Other)
# or: --category Insurance/EDI
```
