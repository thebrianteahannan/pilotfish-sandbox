<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Converts SQLXML select of RawFhir into either the Patient JSON text or a 404 OperationOutcome JSON. -->
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:variable name="raw" select="normalize-space(string((.//*[local-name()='RawFhir'])[1]))"/>
    <xsl:choose>
      <xsl:when test="$raw != ''">
        <xsl:value-of select="string((.//*[local-name()='RawFhir'])[1])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>{</xsl:text>
        <xsl:text>"resourceType":"OperationOutcome",</xsl:text>
        <xsl:text>"issue":[{"severity":"error","code":"not-found","diagnostics":"Patient not found for the requested id."}]</xsl:text>
        <xsl:text>}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
