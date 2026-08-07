# DESIGN — EDI 837 Claim Scrub (pre-clearinghouse)

## 1. Intent

Demonstrate **claims rejection reduction before the clearinghouse**: SNIP-ready 837 generation plus **payer-specific business edits** (missing referring NPI, invalid Place of Service). Failures land in a human-readable **kickout work queue**; only clean claims write outbound 837 + SNIP. Every scrub decision is copied to a **BI outcome** folder.

## 2. Actors / systems

| System | Role |
|--------|------|
| SQL Server `Edi837ClaimScrub` | Claims, lines, patients, providers, `PayerEditRules` |
| eiPlatform 23R1 | Poll → fork → payer-edit evaluate → router → kickout **or** EDI+SNIP |
| Web UI :8115 | Inject claims, view kickouts / clean EDI / SNIP, review PDFs including **test results** |

## 3. Pipeline

| Stage | Module | Notes |
|-------|--------|-------|
| R1 Poll | `DatabaseSqlListener` + `SelectClaimsSQL.xml` | Claim PENDING→PROCESSED; includes `ReferringNpi` |
| Handoff | `EIPTransport` | Trigger `Scrub Claim And Route` |
| Fork | Format `Split Claims` / `XPathForkingModule` | `//CLAIM \| //Claim` |
| Evaluate | `XSLTProcessor` `transform-evaluate-payer-edits.xslt` | Synthetic payer profile (mirrors `PayerEditRules`) |
| Attributes | `XPathEvaluatorProcessor` | Sets `MatchBucket`, `Disposition`, `ReasonSummary` |
| Branch | `ExecuteProcessor` OGNL on `MatchBucket` | `kickout` vs `clean` (always lands on scrub target after fork) |
| Kickout | `FileWriteProcessor` → `output/kickouts/` | Decision XML (human summary + reasons) |
| BI | `FileWriteProcessor` → `output/bi/` | Same decision for both buckets |
| Clean | EDI XML → `EDITransformationProcessor` (TableData `837-Q1`) → EDI file → SNIP 1–3 | `output/edi`, `output/snip` |
| Complete | `NullTransport` | No-op after gated processors |

## 4. Synthetic payer edits

| Payer | Rule | Behavior |
|-------|------|----------|
| AHLIC `66783JJT` | `MISSING_REFERRING_NPI` | Reject when `ReferringNpi` empty |
| AHLIC `66783JJT` | `INVALID_POS` | Allow POS `11`,`12` only |
| MEDICAID MD `MDCAID01` | `INVALID_POS` | Allow POS `11`,`21`,`22`; referring NPI optional |

Seed: 5001 clean AHLIC; 5002 kickout missing NPI; 5003 kickout POS 99; 5004 clean Medicaid POS 21.

## 5. X12 TableData

Compose mounts `EDI/TableData/x12` → `eip-root/edi-tabledata`. XML→EDI uses `USE_ENHANCED_CONTEXT=true`, `UseInternalData=false`, `TransactionDataWithVersion` → `837-Q1` @ 5010 (playbook §3.6).

## 6. Ports

| Service | Host |
|---------|------|
| SQL Server | 14341 |
| EIP | 8114 |
| Web UI | 8115 |

## 7. Risks (demo-honest)

| Sev | Risk | Mitigation |
|-----|------|------------|
| Med | Payer rules duplicated in XSLT (not live SQL join) | UI reads `PayerEditRules`; DESIGN calls out dual source |
| Med | Claim marked PROCESSED before scrub completes | Same claim-before-complete demo pattern as base 837 |
| Low | SNIP does not re-route to kickout | SNIP runs only on clean path; stop-on-error false |
| Low | Large heap for SNIP | `CATALINA_OPTS` 6GB |

## 8. Definition of done checks

- Kickout UI + payer rules table in Web UI  
- Info tab links **test results PDF** (`/documents/test-results.pdf` + catch-all)  
- Automated `tests/plan.json` + route/capability/test PDFs under `documents/`
