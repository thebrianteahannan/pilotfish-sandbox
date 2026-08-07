# Orbit Disc

Fly a spaceship and throw disc-golf discs into baskets on mountain peaks.

## LAN play

With Docker Desktop running:

```bash
docker rm -f orbit-disc-lan 2>/dev/null
docker run -d --name orbit-disc-lan -p 5174:80 \
  -v "$PWD:/usr/share/nginx/html:ro" \
  nginx:alpine
```

Open `http://<your-mac-lan-ip>:5174/` on a phone/tablet on the same Wi-Fi.

Controls: W/S thrust, A/D turn, R/F climb, Q/E roll, Space throw, drag to look.
