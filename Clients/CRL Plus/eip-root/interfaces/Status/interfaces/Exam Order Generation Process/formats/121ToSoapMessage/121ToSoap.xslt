<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ns2="http://tempuri.org/" xmlns:soap="http://www.w3.org/2003/05/soap-envelope" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <soap:Envelope>
      <soap:Header />
      <soap:Body>
        <ns2:AppsAcordAuth>
          <ns2:AcordXML>
            <xsl:apply-templates select="ns1:TXLife" />
          </ns2:AcordXML>
          <ns2:Uid>
            <xsl:value-of select="converter:getAttributeString('EO.HTTPUsername')" />
          </ns2:Uid>
          <ns2:Pwd>
            <xsl:value-of select="converter:getAttributeString('EO.HTTPPassword')" />
          </ns2:Pwd>
        </ns2:AppsAcordAuth>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

