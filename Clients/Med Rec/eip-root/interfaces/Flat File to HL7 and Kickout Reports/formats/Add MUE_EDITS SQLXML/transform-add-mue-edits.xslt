<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="3.1">
  <xsl:template match="XCSExcelBook">
    <ns1:SQLXML>
      <xsl:for-each-group select="XCSExcelSheet/XCSExcelRow[string-length(normalize-space((CDM, CPT)[1])) &gt; 0]" group-starting-with="*[normalize-space((SOFTWAREID, SOFTWAREID__)[1])]">
        <xsl:variable name="sw" select="normalize-space((SOFTWAREID, SOFTWAREID__)[1])" />
        <xsl:for-each select="current-group()[string-length($sw) &gt; 0]">
          <ns1:Insert>
            <MUE_EDITS>
              <SOFTWARE_ID>
                <xsl:value-of select="$sw" />
              </SOFTWARE_ID>
              <CPT>
                <xsl:value-of select="CPT" />
              </CPT>
              <CDM>
                <xsl:value-of select="CDM" />
              </CDM>
              <MAX_VALUE_PER_LINE>
                <xsl:value-of select="normalize-space((MAX_VALUE_PER_LINE, Max_Value_Per_Line)[1])" />
              </MAX_VALUE_PER_LINE>
            </MUE_EDITS>
          </ns1:Insert>
        </xsl:for-each>
      </xsl:for-each-group>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

