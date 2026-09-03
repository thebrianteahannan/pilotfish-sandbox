<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://pilotfish.sqlxml" xmlns:uuid="java:java.util.UUID" exclude-result-prefixes="datetime dtFormatter" version="3.1">
  <xsl:template match="/">
    <ns1:SQLXML>
      <xsl:for-each select="//XCSExcelRow">
        <ns1:Insert>
          <Elite_Trans>
            <ET_TRANS_ID>
              <xsl:value-of select="uuid:randomUUID()" />
            </ET_TRANS_ID>
            <ROOT_OFFENDER_ID>
              <xsl:value-of select="./Root_Offender_ID" />
            </ROOT_OFFENDER_ID>
            <OFFENDER_BOOK_ID>
              <xsl:value-of select="./Offender_Book_ID" />
            </OFFENDER_BOOK_ID>
            <EVENT_TYPE>
              <xsl:value-of select="'DISCHARGE'" />
            </EVENT_TYPE>
            <HL7_TYPE>
              <xsl:value-of select="'A03'" />
            </HL7_TYPE>
            <MOVEMENT_TYPE />
            <MOVEMENT_REASON_CODE />
            <LAST_NAME>
              <xsl:value-of select="tokenize(./patient_name,'\^')[3]" />
            </LAST_NAME>
            <FIRST_NAME>
              <xsl:value-of select="tokenize(./patient_name,'\^')[1]" />
            </FIRST_NAME>
            <MIDDLE_NAME>
              <xsl:value-of select="tokenize(./patient_name,'\^')[2]" />
            </MIDDLE_NAME>
            <BIRTH_DATE>
              <xsl:value-of select="dtFormatter:format(./date_time_of_birth,'YYYYMMdd','YYYY-MM-dd hh:mm:ss')" />
            </BIRTH_DATE>
            <SEX_CODE>
              <xsl:value-of select="./sex" />
            </SEX_CODE>
            <RACE_CODE>
              <xsl:if test="./race != 'null'">
                <xsl:value-of select="./race" />
              </xsl:if>
            </RACE_CODE>
            <BOOKING_BEGIN_DATE>
              <xsl:value-of select="dtFormatter:format(substring(./Booking_Begin_Date,1,12),'YYYYMMddhhmm','YYYY-MM-dd hh:mm:ss')" />
            </BOOKING_BEGIN_DATE>
            <BOOKING_END_DATE>
              <xsl:if test="./Booking_End_Date != 'null'">
                <xsl:value-of select="dtFormatter:format(substring(./Booking_End_Date,1,12),'YYYYMMddhhmm','YYYY-MM-dd hh:mm:ss')" />
              </xsl:if>
            </BOOKING_END_DATE>
            <ELITECOMMITDTTM>
              <!--SHOULD BE CURRENT DATE TIMESTAMP-->
              <xsl:value-of select="substring-before(replace(datetime:dateTime(),'T',' '),'.')" />
            </ELITECOMMITDTTM>
            <LIVUNITBEDLOC>
              <xsl:value-of select="replace(./assigned_patient_location,'\^','-')" />
            </LIVUNITBEDLOC>
            <TO_AGY_LOC_ID>
              <xsl:if test="./To_AGY_Loc_ID != 'null'">
                <xsl:value-of select="./To_AGY_Loc_ID" />
              </xsl:if>
            </TO_AGY_LOC_ID>
            <FROM_AGY_LOC_ID>
              <xsl:if test="./From_AGY_Loc_ID != 'null'">
                <xsl:value-of select="./From_AGY_Loc_ID" />
              </xsl:if>
            </FROM_AGY_LOC_ID>
            <ACTIVE_FLAG />
            <ALIAS_NAME_TYPE />
            <!--LEAVE BLANK - WILL AUTO-INSERT GETDATE()-->
            <CREATION_DATE />
          </Elite_Trans>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

