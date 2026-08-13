# DESIGN — EDI 837 SNIP SQL Server

## 1. Intent

Demonstrate end-to-end **SQL claim → 837P → SNIP Types 1–3** on `pilotfish-eip:23R1`, with Level 4–7 wiring prepared for an `EDISNIP`-capable license.

## 2. Actors / systems

| System | Role |
|--------|------|
| SQL Server `Edi837Demo` | Claims, lines, patients, providers |
| eiPlatform 23R1 | Poll → fork → EDI XML → wire 837 → SNIP 1–3 |
| Web UI :8095 | Inject claims, view EDI/SNIP, route viewer, PDFs |

## 3. Pipeline

| Stage | Module | Notes |
|-------|--------|-------|
| R1 Poll | `DatabaseSqlListener` + `SelectClaimsSQL.xml` | PENDING → PROCESSED |
| Handoff | `EIPTransport` | Trigger `Generate 837 And SNIP` |
| Fork | Format `Split Claims` / `XPathForkingModule` | Per-claim |
| Map | `XSLTProcessor` `transform-claim-to-edi-xml.xslt` | EDI XML (`XCSData/...`) |
| Emit | `EDITransformationProcessor` | TableData `837-Q1` → `output/edi/*.edi` |
| SNIP | `EdiSNIPValidationProcessor` Types **1–3** (runtime) | `output/snip/*_snip.xml`; Types 4–7 flags off until `EDISNIP` |

## 4. SNIP levels (this demo)

| Type | Flag | Runtime | Source |
|------|------|---------|--------|
| 1 | `Snip1Validation` | **on** | Stock rules |
| 2 | `Snip2Validation` | **on** | Stock rules |
| 3 | `Snip3Validation` | **on** | Stock rules |
| 4 | `Snip4Validation` | off | Stock inter-segment rules (**requires `EDISNIP`**) |
| 5 | `Snip5Validation` | off | Stock code-set rules + CompactedLookup (**licensed**) |
| 6–7 | `Snip7Validation` + `Snip7RuleFile=snip7-demo-rules.xml` | off | Customer rule: POS ≠ `99` (**licensed**; no separate Type 6 toggle) |

Runtime gating (decompile): if Types 4/5/7 are enabled and `ProductsValidator.isSnipEnabled()` is false, SNIP throws `Not licensed for SNIP 4 to 7 validations during runtime`.

**Sandbox image (2026-08-07):** `pflicense.key` lacks `EDISNIP`. Runtime therefore keeps Types 4–7 **off** so SNIP reports still write. Rule file + docs stay ready — set the three flags to `true` after rebuilding EIP with a licensed key.

## 5. X12 TableData

Compose mounts `EDI/TableData/x12` → `eip-root/edi-tabledata`. XML→EDI uses `USE_ENHANCED_CONTEXT=true`, `UseInternalData=false`, `TransactionDataWithVersion` → `837-Q1` @ 5010 (playbook §3.6).

## 6. Ports

| Service | Host |
|---------|------|
| SQL Server | 14335 |
| EIP | 8093 |
| Web UI | 8095 |

## 7. Risks (demo-honest)

| Sev | Risk | Mitigation |
|-----|------|------------|
| High | Enabling SNIP 4–7 without `EDISNIP` empties SNIP output | Runtime keeps 4–7 off; flip after licensed key + EIP rebuild |
| Med | Types 4–5 increase heap / first-transaction latency | Compose `CATALINA_OPTS` 6GB G1 |
| Low | Demo Level 7 rule is illustrative (POS 99) | Documented in `snip7-demo-rules.xml` |
| Low | Claim marked PROCESSED before SNIP completes | Same poll-before-complete pattern as sibling demos |

## 8. Definition of done

- Runtime SNIP **Types 1–3** produce `output/snip/*_snip.xml`
- `snip7-demo-rules.xml` present; docs explain enabling Types 4–7 when licensed
- README + DESIGN describe levels and license caveat
- Capability / route / test PDFs regenerated; `tests/plan.json` green
