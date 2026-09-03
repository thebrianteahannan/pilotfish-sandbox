# Module documentation — `hl7-interface-engine-demo`

Deep-dive PDFs for every PilotFish module used by this interface.
Synced `2026-08-31T18:56:01Z` from `/Users/brianhannan/Documents/PilotFish Documentation/Documents`.

Re-sync after route changes:

```bash
python3 tools/sync_module_docs.py --root Clients/Demos/Medical/HL7/hl7-interface-engine-demo
```

| Kind | UI type | PDF | Class |
|------|---------|-----|-------|
| Listener | HL7 LLP | [`PilotFish-HL7-LLP-Listener-Reference-26R1.11.pdf`](PilotFish-HL7-LLP-Listener-Reference-26R1.11.pdf) | `HL7TCPListener` |
| Processor | File Writing | [`PilotFish-File-Writing-Reference-26R1.11.pdf`](PilotFish-File-Writing-Reference-26R1.11.pdf) | `FileWriteProcessor` |
| Processor | HL7 XML | [`PilotFish-HL7-XML-Guide-26R1.11.md`](PilotFish-HL7-XML-Guide-26R1.11.md) | `HL7TransformationProcessor` |
| Processor | XSLT Transformation | [`PilotFish-XSLT-Transformation-Reference-26R1.11.pdf`](PilotFish-XSLT-Transformation-Reference-26R1.11.pdf) | `XSLTProcessor` |
| Transport | Database (SQL) | [`PilotFish-Database-SQL-Transport-Reference-26R1.11.pdf`](PilotFish-Database-SQL-Transport-Reference-26R1.11.pdf) | `DatabaseSqlTransport` |
