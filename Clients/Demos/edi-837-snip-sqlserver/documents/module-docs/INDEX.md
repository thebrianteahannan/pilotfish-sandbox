# Module documentation — `edi-837-snip-sqlserver`

Deep-dive PDFs for every PilotFish module used by this interface.
Synced `2026-08-12T16:56:41Z` from `/Users/brianhannan/Documents/PilotFish Documentation/Documents`.

Re-sync after route changes:

```bash
python3 tools/sync_module_docs.py --root Clients/Demos/edi-837-snip-sqlserver
```

| Kind | UI type | PDF | Class |
|------|---------|-----|-------|
| Listener | Database Polling (SQL) | [`PilotFish-Database-Polling-SQL-Listener-Reference-26R1.11.pdf`](PilotFish-Database-Polling-SQL-Listener-Reference-26R1.11.pdf) | `DatabaseSqlListener` |
| Listener | Programmable (Trigger) | [`PilotFish-Programmable-Trigger-Listener-Reference-26R1.11.pdf`](PilotFish-Programmable-Trigger-Listener-Reference-26R1.11.pdf) | `TriggerableListener` |
| Processor | Data Attribute Swapper | [`PilotFish-Data-Attribute-Swapper-Reference-26R1.11.pdf`](PilotFish-Data-Attribute-Swapper-Reference-26R1.11.pdf) | `SaveDataToAttributeProcessor` |
| Processor | EDI | [`PilotFish-EDI-Transformation-Reference-26R1.11.pdf`](PilotFish-EDI-Transformation-Reference-26R1.11.pdf) | `EDITransformationProcessor` |
| Processor | EDI SNIP Validation | [`PilotFish-EDI-SNIP-Validation-Reference-26R1.11.pdf`](PilotFish-EDI-SNIP-Validation-Reference-26R1.11.pdf) | `EdiSNIPValidationProcessor` |
| Processor | File Writing | [`PilotFish-File-Writing-Reference-26R1.11.pdf`](PilotFish-File-Writing-Reference-26R1.11.pdf) | `FileWriteProcessor` |
| Processor | XPath | [`PilotFish-XPath-Forking-Reference-26R1.11.pdf`](PilotFish-XPath-Forking-Reference-26R1.11.pdf) | `XPathForkingProcessor` |
| Processor | XPath Evaluation | [`PilotFish-XPath-Evaluation-Reference-26R1.11.pdf`](PilotFish-XPath-Evaluation-Reference-26R1.11.pdf) | `XPathEvaluatorProcessor` |
| Processor | XSLT Transformation | [`PilotFish-XSLT-Transformation-Reference-26R1.11.pdf`](PilotFish-XSLT-Transformation-Reference-26R1.11.pdf) | `XSLTProcessor` |
| Routing | Conditional Node Router | [`PilotFish-Conditional-Node-Router-Reference-26R1.11.pdf`](PilotFish-Conditional-Node-Router-Reference-26R1.11.pdf) | `ConditionalNodeRoutingModule` |
| Routing | Conditional Node Router | [`PilotFish-Conditional-Node-Router-Reference-26R1.11.pdf`](PilotFish-Conditional-Node-Router-Reference-26R1.11.pdf) | `XPathRoutingModule` |
| Transport | Directory / File | [`PilotFish-Directory-File-Transport-Reference-26R1.11.pdf`](PilotFish-Directory-File-Transport-Reference-26R1.11.pdf) | `DirectoryTransport` |
| Transport | Route to Route | [`PilotFish-Route-to-Route-Transport-Reference-26R1.11.pdf`](PilotFish-Route-to-Route-Transport-Reference-26R1.11.pdf) | `EIPTransport` |
