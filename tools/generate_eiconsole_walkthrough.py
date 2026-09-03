#!/usr/bin/env python3
"""Build documents/eiconsole-walkthrough.yaml from a demo eip-root route.xml."""
from __future__ import annotations

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path

from demo_paths import require_demo

ROOT = Path(__file__).resolve().parents[1]

def _local(tag: str) -> str:
    return tag.split("}", 1)[-1] if "}" in tag else tag


def _text(el: ET.Element | None) -> str:
    if el is None or el.text is None:
        return ""
    return " ".join(el.text.split())


def _child(parent: ET.Element, name: str) -> ET.Element | None:
    for child in parent:
        if _local(child.tag) == name:
            return child
    return None


def _processors(parent: ET.Element | None) -> list[ET.Element]:
    el = _child(parent, "Processors") if parent is not None else None
    return [c for c in el if _local(c.tag) == "Processor"] if el is not None else []


def _cfg(module: ET.Element | None, name: str) -> str:
    if module is None:
        return ""
    cfg = _child(module, "ModuleConfig")
    if cfg is None:
        return ""
    return _text(_child(cfg, name))


def _cls(el: ET.Element | None) -> str:
    if el is None:
        return ""
    return (el.get("class") or "").rsplit(".", 1)[-1]


def _short(value: str, n: int = 48) -> str:
    t = value.replace("$$", "").strip()
    return t if len(t) <= n else t[: n - 1] + "…"


def _step(steps: list[dict], sid: str, action: str, target: dict, detail: str = "", dwell_ms: int = 350, optional: bool = True, dest: dict | None = None) -> None:
    item = {"id": sid, "action": action, "target": target, "detail": detail, "dwell_ms": dwell_ms}
    if optional:
        item["optional"] = True
    if dest:
        item["dest"] = dest
    steps.append(item)


def _mapper_rail_steps(steps: list[dict], prefix: str) -> None:
    _step(steps, f"{prefix}-map-tab", "click", {"type": "tab", "contains": "Mapping"},
          "The Data Mapper side rails hold the source and target formats.", 400, optional=False)
    _step(steps, f"{prefix}-map-opensrc", "click", {"text": "Open source format"}, "Formats load on the left rail.", 500)
    _step(steps, f"{prefix}-map-opensrc-esc", "escape", {"type": "JMenu", "text": "File"}, "", 150)
    _step(steps, f"{prefix}-map-opentgt", "click", {"text": "Open target format"}, "And on the right rail.", 500)
    _step(steps, f"{prefix}-map-opentgt-esc", "escape", {"type": "JMenu", "text": "File"}, "", 150)
    _step(steps, f"{prefix}-map-drag", "drag", {"type": "FormatTree", "side": "left"},
          "Drag from the source rail onto the target rail.", 600,
          dest={"type": "FormatTree", "side": "right"})


def _package_and_routes(eip_root: Path) -> tuple[str, list[tuple[str, Path]]]:
    iface = eip_root / "interfaces"
    packages = [p for p in iface.iterdir() if p.is_dir()] if iface.is_dir() else []
    if not packages:
        return "", []
    pkg = sorted(packages, key=lambda p: p.name)[0]
    routes: list[tuple[str, Path]] = []
    routes_dir = pkg / "routes"
    if routes_dir.is_dir():
        for route_dir in sorted(routes_dir.iterdir(), key=lambda p: p.name):
            xml = route_dir / "route.xml"
            if xml.is_file():
                routes.append((route_dir.name, xml))
    return pkg.name, routes


def _parse_route(path: Path) -> dict:
    tree = ET.parse(path)
    root = tree.getroot()
    sources = [el for el in root if _local(el.tag) == "Source"]
    targets = [el for el in root if _local(el.tag) == "Target"]
    routing = _child(root, "RoutingModule")
    src = sources[0] if sources else None
    listener = _child(src, "Listener") if src is not None else None
    src_fmt = _child(src, "FormatProfile") if src is not None else None
    return {
        "sources": sources,
        "targets": targets,
        "routing_class": _cls(routing),
        "listener": listener,
        "src_fmt": (src_fmt.get("name") if src_fmt is not None else "") or "",
        "src_procs": _processors(src),
    }


def _format_cfg(eip_root: Path, pkg: str, name: str) -> dict[str, str]:
    fmt = eip_root / "interfaces" / pkg / "formats" / name / "format.xml"
    if not fmt.is_file():
        return {}
    root = ET.parse(fmt).getroot()
    mod = _child(root, "TransformationModule")
    out = {
        "module": _cls(mod),
        "delimiter": _cfg(mod, "Delimiter"),
        "columns": _cfg(mod, "Columns"),
        "detect": _cfg(mod, "DetectDelimiter"),
    }
    xslt = _child(root, "XSLT")
    if xslt is not None:
        out["engine"] = _text(_child(xslt, "XSLTEngine"))
    return out


def _listener_steps(steps: list[dict], prefix: str, listener: ET.Element) -> None:
    name = listener.get("name") or "Listener"
    cls = _cls(listener)
    kind = {
        "DirectoryListener": "Directory Listener",
        "DirectoryTransport": "Directory Transport",
        "HL7TCPListener": "HL7 over LLP listener",
    }.get(cls, cls or "listener")
    interval = _cfg(listener, "PollingInterval")
    folder = _cfg(listener, "PollingDirectory")
    post = _cfg(listener, "PostProcessOperation")
    archive = _cfg(listener, "TargetDirectory")
    port = _cfg(listener, "Port")
    listen_line = f"Work starts at the Listener — {name}. This is a {kind}."
    if cls == "HL7TCPListener" and port:
        listen_line = f"Work starts at the Listener — {name}. This is HL7 over LLP. It monitors TCP port {port}."
    _step(
        steps,
        f"{prefix}-listener",
        "click",
        {"type": "table", "contains": "RoutingSource", "column": 1},
        listen_line,
        450,
        optional=False,
    )
    _step(steps, f"{prefix}-ltype", "click", {"contains": "Listener Type"}, "", 200)
    _step(steps, f"{prefix}-lbasic", "click", {"type": "tab", "contains": "Basic"}, "", 200)
    if cls == "HL7TCPListener":
        if port:
            _step(
                steps,
                f"{prefix}-lport",
                "click",
                {"contains": "Port"},
                f"The socket is port {port}.",
                400,
            )
        return
    folder_say = "the inbound folder" if folder.startswith("$$") or not folder else _short(folder)
    poll = f"It polls {folder_say}"
    if interval:
        poll += f" every {interval} seconds."
    else:
        poll += "."
    _step(steps, f"{prefix}-lpoll", "click", {"contains": "Polling"}, poll, 400)
    if post:
        line = f"After pickup, post-process is {post}"
        if archive:
            arch_say = "the archive folder" if archive.startswith("$$") else _short(archive)
            line += f" into {arch_say}."
        else:
            line += "."
        _step(steps, f"{prefix}-lpost", "click", {"contains": "Post-Process"}, line, 450)
        _step(steps, f"{prefix}-larch", "click", {"contains": "Target directory"}, "", 250)


def _first_proc(procs: list[ET.Element], *needles: str) -> ET.Element | None:
    for proc in procs:
        blob = f"{_cls(proc)} {proc.get('name') or ''}"
        if any(n in blob for n in needles):
            return proc
    return None


def _source_transform_steps(
    steps: list[dict],
    prefix: str,
    pkg: str,
    eip_root: Path,
    fmt_name: str,
    src_procs: list[ET.Element] | None = None,
) -> None:
    hl7_proc = _first_proc(src_procs or [], "HL7Transformation", "HL7 2")
    cfg = _format_cfg(eip_root, pkg, fmt_name) if fmt_name else {}
    cols = cfg.get("columns") or ""
    col_bits = [c.strip() for c in cols.split(",") if c.strip()][:6]
    delim = cfg.get("delimiter") or ""
    detect = (cfg.get("detect") or "").lower() == "true"
    mod = cfg.get("module") or ""
    hl7_story = hl7_proc is not None or "HL7" in mod or "HL7" in fmt_name
    extra = " That's the HL7 2.x to XML module." if hl7_story else (
        " That's the CSV transformer." if "CSV" in mod else (
            " That's the EDI transformer." if "EDI" in mod else (f" Module is {mod}." if mod else "")
        )
    )
    lead = ("Source Transform takes the HL7 and turns it into generic XML." if hl7_story else f"Source Transform is the {fmt_name or 'inbound'} format.") + extra
    _step(steps, f"{prefix}-stx", "click", {"type": "table", "contains": "RoutingSource", "column": 2}, lead, 450, optional=False)
    _step(steps, f"{prefix}-smod", "click", {"contains": "Transformation Module"}, "", 250)
    _step(steps, f"{prefix}-sto", "click", {"contains": "To XML"}, "", 200)
    _step(steps, f"{prefix}-sedit", "click", {"type": "button", "text": "Edit"}, "Open the Data Mapper from the format Edit button.", 400, optional=False)
    _mapper_rail_steps(steps, f"{prefix}-s")
    _step(steps, f"{prefix}-smap-hold", "wait_for", {"type": "JMenu", "text": "File"}, "", 400)
    _step(steps, f"{prefix}-sback", "click", {"contains": "Return to Console"}, "", 300)
    if delim:
        extra = " Detect delimiter is on, so tab or pipe still works." if detect else ""
        _step(
            steps,
            f"{prefix}-sdelim",
            "click",
            {"contains": "Delimiter"},
            f"Delimiter is {'a comma' if delim == ',' else delim}.{extra}",
            400,
        )
    if col_bits:
        _step(
            steps,
            f"{prefix}-scols",
            "click",
            {"contains": "Columns"},
            "Named columns: " + ", ".join(col_bits) + ("…" if len(cols.split(",")) > 6 else "") + ".",
            500,
        )


def _routing_steps(steps: list[dict], prefix: str, routing_class: str) -> None:
    if "Null" in (routing_class or ""):
        return
    _step(
        steps,
        f"{prefix}-route",
        "click",
        {"type": "table", "contains": "RoutingSource", "column": 3},
        "Routing decides who gets the 834 and who goes to kickout.",
        400,
        optional=False,
    )
    _step(steps, f"{prefix}-rrules", "click", {"type": "tab", "contains": "Routing Rules"}, "", 250)
    _step(steps, f"{prefix}-rxpath", "click", {"contains": "XPath"}, "The rule looks for a member id or last name.", 350)


def _target_transform_steps(
    steps: list[dict],
    prefix: str,
    fmt_name: str,
    tgt_procs: list[ET.Element] | None = None,
) -> None:
    xslt_proc = _first_proc(tgt_procs or [], "XSLT", "Map")
    relay = "Relay" in (fmt_name or "")
    use_proc = xslt_proc is not None and (relay or not fmt_name)
    lead = (
        f"Target Transform maps the patient XML into a SQL insert. That's {(xslt_proc.get('name') or 'the Data Mapper')}."
        if use_proc
        else f"Target Transform is {fmt_name or 'the map'} — that's the XSLT."
    )
    _step(
        steps,
        f"{prefix}-ttx",
        "click",
        {"type": "table", "contains": "RoutingSource", "column": 4},
        lead,
        450,
        optional=False,
    )
    _step(steps, f"{prefix}-tfrom", "click", {"contains": "From XML"}, "", 200)
    _step(steps, f"{prefix}-tedit", "click", {"type": "button", "text": "Edit"}, "Open the Data Mapper from the format Edit button.", 400, optional=False)
    _mapper_rail_steps(steps, f"{prefix}-t")
    _step(steps, f"{prefix}-tmap-hold", "wait_for", {"type": "JMenu", "text": "File"}, "", 400)
    _step(steps, f"{prefix}-tback", "click", {"contains": "Return to Console"}, "", 300)


def _testing_mode_steps(steps: list[dict], prefix: str) -> None:
    grid = {"type": "table", "contains": "RoutingSource"}
    _step(steps, f"{prefix}-mode", "click", {"type": "JMenu", "text": "Mode"}, "", 200)
    _step(steps, f"{prefix}-testing", "click", {"type": "JRadioButtonMenuItem", "text": "Testing Mode"}, "Let's move along to Testing Mode and run a saved test.", 400)
    _step(steps, f"{prefix}-tmc", "click", {"contains": "Test Mode Configuration"}, "", 250)
    _step(steps, f"{prefix}-tmopen", "click", {"type": "JMenu", "text": "Open"}, "", 200)
    _step(steps, f"{prefix}-tmsamp", "click", {"type": "JRadioButtonMenuItem", "contains": "Sample"}, "", 400)
    _step(steps, f"{prefix}-exec", "click", {"contains": "Execute Test"}, "Execute Test runs the stages against the live stack.", 400, optional=False)
    _step(steps, f"{prefix}-exec-wait", "pause", {"type": "JMenu", "text": "File"}, "", 2500)
    _step(steps, f"{prefix}-tout-s", "click", {**grid, "column": 2}, "Source Transform shows the inbound sample.", 450)
    _step(steps, f"{prefix}-tout-t", "click", {**grid, "column": 4}, "Target Transform shows what will be sent on.", 450)


def _processor_steps(steps: list[dict], prefix: str, proc: ET.Element, idx: int) -> None:
    if "FileWrite" in _cls(proc) or "XSLT" in _cls(proc) or (proc.get("name") or "").startswith("Snapshot"):
        return
    name = proc.get("name") or f"Processor {idx}"
    direction = _cfg(proc, "TransformationDirection")
    table = _cfg(proc, "TransactionDataWithVersion")
    data_d = _cfg(proc, "DataDelimiter")
    rec_d = _cfg(proc, "RecordDelimiter")
    sub_d = _cfg(proc, "SubDelimiter")
    friendly = _cfg(proc, "FriendlyNamesLevel")
    bits = [name]
    if direction:
        bits.append(direction)
    if "834-A1" in table:
        bits.append("table data 834-A1, 5010")
    if data_d or rec_d:
        bits.append("star and tilde delimiters")
    if friendly:
        bits.append(f"friendly names {friendly}")
    _step(
        steps,
        f"{prefix}-proc{idx}",
        "click",
        {"type": "table", "contains": name},
        ". ".join(bits).replace("XML to EDI 834. XML to EDI.", "XML to EDI 834.") + ".",
        500,
    )
    if data_d:
        _step(steps, f"{prefix}-pdel{idx}", "click", {"contains": "Data Delimiter"}, "", 250)
    if rec_d:
        _step(steps, f"{prefix}-prec{idx}", "click", {"contains": "Record Delimiter"}, "", 250)
    if sub_d:
        _step(steps, f"{prefix}-psub{idx}", "click", {"contains": "Sub Delimiter"}, "", 200)


def _transport_steps(steps: list[dict], prefix: str, transport: ET.Element, first: bool) -> None:
    name = transport.get("name") or "Transport"
    folder = _cfg(transport, "TargetDirectory")
    ext = _cfg(transport, "FileExtension")
    jdbc = _cfg(transport, "JdbcURL")
    if first:
        tr_line = f"Transport writes the file. This one is {name}."
        if _cls(transport) == "DatabaseSqlTransport" or jdbc:
            tr_line = f"Transport writes to the database. This one is {name}."
        _step(
            steps,
            f"{prefix}-tr",
            "click",
            {"type": "table", "contains": "RoutingSource", "column": 5},
            tr_line,
            400,
            optional=False,
        )
    _step(steps, f"{prefix}-trrow", "click", {"type": "table", "contains": name}, "", 300)
    _step(steps, f"{prefix}-trtab", "click", {"type": "tab", "contains": "Transport Configuration"}, "", 200)
    if _cls(transport) == "DatabaseSqlTransport" or jdbc:
        _step(
            steps,
            f"{prefix}-trjdbc",
            "click",
            {"contains": "JDBC"},
            "JDBC URL and credentials are on this panel. Test connection is the button at the bottom.",
            500,
        )
        return
    folder_say = "the output folder" if (folder or "").startswith("$$") or not folder else _short(folder)
    line = f"Target directory is {folder_say}."
    if ext:
        line += f" Extension is {ext}."
    _step(steps, f"{prefix}-trdir", "click", {"contains": "Target directory"}, line, 450)
    if ext:
        _step(steps, f"{prefix}-trext", "click", {"contains": "Target file extension"}, "", 250)


def build_steps(eip_root: Path) -> list[dict]:
    pkg, routes = _package_and_routes(eip_root)
    steps: list[dict] = []
    _step(steps, "wait-fm", "wait_for", {"type": "JMenu", "text": "File"}, "", 400, optional=False)
    _step(steps, "basic", "click", {"type": "tab", "contains": "Basic"}, "This is Route File Management. The working directory holds the interface packages.", 600, optional=False)
    _step(steps, "tools", "click", {"type": "JMenu", "text": "Tools"}, "Tools has the emulator and the H2 database if you need a local file database.", 700)
    _step(steps, "tools-esc", "escape", {"type": "JMenu", "text": "File"}, "", 200)
    if pkg:
        _step(
            steps,
            "open-pkg",
            "double_click",
            {"type": "table", "contains": pkg},
            f"This green box is the interface package — {pkg}.",
            600,
            optional=False,
        )
    for i, (route_name, xml) in enumerate(routes, start=1):
        parsed = _parse_route(xml)
        prefix = f"r{i}"
        _step(
            steps,
            f"{prefix}-open",
            "double_click",
            {"type": "table", "contains": route_name},
            f"Each puzzle piece is one route. This is {route_name}.",
            600,
            optional=i > 1,
        )
        _step(
            steps,
            f"{prefix}-src",
            "click",
            {"type": "table", "contains": "RoutingSource", "column": 0},
            "Source System and Target System are documentation. The work is the modules in between.",
            400,
        )
        if parsed["listener"] is not None:
            _listener_steps(steps, prefix, parsed["listener"])
            if i > 1:
                for step in reversed(steps):
                    if str(step.get("id") or "").startswith(f"{prefix}-"):
                        step["optional"] = True
                    else:
                        break
        if parsed["src_fmt"] or parsed["src_procs"]:
            _source_transform_steps(steps, prefix, pkg, eip_root, parsed["src_fmt"], parsed["src_procs"])
        _routing_steps(steps, prefix, parsed["routing_class"])
        first_target = parsed["targets"][0] if parsed["targets"] else None
        if first_target is not None:
            tfmt = _child(first_target, "FormatProfile")
            tname = (tfmt.get("name") if tfmt is not None else "") or ""
            proc_els = _processors(first_target)
            _target_transform_steps(steps, prefix, tname, proc_els)
            transport = _child(first_target, "Transport")
            if transport is not None:
                _transport_steps(steps, prefix, transport, first=True)
            for j, proc in enumerate(proc_els, start=1):
                _processor_steps(steps, prefix, proc, j)
        if i == 1:
            _testing_mode_steps(steps, prefix)
        if i < len(routes):
            _step(steps, f"{prefix}-file", "click", {"type": "JMenu", "text": "File"}, "", 200)
            _step(steps, f"{prefix}-fm", "click", {"type": "menuitem", "contains": "File Management"}, "", 400)
            _step(steps, f"{prefix}-basic", "click", {"type": "tab", "contains": "Basic"}, "", 200)
            if pkg:
                _step(steps, f"{prefix}-pkg", "double_click", {"type": "table", "contains": pkg}, "", 400)
        if i > 1:
            for step in steps:
                if str(step.get("id") or "").startswith(f"{prefix}-"):
                    step["optional"] = True
    return steps


def dump_yaml(name: str, steps: list[dict]) -> str:
    lines = [
        "# Generated from route.xml — clicks into configured fields, not just stages.",
        f"name: {name}",
        "steps:",
    ]
    for step in steps:
        lines.append(f"  - id: {step['id']}")
        lines.append(f"    action: {step['action']}")
        tgt = step.get("target") or {}
        parts = [
            f'{k}: "{tgt[k]}"' if k in ("contains", "text", "window") else f"{k}: {tgt[k]}"
            for k in ("type", "text", "contains", "window", "column")
            if k in tgt
        ]
        lines.append("    target: { " + ", ".join(parts) + " }")
        detail = str(step.get("detail") or "").replace('"', '\\"')
        lines.append(f'    detail: "{detail}"')
        if step.get("optional"):
            lines.append("    optional: true")
        lines.append(f"    dwell_ms: {int(step.get('dwell_ms') or 300)}")
    return "\n".join(lines) + "\n"


def generate(demo: Path) -> Path:
    eip = demo / "eip-root"
    if not (eip / "interfaces").is_dir():
        raise SystemExit(f"No eip-root/interfaces under {demo}")
    steps = build_steps(eip)
    out = demo / "documents" / "eiconsole-walkthrough.yaml"
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.is_file():
        first = (out.read_text(encoding="utf-8", errors="replace").splitlines() or [""])[0]
        if not first.startswith("# Generated from route.xml"):
            print(f"Keeping handwritten walkthrough: {out}")
            swing = ROOT / "tools" / "swing-demo-auto" / "demos" / f"eiconsole-{demo.name}.yaml"
            swing.parent.mkdir(parents=True, exist_ok=True)
            swing.write_text(out.read_text(encoding="utf-8"), encoding="utf-8")
            return out
    out.write_text(dump_yaml(f"eiconsole-{demo.name}", steps), encoding="utf-8")
    swing = ROOT / "tools" / "swing-demo-auto" / "demos" / f"eiconsole-{demo.name}.yaml"
    swing.parent.mkdir(parents=True, exist_ok=True)
    swing.write_text(out.read_text(encoding="utf-8"), encoding="utf-8")
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="Demo root under Clients/Demos/")
    args = ap.parse_args()
    demo = require_demo(args.root)
    path = generate(demo)
    print(path)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
