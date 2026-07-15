<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--FILTER H.LIND FROM RIO CLIENT FOR SOFTWARE ID 382 ONLY-->
  <xsl:template match="Group[PatientDemographics/admLocation = 'H.LIND']/Charge">
    <Charge>
      <xsl:attribute name="stripped">true</xsl:attribute>
      <xsl:attribute name="stripped_reason" select="'Strip Charge: Strip flagged accounts, flagged locations, F.LAB accounts, F.RLAB accounts'" />
      <REMOVE_ME />
      <xsl:copy-of select="../PatientDemographics" />
      <xsl:copy-of select="." />
    </Charge>
  </xsl:template>
</xsl:stylesheet>

