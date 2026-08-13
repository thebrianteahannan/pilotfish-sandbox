<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/HospitalMessage">
    <HospitalMessage>
      <xsl:copy-of select="*"/>
      <ValidationBasic>
        <xsl:choose>
          <xsl:when test="normalize-space(PatientId) != '' and contains(string(RawHl7), 'MSH|') and contains(string(RawHl7), 'PID|')">PASS</xsl:when>
          <xsl:otherwise>FAIL</xsl:otherwise>
        </xsl:choose>
      </ValidationBasic>
      <BasicValidationNotes>
        <xsl:choose>
          <xsl:when test="normalize-space(PatientId) = ''">Missing patient identifier</xsl:when>
          <xsl:when test="not(contains(string(RawHl7), 'MSH|'))">Missing MSH segment</xsl:when>
          <xsl:when test="not(contains(string(RawHl7), 'PID|'))">Missing PID segment</xsl:when>
          <xsl:otherwise>Structural HL7 checks passed</xsl:otherwise>
        </xsl:choose>
      </BasicValidationNotes>
    </HospitalMessage>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
  </xsl:template>
</xsl:stylesheet>
