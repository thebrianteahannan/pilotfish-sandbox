# Med Rec (MedReceivables)

Client package for MedReceivables Flat File → HL7 interfaces.

## Layout

| Path | Purpose |
|------|---------|
| `eip-root/` | Interface package (copy of sandbox `eip-root`). Use this when spinning a Docker image for Med Rec. |
| `database/` | H2 seeds (`medreceivables.mv.db` = H2 2.1 / Docker; `medreceivables-h2-1.4.mv.db` = Windows/older H2) |
| `data/` | Interface runtime data: `input/`, `output/`, `archive/` (samples), `database/` (Docker volume) |
| `deploy/` | SQL + deploy notes for CAT/GAN onboarding |
| `reports/` | CLIENT_SPLITS extracts |
| `*.pdf` / plans | Facility onboarding and change docs |

Sandbox root `data/{in,out,archive}` stays empty for everyday drop folders. Default `docker-run.sh` mounts those plus this client’s `data/database`. Over time, point Docker at a client’s `eip-root` (and its `data/`) for client-specific images.
