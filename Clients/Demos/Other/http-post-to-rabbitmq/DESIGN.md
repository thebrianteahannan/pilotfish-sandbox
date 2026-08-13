# HTTP POST To RabbitMQ

Status: **WORKING**

## 1. Purpose

Accept an HTTP POST body on a PilotFish web-service path and publish that same payload to a RabbitMQ queue. Demo-only: no transformation, no auth, no dead-letter theater.

## 2. Context / actors

- Sources: any HTTP client (Web UI inject, curl, partner system)
- Destinations: RabbitMQ queue `demo.http.ingress` (AMQP publish)
- Demo vs production: **Demo only** (plain AMQP, demo/demo credentials, no TLS)

## 3. Inbound contract

- Transport: HTTP POST listener `com.pilotfish.eip.modules.http.HttpPostListener`
- Path: `/eip/http-post/ingress` (RequestPath `ingress`)
- Format: opaque body (JSON sample provided; any bytes accepted)
- Identity: none required
- Samples path: `samples/*.json`

## 4. Outbound contract(s)

| Destination | Format | Success criterion |
|-------------|--------|-------------------|
| RabbitMQ queue `demo.http.ingress` | Same bytes as the POST body | Message visible on the queue (management peek / Web UI Queue) |

## 5. Pipeline

| Stage | Module / mechanism | Notes |
|-------|--------------------|-------|
| Listener | `com.pilotfish.eip.modules.http.HttpPostListener` | `Synchronous=false` (playbook §1.4 — queue ingest is fire-and-forget) |
| FormatProfile | Relay | Pass-through (body is not XML) |
| Router | `com.pilotfish.eip.modules.internal.NullRoutingModule` | Single target; do not use XPath (JSON is not XML) |
| Transport | `com.pilotfish.eip.modules.messaging.rabbitmq.RabbitMQTransport` | **Host and Port** `$$RABBITMQ_HOSTS`, `VirtualHost=/` (playbook §1.4 — not URI) |

## 6. State & idempotency

- Status model: queue depth only
- When state advances: publish succeeds
- Dedup keys: none (demo will enqueue duplicates)
- Retry / poison: not implemented (documented)

## 7. Validation

- What is checked: HTTP POST reaches the listener path
- What is NOT checked: JSON schema, content-type, AMQP properties beyond ContentType
- Does failure block outbound? Listener/transport exceptions fail the transaction (`logs/eip.log`)

## 8. Dual-write / side effects

- Single write: RabbitMQ publish
- Compensation: none

## 9. Risks & bottlenecks

| Severity | Risk | Mitigation / accepted? |
|----------|------|------------------------|
| Med | Docs are 26R1.11; runtime is `pilotfish-eip:23R1` | Both modules exist in 23R1 jars (`modules-http-23R1-SNAPSHOT.jar`, `modules-rabbitmq-23R1-SNAPSHOT.jar`) |
| Low | Guest AMQP user is remote-disabled on modern RabbitMQ | Demo user `demo`/`demo` via `RABBITMQ_DEFAULT_USER` |
| Low | HTTP listener is async | Caller gets an immediate POST ack; queue peek confirms publish |
| Low | No TLS / no auth on HTTP | Demo only |

## 10. Ops

- Compose project: `http-post-to-rabbitmq`
- Ports: EIP **8134**, Web UI **8135**, RabbitMQ AMQP **5673**, RabbitMQ management **15673**
- Local Web UI: http://localhost:8135/
- LAN Web UI: http://192.168.68.62:8135/
- EIP: http://localhost:8134/eip/
- POST URL: http://localhost:8134/eip/http-post/ingress
- RabbitMQ management: http://localhost:15673/ (demo/demo)
- Compose profile `stage` = Web UI only; `full` = RabbitMQ + EIP + Web UI
- Cold start ~60–90s for EIP after RabbitMQ is healthy

## 11. Observability

- `logs/eip.log`
- Web UI Demo tab: inject + queue peek
- RabbitMQ management UI on **15673**
- Route design PDF under `documents/`

## 12. Open questions

- Optional Basic auth on the HTTP path
- Optional topic exchange / routing-key theater
