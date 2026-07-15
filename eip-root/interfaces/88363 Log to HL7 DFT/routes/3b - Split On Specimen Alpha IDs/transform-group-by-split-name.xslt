<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <Splits>
      <xsl:for-each-group group-by="Name" select="//Split">
        <Split name="{current-grouping-key()}">
          <xsl:attribute name="prefix" select="Prefix" />
          <xsl:attribute name="shortname" select="ShortName" />
          <xsl:copy-of select="current-group()/Record/XCSRecord" />
        </Split>
      </xsl:for-each-group>
    </Splits>
  </xsl:template>
</xsl:stylesheet>

