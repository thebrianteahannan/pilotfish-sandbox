<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:SOAPENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://crlcorp.com/crlresponse" xmlns:ns2="https://hhws.portamedic.com/wsordresp/hhresponse.asmx" exclude-result-prefixes="SOAPENV" version="1.0">
  <xsl:template match="/SOAPENV:Envelope">
    <SOAPENV:Envelope>
      <SOAPENV:Body>
        <ns1:GetOrderResponseResponse>
          <ns1:GetOrderResponseResult>
            <ns1:POLICY>
              <xsl:value-of select="SOAPENV:Body/ns2:GetOrderResponse/ns2:Policy" />
            </ns1:POLICY>
            <ns1:REQINFO_UNIQUE_ID>
              <xsl:value-of select="SOAPENV:Body/ns2:GetOrderResponse/ns2:RequirmentInfoUniqueID" />
            </ns1:REQINFO_UNIQUE_ID>
            <ns1:TRANSMODE>
              <xsl:value-of select="SOAPENV:Body/ns2:GetOrderResponse/ns2:TransMode" />
            </ns1:TRANSMODE>
            <ns1:REQCODE>
              <xsl:value-of select="SOAPENV:Body/ns2:GetOrderResponse/ns2:ReqCode" />
            </ns1:REQCODE>
            <ns1:RESULTCODE>Failure</ns1:RESULTCODE>
            <ns1:RESULTINFO_DESC>Invalid Credentials</ns1:RESULTINFO_DESC>
          </ns1:GetOrderResponseResult>
        </ns1:GetOrderResponseResponse>
      </SOAPENV:Body>
    </SOAPENV:Envelope>
  </xsl:template>
</xsl:stylesheet>

