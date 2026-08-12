# PilotFish pitch materials

Sales / positioning PDFs and the scripts that regenerate them.

| PDF | Generator |
|-----|-----------|
| [Why_PilotFish_eiPlatform_Not_Just_AI.pdf](Why_PilotFish_eiPlatform_Not_Just_AI.pdf) | `python3 build_why_pilotfish_pdf.py` |
| [Healthcare_Insurance_PilotFish_Opportunity_Ideas.pdf](Healthcare_Insurance_PilotFish_Opportunity_Ideas.pdf) | `python3 build_healthcare_insurance_ideas_pdf.py` |

## Live market buzz (Reddit)

Hourly scout for EDI / HL7 / FHIR / EHR / ACORD integration chatter:

[`tools/healthcare-buzz-scout/`](../../tools/healthcare-buzz-scout/) — `docker compose up -d --build`, UI at http://localhost:8130/

Run generators from this directory (`docs/pitches/`).
