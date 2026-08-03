<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/FhirMessage">
    <FhirMessage>
      <xsl:copy-of select="*"/>
      <ValidationBasic>
        <xsl:choose>
          <xsl:when test="(ResourceType = 'Patient' or ResourceType = 'Bundle')
            and normalize-space(ResourceId) != ''
            and contains(string(RawFhir), 'resourceType')
            and contains(string(RawFhir), string(ResourceType))">PASS</xsl:when>
          <xsl:otherwise>FAIL</xsl:otherwise>
        </xsl:choose>
      </ValidationBasic>
      <BasicValidationNotes>
        <xsl:choose>
          <xsl:when test="not(ResourceType = 'Patient' or ResourceType = 'Bundle')">Unsupported resourceType (demo accepts Patient or Bundle)</xsl:when>
          <xsl:when test="normalize-space(ResourceId) = ''">Missing FHIR resource id</xsl:when>
          <xsl:when test="not(contains(string(RawFhir), 'resourceType'))">RawFhir missing resourceType marker</xsl:when>
          <xsl:when test="not(contains(string(RawFhir), string(ResourceType)))">RawFhir does not match declared ResourceType</xsl:when>
          <xsl:otherwise>Structural FHIR checks passed</xsl:otherwise>
        </xsl:choose>
      </BasicValidationNotes>
    </FhirMessage>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
  </xsl:template>
</xsl:stylesheet>
