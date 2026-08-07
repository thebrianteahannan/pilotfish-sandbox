<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns2 datetime dtFormatter ta td" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="transactionID" select="ta:getAttribute($attributes, 'database.TransactionID')" />
  <xsl:variable name="insertErrorMessage" select="ta:getAttribute($attributes, 'insert.order.error')" />
  <xsl:template match="/ns2:TXLife">
    <xsl:variable name="tdexOrderAttrName" select="concat('teledex.ordernum.for.transrefguid.', ns2:TXLifeRequest/ns2:TransRefGUID)" />
    <xsl:variable name="tdexOrderNum" select="ta:getAttribute($attributes, $tdexOrderAttrName)" />
    <xsl:variable name="skipTeledex" select="ta:getAttribute($attributes, 'skipTeledex')" />
    <soap:Envelope>
      <soap:Body>
        <SubmitOrderDataResponse xmlns="http://crlcorp.com/DocumentService">
          <SubmitOrderDataResult>
            <!--
						<xsl:value-of select="'The order file was sent successfully.'" />
						<xsl:value-of select="'&#xA;'" />
						<xsl:value-of select="'Transaction_ID='" />
						<xsl:value-of select="$transactionID" />
						<xsl:value-of select="'&#xA;'" />
						<xsl:value-of select="'Teledex_Order_Num='" />
						<xsl:value-of select="$tdexOrderNum" />
						-->
            <xsl:choose>
              <xsl:when test="string-length($insertErrorMessage) = 0">
                <Results>
                  <Message>The order file was sent successfully.</Message>
                  <TransactionID>
                    <xsl:value-of select="$transactionID" />
                  </TransactionID>
                  <TeledexOrderNumber>
                    <xsl:if test="string-length($skipTeledex)=0 or $skipTeledex != 'true'">
                      <xsl:value-of select="$tdexOrderNum" />
                    </xsl:if>
                  </TeledexOrderNumber>
                </Results>
              </xsl:when>
              <xsl:otherwise>
                <Results>
                  <Message>
                    <xsl:value-of select="$insertErrorMessage" />
                  </Message>
                </Results>
              </xsl:otherwise>
            </xsl:choose>
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
          <xsl:text>CRL-Plus</xsl:text>
        </FullName>
        <PartyTypeCode tc="2">
          <xsl:text>Company</xsl:text>
        </PartyTypeCode>
        <Organization>
          <DBA>
            <xsl:text>CRL-Plus</xsl:text>
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

