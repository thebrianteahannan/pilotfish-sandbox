# Swing eiConsole driver (Sandbox copy)

Copied from **PilotFish Swing Demo Auto** for use inside this Sandbox. Leave the sibling project untouched.

This package drives `/Applications/eiConsole/eiConsole.app` with `java.awt.Robot`. It does not record video. The Sandbox exporter `tools/export_eiconsole_construction_video.py` screen-captures eiConsole, plays a YAML script, then muxes AvaNeural TTS from the timeline.

## Build

```bash
cd tools/swing-demo-auto
./mvnw -q package
```

## Play a demo walkthrough

```bash
./mvnw -q package exec:java -Dexec.args="--app eiconsole --eip-root \"<demo>/eip-root\" --script <demo>/documents/eiconsole-walkthrough.yaml --timeline out/timeline.json"
```

macOS: grant Accessibility to Terminal, iTerm, or Cursor.
