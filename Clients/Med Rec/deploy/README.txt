CAT / GAN Expanded Expanse deploy package
========================================

Contents
--------
- eip-root/.../routes/1 - Incoming Flat Files by Partition and Client/route.xml
- eip-root/.../routes/2 - Stripping and Tweaking/route.xml
- eip-root/.../formats/Generate ADT A04 HL7/transform.xslt
- deploy/sql/01_insert_CAT_GAN.sql
- database/medreceivables-h2-1.4.mv.db   << use this on Windows / older H2 (write format 1)
- database/medreceivables.mv.db         << Docker / EIP WAR H2 2.1 only (write format 2)
- CAT_GAN_Changed_Files.pdf
- deploy/README.txt

Database (important)
--------------------
Older H2 (1.4.x / typical Windows TEST) cannot open write-format-2 files and reports
"File corrupted". That is a format mismatch, not physical corruption.

Recommended deploy on Windows/TEST:
  1. Apply deploy/sql/01_insert_CAT_GAN.sql to your existing medreceivables DB
     OR replace with database/medreceivables-h2-1.4.mv.db
  2. Do NOT use database/medreceivables.mv.db unless the host runs H2 2.1+

SOFTWAREIDs
-----------
- NHL CAT (Catholic Medical): 524
- IRL GAN (Gainesville):      523

Steps
-----
1. Update DB (SQL or h2-1.4 seed above)
2. Copy eip-root files over existing eip-root (preserve paths)
3. Restart eiPlatform / Tomcat
4. Drop PTH5.CMC.* and PTH5.GA.*.txt into FLAT_FILE_INPUT_DIRECTORY

Verified locally (Docker H2 2.1):
- CAT ADT 146 PID / CAT DFT 612 FT1
- GAN ADT 39 PID / GAN DFT 164 FT1
