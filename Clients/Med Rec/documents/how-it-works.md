# How Med Rec (MedReceivables) works

Read this first. The diagrams after it are the same routes drawn as boxes — useful when you want to see a step, not required to understand the flow.

## 88363 Log to HL7 DFT

This is the older 88363 log path. It picks up log files, turns them into XML, optionally splits on specimen alpha IDs, then writes DFT and kickout reports. 9 routes.

### 1 - Pickup Files

Pickup Files watches inbound folders and turns the client flat file into XML the rest of the interface can read. It starts with a directory listener. Along the way it Get Log Name From File Name, Get Rest of Info For This Log Name In DB, and Put Info Into Attrs. When it is done it hands the transaction to the next route.

### 2 - Flat File to XML

Flat File to XML is one step in this interface. It starts with Programmable (Trigger) Listener. Along the way it Performing Doctors Logic, Default Empty Performing Doctors to SU, Get SU Accounts Count, Call Route to Generate SU Kickout Report, and Normalize Space - Performing Doctors. When it is done it hands the transaction to the next route.

### 3a - Determine If Splitting Or Not (Specimen Alpha IDs)

Determine If Splitting Or Not (Specimen Alpha IDs) decides whether this batch needs to split on specimen alpha IDs. It starts with 3 - Determine If Splitting Or Not. Along the way it 3 - Determine If Splitting Or Not and Conditional Router. When it is done it hands the transaction to the next route.

### 3b - Split On Specimen Alpha IDs

Split On Specimen Alpha IDs splits the batch when specimen alpha IDs say the work belongs in more than one place. It starts with 2a - Split On Specimen Alpha IDs. Along the way it Save Orig Data, Get Split Codes List From DB, Convert DB Results XML to SplitList XML, Save SplitCodesXML to Trans Attr, Swap Orig Data Back In, and Assign Split Names To Records By Specimen Alpha IDs. When it is done it hands the transaction to the next route.

### 4 - Splitting Records by Facility

Splitting Records by Facility sends each account to the facility that should bill it. It starts with 4 - Split and Strip Records by Facility. Along the way it Save Data into Temp Trans Attr, Query Database for Split Information, DB Results to SplintInfo XML, Get Default Split Code, Store Split Database Results to Attribute, and Put Data Back. When it is done it hands the transaction to the next route.

### 5 - Generate DFT

Generate DFT writes the HL7 that actually goes out — ADT for demographics, DFT for charges. It starts with 3 - Generate DFT. Along the way it Cleanup Empty Lines 1 and Cleanup Empty Lines 2. It finishes by writing to 3 - Generate DFT.

### 6 - Generate Kickout Reports

Generate Kickout Reports writes a kickout or ops report from records that did not go to HL7, or that need a human look. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 88 - Add New Facility Splits

Add New Facility Splits sends each account to the facility that should bill it. It starts with 88 - Add New Client Splits. It finishes by writing the outbound files.

### 99 - Error Handling

Error Handling is the catch-all when something in the run fails. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

## Flat File to HL7 and Kickout Reports

This is the live production path. Client flat files come in by partition, become XML, get stripped or tweaked, split by facility, and leave as ADT, DFT, and kickout Excel. 31 routes.

### 1 - Incoming Flat Files by Partition and Client

Incoming Flat Files by Partition and Client watches inbound folders and turns the client flat file into XML the rest of the interface can read. It watches 160 inbound folders (Pickup ZIP Files, GLF - CMX, GLF - KIX, GLF - CYX, and GLF - HWX among them). Along the way it sets the facility name for each inbound folder, turns those files into XML, Save charges xml for later - charges - NSP, Go pickup demographics csv for this charges file from input directory - NSP, Save charges xml for later - demos - NSP, Concat All Records From both sets of cp and ap files together - NSP, and Remove the temp attrs to store ap and cp files into memory - NSP. When it is done it hands the transaction to the next route.

### 1a - PPA Multi

PPA Multi is a client-specific pickup — same idea as the main inbound route, but for this partition only. It starts with a directory listener. It finishes by writing the outbound files.

### 1b - NGP Multi

NGP Multi is a client-specific pickup — same idea as the main inbound route, but for this partition only. It starts with a directory listener. It finishes by writing the outbound files.

### 1c - Halifax Multi

Halifax Multi is a client-specific pickup — same idea as the main inbound route, but for this partition only. It starts with a directory listener. It finishes by writing the outbound files.

### 1d - PPS Multi

PPS Multi is a client-specific pickup — same idea as the main inbound route, but for this partition only. It starts from Directory / File Listener, Directory / File Listener1, Directory / File Listener1-1, and Directory / File Listener1-1-1. It finishes by writing the outbound files.

### 1e - NSP Multi

NSP Multi is a client-specific pickup — same idea as the main inbound route, but for this partition only. It watches 6 inbound folders (Directory / File Listener, Directory / File Listener1, Directory / File Listener2, Directory / File Listener3, and Directory / File Listener2-1 among them). It finishes by writing the outbound files.

### 2 - Stripping and Tweaking

Stripping and Tweaking marks records that must not go to HL7, and tweaks values that still should. It starts with Strip Records. Along the way it merges demographics when the same person shows up more than once, applies the tweak rules, applies the strip rules, Merge Multiple Patient Demographics Records, Fix Diag Codes Numbering - PPA ONLY, Stamford ONLY - Group People With Different Account Numbers But Same Demographics, and Query Database for Feed Information. It finishes by writing to the next route and 2 - Common Stripping and Tweaking.

### 3 - Splitting Records by Facility

Splitting Records by Facility sends each account to the facility that should bill it. It starts with 2-1 - Split and Strip Records by Facility. Along the way it Save Data into Temp Trans Attr, Save Data into Temp Trans Attr For Reports, Query Database for Split Information, DB Results to SplintInfo XML, Get Default Split Code, and Store Split Database Results to Attribute. When it is done it hands the transaction to the next route.

### 3b - Generate HL7 Files

Generate HL7 Files writes the HL7 that actually goes out — ADT for demographics, DFT for charges. It starts with 2-2 - Generate HL7 Files for Cerner. Along the way it Get Charge and Demographics Counts, Remove Lookup Info Not For This SoftwareID, Remove non 797 dept and remove blank cpt charges, If there is no SplitCode then use the DefaultSplitCode, If there is no FacilityCode then use the Default FacilityCode, and Generate Accounts Without Date of Service Report - PPA NEO ONLY. It writes the outbound files and hands the rest to the next route.

### 3c - Generate HL7 Debug Logging - DFT

Generate HL7 Debug Logging - DFT writes a debug copy of the DFT so you can see what left the interface. It starts with Programmable (Trigger) Listener. Along the way it Get AccountNumber From File and Remove MUE Edits Log XML-Copy-1. It finishes by writing the outbound files.

### 3d - Generate HL7 Debug Logging - ADT

Generate HL7 Debug Logging - ADT writes a debug copy of the ADT so you can see what left the interface. It starts with Programmable (Trigger) Listener. Along the way it 3c - Generate HL7 Debug Logging - DFT, Get AccountNumber From File, and Remove MUE Edits Log XML-Copy-1. It finishes by writing the outbound files.

### 4 - Generate Reports

Generate Reports fans the remaining kickout and ops reports out to their writers. It starts with 3-0 - Generate Reports. Along the way it Conditional Router. When it is done it hands the transaction to the next route.

### 4a1 - Kickout Reports - Stripped and Tweaked

4a1 - Kickout Reports - Stripped and Tweaked writes the stripped-and-tweaked kickout workbook, including FLG Location Charges. It starts with 3 - Generate Kickout Reports. It finishes by writing to Create Stripping And Tweaking Report.

### 4a2 - Kickout Reports - Cumulative

4a2 - Kickout Reports - Cumulative builds the cumulative kickout sheet. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 4a3 - Kickout Reports - Warnings

4a3 - Kickout Reports - Warnings builds the warnings kickout sheet. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 4a4 - Kickout Reports - Ref Phys - Ariana - Ligolab

4a4 - Kickout Reports - Ref Phys - Ariana - Ligolab builds the referring-physician kickout sheet (Ariana / Ligolab). It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 4a5 - Kickout Reports - Accounts With No Date of Service

4a5 - Kickout Reports - Accounts With No Date of Service lists accounts that have no date of service. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 4a6 - Kickout Reports - Accession Log

4a6 - Kickout Reports - Accession Log builds the accession-log kickout sheet. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 4b - MUE Edits Report

MUE Edits Report builds the MUE edits report. It starts with 3-1 - Reports - MUE Edits. It finishes by writing to 3-1 - Generate MUE Reports and Directory / File Transport.

### 4c - Additional Reports

Additional Reports fans the remaining kickout and ops reports out to their writers. It starts with 3-2 - Reports - Additional. It finishes by writing to 3-3 - Reports - Additional, 3-3 - Reports - Additional.Directory / File Transport1, and 3-3 - Reports - Additional.Directory / File Transport3.

### 4d - CDM Appended A Report

CDM Appended A Report builds the CDM appended-A report. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 55 - Get Partition Config From DB

Get Partition Config From DB loads partition and client settings from the database so the rest of the run knows who this file is for. It starts with a directory listener. It finishes by writing the outbound files.

### 88a - Add New Facility

Add New Facility adds a facility or a client split so later routes know where to send the account. It starts from 88 - Add New Facility to Database, Pickup Listener Route XML File, and Add New Facility Listener in Route XML File. Along the way it Get Data from Excel Spreadsheet and Save Backup of Route XML File. It finishes by writing to 88 - Add New Facility to Database.Database (SQL) Transport and 88 - Add New Facility to Database.

### 88b - Add New Split Facility for Client

Add New Split Facility for Client sends each account to the facility that should bill it. It starts with 88b - Add Split to Facility. It finishes by writing the outbound files.

### 88c - Add New Secondary Strip Locations for Client

Add New Secondary Strip Locations for Client adds secondary strip locations for a client. It starts with a directory listener. It finishes by writing the outbound files.

### 88d - Add FLG Locations

Add FLG Locations adds flagged / FLG location rows so the strip route can mark those codes. It starts with 77 - Add FLG_LOCATIONS. It finishes by writing the outbound files.

### 88e - Add MUE Edits

Add MUE Edits builds the MUE edits report. It starts with a directory listener. It finishes by writing the outbound files.

### 88f - Add New ER_INS_PLAN_CODES

Add New ER_INS_PLAN_CODES adds ER insurance plan codes used later in stripping and tweaking. It starts with a directory listener. It finishes by writing the outbound files.

### 99 - Error - Handle Wrong Facility Name

Error - Handle Wrong Facility Name catches a facility name the interface does not know. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 99a - Error - Charge Without Demo

Error - Charge Without Demo catches a charge that arrived without matching demographics. It starts with Programmable (Trigger) Listener. It finishes by writing the outbound files.

### 99b - Error - Handle Any Error

Error - Handle Any Error is the catch-all when something in the run fails. It starts with Programmable (Trigger) Listener. Along the way it Conditional Router. It finishes by writing the outbound files.
