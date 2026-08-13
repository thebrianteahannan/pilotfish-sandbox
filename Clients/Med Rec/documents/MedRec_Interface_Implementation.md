# Med Rec interface implementation

How this Flat File → HL7 interface actually works. Use this when planning client emails. Do not invent a different meaning for everyday words like strip, split, partition, or facility.

## What the interface does

Incoming client flat files become canonical XML, then some records are tweaked, some are stripped, then remaining records are split by facility and written as ADT and DFT HL7. Stripped and tweaked records are written to kickout Excel reports.

The main path is:

- Incoming flat files by partition and client — read the file, map it to canonical XML. Halifax Location_ABBR is mapped to a facility code here (HAX, HED, POX, PXE). That map is for splitting, not for stripping.
- Stripping and tweaking — strip_data.xslt marks records that must not go to HL7. tweak_data.xslt changes values that should still go to HL7.
- Splitting records by facility — uses the facility on the record (and CLIENT_SPLITS / CLIENT_CODES) to send each account to the right output.
- Generate HL7 — ADT A04 and DFT P03 from records that were not stripped.
- Kickout reports — stripped and tweaked rows, including the strip locations sheet FLG Location Charges.

## Words Karen uses

**Strip** means leave the record out of ADT and DFT, and show it on the strip report. You do that by marking the record in the stripping route (`stripped="true"`, and for locations `stripped_flagged_locations` or `stripped_flagged_accounts`). You do not delete a location-map line.

**Split** means send the account to a facility output. Halifax is a partition. HAX is one facility inside that partition. Mapping `HMC 201` → HAX is how that row splits to HAX. It is not a strip.

**Partition** is the feed (HAL, ARA, NTX, …). **Facility** is a site inside a partition (HAX, HED, …). **SOFTWARE_ID** is the client/interface id on the lookup tables (Halifax is 750).

When an email has a table of LocationAbbreviation, SOFTWARE_ID, PARTITION, and FACILITY, that is a strip-locations request: those input location codes should be marked stripped for that software id. The FACILITY column is where those rows split today. It is not an instruction to edit the location map.

## How stripping works

Route `2 - Stripping and Tweaking` loads lookup tables, then runs `strip_data.xslt`.

Flagged / FLG locations come from table `FLG_LOCATIONS` (loaded as flagged accounts). A match on location code + SOFTWARE_ID marks the charge and demographics stripped. Those rows land on **FLG Location Charges**.

Other strip tables exist (`STRIP_LOCATIONS`, date-range strips, F.LAB / F.RLAB, bad group numbers). Same idea: mark in this route, omit from HL7, list on a kickout sheet.

The usual production way to add strip locations is to add rows to `FLG_LOCATIONS` (route `88d - Add FLG Locations` / the New FLG Locations Excel). `strip_data.xslt` already looks those up. You only hard-code a location list in `strip_data.xslt` when a lookup cannot see the input code.

## Halifax location map vs strip

The Halifax incoming transform maps Location_ABBR to a facility (`admLocation`). Unknown codes and many listed codes become HAX. That default is correct for splitting. Deleting the `HMC 201` / `HH IPM` / `TL GI` / `OR TL` map lines does nothing useful: those codes already become HAX, and the leftover default also becomes HAX. The claims still flow.

If those input codes must be stripped, keep the facility map as it is, mark the records in `strip_data.xslt`, and list them on FLG Location Charges. Because the map overwrites Location_ABBR with HAX before the strip route, keep the original Location_ABBR on the record (for example `admLocationAbbr`) so the strip can still see `HMC 201` instead of only `HAX`. Do not strip every HAX row.

## What not to do

- Do not treat “strip these Location_ABBR codes” as “delete the xsl:when mappings.”
- Do not change the HAX default to accomplish a strip.
- Do not confuse partition HAL with facility HAX.
- Do not skip the strip report. If it was stripped, it belongs on FLG Location Charges.

## Where to edit

| Ask | Where |
| --- | --- |
| Strip location codes; show on strip report | `strip_data.xslt` and/or `FLG_LOCATIONS`; kickout Excel already has FLG Location Charges |
| Keep Halifax split as-is | Leave `transform-halifax-flatfilexml-to-canconicalxml.xslt` facility map alone |
| New facility / split | CLIENT_SPLITS, CLIENT_CODES, route 88b / 88a — not the strip route |
| Tweak a value but still send HL7 | `tweak_data.xslt`, not strip |
| Ariana insurance / IN1 | ADT A04 transform — not the Halifax location map |
