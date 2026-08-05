<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:variable name="raw" select="string((.//*[upper-case(local-name())='RAWFHIR'])[1])"/>
    <xsl:choose>
      <xsl:when test="normalize-space($raw) != ''">
        <xsl:value-of select="$raw"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"not-found","diagnostics":"Resource not found for the requested type/id."}]}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
