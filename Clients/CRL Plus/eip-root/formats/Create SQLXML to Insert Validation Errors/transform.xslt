<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute>
        <ns1:SQL>INSERT INTO VALIDATION_ERROR (PF_SOURCE_CLIENT, POLNUMBER, ERROR_DATE, REQ_CODE_TC, REQ_CODE_TXT, REASON_FOR_ERROR, TRANSACTION_TEXT_ID) VALUES (?, ?, ?, ?, ?, ?, ?)</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('sourceClient')" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('PolNumber')" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('ErrorDate')" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('ReqCodeTC')" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('ReqCodeText')" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="//Message" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('CurrTransactionTextID')" />
        </ns1:Params>
      </ns1:Execute>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

