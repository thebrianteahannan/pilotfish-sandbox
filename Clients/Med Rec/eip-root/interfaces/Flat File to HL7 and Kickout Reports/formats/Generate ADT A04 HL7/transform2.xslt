<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[normalize-space(text())='null' or normalize-space(text())='NULL' or normalize-space(text())='NULL NULL' or normalize-space(text())='null null']">
    <!--DO NOTHING, REMOVE ANY ELEMENTS WITH 'NULL' OR 'null'-->
  </xsl:template>
</xsl:stylesheet>

