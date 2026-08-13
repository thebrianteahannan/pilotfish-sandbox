# HTTP POST To RabbitMQ

PilotFish demo: HTTP POST in, RabbitMQ queue out.

## URLs

- Local: http://localhost:8135/
- LAN: http://192.168.68.62:8135/
- EIP: http://localhost:8134/eip/
- POST path: http://localhost:8134/eip/http-post/ingress
- RabbitMQ management: http://localhost:15673/ (user `demo` / `demo`)

## Run

```bash
cd Clients/Demos/Other/http-post-to-rabbitmq
docker compose --profile full up -d --build
```

Stage UI only (no EIP / RabbitMQ):

```bash
docker compose --profile stage up -d --build
```

## Pipeline

HTTP Post listener (`/eip/http-post/ingress`) → Relay → RabbitMQ transport (`demo.http.ingress`).

## Docs

From the Sandbox repo root:

```bash
python3 tools/export_route_diagrams.py --root http-post-to-rabbitmq --config compact
python3 tools/export_stakeholder_brief.py --root http-post-to-rabbitmq
python3 tools/export_test_plan_pdf.py --root http-post-to-rabbitmq
python3 tools/run_interface_tests.py --root http-post-to-rabbitmq --wait
```
