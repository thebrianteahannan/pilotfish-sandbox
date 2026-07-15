<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="exslt" version="3.1">
  <xsl:template match="/">
    <XCSData>
      <xsl:for-each select="query_results">
        <xsl:copy-of select="." />
      </xsl:for-each>
      <xsl:for-each select="//Split/Client/Group">
        <xsl:copy-of select="." />
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

