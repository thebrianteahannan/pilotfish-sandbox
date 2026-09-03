<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="/">
    <ns1:SQLXML>
      <!--0. ADMITS - Load-->
      <ns1:Execute as="event" into="recent_events">
        <ns1:SQL>SELECT 
'ADMIT' AS "EVENT_TYPE",
'A01' AS "HL7_TYPE",
O.LAST_NAME, O.FIRST_NAME, 
case when O.MIDDLE_NAME like '%(%' then '' 
else O.MIDDLE_NAME end as MIDDLE_NAME,
'8' || O.ROOT_OFFENDER_ID  AS "ROOT_OFFENDER_ID",
O.BIRTH_DATE, 
O.SEX_CODE, O.RACE_CODE, 
OB.OFFENDER_BOOK_ID, 
 OB.BOOKING_BEGIN_DATE,
OB.BOOKING_BEGIN_DATE AS "ELITECOMMITDTTM",
LV.Description,
LV.Description  AS "LIVUNITBEDLOC",
LV.AGY_LOC_ID AS "TOAGYLOCID", 
OB.ACTIVE_FLAG,
O.ALIAS_NAME_TYPE
FROM   OMS_OWNER.OFFENDERS O 
LEFT OUTER JOIN OMS_OWNER.OFFENDER_BOOKINGS OB
    ON O.ROOT_OFFENDER_ID=OB.ROOT_OFFENDER_ID 
    LEFT OUTER JOIN  OMS_OWNER.LIVING_UNITS LV
    ON OB.LIVING_UNIT_ID=LV.LIVING_UNIT_ID
WHERE  
OB.BOOKING_END_DATE IS  NULL  
AND O.ALIAS_NAME_TYPE='G'
AND OB.ACTIVE_FLAG='Y'
AND
(LV.AGY_LOC_ID= 'DWCRC' OR
LV.AGY_LOC_ID= 'JRCC' OR
LV.AGY_LOC_ID=  'DWCRC' OR
LV.AGY_LOC_ID= 'MRCC' OR
LV.AGY_LOC_ID= 'NDSP')</ns1:SQL>
      </ns1:Execute>
      <ns1:XMLOut var="recent_events" />
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--1. ADMITS-->
      <!--2. TRANSFERS - transfer out-->
      <!--<ns1:Execute as="event" into="recent_events">-->
      <!--<ns1:SQL>SELECT O.alias_name_type,-->
      <!--'TRANSFEROUT' as "event_type",-->
      <!--       O.root_offender_id,-->
      <!--       O.last_name,-->
      <!--       O.first_name,-->
      <!--       O.middle_name,-->
      <!--       O.birth_date,-->
      <!--       O.sex_code,-->
      <!--       O.race_code,-->
      <!--       ob.offender_book_id,-->
      <!--       oem.movement_time AS "ELITECOMMITDTTM",-->
      <!--       oem.from_agy_loc_id,-->
      <!--       oem.to_agy_loc_id-->
      <!--FROM   -->
      <!--       OMS_OWNER.OFFENDERS O-->
      <!--       LEFT OUTER JOIN OMS_OWNER.OFFENDER_BOOKINGS OB ON O.ROOT_OFFENDER_ID=OB.ROOT_OFFENDER_ID-->
      <!--       LEFT OUTER JOIN OMS_OWNER.V_BED_HISTORY VBH ON OB.OFFENDER_BOOK_ID=VBH.OFFENDER_BOOK_ID-->
      <!--WHERE  O.alias_name_type = 'G'-->
      <!--       AND ( oem.from_agy_loc_id = 'DWCRC'-->
      <!--              OR oem.from_agy_loc_id = 'HRCC'-->
      <!--              OR oem.from_agy_loc_id = 'JRCC'-->
      <!--              OR oem.from_agy_loc_id = 'MRCC'-->
      <!--              OR oem.from_agy_loc_id = 'NDSP' )-->
      <!--       AND ( oem.from_agy_loc_id &lt;&gt; 'DWCRC-DICKINSON' )-->
      <!--       AND ( oem.to_agy_loc_id &lt;&gt; 'DWCRC'-->
      <!--             AND oem.to_agy_loc_id &lt;&gt; 'HRCC'-->
      <!--             AND oem.to_agy_loc_id &lt;&gt; 'JRCC'-->
      <!--             AND oem.to_agy_loc_id &lt;&gt; 'MRCC'-->
      <!--             AND oem.to_agy_loc_id &lt;&gt; 'NDSP'-->
      <!--             AND oem.to_agy_loc_id &lt;&gt; 'YCC' )-->
      <!--       AND ( oem.to_agy_loc_id &lt;&gt; 'DWCRC-DICKINSON' )-->
      <!--       AND ( oem.movement_time &gt;= sysdate - 30 )-->
      <!--       AND oem.from_agy_loc_id &lt;&gt; 'OUT'-->
      <!--       AND oem.to_agy_loc_id &lt;&gt; 'OUT'</ns1:SQL>-->
      <!--</ns1:Execute>-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--2. TRANSFERS - bed movement-->
      <!--<ns1:Execute as="event" into="recent_events">-->
      <!--<ns1:SQL>SELECT -->
      <!--       'TRANSFERIN' as "EventType",-->
      <!--       O.alias_name_type,-->
      <!--       O.root_offender_id,-->
      <!--       O.last_name,-->
      <!--       O.first_name,-->
      <!--       O.middle_name,-->
      <!--       O.birth_date,-->
      <!--       O.sex_code,-->
      <!--       O.race_code,-->
      <!--       OB.offender_book_id,-->
      <!--       OEM.movement_time AS "ELITECOMMITDTTM",-->
      <!--       OEM.movement_type,-->
      <!--       OEM.from_agy_loc_id,-->
      <!--       OEM.to_agy_loc_id-->
      <!--FROM   oms_owner.offenders O-->
      <!--       LEFT OUTER JOIN oms_owner.offender_bookings OB-->
      <!--                    ON O.root_offender_id = OB.root_offender_id-->
      <!--       LEFT OUTER JOIN oms_owner.offender_external_movements OEM-->
      <!--                    ON OB.offender_book_id = OEM.offender_book_id-->
      <!--WHERE  O.alias_name_type = 'G'-->
      <!--       AND ( OEM.from_agy_loc_id &lt;&gt; 'DWCRC'-->
      <!--              OR OEM.from_agy_loc_id &lt;&gt; 'HRCC'-->
      <!--              OR OEM.from_agy_loc_id &lt;&gt; 'JRCC'-->
      <!--              OR OEM.from_agy_loc_id &lt;&gt; 'MRCC'-->
      <!--              OR OEM.from_agy_loc_id &lt;&gt; 'NDSP'-->
      <!--              OR OEM.from_agy_loc_id &lt;&gt; 'YCC'-->
      <!--              OR OEM.from_agy_loc_id &lt;&gt; 'NTAD' )-->
      <!--       AND ( OEM.from_agy_loc_id &lt;&gt; 'DWCRC-DICKINSON' )-->
      <!--       AND ( OEM.from_agy_loc_id &lt;&gt; 'DWCRC'-->
      <!--             AND OEM.from_agy_loc_id &lt;&gt; 'HRCC'-->
      <!--             AND OEM.from_agy_loc_id &lt;&gt; 'JRCC'-->
      <!--             AND OEM.from_agy_loc_id &lt;&gt; 'MRCC'-->
      <!--             AND OEM.from_agy_loc_id &lt;&gt; 'NDSP'-->
      <!--             AND OEM.from_agy_loc_id &lt;&gt; 'YCC'-->
      <!--             AND OEM.from_agy_loc_id &lt;&gt; 'NTAD' )-->
      <!--       AND ( OEM.from_agy_loc_id &lt;&gt; 'DWCRC-DICKINSON' )-->
      <!--       AND OEM.from_agy_loc_id &lt;&gt; 'OUT'-->
      <!--       AND OEM.to_agy_loc_id &lt;&gt; 'OUT'-->
      <!--       AND OEM.movement_type = 'TRN'-->
      <!--       AND ( OEM.movement_time &gt;= sysdate - 30 )</ns1:SQL>-->
      <!--</ns1:Execute>-->
      <!--<ns1:XMLOut var="recent_events" />-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--2. TRANSFERS - program movement-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--2. TRANSFERS - move to minimum-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--3. DISCHARGES-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--$-->
      <!--<ns1:XMLOut appendTo="recent_events" output="xml" />-->
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

