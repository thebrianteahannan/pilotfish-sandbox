<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="/">
    <ns1:SQLXML>
      <!--1. ADMITS-->
      <!--<ns1:Execute as="recent_admit" into="recent_admits">-->
      <!--<ns1:SQL>SELECT -->
      <!--EVENTTYPE = 'admit', -->
      <!--"A01_LOAD" as 'HL7Type', -->
      <!--"OFFENDERS"."ALIAS_NAME_TYPE", -->
      <!--"OFFENDERS"."ROOT_OFFENDER_ID" AS "ROOT_OFFENDER_ID", -->
      <!--"OFFENDERS"."LAST_NAME", -->
      <!--"OFFENDERS"."FIRST_NAME", -->
      <!--"OFFENDERS"."MIDDLE_NAME", -->
      <!--"OFFENDERS"."BIRTH_DATE", -->
      <!--"OFFENDERS"."SEX_CODE", -->
      <!--"OFFENDERS"."RACE_CODE",-->
      <!--"OFFENDER_BOOKINGS"."OFFENDER_BOOK_ID",-->
      <!--"LIVING_UNITS"."Description" As "LivUnitBedLoc" || 'T'-->
      <!--FROM -->
      <!--"OMS_OWNER"."OFFENDERS" "OFFENDERS" -->
      <!--LEFT OUTER JOIN-->
      <!--"OMS_OWNER"."OFFENDER_BOOKINGS" "OFFENDER_BOOKINGS" ON-->
      <!--"OFFENDERS"."ROOT_OFFENDER_ID"="OFFENDER_BOOKINGS"."ROOT_OFFENDER_ID"-->
      <!--LEFT OUTER JOIN -->
      <!--"OMS_OWNER"."LIVING_UNITS" "LIVING_UNITS" ON-->
      <!--"OFFENDER_BOOKINGS"."LIVING_UNIT_ID"="LIVING_UNITS"."LIVING_UNIT_ID"-->
      <!--WHERE -->
      <!--"OFFENDERS"."ALIAS_NAME_TYPE"='G'-->
      <!--AND "OFFENDER_BOOKINGS"."BOOKING_END_DATE" IS NULL-->
      <!--AND ROWNUM &lt;= 5</ns1:SQL>-->
      <!--</ns1:Execute>-->
      <!--<ns1:XMLOut output="xml" var="recent_events" />-->
      <!--2. TRANSFERS - bed movement-->
      <ns1:Execute as="recent_transfer_bed_movement" into="recent_transfers_bed_movement">
        <ns1:SQL>SELECT "transfer_bed" as EVENT_TYPE, "offenders"."alias_name_type",
			       "offenders"."root_offender_id",
			       "offenders"."last_name",
			       "offenders"."first_name",
			       "offenders"."sex_code",
			       "offender_bookings"."offender_book_id",
			       "living_units"."description",
			       "living_units"."level_1_code",
			       "living_units"."level_2_code",
			       "living_units"."level_3_code",
			       "v_bed_history"."assignment_time",
			       "v_bed_history"."assignment_date",
			       "v_bed_history"."from_location",
			       "v_bed_history"."to_location",
			       "living_units"."agy_loc_id"
			FROM   (("OMS_OWNER"."offenders" "OFFENDERS"
			         LEFT OUTER JOIN "OMS_OWNER"."offender_bookings" "OFFENDER_BOOKINGS"
			                      ON "offenders"."root_offender_id" =
			                         "offender_bookings"."root_offender_id")
			        LEFT OUTER JOIN "OMS_OWNER"."v_bed_history" "V_BED_HISTORY"
			                     ON "offender_bookings"."offender_book_id" =
			                        "v_bed_history"."offender_book_id")
			       LEFT OUTER JOIN "OMS_OWNER"."living_units" "LIVING_UNITS"
			                    ON "v_bed_history"."living_unit_id" =
			                       "living_units"."living_unit_id"
			WHERE  "v_bed_history"."from_location" &lt;&gt; 'OUT'
			       AND "offenders"."alias_name_type" = 'G'
			       AND ( "v_bed_history"."assignment_time" &gt;= sysdate - 1 )</ns1:SQL>
      </ns1:Execute>
      <ns1:XMLOut appendTo="recent_events" output="xml" />
      <!--2. TRANSFERS - program movement-->
      <!--<ns1:Execute as="recent_transfer_program_movement" into="recent_transfers_program_movement">-->
      <!--<ns1:SQL></ns1:SQL>-->
      <!--</ns1:Execute>-->
      <!--2. TRANSFERS - move to minimum-->
      <!--<ns1:Execute as="recent_transfer_move_to_minimum" into="recent_transfers_move_to_minimum">-->
      <!--<ns1:SQL></ns1:SQL>-->
      <!--</ns1:Execute>-->
      <!--3. DISCHARGES-->
      <!--<ns1:Execute as="recent_discharges" into="recent_discharges">-->
      <!--<ns1:SQL>SELECT "discharge" as EVENT_TYPE, "OFFENDERS"."ALIAS_NAME_TYPE",-->
      <!--                "OFFENDERS"."ROOT_OFFENDER_ID",-->
      <!--                "OFFENDERS"."LAST_NAME",-->
      <!--                "OFFENDERS"."FIRST_NAME",-->
      <!--                "OFFENDERS"."BIRTH_DATE",-->
      <!--                "OFFENDERS"."SEX_CODE",-->
      <!--                "OFFENDERS"."RACE_CODE",-->
      <!--                "OFFENDER_BOOKINGS"."OFFENDER_BOOK_ID",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_DATE",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_TIME",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_TYPE",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_SEQ",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."FROM_AGY_LOC_ID",-->
      <!--                "OFFENDER_EXTERNAL_MOVEMENTS"."TO_AGY_LOC_ID",-->
      <!--                "LIVING_UNITS"."LEVEL_1_CODE",-->
      <!--                "LIVING_UNITS"."LEVEL_2_CODE",-->
      <!--                "LIVING_UNITS"."LEVEL_3_CODE",-->
      <!--                ("LIVING_UNITS"."AGY_LOC_ID"-->
      <!--                                ||"LIVING_UNITS"."LEVEL_1_CODE"-->
      <!--                                ||"LIVING_UNITS"."LEVEL_2_CODE"-->
      <!--                                ||"LIVING_UNITS"."LEVEL_3_CODE") AS "LVL3"-->
      <!--FROM            ("OMS_OWNER"."OFFENDERS" "OFFENDERS"-->
      <!--LEFT OUTER JOIN "OMS_OWNER"."OFFENDER_BOOKINGS" "OFFENDER_BOOKINGS"-->
      <!--ON              "OFFENDERS"."ROOT_OFFENDER_ID"="OFFENDER_BOOKINGS"."ROOT_OFFENDER_ID")-->
      <!--LEFT OUTER JOIN "OMS_OWNER"."OFFENDER_EXTERNAL_MOVEMENTS" "OFFENDER_EXTERNAL_MOVEMENTS"-->
      <!--ON              "OFFENDER_BOOKINGS"."OFFENDER_BOOK_ID"="OFFENDER_EXTERNAL_MOVEMENTS"."OFFENDER_BOOK_ID"-->
      <!--LEFT OUTER JOIN "OMS_OWNER"."LIVING_UNITS" "LIVING_UNITS"-->
      <!--ON              "OFFENDER_BOOKINGS"."LIVING_UNIT_ID"="LIVING_UNITS"."LIVING_UNIT_ID"-->
      <!--WHERE           "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_TYPE"='REL'-->
      <!--AND             "OFFENDERS"."ALIAS_NAME_TYPE"='G'-->
      <!--AND             "OFFENDER_EXTERNAL_MOVEMENTS"."TO_AGY_LOC_ID"='OUT'-->
      <!--AND             not ("OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='ADM ERROR'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='EESC'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='ERR'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='ESC'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='ESCAPE'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='ESCP'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='INT'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='READMN'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='REC'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='RECA'-->
      <!--OR              "OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_REASON_CODE"='REL ERROR') and ("OFFENDER_EXTERNAL_MOVEMENTS"."MOVEMENT_DATE"&gt;=sysdate-3)</ns1:SQL>-->
      <!--&gt;-->
      <!--</ns1:Execute>-->
      <!--<ns1:XMLOut appendTo="recent_events" output="xml" />-->
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

