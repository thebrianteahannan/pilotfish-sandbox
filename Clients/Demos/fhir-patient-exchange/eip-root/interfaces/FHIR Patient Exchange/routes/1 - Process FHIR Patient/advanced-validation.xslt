<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/FhirMessage">
    <FhirMessage>
      <xsl:copy-of select="*[not(self::ValidationAdvanced) and not(self::AdvancedValidationNotes) and not(self::BundleFlag)]"/>
      <BundleFlag>
        <xsl:value-of select="if (IsBundle='true' or IsBundle='1') then 'true' else 'false'"/>
      </BundleFlag>
      <ValidationAdvanced>
        <xsl:choose>
          <xsl:when test="ValidationBasic != 'PASS'">FAIL</xsl:when>
          <xsl:when test="normalize-space(PatientId) = ''">FAIL</xsl:when>
          <xsl:when test="string-length(normalize-space(PatientName)) &lt; 2">FAIL</xsl:when>
          <xsl:when test="(IsBundle='true' or IsBundle='1') and not(contains(string(RawFhir), 'entry'))">FAIL</xsl:when>
          <xsl:when test="ResourceType = 'Patient' and not(contains(string(RawFhir), 'name')) and not(contains(string(RawFhir), 'identifier'))">FAIL</xsl:when>
          <xsl:otherwise>PASS</xsl:otherwise>
        </xsl:choose>
      </ValidationAdvanced>
      <AdvancedValidationNotes>
        <xsl:choose>
          <xsl:when test="ValidationBasic != 'PASS'">Blocked by basic validation</xsl:when>
          <xsl:when test="normalize-space(PatientId) = ''">Missing patient MRN / identifier</xsl:when>
          <xsl:when test="string-length(normalize-space(PatientName)) &lt; 2">Missing patient name</xsl:when>
          <xsl:when test="(IsBundle='true' or IsBundle='1') and not(contains(string(RawFhir), 'entry'))">Bundle missing entry array</xsl:when>
          <xsl:when test="ResourceType = 'Patient' and not(contains(string(RawFhir), 'name')) and not(contains(string(RawFhir), 'identifier'))">Patient missing name/identifier content</xsl:when>
          <xsl:when test="IsBundle='true' or IsBundle='1'">Bundle business rules passed</xsl:when>
          <xsl:otherwise>Patient business-rule FHIR checks passed</xsl:otherwise>
        </xsl:choose>
      </AdvancedValidationNotes>
    </FhirMessage>
  </xsl:template>
</xsl:stylesheet>
