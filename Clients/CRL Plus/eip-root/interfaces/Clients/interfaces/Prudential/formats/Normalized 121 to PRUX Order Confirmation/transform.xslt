<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns2 datetime dtFormatter ta td" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.35.00.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attr" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="insertErrorMessage" select="ta:getAttribute($attr, 'insert.order.error')" />
  <xsl:template match="/ns2:TXLife">
    <!--<soap:Envelope>-->
    <!--<soap:Body> -->
    <TXLife xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.35.00.xsd">
      <UserAuthResponse>
        <TransResult>
          <xsl:choose>
            <xsl:when test="string-length($insertErrorMessage) = 0">
              <ResultCode tc="1">
                <xsl:text>Success</xsl:text>
              </ResultCode>
            </xsl:when>
            <xsl:otherwise>
              <ResultCode tc="5">
                <xsl:text>Failure</xsl:text>
              </ResultCode>
            </xsl:otherwise>
          </xsl:choose>
        </TransResult>
        <SvrDate>
          <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
        </SvrDate>
        <SvrTime>
          <xsl:value-of select="datetime:time()" />
        </SvrTime>
      </UserAuthResponse>
      <TXLifeResponse>
        <xsl:comment>TransRefGUID value from Acord 121 transaction</xsl:comment>
        <TransRefGUID>
          <xsl:value-of select="ns2:TXLifeRequest/ns2:TransRefGUID" />
        </TransRefGUID>
        <TransType tc="{ns2:TXLifeRequest/ns2:TransType/@tc}">
          <xsl:value-of select="ns2:TXLifeRequest/ns2:TransType" />
        </TransType>
        <TransExeDate>
          <xsl:value-of select="ns2:TXLifeRequest/ns2:TransExeDate" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="ns2:TXLifeRequest/ns2:TransExeTime" />
        </TransExeTime>
        <TransResult>
          <xsl:choose>
            <xsl:when test="string-length($insertErrorMessage) = 0">
              <ResultCode tc="1">
                <xsl:text>Success</xsl:text>
              </ResultCode>
              <ConfirmationID />
            </xsl:when>
            <xsl:otherwise>
              <ResultCode tc="5">
                <xsl:text>Failure</xsl:text>
              </ResultCode>
              <ResultInfo>
                <ResultInfoDesc>
                  <xsl:value-of select="$insertErrorMessage" />
                </ResultInfoDesc>
              </ResultInfo>
            </xsl:otherwise>
          </xsl:choose>
        </TransResult>
        <xsl:apply-templates select="ns2:TXLifeRequest/ns2:OLifE" />
      </TXLifeResponse>
    </TXLife>
    <!--</soap:Body>-->
    <!--</soap:Envelope>-->
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

