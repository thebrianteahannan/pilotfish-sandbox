<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--FILTER CHARGES THAT MATCH STRIP_SITE_LOCATIONS - LAKE NONA ONLY-->
  <xsl:template match="Charge">
    <xsl:variable name="performingSite" select="./performingSite" />
    <xsl:variable name="performingSiteCount" select="count(/XCSData/query_results/STRIP_PERFORMING_SITES/STRIP_PERFORMING_SITES[MNEMONIC = $performingSite])" />
    <xsl:choose>
      <xsl:when test="$performingSiteCount = 0">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <Charge>
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:if test="$performingSiteCount != 0">
            <xsl:attribute name="stripped_reason" select="'Strip Charge: Strip performing site locations'" />
          </xsl:if>
          <xsl:if test="$performingSiteCount != 0">
            <xsl:attribute name="stripped_performing_sites" select="'true'" />
          </xsl:if>
          <xsl:copy-of select="../PatientDemographics" />
          <xsl:copy-of select="." />
        </Charge>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

