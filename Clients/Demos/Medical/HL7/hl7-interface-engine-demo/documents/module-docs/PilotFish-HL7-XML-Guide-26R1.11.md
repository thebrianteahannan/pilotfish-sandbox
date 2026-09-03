---
title: "PilotFish HL7 XML Guide -- Deep Dive (26R1.11)"
author: "Derived from decompiled eip.war.hs.26R1.11"
date: "August 4, 2026"
geometry: margin=1in
fontsize: 11pt
---

<!-- PLAIN_ENGLISH_OVERVIEW -->
# At a glance (plain English)

**HL7 XML is PilotFish's XML view of HL7 v2 pipe messages.** An `MSH|^~\&|…` stream becomes nested segment / field / component tags you can map with XSLT, validate, then render back to ER7. It is produced and consumed by the **HL7 v2.X** transformation module (`HL7v2ToXMLTransformer` / `XMLToHL7v2Transformer`), not by writing raw pipes into an XML editor.

![At a glance (plain English)](../../_shared/overview-images/overview-hl7-xml.png){ width=95% }

- Root is usually the **message type** element (for example `ORU_R01`, `ADT_A01`), optionally under `urn:hl7-org:v2xml`.
- Segments are tags (`MSH`, `PID`); fields `MSH.3`, components `PID.5.1`, with repetition / grouping per vocabulary.
- Bidirectional: **HL7 to XML** and **XML to HL7** via transformer direction.
- Options (friendly names, namespace, empty fields, Z-segments) change the tree maps must match.

\newpage

# Purpose

This guide explains **HL7 v2 XML shape and round-trip behavior** in **`eip.war.hs.26R1.11`**. Companion to HL7 LLP listener / MLLP transport docs and `PilotFish-HL7-Validation-Reference-26R1.11.md`.

| Provenance | Value |
|------------|-------|
| WAR | `eip.war.hs.26R1.11` |
| Transformer type string | `HL7 v2.X` |
| Module | `HL7v2TransformationModule` / `HL7v2TransformationModuleInt` |
| Processor wrapper | `HL7TransformationProcessor` |
| HL7 -> XML | `…/transformers/HL7v2ToXMLTransformer.java` |
| XML -> HL7 | `…/transformers/XMLToHL7v2Transformer.java` |
| Optional namespace | `urn:hl7-org:v2xml` (`HL7Namespace` constant) |

> Derived from CFR decompile of the HL7 transform stack. XML layout also depends on selected HL7 version vocabulary (2.2–2.8.x).

---

# 1. Mental model

```text
ER7 HL7 v2 bytes (pipe/caret/tilde)
        |
        v
 HL7 v2.X transformation -- "HL7 to XML"
   detect delimiters from MSH
   parse segments -> data model
   emit XML (message / groups / segments / fields)
        |
        v
 XSLT / validation / enrichment
        |
        v
 HL7 v2.X transformation -- "XML to HL7"
   XML -> data model -> ER7 string
```

Related (not this dialect): **HL7 Identification** (raw ER7 attributes), **HL7 Validation** (rules on the chosen format), **HL7 LLP / MLLP** (wire protocol).

---

# 2. Typical XML skeleton

Without friendly names (default-style numeric fields):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ORU_R01 xmlns="urn:hl7-org:v2xml">
  <MSH>
    <MSH.1>|</MSH.1>
    <MSH.2>^~\&amp;</MSH.2>
    <MSH.3>
      <MSH.3.1>SENDING_APP</MSH.3.1>
    </MSH.3>
    <MSH.9>
      <MSH.9.1>ORU</MSH.9.1>
      <MSH.9.2>R01</MSH.9.2>
    </MSH.9>
    <MSH.12>
      <MSH.12.1>2.5.1</MSH.12.1>
    </MSH.12>
  </MSH>
  <PID>
    <PID.3>
      <PID.3.1>MRN123</PID.3.1>
    </PID.3>
    <PID.5>
      <PID.5.1>DOE</PID.5.1>
      <PID.5.2>JOHN</PID.5.2>
    </PID.5>
  </PID>
  <!-- OBX / NTE / groups per message definition -->
</ORU_R01>
```

Notes:

- Root tag follows **message structure name** from the HL7 version tables (often `MSGTYPE_TRIGGER`).
- Segment groups from the specification appear as intermediate wrapper elements when group detection / format metadata says so.
- Namespace is **optional** -- controlled by **Use namespace** on the transformer (`useNamespace`). Maps must decide: with NS prefer `local-name()`, or declare the prefix.

---

# 3. Options that change the XML

From `HL7v2ToXMLTransformerSettings` / module configuration (labels from `HL7v2TransformationModuleInt`):

| Concern | Effect on XML / reverse |
|---------|-------------------------|
| HL7 Version to expect | Which vocabulary builds structure / field names |
| Rebuild format for unexpected version | Re-derive format when MSH version differs |
| Automatically detect segment separator | CR vs LF vs CRLF detection (costly on large files) |
| Ignore Unknown Z-segments | Drop vs fail on custom Zxx segments |
| Fail if component not found | Strictness on XML -> HL7 required pieces |
| Ignore Max Occurrences | Allow more repeats than the table max |
| Friendly names / attribute friendly names | Human labels instead of or in addition to `SEG.N` tags |
| Use namespace | Emit `urn:hl7-org:v2xml` |
| Include empty fields | Keep empty `SEG.N` elements vs omit |
| Children handling strategy | Default / per-specification / custom child population lists |
| Populate FirstChildRawValue attr | Extra attribute on parents (`FirstChildRawValue`) |

Wrong option set between to-XML and from-XML is a common round-trip failure mode.

---

# 4. Field encoding model

Conceptual hierarchy (data model classes):

```text
Message
  Segment | SegmentGroup
    Field (may repeat)
      FieldRepetition
        Component
          SubComponent
```

XML tag patterns commonly look like:

| Level | Pattern |
|-------|---------|
| Segment | `MSH`, `PID`, `OBX` |
| Field | `MSH.3`, `PID.5` |
| Component | `PID.5.1`, `PID.5.2` |
| Subcomponent | deeper `.N` where defined |

Delimiters for reverse transform are recovered from MSH parsing rules on forward transform; keep MSH encoding characters consistent when authoring XML by hand.

---

# 5. XML -> HL7 behavior

`XMLToHL7v2Transformer`:

1. Parse DOM -> data model (`XMLToDataModelConverter`).
2. Optional **format fill** inserts missing segments/fields per format container.
3. Emit ER7 via `DataModelToStringConverter` (segment terminator default CR `\r`).
4. Optional batch segment wrapping when configured.

Whitespace-only or friendly-name-only trees that do not match the expected tags will drop data or throw `HL7Exception`.

---

# 6. XSLT patterns

Prefer local-name when namespace may be on/off:

```xpath
//*[local-name()='PID']/*[local-name()='PID.5']/*[local-name()='PID.5.1']
```

When friendly names are enabled, update XPaths to the emitted labels (do not assume `PID.5.1`).

---

# 7. Quirks

1. **Not HL7 CDA / FHIR** -- this dialect is v2 ER7 mirrored in XML.
2. **Version drift** -- MSH.12 vs configured version changes grouping.
3. **Z-segments** -- custom segments need Ignore Unknown Z or explicit format support.
4. **Empty fields** -- omit vs include changes XPath cardinality.
5. **Namespace toggle** -- breaks naive `/ORU_R01/MSH` paths when NS is added later.
6. **HAPI module sibling** -- `HL7HAPITransformationModule` is a separate path; do not mix assumptions with v2.X transformer options blindly.
7. **Batch / multi-message** -- files with multiple MSH blocks become multiple messages in the model; XML authorship should preserve that if round-tripping batches.

---

# 8. Operational recommendations

| Goal | Guidance |
|------|----------|
| Stable maps | Freeze version, namespace, friendly-name flags in the Format/transformer |
| Healthcare ORU/ADT | Enable vocabulary cache; match LLP listener version |
| Round trip | Same settings both directions; validate with sample MSH |
| Custom Z content | Agree whether Z-segments are ignored or modeled |
| XPath | `local-name()` unless NS is guaranteed |

---

# 9. Source index

| Topic | Path under `war-pipeline/decompiled/eip-26R1.11/` |
|-------|------|
| Module | `…/transform/hl7/transformers/HL7v2TransformationModuleInt.java` |
| HL7 -> XML | `…/transformers/HL7v2ToXMLTransformer.java` |
| XML -> HL7 | `…/transformers/XMLToHL7v2Transformer.java` |
| Settings | `…/transformers/HL7v2ToXMLTransformerSettings.java` |
| Processor | `…/transform/hl7/HL7TransformationProcessor.java` |

---

# 10. See also

- `Documents/Processors/26R1.11/PilotFish-HL7-Validation-Reference-26R1.11.md`
- `Documents/Listeners/26R1.11/PilotFish-HL7-LLP-Listener-Reference-26R1.11.md`
- `Documents/Transports/26R1.11/PilotFish-HL7-MLLP-Simple-Transport-Reference-26R1.11.md`
- Other dialect guides under search filter **Transformations**

---

*Guide derived from WAR decompile -- HL7 XML -- 26R1.11 -- August 2026.*
