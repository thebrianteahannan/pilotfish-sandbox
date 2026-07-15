<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSData>
      <query_results>
        <xsl:for-each-group group-by="local-name(.)" select="query_results/LOCATIONS/*">
          <xsl:element name="{local-name(.)}">
            <xsl:copy-of select="current-group()" />
          </xsl:element>
        </xsl:for-each-group>
      </query_results>
      <Import>
        <xsl:copy-of select="//Group[string-length(@key) != 0]" />
      </Import>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

