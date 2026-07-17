<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//Group">
    <Client>
      <!--FORPATSO TO FINISH-->
      <xsl:variable name="ClientCode">
        <xsl:choose>
          <xsl:when test="$Partition = 'NHL' and $Client = 'POS'">
            <!--FORPATSO SPLIT-->
            <xsl:value-of select="PatientDemographics/Filler2" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of name="client_code" select="PatientDemographics/admLocation" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:attribute name="client_code" select="$ClientCode" />
      <xsl:copy-of select="." />
      <!--BEFORE FORPATSO SPLIT LOGIC ADDED-->
      <!--<xsl:attribute name="client_code" select="PatientDemographics/admLocation" />-->
      <!--<xsl:copy-of select="." />-->
    </Client>
  </xsl:template>
</xsl:stylesheet>

