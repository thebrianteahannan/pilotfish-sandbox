# eiConsole for Healthcare – HL7 Demo

Verbatim sandbox of the public [HL7 Interface Demo](https://cms.pilotfishtechnology.com/hl7-interface-engine-demo/): hospital HL7 over LLP → HL7 XML → Data Mapper (patient XML, PID.7 date format) → SQL insert.

## 1. Purpose
Show the eiConsole for Healthcare route grid exactly as the website does: LLP Listener, HL7 2.x to XML, logical map of last name / first name / date of birth, one Target, SQL mapper, database Transport.

## 2. Context / actors
- Sources: Hospital ADT over HL7 LLP (TCP)
- Destinations: data-measures SQL Server (`dbo.Patients`)
- Demo vs production: synthetic ADT only. No SNIP, no real MPI.

## 3. Inbound contract
- Transport: **HL7 LLP** (`HL7TCPListener`) host port **2578**
- Format: HL7 v2.5.1 ADT^A01 (pipe-delimited), MLLP framed
- Identity: MSH-10 control ID
- Samples: `samples/hospital_ADT_A01.hl7`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| SQL Server `Hl7MeasuresDemo.dbo.Patients` | JDBC insert | Row has SMITH / JOHN / 1980-05-15 |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.hl7.HL7TCPListener` | Port 2578, Engine=PilotFish, async AA |
| Source Transform | Format `HL7 2.x to XML` | `HL7v2TransformationModule` + Data Mapper `hl7-xml-to-patient.xslt` |
| Logical map | Source format XSLT | LastName, FirstName, DateOfBirth; PID.7 `yyyyMMdd` → `yyyy-MM-dd` |
| Routing | `NullRoutingModule` | Single Target (website: one database) |
| Target Transform | Format `Patient XML to SQL` | Data Mapper `patient-to-sqlxml.xslt` → SQLXML Insert |
| Transport | `com.pilotfish.eip.modules.db.DatabaseSqlTransport` | JDBC via `$$sqlserver.*` |

**FQCN sources:** public demo + `PilotFish_V2` `modules.conf` + Med Rec `HL7 to XML` format + `csv-sftp-to-sql` / lab LLP skeletons. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency
- SQL insert is append-only. Resend duplicates (accepted).
- Snapshots under `output/snapshots/` match the website Testing Mode panes.

## 7. Validation
- What is checked: LLP ACK, patient XML date format, SQL row
- What is NOT checked: full ADT IG, MPI match
- Failure blocks outbound: HL7 parse / XSLT throw

## 8. Dual-write / side effects
- Order: LLP → Source Transform (HL7 XML + patient map) → Target Transform (SQLXML) → JDBC insert

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| Med | HL7 XML shape varies with friendly names | Mapper XSLT must be path-tolerant | local-name() + PID.7 / TS.1 |
| Med | 23R1 vs 26R1 docs | Website may show newer UI | Same modules; 23R1 config tags |
| Low | Website test starts after Listener | We send real MLLP so the Listener is in the path | Accepted (more complete) |

## 10. Ops
- Ports: Web UI **8142**, EIP **8141**, LLP **2578**, SQL **14342**
- Credentials: `sa` / `PilotFish_Demo1!` (demo only)
- Heap: 2GB
- Cold start: SQL healthy + init, then EIP ~60–90s

## 11. Observability
- Logs: `logs/eip.log`
- Artifacts: `output/snapshots/`, SQL `dbo.Patients`

## 12. Open questions
- None for this website slice.
