<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--FILTER CHARGES THAT MATCH CHARGE STATUS OF VOIDED [4] OR DELETED [2]-->
  <xsl:template match="Charge">
    <xsl:variable name="chargeStatus" select="./chargeStatus" />
    <xsl:variable name="voidedOrDeleted" select="$chargeStatus = 'VOIDED [4]' or $chargeStatus = 'DELETED [2]'" />
    <xsl:choose>
      <xsl:when test="not($voidedOrDeleted)">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <Charge>
          <xsl:attribute name="stripped">true</xsl:attribute>
          <xsl:if test="$voidedOrDeleted">
            <xsl:attribute name="stripped_reason" select="'Strip Charge: Strip charge status voided or deleted'" />
          </xsl:if>
          <xsl:if test="$voidedOrDeleted">
            <xsl:attribute name="stripped_charge_status_voided_or_deleted" select="'true'" />
          </xsl:if>
          <xsl:copy-of select="../PatientDemographics" />
          <xsl:copy-of select="." />
        </Charge>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

