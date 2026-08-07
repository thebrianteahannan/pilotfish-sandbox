<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:acord="http://ACORD.org/Standards/Life/2" version="1.0">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="acord:TransType/@tc">
    <xsl:attribute name="tc">103</xsl:attribute>
  </xsl:template>
  <xsl:template match="acord:TransType/text()">
    <xsl:text>New Business Submission</xsl:text>
  </xsl:template>
</xsl:stylesheet>

