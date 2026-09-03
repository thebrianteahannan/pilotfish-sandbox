"""Open Mac eiConsole with a client's eip-root as the working directory."""

from __future__ import annotations

import plistlib
import subprocess
import tempfile
import time
from pathlib import Path

APP = Path("/Applications/eiConsole/eiConsole.app")
JRE_JAVA = Path("/Applications/eiConsole/.install4j/jre.bundle/Contents/Home/bin/java")
DOMAIN = "com.pilotfish.eip"
PLIST = Path.home() / "Library/Preferences" / f"{DOMAIN}.plist"
WD = "com.pilotfish.eip.console.workingDirectory"
WD_I = WD + "_{i}"
# Live node eiConsole actually reads (other slash/empty-string trees are leftovers).
LIVE = ("/com/pilotfish/eip/", "gui/", "console/", "config/", "prefs/")
ALSO = (
    ("", "com", "pilotfish", "eip", "", "gui", "", "console", "", "config", "", "prefs"),
    ("/com/pilotfish/eip/", "/gui/", "/console/", "/config/", "/prefs/"),
    ("com", "pilotfish", "eip", "gui", "console", "config", "prefs"),
)
SET_WD_JAVA = r"""
import java.util.ArrayList;
import java.util.prefs.Preferences;
public class SetEiConsoleWd {
  public static void main(String[] args) throws Exception {
    String path = args[0];
    Preferences p = Preferences.userRoot().node("com/pilotfish/eip/gui/console/config/prefs");
    ArrayList<String> list = new ArrayList<String>();
    list.add(path);
    for (int i = 0; i < 10; i++) {
      String v = p.get("com.pilotfish.eip.console.workingDirectory_" + i, "");
      if (v != null && !v.isEmpty() && !v.equals(path) && !list.contains(v)) list.add(v);
    }
    p.put("com.pilotfish.eip.console.workingDirectory", path);
    for (int i = 0; i < 10; i++) {
      String key = "com.pilotfish.eip.console.workingDirectory_" + i;
      if (i < list.size()) p.put(key, list.get(i));
      else p.remove(key);
    }
    p.flush();
    System.out.println(p.get("com.pilotfish.eip.console.workingDirectory_0", ""));
  }
}
"""


def _node(data: dict, parts: tuple[str, ...]) -> dict:
    node = data
    for part in parts:
        cur = node.get(part)
        if not isinstance(cur, dict):
            node[part] = {}
            cur = node[part]
        node = cur
    return node


def _load() -> dict:
    proc = subprocess.run(["defaults", "export", DOMAIN, "-"], capture_output=True, timeout=10)
    if proc.returncode == 0 and proc.stdout:
        try:
            loaded = plistlib.loads(proc.stdout)
            if isinstance(loaded, dict):
                return loaded
        except Exception:
            pass
    if PLIST.is_file():
        try:
            loaded = plistlib.loads(PLIST.read_bytes())
            if isinstance(loaded, dict):
                return loaded
        except Exception:
            pass
    return {}


def _rotate(prefs: dict, path: str) -> None:
    ordered: list[str] = [path]
    for i in range(16):
        val = prefs.get(WD_I.format(i=i))
        if isinstance(val, str) and val and val != path and val not in ordered:
            ordered.append(val)
    extra = prefs.get(WD)
    if isinstance(extra, str) and extra and extra != path and extra not in ordered:
        ordered.append(extra)
    ordered = ordered[:10]
    prefs[WD] = path
    for i in range(16):
        prefs.pop(WD_I.format(i=i), None)
    for i, val in enumerate(ordered):
        prefs[WD_I.format(i=i)] = val


def _import_plist(data: dict) -> None:
    raw = plistlib.dumps(data, fmt=plistlib.FMT_XML)
    with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as tmp:
        tmp.write(raw)
        tmp_path = tmp.name
    try:
        proc = subprocess.run(["defaults", "import", DOMAIN, tmp_path], capture_output=True, text=True, timeout=10)
        if proc.returncode != 0:
            PLIST.write_bytes(plistlib.dumps(data, fmt=plistlib.FMT_BINARY))
            subprocess.run(["killall", "cfprefsd"], capture_output=True, timeout=5)
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def _set_via_java(path: str) -> str:
    if not JRE_JAVA.is_file():
        return ""
    with tempfile.TemporaryDirectory() as td:
        src = Path(td) / "SetEiConsoleWd.java"
        src.write_text(SET_WD_JAVA, encoding="utf-8")
        javac = JRE_JAVA.with_name("javac")
        compile_cmd = [str(javac if javac.is_file() else "javac"), str(src)]
        proc = subprocess.run(compile_cmd, capture_output=True, text=True, timeout=30, cwd=td)
        if proc.returncode != 0:
            return ""
        run = subprocess.run(
            [str(JRE_JAVA), "-cp", td, "SetEiConsoleWd", path],
            capture_output=True,
            text=True,
            timeout=20,
        )
        if run.returncode != 0:
            return ""
        return (run.stdout or "").strip()


def set_working_directory(eip_root: Path) -> str:
    path = str(eip_root.resolve())
    via_java = _set_via_java(path)
    data = _load()
    for parts in (LIVE,) + ALSO:
        _rotate(_node(data, parts), path)
    _import_plist(data)
    return via_java or path


def _quit() -> None:
    subprocess.run(["osascript", "-e", 'quit app "eiConsole"'], capture_output=True, timeout=15)
    time.sleep(0.8)
    subprocess.run(["killall", "eiConsole"], capture_output=True, timeout=5)
    time.sleep(0.5)


def open_eip(eip_root: Path) -> dict:
    if not APP.is_dir():
        raise FileNotFoundError("eiConsole is not installed at /Applications/eiConsole/eiConsole.app")
    if not eip_root.is_dir() or not (eip_root / "interfaces").is_dir():
        raise FileNotFoundError(f"No eip-root with interfaces/ at {eip_root}")
    _quit()
    wd = set_working_directory(eip_root)
    time.sleep(0.3)
    proc = subprocess.run(["open", "-a", str(APP)], capture_output=True, text=True, timeout=20)
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout or "open eiConsole failed").strip())
    return {"ok": True, "working_directory": wd}
