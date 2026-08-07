<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns2 datetime dtFormatter" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:template match="/">
    <soap:Envelope>
      <soap:Body>
        <SubmitResponseDataResponse xmlns="http://crlcorp.com/DocumentService">
          <SubmitResponseDataResult>
            <xsl:text>Success</xsl:text>
          </SubmitResponseDataResult>
        </SubmitResponseDataResponse>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
</xsl:stylesheet>

