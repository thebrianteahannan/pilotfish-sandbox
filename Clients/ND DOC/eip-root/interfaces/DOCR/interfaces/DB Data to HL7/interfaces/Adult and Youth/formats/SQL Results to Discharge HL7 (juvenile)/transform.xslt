<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:access="xalan://com.pilotfish.utils.AttributeAndPropertyAccessor" exclude-result-prefixes="access" expand-text="true" version="3.1">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:param name="pf_accessObj" select="access:new($eiPlatformTransactionData)" />
  <xsl:param name="Environment" select="'TEST'" />
  <xsl:param name="UniqueControlID" select="23" />
  <xsl:template match="SIMPLEQUERY">
    <XCSData>
      <ADT_A03>
        <MSH>
          <MSH.1>|</MSH.1>
          <MSH.2>^~\&amp;</MSH.2>
          <MSH.3 />
          <MSH.4>
            <xsl:value-of select="AGYLOCID" />
          </MSH.4>
          <MSH.5>CSM</MSH.5>
          <MSH.6>
            <xsl:value-of select="AGYLOCID" />
          </MSH.6>
          <MSH.7>
            <xsl:value-of select="dtFormatter:format(BOOKINGBEGINDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
          </MSH.7>
          <MSH.8 />
          <MSH.9>
            <MSG.1>ADT</MSG.1>
            <MSG.2>A03</MSG.2>
          </MSH.9>
          <MSH.10>
            <xsl:value-of select="$UniqueControlID" />
          </MSH.10>
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
          <MSH.12>2.3.1</MSH.12>
          <xsl:call-template name="pf_setAttribute">
            <xsl:with-param name="name" select="'key'" />
            <xsl:with-param name="output" select="'false'" />
            <xsl:with-param name="value" select="concat(ROOTOFFENDERID,OFFENDERBOOKID)" />
          </xsl:call-template>
        </MSH>
        <EVN>
          <EVN.1>A03</EVN.1>
          <EVN.2>
            <TS.1>
              <xsl:value-of select="dtFormatter:format(BOOKINGBEGINDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
            </TS.1>
          </EVN.2>
        </EVN>
        <PID>
          <PID.1 />
          <PID.2 />
          <!--REQUIRED-->
          <PID.3>
            <xsl:value-of select="ROOTOFFENDERID" />
          </PID.3>
          <PID.4 />
          <!--REQUIRED-->
          <PID.5>
            <XPN.1>
              <xsl:value-of select="LASTNAME" />
            </XPN.1>
            <XPN.2>
              <xsl:value-of select="FIRSTNAME" />
            </XPN.2>
          </PID.5>
          <PID.6 />
          <PID.7>
            <xsl:value-of select="BIRTHDATE" />
          </PID.7>
          <!--REQUIRED-->
          <PID.8>
            <xsl:value-of select="SEXCODE" />
          </PID.8>
          <PID.10>
            <xsl:value-of select="RACECODE" />
          </PID.10>
          <!--REQUIRED - BOOKING ID-->
          <PID.18>
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
          <!--REQUIRED - LOCATION INFO-->
          <PV1.3>
            <PL.1>
              <xsl:value-of select="LEVEL1CODE" />
            </PL.1>
            <PL.2>
              <xsl:value-of select="LEVEL2CODE" />
            </PL.2>
            <PL.3>
              <xsl:value-of select="LEVEL3CODE" />
            </PL.3>
          </PV1.3>
          <PV1.4 />
          <PV1.5 />
          <PV1.6 />
          <PV1.7 />
          <PV1.8 />
          <PV1.9 />
          <!--REQUIRED-->
          <PV1.10>
            <xsl:value-of select="AGYLOCID" />
          </PV1.10>
          <!--ADMIT DATE - REQUIRED-->
          <PV1.44>
            <xsl:value-of select="dtFormatter:format(BOOKINGBEGINDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
          </PV1.44>
          <!--REQUIRED-->
          <PV1.45>
            <xsl:value-of select="dtFormatter:format(BOOKINGBEGINDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
          </PV1.45>
        </PV1>
        <PV2>
          <PV2.1>1</PV2.1>
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
          </GT1.3>
        </GT1>
      </ADT_A03>
    </XCSData>
  </xsl:template>
  <xsl:template name="pf_setAttribute">
    <xsl:param name="name" />
    <xsl:param name="output" />
    <xsl:param name="value" />
    <xsl:value-of select="access:setAttribute($pf_accessObj, $name, string($value), $output)" />
  </xsl:template>
</xsl:stylesheet>

