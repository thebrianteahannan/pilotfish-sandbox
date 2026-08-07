<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="datetime dtFormatter ns2" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:template match="/XCSData">
    <soap:Envelope>
      <soap:Body>
        <TXLife version="2.35">
          <xsl:for-each select="node()[local-name(.)='TXLifeRequest']|soap:Envelope/soap:Body/node()[local-name(.)='TXLife']/node()[local-name(.)='TXLifeRequest']">
            <xsl:copy>
              <xsl:apply-templates select="@*|node()" />
            </xsl:copy>
          </xsl:for-each>
        </TXLife>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
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
</xsl:stylesheet>

