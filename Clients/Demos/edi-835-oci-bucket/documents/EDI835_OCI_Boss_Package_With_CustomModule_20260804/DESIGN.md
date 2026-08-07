# EDI 835 → OCI Object Storage — Design

## 1. Purpose
Demo of Brian Wolfe’s pattern: **SFTP poll EDI 835** → **split each ST / Transaction** → **JSON** → **Oracle OCI Object Storage** via custom Java `OciObjectStorageTransport` against local **floci-oci**.

## 2. Context / actors
- Source: Trading partner / payer drop folder on **SFTP** (Docker `atmoz/sftp`)
- Destination: **OCI Object Storage** mock (`PUT`/`POST` `/n/{namespace}/b/{bucket}/o/{object}`)
- Demo vs production: **Demo only** — no Oracle tenancy, no OCI signed requests, synthetic 835

## 3. Inbound contract
- Transport: **SFTP** (`FTPListener` / `Encrypted FTP (JSCH SSH/SFTP)`)
- Format: X12 **835** (5010-shaped), multi-`ST` / multi-`Transaction` allowed
- Identity: `ST02` / Transaction `ControlNumber`
- Samples: `samples/sample_multi_st_835.edi`

## 4. Outbound contract(s)
| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| OCI mock | JSON body via HTTP | Object listed under mock + file in `output/oci-received/` |
| Local JSON archive | JSON file | File under `output/json/` |
| Raw EDI archive | EDI | File under `output/archive/` |

## 5. Pipeline
| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener (R1) | `com.pilotfish.eip.modules.file.ftp.FTPListener` | Host `sftp`, JSCH SFTP, poll `upload` |
| Stage | `DirectoryTransport` | `output/staged/` |
| Listener (R2) | `DirectoryListener` | Pick staged `.edi` |
| Format | `EDITransformationModule` + `XPathForkingModule` | EDI→XML then fork `//Transaction` |
| Map | `XSLTProcessor` | Transaction XML → JSON text |
| Archive JSON | `FileWriteProcessor` | `output/json/` |
| Transport | `com.pilotfish.eip.modules.oci.OciObjectStorageTransport` | Custom module; PutObject to floci-oci (`http://floci-oci:4599`) |

**FQCN sources:** `PilotFish_V2` (`modules-ftp`, `format-edi`, `modules-http`, `modules-other` XPath fork). Image: `pilotfish-eip:23R1`.

## 6. State & idempotency
- SFTP post-process: **Delete** after pickup
- Staged post-process: **Delete** after split
- Object name includes ST control # + timestamp — resubmits create new objects (accepted)

## 7. Validation
- Checked: EDI parses to XML via bundled X12 trial / internal table data path
- Not checked: full SNIP Types 1–7 for 835, payer business edits
- Bad EDI: transform throws → no OCI object (fail-closed at transform)

## 8. Dual-write / side effects
Order: stage raw → fork Transaction → write JSON → HTTP POST to OCI mock. Mock also persists bodies under `output/oci-received/` for the Web UI.

## 9. Risks & bottlenecks
| Severity | Risk | Why it bites here | Mitigation / accepted? |
|----------|------|-------------------|------------------------|
| **High** | No *productized* OCI Object Storage Transport in PF core | Historical gap Brian called out | **Mitigated in this demo** by custom `OciObjectStorageTransport` (SDK PutObject) |
| High | Was using `HttpPostTransport` (POST-only) | OCI PutObject needs signed PUT | Replaced by custom module |
| High | `$$ENV` TargetURL interpolation | `$$BASE/{ognl:...}` treated as one missing property | Use OGNL fully-qualified URL string (smoke-verified) |
| Med | No OCI request signing (OCI-HMAC signature) | Naked HTTP won’t auth against Oracle | Custom module + OCI Java SDK |
| Med | Bundled X12 **trial table data expired** on 23R1 | `UseInternalData=true` fails EDI→XML | Demo uses `UseInternalData=false` |
| Med | EDI→XML invalid element names | Empty SVC (`~~`) produced `<120.00/>` and broke XPath fork | Sanitize sample; recommend custom ST splitter |
| Med | JSCH vs modern OpenSSH algorithms | Fresh `atmoz/sftp` → “Algorithm negotiation fail” | Mount compat `sftp/sshd_config` |
| Med | Multi-ST file → N HTTP calls | Throughput / partial failure | Retries on transport; optional custom batch putter |
| Low | Demo mock ≠ real OCI IAM | Local only | Accepted |

## 10. Ops
- Ports: EIP **8104**, Web UI **8105**, SFTP **2222→22**, floci-oci **4599**
- Volumes: `./output`, `./logs`, `./samples`, `./sftp-seed`
- Heap: 2GB
- Cold start: ~60–90s EIP

## 11. Observability
- Logs: `logs/eip.log`
- Artifacts: `output/archive`, `output/staged`, `output/json`, `output/oci-received`
- Gaps PDF: `documents/PilotFish_EDI835_OCI_Gaps_And_Custom_Modules.pdf`
- debuggingTrace: true (demo)

## 12. Open questions
- Prefer OCI SDK vs raw signed REST in the custom transport?
- Should EdiForkingModule (pre-XML ST fork) replace Format EDI+XPath for throughput?
