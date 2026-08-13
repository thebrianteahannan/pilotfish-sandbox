# SQL Server PilotFish XML Export — Design

Status: **WORKING**

## 1. Purpose

Poll SQL Server `PilotFishDemo.dbo.Captures` on a timer and write the current result set as one pretty-printed XML file. Demo-only: no business transform, no SNIP, no dual-write.

## 2. Context / actors

- Sources: SQL Server 2022 (`PilotFishDemo.dbo.Captures`)
- Destinations: XML file `captures_export.xml` on the EIP output volume
- Demo vs production: Demo only (SA login, `encrypt=true;trustServerCertificate=true`, overwrite the same file each poll)

## 3. Inbound contract

- Transport: Database Polling (SQL) listener, JDBC, every 15 seconds
- Format / envelope: SQL-XML (`SelectCapturesSQL.xml`) → XML result document (`Execute into="records" as="Capture"` + `XMLOut`)
- Identity fields: `CaptureId` (int, identity)
- Samples path: seed rows in `sql/01_init.sql` (1001–1003); Demo tab can insert more

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| `/opt/pilotfish/output/captures_export.xml` | Pretty-printed XML (2-space indent) | File exists, contains seeded `CaptureId` 1001, and indented tags (`  <RECORDS>` / `  <CAPTURE>`) |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.db.DatabaseSqlListener` (Database Polling (SQL)) | Docs: 26R1.11; runtime `pilotfish-eip:23R1`. `PollingInterval=15`, `UseSingleOutputStream=true`, `InputFile=SelectCapturesSQL.xml`. JDBC via `$$sqlserver.*`. Skeleton: `edi-837-snip-sqlserver` poll route. |
| Listener processors | none | Do **not** put XML Formatting here — listener-side has no effect on the file write (§1.4). |
| Router | `com.pilotfish.eip.modules.routing.XPathRoutingModule` (shown as Conditional Node Router in V2) | `count(//CAPTURE \| //Capture) > 0` → file transport. Same module as `edi-837-snip-sqlserver`. |
| Target processors | `com.pilotfish.eip.modules.transform.XMLFormattingProcessor` | On the **transport**, before Directory File. Indent is hardcoded to 2 spaces. |
| Transports | `com.pilotfish.eip.modules.file.DirectoryTransport` | `TargetDirectory=$$XML_OUTPUT_DIRECTORY`, `FileName=captures_export`, `AppendToFile=Overwrite`. Skeleton: `edi-999-ta1-ack-triage` Directory File transport. |

## 6. State & idempotency

- Status model: table `Status` is display-only (COMPLETE / PENDING). Poll does **not** claim or update rows.
- When state advances: n/a — each poll re-exports the whole table
- Dedup keys: `CaptureId` in SQL; file overwrite (last poll wins)
- Retry / poison: none; failed poll logs in EIP. No kickout directory.

## 7. Validation

- What is checked: JDBC query must return well-formed XML or XML Formatting throws
- What is NOT checked: SNIP, schema XSD, business rules
- Does failure block outbound? (yes/no): yes — no file write if the processor throws

## 8. Dual-write / side effects

- Order of commits: SQL is read-only from EIP; Web UI inserts are a separate demo side effect
- Compensation: none
- Demo shortcuts (if any): SA password in compose; trust server cert; overwrite one file

## 9. Risks & bottlenecks

| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| High | SA login on the LAN port | Demo SQL is published on 14342 | Accepted demo-only; documented on Info tab |
| Med | Overwrite semantics | Each poll replaces `captures_export.xml` | Accepted; Demo tab shows latest file |
| Med | Docs 26R1.11 vs image 23R1 | Config tag names could drift | Used tags that already work on 23R1 in `edi-837-snip-sqlserver` / `csv-sftp-to-sql` |
| Low | Unbounded poll | 15s is light (one SELECT) | Accepted |

## 10. Ops

- Ports: EIP 8136, Web UI 8137, SQL Server 14342
- Volumes: `./output` → `/opt/pilotfish/output`; `./sql` into init container
- Heap / special JVM: default G1, 256–1024M
- Dependencies / cold start: SQL healthy → `sql/01_init.sql` → EIP. JDBC driver `mssql-jdbc-12.8.1.jre11.jar` in EIP image (same as `csv-sftp-to-sql`).

## 11. Observability

- Logs: bind-mount `./logs` to Tomcat EIP logs
- Kickout dir: none
- Transaction / debug tracing: `debuggingTrace=true` on the route; SQLXML `LogSQL=true`

## 12. Open questions

- None for this demo scope.
