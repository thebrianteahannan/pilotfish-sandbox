<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Copy everything as is by default -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!-- Special handling for Diag elements -->
  <xsl:template match="DiagnosisCodes">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:for-each select="Diag">
        <xsl:element name="Diag{position()}">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

