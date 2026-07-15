<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" expand-text="yes" version="3.1">
  <xsl:param name="DefaultSplitCode" />
  <xsl:template match="Import">
    <XCSData>
      <Import>
        <xsl:for-each-group group-by="XCSRecord/@row" select="Client[IsDuplicate = 'yes']">
          <xsl:variable name="CurrentRowNum" select="./XCSRecord/@row" />
          <xsl:variable name="ClientCountWithRowNumNotDefault" select="count(../Client[XCSRecord/@row = $CurrentRowNum and SplitCode != $DefaultSplitCode])" />
          <xsl:if test="$ClientCountWithRowNumNotDefault = 0">
            <xsl:copy-of select="." />
          </xsl:if>
        </xsl:for-each-group>
        <xsl:for-each select="Client[string-length(IsDuplicate) = 0]">
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Import>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

