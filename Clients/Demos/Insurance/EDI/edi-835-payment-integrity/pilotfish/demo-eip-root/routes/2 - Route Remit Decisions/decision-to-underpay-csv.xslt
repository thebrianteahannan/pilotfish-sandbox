<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xsl">
  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/">
    <xsl:value-of select="normalize-space(string(//ClaimControlNumber[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//PatientName[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//ExpectedPaid[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//PaidAmount[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//Variance[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//CasCodes[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//Reason[1]))"/>
    <xsl:text>,</xsl:text>
    <xsl:value-of select="normalize-space(string(//SourceFile[1]))"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
