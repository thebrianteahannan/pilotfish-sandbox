<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/HospitalMessage">
    <HospitalMessage>
      <xsl:copy-of select="*[not(self::ValidationAdvanced) and not(self::AdvancedValidationNotes) and not(self::SplitBatchApplied)]"/>
      <SplitBatchApplied>
        <xsl:value-of select="if (IsBatch='true' or IsBatch='1') then 'true' else 'false'"/>
      </SplitBatchApplied>
      <ValidationAdvanced>
        <xsl:choose>
          <xsl:when test="ValidationBasic != 'PASS'">FAIL</xsl:when>
          <xsl:when test="normalize-space(MessageType) = '' or normalize-space(TriggerEvent) = ''">FAIL</xsl:when>
          <xsl:when test="normalize-space(ControlId) = ''">FAIL</xsl:when>
          <xsl:when test="string-length(normalize-space(PatientName)) &lt; 2">FAIL</xsl:when>
          <xsl:otherwise>PASS</xsl:otherwise>
        </xsl:choose>
      </ValidationAdvanced>
      <AdvancedValidationNotes>
        <xsl:choose>
          <xsl:when test="ValidationBasic != 'PASS'">Blocked by basic validation</xsl:when>
          <xsl:when test="normalize-space(MessageType) = '' or normalize-space(TriggerEvent) = ''">Missing message type / trigger</xsl:when>
          <xsl:when test="normalize-space(ControlId) = ''">Missing control ID</xsl:when>
          <xsl:when test="string-length(normalize-space(PatientName)) &lt; 2">Missing patient name</xsl:when>
          <xsl:when test="IsBatch='true' or IsBatch='1'">Batch envelope validated; member ADT events accepted</xsl:when>
          <xsl:otherwise>Business-rule HL7 checks passed</xsl:otherwise>
        </xsl:choose>
      </AdvancedValidationNotes>
    </HospitalMessage>
  </xsl:template>
</xsl:stylesheet>
