<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns2 datetime dtFormatter ta td" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attr" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/ns2:TXLife">
    <soap:Envelope>
      <soap:Body>
        <SubmitOrderDataResponse xmlns="http://crlcorp.com/DocumentService">
          <SubmitOrderDataResult>
            <Results>
              <Message>
                <xsl:value-of select="ta:getAttribute($attr, 'error.exceptionMessage')" />
              </Message>
            </Results>
          </SubmitOrderDataResult>
        </SubmitOrderDataResponse>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns2:Attachment" />
  <xsl:template match="ns2:OLifE">
    <OLifE>
      <xsl:apply-templates />
      <Party id="Party_Fulfiller_1">
        <FullName>
          <xsl:text>CRL Plus</xsl:text>
        </FullName>
        <PartyTypeCode tc="2">
          <xsl:text>Company</xsl:text>
        </PartyTypeCode>
        <Organization>
          <DBA>
            <xsl:text>CRL Plus</xsl:text>
          </DBA>
        </Organization>
      </Party>
      <xsl:if test="ns2:Relation[ns2:RelationRoleCode/@tc=32]/@RelatedObjectID and not(ns2:Relation[ns2:RelationRoleCode/@tc=99])">
        <Relation OriginatingObjectID="{ns2:Relation[ns2:RelationRoleCode/@tc=32]/@RelatedObjectID}" RelatedObjectID="Party_Fulfiller_1" id="Relation_Fulfiller_1">
          <RelationRoleCode tc="99">
            <xsl:text>Fulfills</xsl:text>
          </RelationRoleCode>
        </Relation>
      </xsl:if>
    </OLifE>
  </xsl:template>
</xsl:stylesheet>

