<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="XCSExcelBook">
    <ns1:SQLXML>
      <xsl:for-each select="XCSExcelSheet/XCSExcelRow[string-length(ER_INS_PLAN_CODE) &gt; 0]">
        <ns1:Insert>
          <ER_INS_PLAN_CODES>
            <CODE>
              <xsl:value-of select="ER_INS_PLAN_CODE" />
            </CODE>
          </ER_INS_PLAN_CODES>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

