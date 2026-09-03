<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:access="xalan://com.pilotfish.utils.AttributeAndPropertyAccessor" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" exclude-result-prefixes="access datetime" version="3.1">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:param name="pf_accessObj" select="access:new($eiPlatformTransactionData)" />
  <xsl:param name="Environment" select="'TEST'" />
  <xsl:param name="UniqueControlID" select="23" />
  <xsl:param name="MSHGUID" />
  <xsl:param name="DatabaseType" />
  <xsl:template match="//EVENT">
    <XCSData>
      <ADT_A01>
        <MSH>
          <!--REQUIRED - FIELD SEPARATOR-->
          <MSH.1>|</MSH.1>
          <!--REQUIRED - MESSAGE DELIMITERS-->
          <MSH.2>^~\&amp;</MSH.2>
          <MSH.3 />
          <!--REQUIRED - FROM AGENCY LOCATION ID-->
          <MSH.4>
            <xsl:value-of select="FROMAGYLOCID" />
          </MSH.4>
          <MSH.5>CSM</MSH.5>
          <!--REQUIRED - TO AGENCY LOCATION ID-->
          <MSH.6>
            <xsl:value-of select="TOAGYLOCID" />
          </MSH.6>
          <!--REQUIRED - EVENT TIMESTAMP-->
          <MSH.7>
            <xsl:value-of select="substring-before(replace(datetime:dateTime(),'T',' '),'.')" />
          </MSH.7>
          <MSH.8 />
          <!--REQUIRED - HL7 MESSAGE TYPE-->
          <MSH.9>
            <MSG.1>ADT</MSG.1>
            <MSG.2>A01</MSG.2>
          </MSH.9>
          <!--REQUIRED - UNIQUE GUID CONTROL NUMBER NEEDED FOR EACH MESSAGE SENT-->
          <MSH.10>
            <xsl:value-of select="$MSHGUID" />
          </MSH.10>
          <!--REQUIRED - ENVIRONMENT INDICATOR -DEFAULTS TO TEST-->
          <MSH.11>
            <xsl:choose>
              <xsl:when test="$Environment = 'PROD'">
                <xsl:text>P</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>T</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </MSH.11>
          <!--REQUIRED - HL7 VERSION-->
          <MSH.12>2.3.1</MSH.12>
        </MSH>
        <EVN>
          <!--REQUIRED - EVENT TYPE-->
          <EVN.1>A01</EVN.1>
          <!--REQUIRED - EVENT TIMESTAMP-->
          <EVN.2>
            <TS.1>
              <xsl:if test="string-length(BOOKINGBEGINDATE) &gt; 0">
                <xsl:value-of select="dtFormatter:format(BOOKINGBEGINDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
              </xsl:if>
            </TS.1>
          </EVN.2>
        </EVN>
        <PID>
          <PID.1 />
          <PID.2 />
          <!--REQUIRED - INTERNAL PATIENT ID-->
          <PID.3>
            <xsl:value-of select="ROOTOFFENDERID" />
          </PID.3>
          <PID.4 />
          <!--REQUIRED - FIRST AND LAST NAME-->
          <PID.5>
            <XPN.1>
              <xsl:value-of select="LASTNAME" />
            </XPN.1>
            <XPN.2>
              <xsl:value-of select="FIRSTNAME" />
            </XPN.2>
            <XPN.3>
              <xsl:value-of select="MIDDLENAME" />
            </XPN.3>
          </PID.5>
          <PID.6 />
          <!--REQUIRED - BIRTHDATE-->
          <PID.7>
            <xsl:if test="string-length(BIRTHDATE) &gt; 0">
              <xsl:value-of select="dtFormatter:format(BIRTHDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMdd')" />
            </xsl:if>
          </PID.7>
          <!--REQUIRED - GENDER-->
          <PID.8>
            <xsl:value-of select="SEXCODE" />
          </PID.8>
          <!--REQUIRED - BOOKING ID-->
          <PID.18>
            <!--Avatar is an episode based system with an episode# being the identifier used to track all client activity -->
            <!--from admit through discharge. The expecation is that there is some equivalent value that is assigned by the registration -->
            <!--system. This value is used by Avatar to identify the specific episode of care that should be updated in when a message is -->
            <!--received / processed.-->
            <xsl:value-of select="OFFENDERBOOKID" />
          </PID.18>
        </PID>
        <NK1>
          <NK1.1>1</NK1.1>
        </NK1>
        <PV1>
          <PV1.1 />
          <PV1.2>
            <xsl:text>I</xsl:text>
          </PV1.2>
          <xsl:choose>
            <xsl:when test="$DatabaseType = 'A'">
              <!--ADULT-->
              <!--REQUIRED - NEW LOCATION INFORMATION-->
              <xsl:variable name="LEVEL1CODE" select="substring(substring-before(LIVUNITBEDLOC,'-'),1,10)" />
              <xsl:variable name="LEVEL1LENGTH" select="string-length($LEVEL1CODE)" />
              <xsl:variable name="LEVEL2CODE" select="substring-before(substring-after(substring-after(LIVUNITBEDLOC,$LEVEL1CODE),'-'),'-')" />
              <xsl:variable name="PL1" select="substring(concat($LEVEL1CODE,$LEVEL2CODE),1,10)" />
              <xsl:variable name="PL2" select="substring($PL1,$LEVEL1LENGTH+1,string-length($LEVEL2CODE))" />
              <xsl:variable name="LEVEL3CODE" select="replace(substring-after(substring-after(LIVUNITBEDLOC,$LEVEL2CODE),'-'),'-','')" />
              <PV1.3>
                <PL.1>
                  <xsl:value-of select="$PL1" />
                </PL.1>
                <PL.2>
                  <xsl:value-of select="$PL2" />
                </PL.2>
                <PL.3>
                  <xsl:value-of select="concat($LEVEL1CODE,$PL2,$LEVEL3CODE)" />
                </PL.3>
              </PV1.3>
            </xsl:when>
            <xsl:otherwise>
              <!--YOUTH-->
              <!--REQUIRED - NEW LOCATION INFORMATION-->
              <xsl:variable name="LEVEL1CODE" select="substring-before(LIVUNITBEDLOC,'-')" />
              <xsl:variable name="LEVEL2CODE" select="substring-before(substring-after(substring-after(LIVUNITBEDLOC,$LEVEL1CODE),'-'),'-')" />
              <xsl:variable name="LEVEL3CODE" select="replace(substring-after(substring-after(LIVUNITBEDLOC,$LEVEL2CODE),'-'),'-','')" />
              <PV1.3>
                <PL.1>
                  <xsl:value-of select="concat($LEVEL1CODE,$LEVEL2CODE)" />
                </PL.1>
                <PL.2>
                  <xsl:value-of select="$LEVEL3CODE" />
                </PL.2>
                <PL.3>
                  <xsl:value-of select="concat($LEVEL1CODE,$LEVEL2CODE,$LEVEL3CODE,ROOTOFFENDERID)" />
                </PL.3>
              </PV1.3>
            </xsl:otherwise>
          </xsl:choose>
          <PV1.4 />
          <PV1.5 />
          <PV1.6 />
          <!--attending practicitioner - this doesn't apply because it is prison and your doctor isn't available-->
          <PV1.7 />
          <PV1.8 />
          <PV1.9 />
          <!--REQUIRED-->
          <PV1.10>
            <xsl:value-of select="TOAGYLOCID" />
          </PV1.10>
          <!--admitting practicitioner - this doesn't apply because it is prison and your doctor isn't available-->
          <PV1.17 />
          <!--REQUIRED-->
          <PV1.44>
            <xsl:if test="string-length(ELITECOMMITDTTM) &gt; 0">
              <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
            </xsl:if>
          </PV1.44>
          <!--NOT NEEDED - FOR DISCHARGES ONLY-->
          <PV1.45 />
        </PV1>
        <PV2>
          <PV2.1>1</PV2.1>
          <!--accommodation code-->
          <PV2.2>ROOMBOARD</PV2.2>
        </PV2>
        <GT1>
          <GT1.1>1</GT1.1>
          <GT1.3>
            <XPN.1>
              <xsl:value-of select="LASTNAME" />
            </XPN.1>
            <XPN.2>
              <xsl:value-of select="FIRSTNAME" />
            </XPN.2>
            <XPN.3>
              <xsl:value-of select="MIDDLENAME" />
            </XPN.3>
          </GT1.3>
        </GT1>
      </ADT_A01>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

