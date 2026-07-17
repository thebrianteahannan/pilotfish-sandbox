<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XCSData>
      <xsl:for-each select="//query_results">
        <xsl:copy-of select="//query_results" />
      </xsl:for-each>
      <Import>
        <xsl:for-each select="//Client">
          <xsl:copy-of select="." />
        </xsl:for-each>
      </Import>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

