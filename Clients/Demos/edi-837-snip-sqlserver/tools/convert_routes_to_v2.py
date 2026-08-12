#!/usr/bin/env python3
"""Convert V1 PilotFish route.xml to V2 (route.v2.xml + modules/*.xml).

Mirrors the layout produced by com.pilotfish.eip.config.node.NodeRouteLegacyImporter:
Listener/processors (+ source format fork) → Conditional router → target processors → Transport.
Keeps the original route.xml untouched.
"""

from __future__ import annotations

import re
import uuid
from pathlib import Path
from xml.dom import minidom
from xml.etree import ElementTree as ET

NS = {"r": "http://www.pilotfishtechnology.com/eipr/RouteSpec"}
COLUMN_SPACING = 260.0
ROW_SPACING = 140.0
NODE_W = 180.0
NODE_H = 64.0

TYPE_BY_CLASS = {
    "com.pilotfish.eip.modules.db.DatabaseSqlListener": "Database Polling (SQL)",
    "com.pilotfish.eip.modules.core.TriggerableListener": "Programmable (Trigger)",
    "com.pilotfish.eip.modules.file.DirectoryTransport": "Directory / File",
    "com.pilotfish.eip.modules.file.FileWriteProcessor": "File Writing",
    "com.pilotfish.eip.modules.other.XPathEvaluatorProcessor": "XPath Evaluation",
    "com.pilotfish.eip.modules.transform.XSLTProcessor": "XSLT Transformation",
    "com.pilotfish.eip.modules.internal.SaveDataToAttributeProcessor": "Data Attribute Swapper",
    "com.pilotfish.eip.modules.transform.EDITransformationProcessor": "EDI",
    "com.pilotfish.eip.modules.transform.edi.EdiSNIPValidationProcessor": "EDI SNIP Validation",
    "com.pilotfish.eip.modules.other.XPathForkingProcessor": "XPath",
    "com.pilotfish.eip.modules.internal.EIPTransport": "Route to Route",
    "com.pilotfish.eip.modules.internal.ConditionalNodeRoutingModule": "Conditional Node Router",
}

TAG_BY_KIND = {
    "listener": "Listener",
    "processor": "Processor",
    "transport": "Transport",
    "routing": "RoutingModule",
}


def local(tag: str) -> str:
    return tag.split("}")[-1] if "}" in tag else tag


def find_child(el: ET.Element | None, name: str) -> ET.Element | None:
    if el is None:
        return None
    for child in el:
        if local(child.tag) == name:
            return child
    return None


def find_all(el: ET.Element | None, name: str) -> list[ET.Element]:
    if el is None:
        return []
    return [c for c in el if local(c.tag) == name]


def text_of(el: ET.Element | None) -> str:
    if el is None or el.text is None:
        return ""
    return el.text.strip()


def expression_xpath(condition_el: ET.Element | None) -> str:
    expr = find_child(condition_el, "Expression")
    if expr is None:
        return "true()"
    # text content before Namespaces child
    parts = []
    if expr.text and expr.text.strip():
        parts.append(expr.text.strip())
    for child in expr:
        if local(child.tag) == "Namespaces":
            break
        if child.tail and child.tail.strip():
            parts.append(child.tail.strip())
    raw = " ".join(parts).strip()
    # ElementTree already unescapes &gt; etc.
    return raw or "true()"


def pretty_xml(root: ET.Element) -> str:
    rough = ET.tostring(root, encoding="utf-8")
    parsed = minidom.parseString(rough)
    return parsed.toprettyxml(indent="   ", encoding="UTF-8").decode("utf-8")


def copy_module_config(src_cfg: ET.Element | None) -> ET.Element:
    cfg = ET.Element("ModuleConfig")
    if src_cfg is None:
        return cfg
    for child in src_cfg:
        cfg.append(clone_element(child))
    return cfg


def clone_element(el: ET.Element) -> ET.Element:
    out = ET.Element(local(el.tag), {k: v for k, v in el.attrib.items()})
    out.text = el.text
    out.tail = el.tail
    for child in el:
        out.append(clone_element(child))
    return out


class Converter:
    def __init__(self, route_dir: Path, formats_dir: Path):
        self.route_dir = route_dir
        self.formats_dir = formats_dir
        self.modules_dir = route_dir / "modules"
        self.modules: list[dict] = []
        self.nodes: list[dict] = []
        self.connections: list[dict] = []

    def new_id(self) -> str:
        return str(uuid.uuid4())

    def add_module(
        self,
        *,
        kind: str,
        class_name: str,
        name: str,
        cfg: ET.Element | None,
        type_name: str | None = None,
    ) -> str:
        mid = self.new_id()
        self.modules.append(
            {
                "id": mid,
                "class": class_name,
                "name": name,
                "tag": TAG_BY_KIND[kind],
                "type": type_name or TYPE_BY_CLASS.get(class_name, class_name.rsplit(".", 1)[-1]),
                "config": copy_module_config(cfg),
            }
        )
        return mid

    def add_node(self, module_id: str, label: str, col: int, row: int, height: float | None = None) -> str:
        nid = self.new_id()
        self.nodes.append(
            {
                "id": nid,
                "moduleId": module_id,
                "label": label,
                "x": col * COLUMN_SPACING,
                "y": row * ROW_SPACING,
                "width": NODE_W,
                "height": height or NODE_H,
            }
        )
        return nid

    def connect(
        self,
        source: str,
        target: str,
        *,
        condition: str = "true",
        source_connector: str = "right-output",
        target_connector: str = "left-input",
    ) -> None:
        self.connections.append(
            {
                "id": self.new_id(),
                "sourceNodeId": source,
                "targetNodeId": target,
                "condition": condition,
                "sourceConnector": source_connector,
                "targetConnector": target_connector,
            }
        )

    def add_chain(self, modules: list[tuple], start_col: int, row: int) -> list[str]:
        """modules: list of (kind, class, name, cfg_el, optional type)"""
        node_ids = []
        col = start_col
        prev = None
        for item in modules:
            kind, class_name, name, cfg = item[:4]
            typ = item[4] if len(item) > 4 else None
            mid = self.add_module(kind=kind, class_name=class_name, name=name, cfg=cfg, type_name=typ)
            nid = self.add_node(mid, name, col, row)
            node_ids.append(nid)
            if prev is not None:
                self.connect(prev, nid)
            prev = nid
            col += 1
        return node_ids

    def load_format(self, name: str) -> ET.Element | None:
        if not name or name.startswith("Relay"):
            return None
        path = self.formats_dir / name / "format.xml"
        if not path.is_file():
            return None
        return ET.parse(path).getroot()

    def source_format_modules(self, format_name: str) -> list[tuple]:
        fmt = self.load_format(format_name)
        if fmt is None:
            return []
        out: list[tuple] = []
        # Skip RelayTransformationModule
        split = None
        for child in fmt.iter():
            if local(child.tag) == "ForkModule":
                split = child
                break
        if split is not None:
            cls = split.attrib.get("class", "")
            if not cls.endswith("NullForkModule"):
                # XPathForkingModule -> XPathForkingProcessor
                proc_cls = cls
                if proc_cls.endswith("ForkingModule"):
                    proc_cls = proc_cls[: -len("ForkingModule")] + "ForkingProcessor"
                elif proc_cls.endswith("ForkModule"):
                    proc_cls = proc_cls[: -len("ForkModule")] + "ForkProcessor"
                cfg = find_child(split, "ModuleConfig")
                out.append(("processor", proc_cls, "Fork - XPath", cfg))
        # Skip empty ToXML XSLT paths
        return out

    def convert(self) -> None:
        route_xml = self.route_dir / "route.xml"
        root = ET.parse(route_xml).getroot()
        route_name = self.route_dir.name

        # settings
        pooling = root.attrib.get("RouteSpecificPooling", "true")
        debug = root.attrib.get("debuggingTrace", "false")
        ttl = root.attrib.get("transactionTimeToLive", "300000")
        keep = root.attrib.get("debugTraceCurrentSecondsToKeepFiles", "-1")
        maxf = root.attrib.get("debugTraceMaxFiles", "-1")

        source_tails: list[str] = []
        row = 0
        for source in find_all(root, "Source"):
            chain: list[tuple] = []
            listener = find_child(source, "Listener")
            if listener is not None:
                chain.append(
                    (
                        "listener",
                        listener.attrib["class"],
                        listener.attrib.get("name") or "Listener",
                        find_child(listener, "ModuleConfig"),
                    )
                )
            for proc in find_all(source, "Processor"):
                # Processors may be nested under Source/Processors
                pass
            procs_wrap = find_child(source, "Processors")
            for proc in find_all(procs_wrap, "Processor"):
                chain.append(
                    (
                        "processor",
                        proc.attrib["class"],
                        proc.attrib.get("name") or "Processor",
                        find_child(proc, "ModuleConfig"),
                    )
                )
            # also direct Processor children (older layouts)
            for proc in find_all(source, "Processor"):
                if find_child(source, "Processors") is not None:
                    break
                chain.append(
                    (
                        "processor",
                        proc.attrib["class"],
                        proc.attrib.get("name") or "Processor",
                        find_child(proc, "ModuleConfig"),
                    )
                )

            fmt = find_child(source, "FormatProfile")
            fmt_name = fmt.attrib.get("name", "") if fmt is not None else ""
            chain.extend(self.source_format_modules(fmt_name))

            nodes = self.add_chain(chain, 0, row)
            if nodes:
                source_tails.append(nodes[-1])
            row += 1

        # routing
        router_node = None
        router_in = None
        router_out = None
        routing = find_child(root, "RoutingModule")
        transport_by_rule: list[tuple[str, str]] = []  # (output_port_id, transport_name)
        if routing is not None and routing.attrib.get("class", "").endswith("XPathRoutingModule"):
            cfg = find_child(routing, "ModuleConfig")
            rule_set = None
            if cfg is not None:
                for child in cfg.iter():
                    if local(child.tag) == "RuleSet":
                        rule_set = child
                        break
            inputs_xml = []
            outputs_xml = []
            in_id = self.new_id()
            inputs_xml.append((in_id, "Input"))
            router_in = in_id
            rule_num = 1
            if rule_set is not None:
                for rule in find_all(rule_set, "Rule"):
                    targets = find_child(rule, "Targets")
                    names = []
                    for tt in find_all(targets, "TransportTarget"):
                        names.append(tt.attrib.get("name", ""))
                    cond_el = find_child(rule, "Condition")
                    xpath = expression_xpath(cond_el)
                    out_id = self.new_id()
                    label = f"Rule {rule_num}" + (f" - {', '.join(n for n in names if n)}" if names else "")
                    outputs_xml.append((out_id, label, xpath))
                    for n in names:
                        transport_by_rule.append((out_id, n))
                    rule_num += 1
            if not outputs_xml:
                out_id = self.new_id()
                outputs_xml.append((out_id, "No matching rules", "false"))

            # build ConditionalNodeRoutingModule config
            rcfg = ET.Element("ModuleConfig")
            ET.SubElement(rcfg, "SelectionMode").text = "FIRST_MATCH"
            ports = ET.SubElement(rcfg, "RoutingPorts", {"version": "1"})
            inputs = ET.SubElement(ports, "inputs")
            for iid, iname in inputs_xml:
                ET.SubElement(inputs, "input", {"id": iid, "name": iname})
            outputs = ET.SubElement(ports, "outputs")
            for oid, oname, xpath in outputs_xml:
                oel = ET.SubElement(outputs, "output", {"id": oid, "name": oname, "type": "XPATH"})
                ET.SubElement(oel, "condition").text = xpath
                if outputs_xml and oid == outputs_xml[0][0]:
                    router_out = oid

            mid = self.add_module(
                kind="routing",
                class_name="com.pilotfish.eip.modules.internal.ConditionalNodeRoutingModule",
                name="Conditional Router",
                cfg=rcfg,
            )
            height = max(NODE_H, (max(len(inputs_xml), len(outputs_xml)) + 1) * 24.0)
            router_node = self.add_node(mid, "Conditional Router", 3, 0, height=height)

            # remember all output ports for connection mapping
            self._router_outputs = {name: oid for oid, name, _ in outputs_xml}  # unused
            self._out_ports_by_transport = {}
            for oid, tname in transport_by_rule:
                self._out_ports_by_transport.setdefault(tname, oid)
            # if single output, keep router_out
            if len(outputs_xml) == 1:
                router_out = outputs_xml[0][0]

        # targets
        target_heads: dict[str, str] = {}  # transport name -> head node
        row = 0
        for target in find_all(root, "Target"):
            chain = []
            procs_wrap = find_child(target, "Processors")
            for proc in find_all(procs_wrap, "Processor"):
                chain.append(
                    (
                        "processor",
                        proc.attrib["class"],
                        proc.attrib.get("name") or "Processor",
                        find_child(proc, "ModuleConfig"),
                    )
                )
            transport = find_child(target, "Transport")
            tname = ""
            if transport is not None:
                tname = transport.attrib.get("name") or "Transport"
                chain.append(
                    (
                        "transport",
                        transport.attrib["class"],
                        tname,
                        find_child(transport, "ModuleConfig"),
                    )
                )
            nodes = self.add_chain(chain, 5, row)
            if nodes and tname:
                target_heads[tname] = nodes[0]
                # set retries on transport node if present
                retries = transport.attrib.get("retries") if transport is not None else None
                if retries:
                    for n in self.nodes:
                        if n["id"] == nodes[-1]:
                            n["retries"] = retries
            row += 1

        # wire source -> router -> targets
        if router_node is not None:
            for tail in source_tails:
                self.connect(
                    tail,
                    router_node,
                    target_connector=f"router-input:{router_in}",
                )
            # connect each rule output to matching transport
            connected = set()
            for tname, head in target_heads.items():
                out_port = self._out_ports_by_transport.get(tname) or router_out
                self.connect(
                    router_node,
                    head,
                    source_connector=f"router-output:{out_port}",
                )
                connected.add(tname)
            # if no transport mapping worked, mesh
            if not connected and router_out:
                for head in target_heads.values():
                    self.connect(
                        router_node,
                        head,
                        source_connector=f"router-output:{router_out}",
                    )
        else:
            for tail in source_tails:
                for head in target_heads.values():
                    self.connect(tail, head)

        self.write_files(route_name, pooling, debug, ttl, keep, maxf)

    def write_files(self, route_name, pooling, debug, ttl, keep, maxf) -> None:
        self.modules_dir.mkdir(parents=True, exist_ok=True)
        # clear previous modules
        for old in self.modules_dir.glob("*.xml"):
            old.unlink()

        for mod in self.modules:
            mroot = ET.Element(
                "Module",
                {
                    "version": "2.0",
                    "id": mod["id"],
                    "name": mod["name"],
                    "type": mod["type"],
                    "tag": mod["tag"],
                    "class": mod["class"],
                },
            )
            mroot.append(mod["config"])
            (self.modules_dir / f"{mod['id']}.xml").write_text(pretty_xml(mroot), encoding="utf-8")

        rroot = ET.Element(
            "Route",
            {
                "version": "2.0",
                "id": self.new_id(),
                "name": route_name,
            },
        )
        settings = ET.SubElement(
            rroot,
            "RouteSettings",
            {
                "RouteSpecificPooling": pooling,
                "debuggingTrace": debug,
                "debugTraceCurrentSecondsToKeepFiles": keep,
                "debugTraceMaxFiles": maxf,
                "transactionTimeToLive": ttl,
            },
        )
        # keep serializer-ish optional empty attrs off
        nodes_el = ET.SubElement(rroot, "Nodes")
        for n in self.nodes:
            attrs = {
                "id": n["id"],
                "moduleId": n["moduleId"],
                "label": n["label"],
                "x": str(n["x"]),
                "y": str(n["y"]),
                "width": str(n["width"]),
                "height": str(n["height"]),
            }
            if "retries" in n:
                attrs["retries"] = str(n["retries"])
            ET.SubElement(nodes_el, "Node", attrs)
        conns_el = ET.SubElement(rroot, "Connections")
        for c in self.connections:
            ET.SubElement(
                conns_el,
                "Connection",
                {
                    "id": c["id"],
                    "sourceNodeId": c["sourceNodeId"],
                    "targetNodeId": c["targetNodeId"],
                    "sourceConnector": c["sourceConnector"],
                    "targetConnector": c["targetConnector"],
                    "condition": c["condition"],
                },
            )
        (self.route_dir / "route.v2.xml").write_text(pretty_xml(rroot), encoding="utf-8")
        print(f"Wrote {self.route_dir / 'route.v2.xml'} + {len(self.modules)} modules")


def main():
    iface = Path(
        "/Users/brianhannan/Documents/PilotFish Sandbox/Clients/Demos/"
        "edi-837-snip-sqlserver/eip-root/interfaces/EDI 837 SNIP SQL Server"
    )
    formats = iface / "formats"
    for route in sorted((iface / "routes").iterdir()):
        if not (route / "route.xml").is_file():
            continue
        print("Converting", route.name)
        Converter(route, formats).convert()

    try:
        import sys
        from pathlib import Path as _P

        tools = _P("/Users/brianhannan/Documents/PilotFish Sandbox/tools")
        if str(tools) not in sys.path:
            sys.path.insert(0, str(tools))
        from sync_module_docs import sync_demo

        sync_demo(root)
        print("Synced documents/module-docs/")
    except Exception as exc:
        print(f"WARNING: sync_module_docs skipped ({exc})")


if __name__ == "__main__":
    main()
