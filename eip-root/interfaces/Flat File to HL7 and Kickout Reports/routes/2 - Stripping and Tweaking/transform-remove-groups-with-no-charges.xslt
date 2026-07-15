<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//Group[count(./Charge) = 0 or count(./Charge[@stripped = 'true']) = count(./Charge)]">
    <!--Strip if no charge data-->
    <xsl:copy select=".">
      <xsl:attribute name="stripped">true</xsl:attribute>
      <xsl:attribute name="stripped_reason" select="'Strip Group: No charge data.'" />
      <xsl:attribute name="key" select="@key" />
      <xsl:copy-of select="Charge" />
      <xsl:copy-of select="PatientDemographics" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

