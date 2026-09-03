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
      <ADT_A02>
        <MSH>
          <MSH.1>|</MSH.1>
          <MSH.2>^~\&amp;</MSH.2>
          <MSH.3 />
          <MSH.4 />
          <MSH.5>CSM</MSH.5>
          <MSH.6>
            <xsl:value-of select="FROMAGYLOCID" />
          </MSH.6>
          <MSH.7>
            <!--<xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />-->
            <xsl:value-of select="substring-before(replace(datetime:dateTime(),'T',' '),'.')" />
          </MSH.7>
          <MSH.8 />
          <MSH.9>
            <MSG.1>ADT</MSG.1>
            <MSG.2>A02</MSG.2>
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
          <EVN.1>A02</EVN.1>
          <EVN.2>
            <TS.1>
              <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
            </TS.1>
          </EVN.2>
          <EVN.6>
            <TS.1>
              <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
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
          </PID.5>
          <PID.6 />
          <!--REQUIRED - BIRTHDATE-->
          <PID.7>
            <xsl:value-of select="dtFormatter:format(BIRTHDATE,'yyyy-MM-dd hh:mm:ss.S','yyyyMMdd')" />
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
          <!--IN OR OUT - THIS IS OUT HERE BECAUSE WE ARE TRANSFERRING PROGRAMS-->
          <PV1.2>
            <xsl:text>O</xsl:text>
          </PV1.2>
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
          <PV1.4 />
          <PV1.5 />
          <!--REQUIRED - PRIOR LOCATION INFORMATION-->
          <xsl:variable name="LEVEL1CODE" select="substring(substring-before(FROMLIVUNITBEDLOC,'-'),1,10)" />
          <xsl:variable name="LEVEL2CODE" select="substring-before(substring-after(substring-after(FROMLIVUNITBEDLOC,$LEVEL1CODE),'-'),'-')" />
          <xsl:variable name="LEVEL3CODE" select="replace(substring-after(substring-after(FROMLIVUNITBEDLOC,$LEVEL2CODE),'-'),'-','')" />
          <PV1.6>
            <PL.1>
              <xsl:value-of select="concat($LEVEL1CODE,substring($LEVEL2CODE,1,10))" />
            </PL.1>
            <PL.2>
              <xsl:value-of select="$LEVEL2CODE" />
            </PL.2>
            <PL.3>
              <xsl:value-of select="concat($LEVEL1CODE,$LEVEL2CODE,$LEVEL3CODE)" />
            </PL.3>
          </PV1.6>
          <PV1.7 />
          <PV1.8 />
          <PV1.9 />
          <!--REQUIRED-->
          <PV1.10>
            <xsl:value-of select="TOAGYLOCID" />
          </PV1.10>
          <!--REQUIRED-->
          <PV1.44>
            <xsl:value-of select="dtFormatter:format(ELITECOMMITDTTM,'yyyy-MM-dd hh:mm:ss.S','yyyyMMddhhmmss.SSSS')" />
          </PV1.44>
        </PV1>
        <PV2>
          <PV2.1>1</PV2.1>
          <!--accommodation code-->
          <PV2.2>ROOMBOARD</PV2.2>
        </PV2>
      </ADT_A02>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

