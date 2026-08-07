<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.1">
  <xsl:output cdata-section-elements="Text" indent="yes" method="xml" />
  <xsl:template match="/">
    <sorted-errors>
      <xsl:for-each select="./errors/error">
        <xsl:sort select="./Group" />
        <xsl:sort select="./Transaction" />
        <xsl:sort select="./SegPosition" />
        <xsl:sort select="./ElePosition" />
        <xsl:copy-of copy-namespaces="no" select="." />
      </xsl:for-each>
    </sorted-errors>
  </xsl:template>
</xsl:stylesheet>

