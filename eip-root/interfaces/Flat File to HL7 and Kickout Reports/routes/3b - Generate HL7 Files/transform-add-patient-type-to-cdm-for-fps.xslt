<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--ADD PATIENT TYPE TO CDMs 112698, 112901 - FOR FPS ONLY-->
  <xsl:template match="FT1.25">
    <xsl:variable name="PatientType" select="'E'" />
    <FT1.25>
      <xsl:choose>
        <xsl:when test=". = ('112698','112901')">
          <xsl:value-of select="concat(.,$PatientType)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="starts-with(.,'0')">
              <xsl:value-of select="substring(.,2,string-length(.))" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="." />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </FT1.25>
  </xsl:template>
</xsl:stylesheet>

