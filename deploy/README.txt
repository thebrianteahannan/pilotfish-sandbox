CAT / GAN Expanded Expanse deploy package
========================================
1. Apply SQL: deploy/sql/01_insert_CAT_GAN.sql against medreceivables H2 DB
   (or replace database/medreceivables.mv.db if using packaged seed).
2. Copy eip-root files over existing eip-root preserving paths.
3. Restart eiPlatform / Tomcat.
4. Drop PTH5.CMC.* (NHL CAT) and PTH5.GA.* (IRL GAN) into FLAT_FILE_INPUT_DIRECTORY.

Verified locally:
- CAT0715a.ADT (146 PID) / CAT0715d.DFT (137 msgs, 612 FT1)
- GAN0715a.ADT (39 PID) / GAN0715d.DFT (38 msgs, 164 FT1)
