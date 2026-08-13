# CSV SFTP To SQL

Status: **IN PROGRESS**

## 1. Purpose
Poll a CSV file from an SFTP directory, stage it locally, parse rows (CSV→XML Dialect A), and insert into SQL Server `dbo.CsvPatients`.

## 2. Actors / systems
- Trading partner / ops drop CSV on SFTP (`demo` / `demo`, dir `upload`)
- PilotFish eiPlatform (23R1)
- SQL Server 2022 (`CsvSftpDemo`)

## 3. Pipeline

| Stage | Module | FQCN |
|-------|--------|------|
| SFTP poll | FTP / SFTP Listener (JSCH) | `com.pilotfish.eip.modules.file.ftp.FTPListener` |
| Archive raw | File Writing | `com.pilotfish.eip.modules.file.FileWriteProcessor` |
| Stage | Directory / File Transport | `com.pilotfish.eip.modules.file.DirectoryTransport` |
| Local poll | Directory / File Listener | `com.pilotfish.eip.modules.file.DirectoryListener` |
| CSV parse | CSV | `com.pilotfish.eip.modules.transform.CSVTransformationProcessor` |
| Map SQLXML | XSLT | `com.pilotfish.eip.modules.transform.XSLTProcessor` |
| Insert | Database (SQL) Transport | `com.pilotfish.eip.modules.db.DatabaseSqlTransport` |

## 4. Routes
1. **1 - SFTP Poll And Stage** — poll `.csv` from SFTP, archive, write `input/staged`
2. **2 - CSV To SQL** — poll staged CSV → CSV XML → SQLXML → insert

## 5. Data
Sample: `samples/patients.csv` → columns patientId, firstName, lastName, dateOfBirth, city, state

## 10. Ops
- Web UI: http://localhost:8133/
- LAN: http://192.168.68.62:8133/
- EIP: http://localhost:8132/eip/
- SFTP: localhost:2224 (demo/demo, upload/)
- SQL Server: localhost:14341 (sa / PilotFish_Demo1!)

```bash
cd Clients/Demos/Other/csv-sftp-to-sql
docker compose --profile full up -d --build
```

## 11. Risks / honesty
- JSCH requires mounted `sftp/sshd_config` (algorithm negotiation)
- Demo SA password is for local sandbox only
- DateOfBirth cast relies on ISO `YYYY-MM-DD` in CSV
