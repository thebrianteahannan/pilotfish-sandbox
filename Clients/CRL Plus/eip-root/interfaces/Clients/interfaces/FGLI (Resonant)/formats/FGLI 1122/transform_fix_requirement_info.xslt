<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:n="http://ACORD.org/Standards/Life/2" version="1.0">
  <!--IDENTITY TRANSFORM-->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[name() = 'RequirementInfo' and @AppliesToPartyID = 'Party_Insured']">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
      <xsl:for-each select="..//n:StatusEvent">
        <xsl:copy-of select="." />
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[name() = 'RequirementInfo' and @AppliesToPartyID = 'Patient']">
    <!--REMOVE-->
  </xsl:template>
</xsl:stylesheet>

