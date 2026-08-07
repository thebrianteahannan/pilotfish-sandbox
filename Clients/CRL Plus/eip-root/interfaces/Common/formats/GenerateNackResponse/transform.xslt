<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="err td ta" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/">
    <AcordResponse>
      <ResponseCode>5</ResponseCode>
      <ResponseDetail>Failure</ResponseDetail>
      <OLifEExtension>
        <SystemTrackingNo>
          <xsl:value-of select="ta:getAttribute($attributes, 'error.subdir')" />
        </SystemTrackingNo>
      </OLifEExtension>
    </AcordResponse>
  </xsl:template>
</xsl:stylesheet>

