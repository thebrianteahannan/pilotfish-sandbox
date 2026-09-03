# HL7, EDI & FHIR Data Integration for Analytics & Reporting

Website-verbatim of [the public healthcare reporting demo](https://healthcare.pilotfishtechnology.com/videos/healthcare-reporting-analytics-demo) ([YouTube 7:24](https://www.youtube.com/watch?v=xgJjWRUqHFw)). Routes come from Jenny’s HIMSS 2018 aggregation interface.

## Run

```bash
cd "Clients/Demos/Medical/HL7/healthcare-reporting-analytics-demo"
docker compose --profile full up -d --build
```

- Local Web UI: http://127.0.0.1:8154/
- EIP: http://127.0.0.1:8153/eip/
- HL7 LLP: `127.0.0.1:10001`
- FTP: `127.0.0.1:2121` (`demo` / `demo`)
- Analytics: http://127.0.0.1:7072/aggregationanalytics/restservice
- SQL Server: `127.0.0.1:14344` (`sa` / `PilotFish_Demo1!`)

Stage UI only: `docker compose --profile stage up -d --build`

## Smoke

From the Demo tab, send `test.hl7` over LLP and confirm a `BUNNY` row in `dbo.PATIENT` plus a JSON post under `output/analytics/`.
