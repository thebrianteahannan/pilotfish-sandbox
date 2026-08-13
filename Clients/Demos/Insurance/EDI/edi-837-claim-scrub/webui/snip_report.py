"""Build HTML SNIP validation reports using the shared PilotFish XSLT pipeline."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from xml.sax.saxutils import escape

from saxonche import PySaxonProcessor

XSLT_DIR = Path(__file__).resolve().parent / "xslt"


def _wrap_edi_xml(edi_text: str) -> str:
    # Match Route 14a: wrap raw EDI so transform.xslt can tokenize XCSData/text().
    return f"<XCSData><![CDATA[{edi_text}]]></XCSData>"


@lru_cache(maxsize=1)
def _xslt_paths() -> dict[str, str]:
    needed = ("transform.xslt", "normalize.xslt", "sort.xslt", "merge.xslt", "html.xslt")
    paths = {}
    for name in needed:
        path = XSLT_DIR / name
        if not path.is_file():
            raise FileNotFoundError(f"Missing XSLT: {path}")
        paths[name] = str(path)
    return paths


def build_snip_html(snip_xml: str, edi_text: str, *, segment_delim: str = "~", element_delim: str = "*") -> str:
    """Run normalize → sort → merge (with EDI map) → html from the 14a report route."""
    paths = _xslt_paths()
    edi_clean = (edi_text or "").replace("\r\n", "\n").replace("\r", "")
    # html.xslt tokenizes on '~'; strip trailing empties later in markup
    if not edi_clean.endswith("~") and "~" in edi_clean:
        # keep as-is; segments may already end with ~
        pass

    with PySaxonProcessor(license=False) as proc:
        xsltproc = proc.new_xslt30_processor()

        # 1) EDI map
        edi_doc = proc.parse_xml(xml_text=_wrap_edi_xml(edi_clean))
        transform = xsltproc.compile_stylesheet(stylesheet_file=paths["transform.xslt"])
        transform.set_parameter("segment-delimiter", proc.make_string_value(segment_delim))
        transform.set_parameter("element-delimiter", proc.make_string_value(element_delim))
        map_xml = transform.apply_templates_returning_string(xdm_node=edi_doc)
        if not map_xml:
            raise RuntimeError("EDI map transform produced empty output")

        # 2) normalize + sort SNIP results
        snip_doc = proc.parse_xml(xml_text=snip_xml)
        normalize = xsltproc.compile_stylesheet(stylesheet_file=paths["normalize.xslt"])
        errors_xml = normalize.apply_templates_returning_string(xdm_node=snip_doc)
        errors_doc = proc.parse_xml(xml_text=errors_xml)
        sort = xsltproc.compile_stylesheet(stylesheet_file=paths["sort.xslt"])
        sorted_xml = sort.apply_templates_returning_string(xdm_node=errors_doc)
        sorted_doc = proc.parse_xml(xml_text=sorted_xml)

        # 3) merge errors with segment line map
        merge = xsltproc.compile_stylesheet(stylesheet_file=paths["merge.xslt"])
        merge.set_parameter("map", proc.make_string_value(map_xml))
        merged_xml = merge.apply_templates_returning_string(xdm_node=sorted_doc)
        merged_doc = proc.parse_xml(xml_text=merged_xml)

        # 4) HTML report
        html = xsltproc.compile_stylesheet(stylesheet_file=paths["html.xslt"])
        # Tokenize parameter expects raw EDI text with '~' delimiters
        html.set_parameter("edi-text", proc.make_string_value(edi_clean.replace("\n", "")))
        report = html.apply_templates_returning_string(xdm_node=merged_doc)
        if not report:
            raise RuntimeError("HTML report transform produced empty output")
        return report


def fallback_html(message: str) -> str:
    return (
        "<!doctype html><html><head><meta charset='utf-8'/>"
        "<title>SNIP Report</title></head><body>"
        f"<p>{escape(message)}</p></body></html>"
    )
