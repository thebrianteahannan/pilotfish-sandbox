<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:tem="http://acord.ws.ure.allfinanz.com" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="converter datetime dtFormatter ta td ns2 xsl xsi xsd" extension-element-prefixes="converter" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="username" select="ta:getAttribute($attributes, 'AIGOutgoingWsUsername')" />
  <xsl:variable name="password" select="ta:getAttribute($attributes, 'AIGOutgoingWsPassword')" />
  <xsl:template match="/ns2:TXLife">
    <soap:Envelope>
      <soap:Header>
        <wsse:Security xmlns:wsse="http://schemas.xmlsoap.org/ws/2003/06/secext">
          <wsse:UsernameToken>
            <wsse:Username>
              <xsl:value-of select="$username" />
            </wsse:Username>
            <wsse:Password>
              <xsl:value-of select="$password" />
            </wsse:Password>
          </wsse:UsernameToken>
        </wsse:Security>
      </soap:Header>
      <soap:Body>
        <tem:TXLifePayload>
          <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
          <TXLife>
            <xsl:apply-templates select="node()|@*" />
          </TXLife>
          <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
        </tem:TXLifePayload>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
  <xsl:template match="node()">
    <!-- strip out empty elements that have no attributes -->
    <xsl:choose>
      <xsl:when test="string-length(name()) &gt; 1">
        <xsl:if test="normalize-space(string(.)) != '' or count(*) &gt; 0 or @*[string-length(.) &gt; 0]">
          <xsl:element name="{name()}" namespace="{namespace-uri()}">
            <xsl:apply-templates select="node()|@*[.!='']" />
          </xsl:element>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="node()|@*[.!='']" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@*">
    <!-- strip out empty elements that have no attributes -->
    <xsl:if test="normalize-space(string(.)) != '' or count(*) &gt; 0 or @*[string-length(.) &gt; 0]">
      <xsl:copy>
        <xsl:apply-templates select="node()|@*[.!='']" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <xsl:template match="*" mode="copy">
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates select="@*|node()" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*|text()|comment()" mode="copy">
    <xsl:copy />
  </xsl:template>
</xsl:stylesheet>

