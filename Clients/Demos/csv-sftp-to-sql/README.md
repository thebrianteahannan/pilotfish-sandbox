# CSV SFTP To SQL

Poll CSV from SFTP → stage → SQL Server.

## Run

```bash
cd Clients/Demos/csv-sftp-to-sql
docker compose --profile full up -d --build
open http://localhost:8133/
```

Stage UI only: `docker compose --profile stage up -d --build`

## Smoke

1. Open Demo tab → Inject `patients.csv` to SFTP
2. Wait for rows in `CsvPatients`
3. Routes tab shows both V2 diagrams
4. Construction video: `documents/construction-replay.mp4` (Info tab). Transcript PDF/TXT: `documents/construction-replay-transcript.pdf`. Regenerate with:

```bash
python3 tools/export_construction_video.py --root Clients/Demos/csv-sftp-to-sql
# transcript only:
python3 tools/export_construction_transcript_pdf.py --root Clients/Demos/csv-sftp-to-sql
# or automatically via:
python3 tools/update_build_status.py --root Clients/Demos/csv-sftp-to-sql --complete
```
