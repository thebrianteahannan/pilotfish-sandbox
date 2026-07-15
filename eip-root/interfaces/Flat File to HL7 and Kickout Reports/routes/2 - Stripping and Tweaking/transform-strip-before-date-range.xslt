<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="DateRange" select="'20220113'" />
  <!--<xsl:param name="DateRangeConverted" select="$DateRange" />-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="Charge[radExamServDate &lt; $DateRange]">
    <xsl:copy select=".">
      <xsl:attribute name="stripped">true</xsl:attribute>
      <xsl:attribute name="stripped_reason" select="'Strip Charge: Exam Service Date Is Before DateRange.'" />
      <xsl:copy-of select="." />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

