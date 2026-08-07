<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ta td ns2 datetime dtFormatter" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attr" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="insertError" select="ta:getAttribute($attr, 'insert.order.error')" />
  <xsl:template match="/">
    <soap:Envelope>
      <soap:Body>
        <SubmitOrderDataResponse xmlns="http://crlcorp.com/DocumentService">
          <SubmitOrderDataResult>
            <xsl:choose>
              <xsl:when test="string-length($insertError) &gt; 0">
                <xsl:value-of select="concat('Error: ',$insertError)" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>The order file was sent successfully.</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </SubmitOrderDataResult>
        </SubmitOrderDataResponse>
      </soap:Body>
    </soap:Envelope>
  </xsl:template>
</xsl:stylesheet>

