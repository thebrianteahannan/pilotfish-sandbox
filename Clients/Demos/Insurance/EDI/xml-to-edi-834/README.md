# XML → EDI 834

Standalone PilotFish demo: pick up enrollment XML and write X12 834.

## Layout

| Path | Purpose |
|------|---------|
| `eip-root/` | Interface package (`XML to EDI 834`) |
| `data/` | Runtime input / output / archive / database (gitignored) |
| `docker-run.sh` | Build/start helper (port **8081**) |

## Run

From this directory:

```bash
./docker-run.sh demo
```

Or from the Sandbox root (wrapper):

```bash
./docker-run-834.sh demo
```

EIP UI: http://localhost:8081/eip/
