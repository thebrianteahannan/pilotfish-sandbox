<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:param name="UniqueControlID" />
  <xsl:param name="MSHGUID" />
  <xsl:param name="Response" />
  <xsl:template match="/">
    <ns1:SQLXML>
      <ns1:Execute>
        <ns1:SQL>UPDATE PilotFish_HL7_Log SET HL7_SEND_RESPONSE = ? WHERE PF_CONTROL_ID = ?</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="$Response" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="$MSHGUID" />
        </ns1:Params>
      </ns1:Execute>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

