<?xml version="1.0" encoding="UTF-8"?>
<!-- Perform any Prudential specific customization to the 1122 here -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="datetime dtFormatter ns2 xsi xsd" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:template match="/ns2:TXLife">
    <!--
		<TXLife version="2.35">
			<xsl:for-each select="node()">
				<xsl:copy>
					<xsl:apply-templates select="@*|node()" />
				</xsl:copy>
			</xsl:for-each>
		</TXLife>
		-->
    <xsl:apply-templates select="ns2:TXLifeRequest" />
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns2:StatusEventTime">
    <StatusEventTime>
      <!-- TEST if there are Time Zone -->
      <xsl:choose>
        <xsl:when test="contains(.,'-')">
          <!-- TEST for colon in the Time Zone -->
          <xsl:variable name="test" select="substring-after(.,'-')" />
          <xsl:variable name="withTimeZone">
            <xsl:choose>
              <xsl:when test="contains($test,':')">
                <xsl:value-of select="concat(substring-before(.,'-'),'-',translate(substring-after(.,'-'),':',''))" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="." />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:call-template name="formatDateTime">
            <xsl:with-param name="inputValue" select="concat(../ns2:StatusEventDate, ' ', $withTimeZone)" />
            <xsl:with-param name="inputFormat" select="'yyyy-MM-dd HH:mm:ssZ'" />
            <xsl:with-param name="outputFormat" select="'hh:mm:ss a'" />
            <xsl:with-param name="outputTimeZone" select="'CST6CDT'" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="formatDateTime">
            <xsl:with-param name="inputValue" select="concat(../ns2:StatusEventDate, ' ', .)" />
            <xsl:with-param name="inputFormat" select="'yyyy-MM-dd HH:mm:ss'" />
            <xsl:with-param name="outputFormat" select="'hh:mm:ss a'" />
            <xsl:with-param name="outputTimeZone" select="'CST6CDT'" />
          </xsl:call-template>
          <xsl:value-of select="dtFormatter:format(.,'hh:mm:ss','hh:mm:ss a')" />
        </xsl:otherwise>
      </xsl:choose>
    </StatusEventTime>
  </xsl:template>
  <xsl:template match="ns2:RequirementInfo">
    <!-- Only use the original (first) RequirementInfo -->
    <xsl:if test="not(preceding-sibling::ns2:RequirementInfo)">
      <RequirementInfo>
        <xsl:attribute name="AppliesToPartyID">
          <xsl:value-of select="@AppliesToPartyID" />
        </xsl:attribute>
        <xsl:attribute name="RequesterPartyID">
          <xsl:value-of select="@RequesterPartyID" />
        </xsl:attribute>
        <xsl:attribute name="FulfillerPartyID">
          <xsl:value-of select="@FulfillerPartyID" />
        </xsl:attribute>
        <!-- apply templates for children of this first RequirementInfo and the StatusEvents of all RequirementInfo elements -->
        <xsl:apply-templates select="node() | ../ns2:RequirementInfo[preceding-sibling::ns2:RequirementInfo]/ns2:StatusEvent" />
      </RequirementInfo>
    </xsl:if>
  </xsl:template>
  <xsl:template match="ns2:ReqStatus">
    <xsl:variable name="lastReqStatus" select="../../ns2:RequirementInfo[last()]/ns2:ReqStatus" />
    <ReqStatus>
      <xsl:choose>
        <xsl:when test="../../ns2:RequirementInfo[last()]/ns2:StatusEvent/ns2:ProviderEventCode[.='S78' or .='333' or .='258']">
          <!-- Tamara at PacLife requested that cancelled statuses be sent with a ReqStatus of Pending -->
          <xsl:attribute name="tc">1</xsl:attribute>
          <xsl:text>Pending</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="$lastReqStatus/node() | $lastReqStatus/@*[.!='']" />
        </xsl:otherwise>
      </xsl:choose>
    </ReqStatus>
  </xsl:template>
  <xsl:template match="ns2:FulfilledDate">
    <FulfilledDate>
      <xsl:call-template name="format-date">
        <xsl:with-param name="date" select="../../ns2:RequirementInfo[last()]/ns2:FulfilledDate" />
      </xsl:call-template>
    </FulfilledDate>
  </xsl:template>
  <xsl:template match="Attachment">
    <xsl:if test="not(../StatusEvent)">
      <StatusEvent>
        <xsl:variable name="apos">'</xsl:variable>
        <StatusEventDate>
          <xsl:value-of select="dtFormatter:format(datetime:dateTime(),concat('yyyy-MM-dd', $apos, 'T', $apos, 'hh:mm:ss'),'yyyy-MM-dd')" />
        </StatusEventDate>
        <StatusEventTime>
          <xsl:value-of select="dtFormatter:format(datetime:dateTime(),concat('yyyy-MM-dd', $apos, 'T', $apos, 'hh:mm:ss'),'hh:mm:ss')" />
        </StatusEventTime>
        <StatusEventDetail>See attached image</StatusEventDetail>
      </StatusEvent>
    </xsl:if>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns2:RequestedDate">
    <RequestedDate>
      <xsl:value-of select="substring(., 1, 10)" />
    </RequestedDate>
  </xsl:template>
  <xsl:template match="ns2:OLifE">
    <ns2:OLifE>
      <xsl:apply-templates />
      <ns2:Party id="Party_Fulfiller_1">
        <ns2:FullName>
          <xsl:text>CRL-Plus</xsl:text>
        </ns2:FullName>
        <ns2:PartyTypeCode tc="2">
          <xsl:text>Company</xsl:text>
        </ns2:PartyTypeCode>
        <ns2:Organization>
          <ns2:DBA>
            <xsl:text>CRL-Plus</xsl:text>
          </ns2:DBA>
        </ns2:Organization>
      </ns2:Party>
      <xsl:if test="ns2:Relation[ns2:RelationRoleCode/@tc=32]/@RelatedObjectID and not(ns2:Relation[ns2:RelationRoleCode/@tc=99])">
        <ns2:Relation OriginatingObjectID="{ns2:Relation[ns2:RelationRoleCode/@tc=32]/@RelatedObjectID}" RelatedObjectID="Party_Fulfiller_1" id="Relation_Fulfiller_1">
          <ns2:RelationRoleCode tc="99">
            <xsl:text>Fulfills</xsl:text>
          </ns2:RelationRoleCode>
        </ns2:Relation>
      </xsl:if>
    </ns2:OLifE>
  </xsl:template>
  <xsl:template match="ns2:StatusDate">
    <xsl:if test="string-length(normalize-space(.)) &gt; 0">
      <StatusDate>
        <xsl:call-template name="format-date">
          <xsl:with-param name="date">
            <xsl:choose>
              <xsl:when test="string-length(../../ns2:RequirementInfo[last()]/ns2:StatusDate) &gt; 0">
                <xsl:value-of select="../../ns2:RequirementInfo[last()]/ns2:StatusDate" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="../../ns2:RequirementInfo[last()]/ns2:StatusEvent[last()]/ns2:StatusEventDate" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </StatusDate>
    </xsl:if>
  </xsl:template>
  <xsl:template name="current-time">
    <xsl:value-of select="datetime:time()" />
  </xsl:template>
  <xsl:template name="format-date">
    <xsl:param name="date" />
    <xsl:choose>
      <xsl:when test="string-length($date) &gt; 8 and contains($date,' ')">
        <xsl:value-of select="substring-before(normalize-space($date),' ')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$date" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="current-date">
    <xsl:value-of select="datetime:format-date(datetime:date-time(),'yyyy-MM-dd')" />
  </xsl:template>
  <!-- Formats a DateTime value given an input format, output format, timezone name, and value -->
  <!-- inputValue		- The value to parse and format ("2017-12-25 HH:mm:ssZ") -->
  <!-- inputFormat	- The input format to parse "inputValue" ("yyyy-MM-dd HH:mm:ssZ") -->
  <!-- outputFormat	- The output format for the result DateTime ("hh:mm:ss a") -->
  <!-- outputTimeZone	- The time zone name to use for the output format ("CST6CDT") -->
  <xsl:template name="formatDateTime">
    <!-- Define parameters -->
    <xsl:param name="inputFormat" />
    <xsl:param name="outputFormat" />
    <xsl:param name="outputTimeZone" />
    <xsl:param name="inputValue" />
    <!-- Define input and output parameters -->
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="inputDateFormat" select="java:new($inputFormat)" />
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="outputDateFormat" select="java:new($outputFormat)" />
    <!-- Create and set timezone -->
    <xsl:variable xmlns:java="xalan://java.util.TimeZone" name="timeZoneInstance" select="java:getTimeZone($outputTimeZone)" />
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="dummy" select="java:setTimeZone($inputDateFormat, $timeZoneInstance)" />
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="dummy" select="java:setTimeZone($outputDateFormat, $timeZoneInstance)" />
    <!-- Parse the input, then format it out -->
    <xsl:variable xmlns:java="xalan://java.text.SimpleDateFormat" name="date" select="java:parse($inputDateFormat, $inputValue)" />
    <xsl:value-of xmlns:java="xalan://java.text.SimpleDateFormat" select="java:format($outputDateFormat, $date)" />
  </xsl:template>
</xsl:stylesheet>

