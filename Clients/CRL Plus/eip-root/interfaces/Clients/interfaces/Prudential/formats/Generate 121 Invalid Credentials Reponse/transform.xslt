<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:SOAPENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://crlcorp.com/crlresponse" exclude-result-prefixes="SOAPENV" version="1.0">
  <xsl:template match="/">
    <SOAPENV:Envelope>
      <SOAPENV:Body>
        <SOAPENV:Fault>
          <Faultcode>soapenv:Credentials.Invalid</Faultcode>
          <Faultstring>WSSecurity credentials missing or invalid.</Faultstring>
          <Detail>A valid Username and Password element must be provided in the http://crlcorp.com/DocumentService namespace.</Detail>
        </SOAPENV:Fault>
      </SOAPENV:Body>
    </SOAPENV:Envelope>
  </xsl:template>
</xsl:stylesheet>

