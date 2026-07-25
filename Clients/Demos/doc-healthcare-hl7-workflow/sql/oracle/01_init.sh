#!/bin/bash
# Seed DOCOMS schema in XEPDB1 (not CDB$ROOT / SYS).
set -euo pipefail

echo "Seeding Oracle OMS schema as ${APP_USER} @ XEPDB1 ..."

sqlplus -s "${APP_USER}/${APP_USER_PASSWORD}@//localhost/XEPDB1" <<'SQL'
WHENEVER SQLERROR EXIT SQL.SQLCODE

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE operational_events CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE patients CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

CREATE TABLE patients (
    offender_id      VARCHAR2(20)  NOT NULL PRIMARY KEY,
    mrn              VARCHAR2(20)  NOT NULL,
    last_name        VARCHAR2(50)  NOT NULL,
    first_name       VARCHAR2(50)  NOT NULL,
    middle_name      VARCHAR2(50),
    birth_date       DATE          NOT NULL,
    sex              CHAR(1)       NOT NULL,
    street           VARCHAR2(100) NOT NULL,
    city             VARCHAR2(50)  NOT NULL,
    state            CHAR(2)       NOT NULL,
    zip              VARCHAR2(10)  NOT NULL,
    phone            VARCHAR2(20)
);

CREATE TABLE operational_events (
    event_id            NUMBER(10)    NOT NULL PRIMARY KEY,
    source_system       VARCHAR2(40)  NOT NULL,
    event_type          VARCHAR2(30)  NOT NULL,
    child_event_types   VARCHAR2(200),
    offender_id         VARCHAR2(20)  NOT NULL REFERENCES patients(offender_id),
    facility_code       VARCHAR2(20)  NOT NULL,
    unit_code           VARCHAR2(20),
    bed_code            VARCHAR2(20),
    prior_facility_code VARCHAR2(20),
    prior_unit_code     VARCHAR2(20),
    prior_bed_code      VARCHAR2(20),
    attending_npi       VARCHAR2(20),
    attending_name      VARCHAR2(80),
    event_timestamp     TIMESTAMP     NOT NULL,
    status              VARCHAR2(20)  DEFAULT 'PENDING' NOT NULL,
    notes               VARCHAR2(200)
);

INSERT INTO patients VALUES ('OFF-10021','MRN10021','GARCIA','MIGUEL','A',DATE '1984-03-12','M','14 CEDAR LN','SPRINGFIELD','IL','62701','2175550142');
INSERT INTO patients VALUES ('OFF-10044','MRN10044','JOHNSON','DEANDRE','L',DATE '1991-11-02','M','880 RIVER RD','PEORIA','IL','61602','3095550188');
INSERT INTO patients VALUES ('OFF-10057','MRN10057','WILLIAMS','ASHLEY','R',DATE '1988-07-25','F','221 OAK ST APT 4','CHAMPAIGN','IL','61820','2175550199');
INSERT INTO patients VALUES ('OFF-10063','MRN10063','BROWN','TYRONE',NULL,DATE '1979-01-30','M','55 PINE AVE','DECATUR','IL','62521','2175550110');

INSERT INTO operational_events (
  event_id, source_system, event_type, child_event_types, offender_id,
  facility_code, unit_code, bed_code, prior_facility_code, prior_unit_code, prior_bed_code,
  attending_npi, attending_name, event_timestamp, status, notes
) VALUES
  (2001,'ORACLE_OMS','ADMIT',NULL,'OFF-10021','NORTH','A-WING','101',NULL,NULL,NULL,'1234567890','SMITH^JANE^MD',TIMESTAMP '2026-07-24 08:05:00','PENDING','New intake admission from Oracle OMS');

INSERT INTO operational_events (
  event_id, source_system, event_type, child_event_types, offender_id,
  facility_code, unit_code, bed_code, prior_facility_code, prior_unit_code, prior_bed_code,
  attending_npi, attending_name, event_timestamp, status, notes
) VALUES
  (2002,'ORACLE_OMS','MULTI','ADMIT,BED_ASSIGN,DEMO_UPDATE','OFF-10044','NORTH','B-WING','214',NULL,NULL,NULL,'1234567890','SMITH^JANE^MD',TIMESTAMP '2026-07-24 08:17:00','PENDING','Multi-step intake package from Oracle OMS');

INSERT INTO operational_events (
  event_id, source_system, event_type, child_event_types, offender_id,
  facility_code, unit_code, bed_code, prior_facility_code, prior_unit_code, prior_bed_code,
  attending_npi, attending_name, event_timestamp, status, notes
) VALUES
  (2005,'ORACLE_OMS','DEMO_UPDATE',NULL,'OFF-10057','SOUTH','D-WING','012',NULL,NULL,NULL,'1987654321','LEE^DAVID^MD',TIMESTAMP '2026-07-24 11:20:00','PENDING','Address/phone correction from Oracle OMS');

INSERT INTO operational_events (
  event_id, source_system, event_type, child_event_types, offender_id,
  facility_code, unit_code, bed_code, prior_facility_code, prior_unit_code, prior_bed_code,
  attending_npi, attending_name, event_timestamp, status, notes
) VALUES
  (2007,'ORACLE_OMS','DISCHARGE',NULL,'OFF-10021','NORTH','C-WING','308',NULL,NULL,NULL,'1234567890','SMITH^JANE^MD',TIMESTAMP '2026-07-24 16:30:00','PENDING','Release / healthcare discharge from Oracle OMS');

COMMIT;

SELECT event_id, source_system, event_type, status FROM operational_events ORDER BY event_id;
EXIT;
SQL

echo "Oracle OMS seed complete."
