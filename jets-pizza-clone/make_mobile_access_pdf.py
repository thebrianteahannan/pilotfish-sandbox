#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PDF with LAN URL + QR so phone/iPad can open the local Jets clone."""

from datetime import datetime
from io import BytesIO
from pathlib import Path

import qrcode
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / "JetsPizza_Mobile_Access.pdf"
LAN_IP = "192.168.68.62"
PORT = 5173
URL = f"http://{LAN_IP}:{PORT}/"


def qr_image(url: str) -> ImageReader:
    qr = qrcode.QRCode(version=2, box_size=10, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white").convert("RGB")
    buf = BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return ImageReader(buf)


def main() -> None:
    c = canvas.Canvas(str(OUT), pagesize=letter)
    w, h = letter
    y = h - 0.85 * inch

    c.setFillColorRGB(0.93, 0.13, 0.14)
    c.rect(0, h - 0.35 * inch, w, 0.35 * inch, fill=1, stroke=0)

    c.setFillColorRGB(0.05, 0.05, 0.05)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(0.75 * inch, y, "View Jet's Pizza Clone on Your Phone / iPad")
    y -= 0.45 * inch

    c.setFont("Helvetica", 11)
    c.setFillColorRGB(0.25, 0.25, 0.25)
    stamp = datetime.now().strftime("%b %d, %Y %I:%M %p")
    c.drawString(
        0.75 * inch,
        y,
        f"Generated {stamp}  |  Same Wi-Fi as your Mac required",
    )
    y -= 0.55 * inch

    c.setFillColorRGB(0.02, 0.65, 0.31)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(0.75 * inch, y, "OPEN THIS URL ON YOUR DEVICE")
    y -= 0.35 * inch

    c.setFillColorRGB(0.05, 0.05, 0.05)
    c.setFont("Courier-Bold", 16)
    c.drawString(0.75 * inch, y, URL)
    y -= 0.2 * inch

    qr = qr_image(URL)
    qr_size = 2.4 * inch
    c.drawImage(qr, 0.75 * inch, y - qr_size - 0.15 * inch, qr_size, qr_size, mask="auto")
    c.setFont("Helvetica", 10)
    c.setFillColorRGB(0.35, 0.35, 0.35)
    c.drawString(
        0.75 * inch,
        y - qr_size - 0.35 * inch,
        "Scan with Camera (iPhone/iPad) or any QR reader",
    )

    sx = 3.5 * inch
    sy = y
    c.setFillColorRGB(0.05, 0.05, 0.05)
    c.setFont("Helvetica-Bold", 12)
    c.drawString(sx, sy, "Steps")
    sy -= 0.3 * inch
    steps = [
        "1. Keep your Mac awake (and Docker Desktop",
        "   running — the site is served via Docker).",
        "2. Join phone/iPad to the SAME Wi-Fi as Mac",
        "   (not cellular; avoid guest Wi-Fi).",
        "3. Prefer VPN OFF on phone and Mac while",
        "   testing (OpenVPN often blocks LAN).",
        "4. Open Safari/Chrome and type the URL,",
        "   or scan the QR code.",
        "5. The Jet's Pizza clone should load.",
    ]
    c.setFont("Helvetica", 10.5)
    for line in steps:
        c.drawString(sx, sy, line)
        sy -= 0.22 * inch

    y = y - qr_size - 0.7 * inch
    c.setFont("Helvetica-Bold", 12)
    c.setFillColorRGB(0.05, 0.05, 0.05)
    c.drawString(0.75 * inch, y, "What this does")
    y -= 0.28 * inch
    c.setFont("Helvetica", 10.5)
    body = [
        "Your Mac's Wi-Fi address is used so devices on the same LAN can open the demo.",
        f"Right now a Docker nginx container publishes the site at {URL}",
        "(container name: jets-pizza-lan). Nothing is exposed to the public internet.",
    ]
    for line in body:
        c.drawString(0.75 * inch, y, line)
        y -= 0.2 * inch

    y -= 0.15 * inch
    c.setFont("Helvetica-Bold", 12)
    c.drawString(0.75 * inch, y, "If it does not load")
    y -= 0.28 * inch
    c.setFont("Helvetica", 10.5)
    tips = [
        "- Confirm Docker container:  docker ps --filter name=jets-pizza-lan",
        "- Confirm Mac IP still matches:  ipconfig getifaddr en0",
        "- Turn off VPN; avoid guest Wi-Fi / AP client isolation.",
        "- If IP changed, use http://<new-ip>:5173/ instead.",
        "- macOS may ask to allow Local Network for Docker — allow it.",
    ]
    for line in tips:
        c.drawString(0.75 * inch, y, line)
        y -= 0.22 * inch

    y -= 0.2 * inch
    c.setFont("Helvetica-Bold", 12)
    c.drawString(0.75 * inch, y, "Restart later (Docker)")
    y -= 0.28 * inch
    c.setFont("Courier", 8.5)
    lines = [
        "docker rm -f jets-pizza-lan 2>/dev/null; docker run -d --name jets-pizza-lan -p 5173:80 \\",
        '  -v ".../CapturesChecking/jets-pizza-clone:/usr/share/nginx/html:ro" nginx:alpine',
    ]
    for line in lines:
        c.drawString(0.75 * inch, y, line)
        y -= 0.18 * inch

    y -= 0.15 * inch
    c.setFont("Helvetica", 9.5)
    c.setFillColorRGB(0.25, 0.25, 0.25)
    c.drawString(
        0.75 * inch,
        y,
        "Alternate (no Docker): double-click jets-pizza-clone/Serve-on-LAN.command",
    )

    c.setFont("Helvetica", 9)
    c.setFillColorRGB(0.45, 0.45, 0.45)
    c.drawString(
        0.75 * inch,
        0.55 * inch,
        "Local demo only - not affiliated with Jet's America, Inc. Works only while the Mac container is running.",
    )

    c.showPage()
    c.save()
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
