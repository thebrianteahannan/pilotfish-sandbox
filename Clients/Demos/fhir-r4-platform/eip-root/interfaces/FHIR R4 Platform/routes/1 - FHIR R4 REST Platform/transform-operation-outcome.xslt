<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:param name="diagnostics" select="'Bad request'"/>
  <xsl:param name="code" select="'invalid'"/>
  <xsl:template match="/">
    <xsl:text>{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"</xsl:text>
    <xsl:value-of select="$code"/>
    <xsl:text>","diagnostics":"</xsl:text>
    <xsl:value-of select="replace(replace(string($diagnostics),'\\','\\\\'),'&quot;','\\&quot;')"/>
    <xsl:text>"}]}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
