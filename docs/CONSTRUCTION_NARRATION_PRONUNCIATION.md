# Construction narration pronunciation

**Audience:** Cursor agents exporting construction videos; humans reviewing voiceovers.  
**Machine source:** `docs/construction-narration-pronunciation.json`  
**PDF:** `docs/CONSTRUCTION_NARRATION_PRONUNCIATION.pdf`  
**Applied by:** `tools/construction_speech.py` (used from `tools/export_construction_video.py`)

## Display vs speech

| Surface | Spelling |
|---------|----------|
| Overlay, transcript PDF/TXT, build-replay `detail` | Normal technical spelling (`SFTP`, `/opt/pilotfish/...`) |
| TTS voiceover only | Pronunciation-safe rewrite from this guide |

Do **not** dumbed-down the on-screen transcript. Rewrite **only** for speech synthesis.

## Paths — never say “slash”

- Never speak `/` or `\` as “slash” / “backslash”.
- Prefer a **role name** when the path is a known demo folder:
  - `/opt/pilotfish/input/staged` → “the staged input folder”
  - `/opt/pilotfish/output/archive` → “the archive output folder”
- If the full path must be spoken, say folder segments with short pauses: `opt, pilotfish, input, staged`.
- File extensions: `.csv` → “dot C S V”.

## Letter-by-letter terms

Spell these out (spaces between letters) unless noted:

| Term | Say |
|------|-----|
| SFTP | S F T P |
| FTP | F T P |
| SSH | S S H |
| JSCH | J S C H |
| JDBC | J D B C |
| CSV | C S V |
| XML | X M L |
| XSLT | X S L T |
| SQLXML | S Q L X M L |
| API | A P I |
| HTTP / HTTPS | H T T P / H T T P S |
| OGNL | O G N L |
| dbo. | D B O dot … |

## Word pronunciations

| Term | Say |
|------|-----|
| SQL Server | sequel Server |
| SQL (alone) | sequel |
| JSON | jay son |
| XPath | X Path |
| eiPlatform | E I Platform |
| eiConsole | E I Console |
| localhost | local host |
| FQCN | fully qualified class name |

## Filenames & IDs

- Prefer human OGNL summaries already in the transcript (`{sourceFileName}_<timestamp>.csv`).
- For speech, “source file name, underscore, timestamp, dot C S V”.
- Do **not** read UUID module ids aloud — say “module id”.

## Regenerating the PDF

```bash
python3 tools/export_construction_narration_pronunciation_pdf.py
```

## Using it in videos

`export_construction_video.py` loads the JSON and rewrites each step’s spoken line before Edge TTS / `say`. After changing the guide, re-export the video:

```bash
python3 tools/export_construction_video.py --root Clients/Demos/<demo>
```
