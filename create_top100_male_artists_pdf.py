#!/usr/bin/env python3
"""Generate a PDF ranking of the top 100 male music artists by Spotify streams."""

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Top_100_Male_Music_Artists.pdf"

# Ranked primarily from SpotifyStats all-time stream totals (lead + featured),
# updated July 17, 2026. Female artists removed; male solo acts and male groups
# retained in cumulative-stream order. Ranks 76–100 continue that order with
# well-documented high-streaming male acts just outside the overall top 100.
ARTISTS: list[tuple[str, str, str]] = [
    ("Drake", "137.3B", "Hip-hop / Canada"),
    ("Bad Bunny", "125.7B", "Reggaeton / Puerto Rico"),
    ("The Weeknd", "95.6B", "Pop/R&B / Canada"),
    ("Justin Bieber", "78.0B", "Pop / Canada"),
    ("Travis Scott", "65.3B", "Hip-hop / USA"),
    ("Kanye West", "65.1B", "Hip-hop / USA"),
    ("Ed Sheeran", "64.6B", "Pop / UK"),
    ("Eminem", "64.5B", "Hip-hop / USA"),
    ("Bruno Mars", "56.6B", "Pop/R&B / USA"),
    ("Kendrick Lamar", "56.5B", "Hip-hop / USA"),
    ("Post Malone", "55.0B", "Pop/Hip-hop / USA"),
    ("J Balvin", "54.6B", "Reggaeton / Colombia"),
    ("Future", "53.9B", "Hip-hop / USA"),
    ("BTS", "53.2B", "K-pop / South Korea"),
    ("Ozuna", "47.6B", "Reggaeton / Puerto Rico"),
    ("Coldplay", "46.7B", "Alternative / UK"),
    ("Juice WRLD", "46.3B", "Hip-hop / USA"),
    ("Chris Brown", "44.0B", "R&B / USA"),
    ("David Guetta", "42.0B", "Electronic / France"),
    ("Daddy Yankee", "41.4B", "Reggaeton / Puerto Rico"),
    ("Rauw Alejandro", "40.7B", "Reggaeton / Puerto Rico"),
    ("Anuel AA", "40.4B", "Reggaeton / Puerto Rico"),
    ("XXXTENTACION", "40.4B", "Hip-hop / USA"),
    ("Imagine Dragons", "40.3B", "Alternative / USA"),
    ("Lil Wayne", "40.1B", "Hip-hop / USA"),
    ("21 Savage", "39.0B", "Hip-hop / USA"),
    ("Arijit Singh", "37.5B", "Bollywood / India"),
    ("Lil Baby", "35.9B", "Hip-hop / USA"),
    ("Maroon 5", "35.8B", "Pop / USA"),
    ("Khalid", "35.7B", "R&B/Pop / USA"),
    ("Maluma", "34.8B", "Reggaeton / Colombia"),
    ("Feid", "34.5B", "Reggaeton / Colombia"),
    ("Calvin Harris", "34.1B", "Electronic / UK"),
    ("Myke Towers", "33.6B", "Reggaeton / Puerto Rico"),
    ("Linkin Park", "33.2B", "Rock / USA"),
    ("Peso Pluma", "33.1B", "Regional Mexican / Mexico"),
    ("J. Cole", "32.2B", "Hip-hop / USA"),
    ("Lil Uzi Vert", "32.1B", "Hip-hop / USA"),
    ("Morgan Wallen", "31.1B", "Country / USA"),
    ("Young Thug", "30.9B", "Hip-hop / USA"),
    ("Farruko", "29.8B", "Reggaeton / Puerto Rico"),
    ("Shawn Mendes", "29.5B", "Pop / Canada"),
    ("Harry Styles", "29.4B", "Pop / UK"),
    ("Queen", "29.4B", "Rock / UK"),
    ("Sam Smith", "29.2B", "Pop / UK"),
    ("One Direction", "28.9B", "Pop / UK"),
    ("Metro Boomin", "28.8B", "Hip-hop / USA"),
    ("Pritam", "28.5B", "Bollywood / India"),
    ("Gunna", "28.2B", "Hip-hop / USA"),
    ("Arctic Monkeys", "28.1B", "Indie Rock / UK"),
    ("Fuerza Regida", "27.4B", "Regional Mexican / Mexico"),
    ("Junior H", "27.4B", "Regional Mexican / Mexico"),
    ("Tyler, The Creator", "27.1B", "Hip-hop / USA"),
    ("Ty Dolla $ign", "26.5B", "R&B/Hip-hop / USA"),
    ("The Beatles", "26.1B", "Rock / UK"),
    ("Nicky Jam", "25.9B", "Reggaeton / USA"),
    ("Pitbull", "25.8B", "Pop/Hip-hop / USA"),
    ("Playboi Carti", "25.8B", "Hip-hop / USA"),
    ("Wiz Khalifa", "25.3B", "Hip-hop / USA"),
    ("Michael Jackson", "25.2B", "Pop / USA"),
    ("Frank Ocean", "24.8B", "R&B / USA"),
    ("JAY-Z", "24.4B", "Hip-hop / USA"),
    ("A$AP Rocky", "24.2B", "Hip-hop / USA"),
    ("The Chainsmokers", "23.8B", "Electronic / USA"),
    ("Marshmello", "23.7B", "Electronic / USA"),
    ("Twenty One Pilots", "22.5B", "Alternative / USA"),
    ("Arcángel", "21.9B", "Reggaeton / Puerto Rico"),
    ("Red Hot Chili Peppers", "21.9B", "Rock / USA"),
    ("$uicideboy$", "21.2B", "Hip-hop / USA"),
    ("OneRepublic", "21.2B", "Pop Rock / USA"),
    ("Avicii", "21.0B", "Electronic / Sweden"),
    ("Diplo", "20.7B", "Electronic / USA"),
    ("Snoop Dogg", "20.6B", "Hip-hop / USA"),
    ("Romeo Santos", "20.5B", "Bachata / USA"),
    ("50 Cent", "20.4B", "Hip-hop / USA"),
    ("Elton John", "~20B", "Pop/Rock / UK"),
    ("The Kid LAROI", "~19B", "Pop/Hip-hop / Australia"),
    ("Justin Timberlake", "~19B", "Pop/R&B / USA"),
    ("Mac Miller", "~19B", "Hip-hop / USA"),
    ("Pop Smoke", "~18B", "Hip-hop / USA"),
    ("Luke Combs", "~18B", "Country / USA"),
    ("Zach Bryan", "~18B", "Country / USA"),
    ("Lewis Capaldi", "~18B", "Pop / UK"),
    ("Charlie Puth", "~17B", "Pop / USA"),
    ("Kid Cudi", "~17B", "Hip-hop / USA"),
    ("Burna Boy", "~17B", "Afrobeats / Nigeria"),
    ("Kygo", "~17B", "Electronic / Norway"),
    ("Martin Garrix", "~16B", "Electronic / Netherlands"),
    ("Luis Fonsi", "~16B", "Latin Pop / Puerto Rico"),
    ("Enrique Iglesias", "~16B", "Latin Pop / Spain"),
    ("Usher", "~16B", "R&B / USA"),
    ("Jason Derulo", "~15B", "Pop/R&B / USA"),
    ("Hozier", "~15B", "Alternative / Ireland"),
    ("The Neighbourhood", "~15B", "Alternative / USA"),
    ("Metallica", "~15B", "Metal / USA"),
    ("The Rolling Stones", "~15B", "Rock / UK"),
    ("Elvis Presley", "~14B", "Rock & Roll / USA"),
    ("Bob Marley & The Wailers", "~14B", "Reggae / Jamaica"),
    ("2Pac", "~14B", "Hip-hop / USA"),
    ("Nas", "~13B", "Hip-hop / USA"),
]


def build_pdf(path: Path) -> Path:
    assert len(ARTISTS) == 100, len(ARTISTS)
    path.parent.mkdir(parents=True, exist_ok=True)

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "TitleCustom",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=18,
        leading=22,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#1a1a1a"),
        spaceAfter=6,
    )
    sub_style = ParagraphStyle(
        "Sub",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=9,
        leading=12,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#444444"),
        spaceAfter=14,
    )
    cell = ParagraphStyle(
        "Cell",
        parent=styles["Normal"],
        fontName="Helvetica",
        fontSize=8,
        leading=10,
        alignment=TA_LEFT,
    )
    cell_center = ParagraphStyle(
        "CellCenter",
        parent=cell,
        alignment=TA_CENTER,
    )

    generated = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    doc = SimpleDocTemplate(
        str(path),
        pagesize=letter,
        leftMargin=0.6 * inch,
        rightMargin=0.6 * inch,
        topMargin=0.55 * inch,
        bottomMargin=0.55 * inch,
        title="Top 100 Male Music Artists",
        author="Cursor Agent",
    )

    story: list = [
        Paragraph("Top 100 Male Music Artists", title_style),
        Paragraph(
            "Ranked by approximate all-time Spotify streams (lead + featured). "
            f"Source basis: SpotifyStats / ChartMasters data as of July 17, 2026. "
            f"Generated {generated}.",
            sub_style,
        ),
    ]

    header = [
        Paragraph("<b>#</b>", cell_center),
        Paragraph("<b>Artist</b>", cell),
        Paragraph("<b>Streams</b>", cell_center),
        Paragraph("<b>Genre / Origin</b>", cell),
    ]
    data = [header]
    for i, (name, streams, meta) in enumerate(ARTISTS, start=1):
        data.append(
            [
                Paragraph(str(i), cell_center),
                Paragraph(name, cell),
                Paragraph(streams, cell_center),
                Paragraph(meta, cell),
            ]
        )

    table = Table(data, colWidths=[0.45 * inch, 2.4 * inch, 1.0 * inch, 3.3 * inch])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#222222")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("BACKGROUND", (0, 1), (-1, 1), colors.HexColor("#fff3cd")),
                ("BACKGROUND", (0, 2), (-1, 3), colors.HexColor("#f8f8f8")),
                ("ROWBACKGROUNDS", (0, 4), (-1, -1), [colors.white, colors.HexColor("#f4f4f4")]),
                ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#cccccc")),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    story.append(table)
    story.append(Spacer(1, 0.25 * inch))
    story.append(
        Paragraph(
            "Note: Stream totals are approximate and change daily. "
            "Male groups (e.g. BTS, Coldplay, Queen) are included alongside solo male artists.",
            sub_style,
        )
    )
    doc.build(story)
    return path


if __name__ == "__main__":
    out = build_pdf(OUT)
    print(out)
    print(out.stat().st_size)
