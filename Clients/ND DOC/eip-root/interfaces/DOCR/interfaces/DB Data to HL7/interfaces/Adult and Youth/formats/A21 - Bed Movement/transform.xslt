<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:access="xalan://com.pilotfish.utils.AttributeAndPropertyAccessor" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" exclude-result-prefixes="dtFormatter access" expand-text="true" version="3.1">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:param name="pf_accessObj" select="access:new($eiPlatformTransactionData)" />
  <xsl:param name="Environment" select="'TEST'" />
  <xsl:param name="UniqueControlID" select="23" />
  <xsl:param name="MSHGUID" />
  <xsl:param name="DatabaseType" />
  <xsl:template match="//EVENT">
    <XCSData>
      <ADT_A21>
        <MSH>
          <MSH.1>|</MSH.1>
          <MSH.2>^~\&amp;</MSH.2>
          <MSH.3 />
          <MSH.4 />
          <MSH.5>CSM</MSH.5>
          <MSH.6>
            <xsl:value-of select="AGYLOCID" />
          </MSH.6>
          <MSH.7>
            <xsl:value-of select="substring-before(replace(datetime:dateTime(),'T',' '),'.')" />
          </MSH.7>
          <MSH.8 />
          <MSH.9>
            <MSG.1>ADT</MSG.1>
            <MSG.2>A21</MSG.2>
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
        </MSH>
        <EVN>
          <EVN.1>A21</EVN.1>
          <EVN.2>
            <TS.1>
              <xsl:if test="string-length(ELITECOMMITDTTM) &gt; 0">
                <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
              </xsl:if>
            </TS.1>
          </EVN.2>
          <EVN.6>
            <TS.1>
              <xsl:if test="string-length(ELITECOMMITDTTM) &gt; 0">
                <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
              </xsl:if>
            </TS.1>
          </EVN.6>
        </EVN>
        <PID>
          <PID.1 />
          <PID.2 />
          <!--REQUIRED-->
          <PID.3>
            <!--This a unique number from Elite and we have opted to use this option-->
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
          <!--REQUIRED - BIRTHDATE - MAY NOT BE REQUIRED-->
          <PID.7>
            <xsl:if test="string-length(BIRTHDATE) &gt; 0">
              <xsl:value-of select="dtFormatter:format(BIRTHDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMdd')" />
            </xsl:if>
          </PID.7>
          <!--REQUIRED - GENDER-->
          <PID.8>
            <xsl:value-of select="SEXCODE" />
          </PID.8>
          <!--REQUIRED - BOOKING ID - NEED THIS INFO FROM QUERY-->
          <PID.18>
            <xsl:value-of select="OFFENDERBOOKID" />
          </PID.18>
        </PID>
        <PV1>
          <PV1.1 />
          <!--REQUIRED - IN OR OUT - THIS IS IN SINCE IT'S A BED MOVEMENT WITHIN A FACILITY-->
          <PV1.2>
            <xsl:text>I</xsl:text>
          </PV1.2>
          <PV1.3 />
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
          <!--REQUIRED-->
          <PV1.44>
            <xsl:if test="string-length(ELITECOMMITDTTM) &gt; 0">
              <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
            </xsl:if>
          </PV1.44>
        </PV1>
        <PV2>
          <PV2.1>1</PV2.1>
          <!--accommodation code - MIGHT NOT NEED THIS-->
          <PV2.2>ROOMBOARD</PV2.2>
        </PV2>
        <ZLR>
          <ZLR.1>TFO</ZLR.1>
          <ZLR.2>EB</ZLR.2>
          <ZLR.3 />
          <ZLR.4 />
          <ZLR.5 />
          <ZLR.6 />
          <ZLR.7 />
          <ZLR.8 />
          <ZLR.9 />
          <ZLR.10 />
          <ZLR.11 />
          <ZLR.12 />
        </ZLR>
      </ADT_A21>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

