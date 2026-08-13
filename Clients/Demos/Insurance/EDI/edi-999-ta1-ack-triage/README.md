# EDI 999 / TA1 Ack Triage

Pitch §3 demo: triage inbound **999** and **TA1** acknowledgments into accepted / rejected / error buckets with an ops report.

## Replay construction (module-by-module)

1. Click **Construction view**
2. Click **Replay construction**

Starts from an **empty canvas**, then adds every module one-by-one with an explanation and focus highlight on the new node.

Re-record after route changes:

```bash
python3 tools/record_module_replay.py --root Clients/Demos/Insurance/EDI/edi-999-ta1-ack-triage
```

## Progressive stage (Web UI early)

```bash
cd Clients/Demos/Insurance/EDI/edi-999-ta1-ack-triage
docker compose --profile stage up -d --build
open http://localhost:8129/
```

LAN: http://192.168.68.62:8129/

## Replay live construction theater

```bash
# From Sandbox root — watch http://localhost:8129/ Routes tab
python3 Clients/Demos/Insurance/EDI/edi-999-ta1-ack-triage/tools/progressive_build_theater.py 5
```

Or module-by-module on one route:

```bash
python3 tools/publish_route_progress.py \
  --root Clients/Demos/Insurance/EDI/edi-999-ta1-ack-triage \
  --route "1 - Intake And Classify" \
  --replay-stages --pause 5
```

## Samples

- `samples/999-partial-accept.edi` — TableData X231 (partial reject)
- `samples/999-all-accept.edi`
- `samples/ta1-accept.edi`
