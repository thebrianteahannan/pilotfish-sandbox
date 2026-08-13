# EDI 837 Claim Scrub — Design

Status: **WORKING**

## 1. Purpose

SQL Server professional claims → payer-profile edits (referring NPI / Place of Service) → **kickout work queue** or clean **837 + SNIP** before the clearinghouse. Every scrub decision is copied to a BI outcome folder.

## 2. Context / actors

- Sources: `Edi837ClaimScrub` (`Claims` PENDING)
- Destinations: `output/kickouts/`, `output/edi/`, `output/snip/`, `output/bi/`
- Demo vs production: Synthetic payer rules mirrored in XSLT (not a live SQL join). SNIP on the clean path only.

## 3. Inbound contract

- Transport: `DatabaseSqlListener` (poll PENDING → PROCESSED)
- Format: SQLXML `CLAIM` rows (tags **UPPERCASE**)
- Identity: `ClaimId` / `ClaimNumber`
- Seed: 5001 clean AHLIC; 5002 kickout missing NPI; 5003 kickout POS 99; 5004 clean Medicaid POS 21

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| Kickout queue | Decision XML | `5002_CLM-5002_kickout.xml`, `5003_CLM-5003_kickout.xml` |
| Clean 837 | X12 837P | `5001_CLM-5001.edi`, `5004_CLM-5004.edi` |
| SNIP | Types 1–3 XML | matching `*_snip.xml` |
| BI | Decision XML | all four claims |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `DatabaseSqlListener` | `SelectClaimsSQL.xml` |
| R1 Transport | `EIPTransport` | Trigger Route 2 |
| R2 Listener | `TriggerableListener` | Format `Split Claims` `//CLAIM \| //Claim` |
| R2 Evaluate | `XSLTProcessor` | Synthetic payer profile |
| R2 Gate | `ExecuteProcessor` OGNL on `MatchBucket` | kickout vs clean (no `;` / colon-in-string) |
| R2 Clean | XSLT → `EDITransformationProcessor` XML→EDI `837-Q1` → SNIP 1–3 | TableData mount |
| R2 Complete | `NullTransport` | |

**FQCN sources:** 835 PI (JDBC), 278 (XPath / FileWrite / NullTransport), this story’s SNIP processor from PilotFish EDI SNIP docs. Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- Claim marked PROCESSED on poll (before scrub completes) — demo pattern
- Re-inject sets Status back to PENDING

## 7. Validation

- Checked: kickouts 5002/5003; clean EDI+SNIP 5001/5004; SNIP HTML report
- Not checked: live payer policy, SNIP 4–7

## 8. Dual-write / side effects

Order: snapshot claims → evaluate → kickout and/or 837+SNIP → BI copy.

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation |
|----------|------|------------|
| Med | Payer rules duplicated in XSLT | UI also reads `PayerEditRules` |
| Med | PROCESSED before scrub finishes | Demo-honest; re-inject resets |
| Low | SNIP heap | `CATALINA_OPTS` 6GB |

## 10. Ops

- Ports: SQL **14341**, EIP **8114**, Web UI **8115**
- SQL: `sa` / `PilotFish_Demo1!` · `Edi837ClaimScrub`
- TableData: `../../../../../EDI/TableData/x12` → `edi-tabledata/837-Q1`

## 11. Observability

- Logs: `logs/eip.log`
- debuggingTrace: true (demo)

## 12. Open questions

- None for this recreate.

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-837-claim-scrub --wait
```
