# Triggered FTP Download

## Progressive stage (Web UI early)

```bash
cd Clients/Demos/Other/triggered-ftp-download
docker compose --profile stage up -d --build
open http://localhost:8125/
```

Update build theater:

```bash
python3 tools/update_build_status.py --root Clients/Demos/Other/triggered-ftp-download --phase routes --message "…" --add-route 01-listen --active
```

When done:

```bash
python3 tools/update_build_status.py --root Clients/Demos/Other/triggered-ftp-download --complete
```
