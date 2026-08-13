# EDI 835 → OCI Object Storage — Design

Status: **WORKING**

## 1. Purpose

Poll X12 **835** remits from FTP, fork each `ST` / `Transaction`, map to JSON, and PUT-style-post each object to a local **Object Storage** mock (`/n/{namespace}/b/{bucket}/o/{object}`). Demo only — not Oracle IAM, not signed OCI requests.

## 2. Context / actors

- Sources: Trading-partner drop on FTP (`sftp` container, user `demo` / `demo`, dir `upload`)
- Destinations: JSON archive (`output/json/`), mock bucket (`output/oci-received/` + HTTP), raw EDI archive
- Demo vs production: **Demo only** — stock `HttpPostTransport` against a local mock. Real OCI PutObject needs signed **PUT** (product gap).

## 3. Inbound contract

- Transport: Encrypted FTP (JSCH SSH/SFTP) `FTPListener`
- Format: X12 **835** (5010-shaped), multi-`ST`
- Identity: `ST02` / Transaction `ControlNumber`
- Samples: `samples/sample_multi_st_835.edi`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| JSON archive | JSON | `output/json/{ST02}_*.json` |
| Mock Object Storage | JSON HTTP POST | Object under `/n/floci-local/b/edi-835-payments/o/` and file in `output/oci-received/` |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| R1 Listener | `FTPListener` JSCH SFTP | Poll `$$SFTP_POLL_DIR`; post-process Delete |
| R1 Transport | `DirectoryTransport` | Stage under `output/staged/` |
| R2 Listener | `DirectoryListener` | Poll staged `*.edi`; post-process Delete |
| R2 Format | `EDITransformationModule` + `XPathForkingModule` `//Transaction` | TableData `835-W1` (5010), 5 `../` |
| R2 Extract | `XPathEvaluatorProcessor` (target, after fork) | ST02 + CLP01 — source processors run on raw EDI and fail |
| R2 Map | `XSLTProcessor` | Transaction XML → JSON text |
| R2 Archive | `FileWriteProcessor` | `output/json/` (no XML Formatting on JSON) |
| R2 Transport | `HttpPostTransport` | Fully-qualified OGNL URL (not `$$BASE/{ognl}`) |

**FQCN sources:** `csv-sftp-to-sql` (FTPListener), `edi-835-payment-integrity` (EDI fork), `edi-270-271-realtime` (HttpPostTransport). Image: `pilotfish-eip:23R1`.

## 6. State & idempotency

- FTP post-process: Delete after pickup
- Staged post-process: Delete after split
- Object name includes ST control # + timestamp — resubmits create new objects

## 7. Validation

- Checked: EDI parses; two ST → two JSON objects (PATCLAIM001, PATCLAIM002)
- Not checked: SNIP, OCI HMAC, real tenancy

## 8. Dual-write / side effects

Order: archive raw → stage → fork → JSON file → HTTP POST to mock (mock also writes `oci-received/`).

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation |
|----------|------|------------|
| High | No productized OCI Object Storage transport | Accepted — mock + HttpPost; DESIGN names the PUT/signing gap |
| High | `$$ENV/{ognl}` TargetURL interpolation | Fully-qualified OGNL URL string |
| Med | JSCH vs modern OpenSSH | Compat `sftp/sshd_config` |
| Med | 23R1 trial tables | TableData mount 5 `../` |

## 10. Ops

- Ports: EIP **8104**, Web UI **8105**, FTP **2222**, mock **4599**
- FTP: `demo` / `demo`, dir `upload`
- TableData: `../../../../../EDI/TableData/x12`
- Compose project: `edi-835-oci-bucket`

## 11. Observability

- Logs: `logs/eip.log`
- debuggingTrace: true (demo)

## 12. Open questions

- Custom Java `OciObjectStorageTransport` (SDK PutObject) later?

## 13. Tests

```bash
python3 tools/run_interface_tests.py --root Clients/Demos/Insurance/EDI/edi-835-oci-bucket --wait
```
