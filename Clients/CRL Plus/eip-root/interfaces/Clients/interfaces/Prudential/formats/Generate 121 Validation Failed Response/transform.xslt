<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:SOAPENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" xmlns:ns1="http://crlcorp.com/crlresponse" exclude-result-prefixes="SOAPENV err" version="1.0">
  <xsl:template match="/">
    <SOAPENV:Envelope>
      <SOAPENV:Body>
        <SOAPENV:Fault>
          <Faultcode>soapenv:Validation.Failure</Faultcode>
          <Faultstring>Message Failed Validation</Faultstring>
          <Detail>
            <xsl:variable name="allmessages">
              <xsl:for-each select="/Messages/Message">
                <xsl:value-of select="." />
                <xsl:value-of select="'. '" />
              </xsl:for-each>
              <xsl:for-each select="err:errorReport">
                <xsl:value-of select="err:exceptionMessage" />
              </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="substring(normalize-space($allmessages),1,4000)" />
          </Detail>
        </SOAPENV:Fault>
      </SOAPENV:Body>
    </SOAPENV:Envelope>
  </xsl:template>
</xsl:stylesheet>

