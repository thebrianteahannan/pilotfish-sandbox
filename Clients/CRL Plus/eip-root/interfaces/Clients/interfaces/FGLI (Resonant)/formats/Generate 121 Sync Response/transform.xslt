<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns2 datetime dtFormatter ta td" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.35.00.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attr" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="insertErrorMessage" select="ta:getAttribute($attr, 'insert.order.error')" />
  <xsl:template match="/ns2:TXLife">
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
        <!-- TRANSREFGUID MUST NOT BE EMPTY, OTHERWISE WE DON'T SEND THE NODE AT ALL -->
        <xsl:choose>
          <xsl:when test="string-length(ns2:TXLifeRequest/ns2:TransRefGUID) &gt; 0">
            <TransRefGUID>
              <xsl:value-of select="ns2:TXLifeRequest/ns2:TransRefGUID" />
            </TransRefGUID>
          </xsl:when>
          <xsl:otherwise>
            <!-- DON'T SEND EMPTY NODES -->
          </xsl:otherwise>
        </xsl:choose>
        <!-- TRANS TYPE MUST NOT BE EMPTY AND IT MUST HAVE THE TC ATTRIBUTE, OTHERWISE WE DON'T SEND THE NODE AT ALL -->
        <xsl:choose>
          <xsl:when test="string-length(ns2:TXLifeRequest/ns2:TransType) &gt; 0">
            <xsl:choose>
              <xsl:when test="string-length(ns2:TXLifeRequest/ns2:TransType/@tc) &gt; 0">
                <TransType tc="{ns2:TXLifeRequest/ns2:TransType/@tc}">
                  <xsl:value-of select="ns2:TXLifeRequest/ns2:TransType" />
                </TransType>
              </xsl:when>
              <xsl:otherwise>
                <!-- DON'T SEND EMPTY NODES -->
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
        <!-- TRANSEXEDATE MUST NOT BE EMPTY, OTHERWISE WE DON'T SEND THE NODE AT ALL -->
        <TransExeDate>
          <xsl:choose>
            <xsl:when test="string-length(ns2:TXLifeRequest/ns2:TransExeDate) &gt; 0">
              <xsl:value-of select="ns2:TXLifeRequest/ns2:TransExeDate" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
            </xsl:otherwise>
          </xsl:choose>
        </TransExeDate>
        <!-- TRANSEXETIME MUST NOT BE EMPTY, OTHERWISE WE DON'T SEND THE NODE AT ALL -->
        <TransExeTime>
          <xsl:choose>
            <xsl:when test="string-length(ns2:TXLifeRequest/ns2:TransExeTime) &gt; 0">
              <xsl:value-of select="ns2:TXLifeRequest/ns2:TransExeTime" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-before(datetime:time(), '-')" />
            </xsl:otherwise>
          </xsl:choose>
        </TransExeTime>
        <TransResult>
          <xsl:choose>
            <xsl:when test="string-length($insertErrorMessage) = 0">
              <ResultCode tc="1">
                <xsl:text>Success</xsl:text>
              </ResultCode>
              <!-- DON'T INCLUDE EMPTY NODES -->
              <!-- <ConfirmationID /> -->
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
          <xsl:apply-templates select="ns2:TXLifeRequest/ns2:OLifE" />
        </TransResult>
      </TXLifeResponse>
    </TXLife>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns2:Attachment" />
  <xsl:template match="ns2:SourceInfo">
    <!-- Replace the SourceInfo to show message is coming from CRL Plus -->
    <ns2:SourceInfo>
      <ns2:SourceInfoName>CRL-Plus</ns2:SourceInfoName>
      <ns2:SourceInfoDescription>Email : INSURANCECS@CRLCORP.COM</ns2:SourceInfoDescription>
      <ns2:SourceInfoComment>Phone : 8558507587</ns2:SourceInfoComment>
    </ns2:SourceInfo>
  </xsl:template>
  <!--
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
	-->
</xsl:stylesheet>

