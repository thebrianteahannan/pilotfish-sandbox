# EDI 276 277 Claim Status

## Progressive stage (Web UI early)

```bash
cd Clients/Demos/edi-276-277-claim-status
docker compose --profile stage up -d --build
open http://localhost:8127/
```

Update build theater:

```bash
python3 tools/update_build_status.py --root Clients/Demos/edi-276-277-claim-status --phase routes --message "…" --add-route 01-listen --active
```

When done:

```bash
python3 tools/update_build_status.py --root Clients/Demos/edi-276-277-claim-status --complete
```
