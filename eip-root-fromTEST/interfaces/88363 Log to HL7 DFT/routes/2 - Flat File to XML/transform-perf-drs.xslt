<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="AddtlSigners">
    <xsl:copy-of select="." />
    <PerformingDoctors>
      <xsl:for-each select="Signer[Date = ../../NewProcDocDateDOS]">
        <xsl:value-of select="concat(Name,' ')" />
      </xsl:for-each>
    </PerformingDoctors>
  </xsl:template>
</xsl:stylesheet>

