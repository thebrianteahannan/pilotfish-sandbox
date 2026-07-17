<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="PerformingDoctors">
    <PerformingDoctors>
      <xsl:choose>
        <xsl:when test="string-length(.) = 0">
          <xsl:value-of select="'SU'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="." />
        </xsl:otherwise>
      </xsl:choose>
    </PerformingDoctors>
  </xsl:template>
</xsl:stylesheet>

