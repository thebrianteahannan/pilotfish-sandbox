<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Dialect A (XCSData/XCSRecord) → compact JSON array of row objects -->
  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/">
    <xsl:text>{"records":[</xsl:text>
    <xsl:for-each select="//*[local-name()='XCSRecord']">
      <xsl:if test="position() &gt; 1">,</xsl:if>
      <xsl:text>{</xsl:text>
      <xsl:for-each select="*[normalize-space(.) != '' or @*]">
        <xsl:if test="position() &gt; 1">,</xsl:if>
        <xsl:text>"</xsl:text>
        <xsl:value-of select="local-name()"/>
        <xsl:text>":"</xsl:text>
        <xsl:value-of select="replace(replace(normalize-space(.), '\\', '\\\\'), '&quot;', '\\&quot;')"/>
        <xsl:text>"</xsl:text>
      </xsl:for-each>
      <xsl:text>}</xsl:text>
    </xsl:for-each>
    <xsl:text>]}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
