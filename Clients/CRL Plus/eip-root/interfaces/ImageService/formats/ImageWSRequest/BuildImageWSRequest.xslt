<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ns2="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns3="http://crlcorp.com/schema/DocumentRequest" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="/ns2:TXLife">
    <xsl:apply-templates select="ns2:TXLifeRequest" />
    <ns2:Envelope>
      <ns2:Header />
      <ns2:Body>
        <ns3:StoreDocumentRequest>
          <ns3:UserId>
            <xsl:text>CRL_PLUS_INSIGHT</xsl:text>
          </ns3:UserId>
        </ns3:StoreDocumentRequest>
      </ns2:Body>
    </ns2:Envelope>
  </xsl:template>
</xsl:stylesheet>

