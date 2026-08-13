# FTP Named Download Trigger — Design

## 1. Purpose

Demonstrate how to **download a remote file by a computed name** when the **FTP Operation** processor has **no Download** operation (Move / Delete / Upload / List Files only). Uses stock PilotFish: parse a local control file → **Listener Trigger (Run One Cycle)** → **separate FTP / SFTP Listener** route that fetches the named file.

## 2. Context / actors

- Sources: Operators / Web UI dropping a `.ctl` control file into `input/control`
- Remote store: demo SFTP (`atmoz/sftp`) with seeded payload + decoy
- Destinations: downloaded bytes under `output/downloaded/`; control archive under `output/archive/`
- Demo vs production: **Demo only** (credentials `demo`/`demo`)

## 3. Inbound contract

- Transport: `DirectoryListener` polling `$$CONTROL_INBOUND_DIRECTORY`
- Format: plain-text control body = remote basename+extension (one line), e.g. `invoice-20260407.dat`
- Identity: control `com.pilotfish.FileName`; remote name attribute `demo.ftp.RemoteFileName`
- Samples: `samples/control/fetch-invoice.ctl`, `samples/remote/invoice-20260407.dat`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| `output/downloaded` | Remote file bytes | File written with remote basename |
| `output/archive` | Control `.ctl` | Listener Move after pick-up |

## 5. Pipeline

| Stage | Module / FQCN | Notes |
|-------|---------------|-------|
| **Route 1** listen | `com.pilotfish.eip.modules.file.DirectoryListener` | `.ctl` only; Move → archive |
| Save body → attr | `com.pilotfish.eip.modules.internal.SaveDataToAttributeProcessor` | Data Attribute Swapper → `demo.ftp.RemoteFileNameRaw` |
| Trim + path | `com.pilotfish.eip.modules.internal.TransactionAttributePopulationProcessor` | Sets `demo.ftp.RemoteFileName`, `demo.ftp.RemoteFullPath` |
| Trigger download | `com.pilotfish.eip.modules.internal.ListenerTriggeringProcessor` | `RUN_ONCE=true`; ServiceName = `2 - Download Named File From SFTP::Download Named File From SFTP.FTP Listener` |
| Null transport | `com.pilotfish.eip.modules.internal.NullTransport` | Route 1 ends after trigger |
| **Route 2** listen | `com.pilotfish.eip.modules.file.ftp.FTPListener` | JSCH SFTP; `IS_TRIGGERABLE_LISTENER=true`; `UseFullFilePath` + OGNL path |
| Write local | `com.pilotfish.eip.modules.file.DirectoryTransport` | `$$DOWNLOAD_OUTPUT_DIRECTORY` |

Docs source: PilotFish Documentation `26R1.11` FTP Operation + Listener Trigger + FTP/SFTP Listener deep-dives. Runtime image: `pilotfish-eip:23R1` (call out version skew if config tags differ).

## 6. State & idempotency

- No SQL; success = file presence
- FTP post-process = **Keep** so the seed can be re-fetched
- Control Move to archive before download completes (accepted demo risk — trigger is async)

## 7. Validation

- Control extension `.ctl` only
- Exact remote path via `FullPathToFile` (not FTP Operation Download)
- Decoy file on SFTP proves the listener does not grab everything

## 8. Dual-write / side effects

- Order: archive control (listener Move) → async FTP poll → write downloaded file
- Compensation: none (demo)

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation / accepted? |
|----------|------|------------------------|
| Med | Listener Trigger Run One Cycle is **async** — control route finishes before download | Accepted; Web UI / tests wait on output file |
| Med | Archive-before-download | Accepted demo risk |
| Low | Docs `26R1.11` vs runtime `23R1` | Smoke-test modules; same FQCNs used in Sandbox/CRL |
| Low | Old JSCH vs modern OpenSSH | Custom `sftp/sshd_config` (same as EDI 835 OCI demo) |
| Info | FTP Operation still has no Download | Documented product gap; this demo is the workaround |

## 10. Ops

- Ports: SFTP host **2223**, EIP **8112**, Web UI **8113**
- LAN: `LAN_HINT=http://192.168.68.62:8113/`
- Compose project: `ftp-named-download-trigger`
- Cold start ~60–90s for EIP

## 11. Observability

- `logs/eip.log`
- Web UI Results: control archive + downloaded files
- Route PDF under `documents/FTP_Named_Download_Trigger_V2_Route_Diagrams.pdf`

## 12. Open questions

- Optional synchronous wait / Call Route hand-back when a future build adds FTP Operation Download
- Optional FileNameRestriction directory-poll variant instead of UseFullFilePath
