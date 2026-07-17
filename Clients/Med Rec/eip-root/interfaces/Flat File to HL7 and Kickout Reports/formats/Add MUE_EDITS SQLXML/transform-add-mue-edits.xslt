<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="XCSExcelBook">
    <ns1:SQLXML>
      <xsl:for-each select="XCSExcelSheet/XCSExcelRow[string-length(SOFTWAREID) &gt; 0]">
        <ns1:Insert>
          <MUE_EDITS>
            <SOFTWARE_ID>
              <xsl:value-of select="SOFTWAREID" />
            </SOFTWARE_ID>
            <CPT>
              <xsl:value-of select="CPT" />
            </CPT>
            <CDM>
              <xsl:value-of select="CDM" />
            </CDM>
            <MAX_VALUE_PER_LINE>
              <xsl:value-of select="MAX_VALUE_PER_LINE" />
            </MAX_VALUE_PER_LINE>
          </MUE_EDITS>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

