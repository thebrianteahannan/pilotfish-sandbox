<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <Status>
      <xsl:choose>
        <xsl:when test="//Group[count(Charge) &gt; 0 and count(PatientDemographics) = 0]">
          <xsl:value-of select="'ERROR'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'OK'" />
        </xsl:otherwise>
      </xsl:choose>
    </Status>
  </xsl:template>
</xsl:stylesheet>

