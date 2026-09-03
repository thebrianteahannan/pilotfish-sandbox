# HL7, EDI & FHIR Data Integration for Analytics & Reporting

Status: **IN PROGRESS** (website-verbatim of the public healthcare reporting demo)

Public page: https://healthcare.pilotfishtechnology.com/videos/healthcare-reporting-analytics-demo  
YouTube: https://www.youtube.com/watch?v=xgJjWRUqHFw (7:24)  
Source routes: Jenny HIMSS 2018 `07 - Aggregation for Analytics and Reporting`

## 1. Purpose
Show the eiConsole multi-source analytics route from the official video: HL7 over LLP, claims X12 over FTP, and FHIR JSON over REST, each normalized to a patient XML canonical, then written to a reporting table and posted as JSON.

## 2. Context / actors
- Sources: hospital ADT (LLP), provider 837 (FTP), cloud EMR FHIR Patient (REST)
- Destinations: SQL Server `AnalyticsDemo.dbo.PATIENT`, mock quality-reporting REST
- Demo vs production: synthetic samples only. Sibling HIMSS interfaces 01–03 are in `eip-root` so the console list matches the video open; only route 07 runs on EIP.

## 3. Inbound contract
| Feed | Transport | Sample |
|------|-----------|--------|
| HL7 v2.3 ADT^A08 | `HL7TCPListener` host port **10001** | `samples/test.hl7` (BUNNY / BUGS) |
| X12 837P | Regular FTP `demo/demo` host port **2121** | `samples/837-sample-encounter.edi` |
| FHIR Patient JSON | `POST /eip/rest/FHIR/Patient` | `samples/test_fhir.json` |

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| SQL Server `dbo.PATIENT` | SQLXML insert | HL7 row LASTNAME BUNNY |
| Analytics REST | JSON POST | File under `output/analytics/` |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `HL7TCPListener` / `FTPListener` / `RESTfulWebServiceListener` | Ports 10001, FTP, `/rest/FHIR` |
| Source Transform | Formats `HL7 to XML`, `EDI to XML`, `JSON-FHIR to XML` | Wire module + Data Mapper ToXML |
| Routing | `NullRoutingModule` | Both targets |
| Target Transform | `XML to DB` (FromXML SQLXML), `XML to JSON` | Jenny maps |
| Transport | `DatabaseSqlTransport`, `HttpPostTransport` | `$$db.*`, `$$simple.server.path` |

**FQCN sources:** Jenny HIMSS 2018 route + `PilotFish_V2` `modules.conf`. Image: `pilotfish-eip:23R1`. X12 tables: mount `EDI/TableData/x12`.

## 6. State & idempotency
- SQL insert is append-only. Resend duplicates (accepted).

## 7. Validation
- Checked: LLP ACK, PATIENT row, analytics JSON file
- Not checked: full 837 IG, FHIR profile, SNIP

## 8. Dual-write / side effects
- One inbound message → SQL insert and JSON POST

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| Med | EDI XML shape vs Jenny XSLT (2010AA billing provider) | Enhanced vs basic EDI XML | TableData `837-Q1` 5010; keep Jenny Loop_2010AA map |
| Med | FHIR JSON → XML element names | JSON module 2.0 vs 2018 mapper | Keep Jenny JSON-FHIR XSLT |
| Low | FTP PASV in Docker | EIP talks to `ftp` service | `delfer/alpine-ftp-server` with `ADDRESS=ftp` |

## 10. Ops
- Ports: Web UI **8154**, EIP **8153**, LLP **10001**, FTP **2121**, analytics **7072**, SQL **14344**
- Credentials: SQL `sa` / `PilotFish_Demo1!`; FTP `demo` / `demo`
- Heap: 2GB
- Cold start: SQL healthy + init, then EIP ~60–90s

## 11. Observability
- Logs: `logs/eip.log`
- Artifacts: `output/snapshots/`, `output/analytics/`, `output/debug-trace/`

## 12. Open questions
- None for this website slice.
