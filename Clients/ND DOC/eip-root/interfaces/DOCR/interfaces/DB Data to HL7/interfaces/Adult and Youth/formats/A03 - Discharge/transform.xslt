<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:access="xalan://com.pilotfish.utils.AttributeAndPropertyAccessor" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" exclude-result-prefixes="dtFormatter access" expand-text="true" version="3.1">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:param name="pf_accessObj" select="access:new($eiPlatformTransactionData)" />
  <xsl:param name="Environment" select="'TEST'" />
  <xsl:param name="UniqueControlID" select="23" />
  <xsl:param name="unit" />
  <xsl:param name="bed" />
  <xsl:param name="room" />
  <xsl:param name="MSHGUID" />
  <xsl:param name="DatabaseType" />
  <xsl:template match="//EVENT">
    <XCSData>
      <ADT_A03>
        <MSH>
          <MSH.1>|</MSH.1>
          <MSH.2>^~\&amp;</MSH.2>
          <MSH.3 />
          <MSH.4>
            <xsl:value-of select="FROMAGYLOCID" />
          </MSH.4>
          <MSH.5>CSM</MSH.5>
          <MSH.6>
            <xsl:value-of select="TOAGYLOCID" />
          </MSH.6>
          <MSH.7>
            <!--<xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />-->
            <xsl:value-of select="substring-before(replace(datetime:dateTime(),'T',' '),'.')" />
          </MSH.7>
          <MSH.8 />
          <MSH.9>
            <MSG.1>ADT</MSG.1>
            <MSG.2>A03</MSG.2>
          </MSH.9>
          <MSH.10>
            <xsl:value-of select="$MSHGUID" />
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
            <xsl:with-param name="value" select="concat(ROOTOFFENDERID,MOVEMENTSEQ)" />
          </xsl:call-template>
        </MSH>
        <EVN>
          <EVN.1>A03</EVN.1>
          <EVN.2>
            <TS.1>
              <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
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
            <XPN.3>
              <xsl:value-of select="MIDDLENAME" />
            </XPN.3>
          </PID.5>
          <PID.6 />
          <PID.7>
            <xsl:if test="string-length(BIRTHDATE) &gt; 0">
              <xsl:value-of select="dtFormatter:format(BIRTHDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMdd')" />
            </xsl:if>
          </PID.7>
          <!--REQUIRED-->
          <PID.8>
            <xsl:value-of select="SEXCODE" />
          </PID.8>
          <PID.10>
            <!--<xsl:value-of select="RACECODE" />-->
          </PID.10>
          <!--BOOKING ID - REQUIRED-->
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
          <!--REQUIRED - NEW LOCATION INFORMATION-->
          <!--<xsl:variable name="LEVEL1CODE" select="substring-before(LIVUNITBEDLOC,'-')" />-->
          <!--<xsl:variable name="LEVEL2CODE" select="substring-before(substring-after(substring-after(LIVUNITBEDLOC,$LEVEL1CODE),'-'),'-')" />-->
          <!--<xsl:variable name="LEVEL3CODE" select="replace(substring-after(substring-after(LIVUNITBEDLOC,$LEVEL2CODE),'-'),'-','')" />-->
          <PV1.3>
            <!--<PL.1>-->
            <!--<xsl:value-of select="substring($LEVEL1CODE,1,10)" />-->
            <!--</PL.1>-->
            <!--<PL.2>-->
            <!--<xsl:value-of select="$LEVEL2CODE" />-->
            <!--</PL.2>-->
            <!--<PL.3>-->
            <!--<xsl:value-of select="$LEVEL3CODE" />-->
            <!--</PL.3>-->
          </PV1.3>
          <PV1.4 />
          <PV1.5 />
          <!--NOT REQUIRED - PRIOR LOCATION INFORMATION-->
          <!--<xsl:variable name="LEVEL1CODE" select="substring-before(FROMLOCATION,'-')" />-->
          <!--<xsl:variable name="LEVEL2CODE" select="substring-before(substring-after(substring-after(FROMLOCATION,$LEVEL1CODE),'-'),'-')" />-->
          <!--<xsl:variable name="LEVEL3CODE" select="substring-before(substring-after(substring-after(FROMLOCATION,$LEVEL2CODE),'-'),'-')" />-->
          <PV1.6>
            <!--<PL.1>-->
            <!--<xsl:value-of select="$LEVEL1CODE" />-->
            <!--</PL.1>-->
            <!--<PL.2>-->
            <!--<xsl:value-of select="$LEVEL2CODE" />-->
            <!--</PL.2>-->
            <!--<PL.3>-->
            <!--<xsl:value-of select="$LEVEL3CODE" />-->
            <!--</PL.3>-->
          </PV1.6>
          <PV1.7 />
          <PV1.8 />
          <PV1.9 />
          <!--REQUIRED-->
          <PV1.10>
            <xsl:value-of select="TOAGYLOCID" />
          </PV1.10>
          <!--TODO: REQUIRED - ADMIT DATE - REQUIRED FOR DISCHARGES? - NEED TO ADD TO QUERY-->
          <PV1.44>
            <!--<xsl:value-of select="dtFormatter:format(MOVEMENTTIME,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />-->
          </PV1.44>
          <!--REQUIRED - DISCHARGE DATE-->
          <PV1.45>
            <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
          </PV1.45>
        </PV1>
        <PV2>
          <PV2.1>1</PV2.1>
          <PV2.2 />
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

