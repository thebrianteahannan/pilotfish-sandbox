<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:param name="resourceType" select="'Patient'"/>
  <xsl:template match="/">
    <xsl:value-of select="string((.//*[upper-case(local-name())='RESOURCETYPE' and normalize-space(.)=$resourceType]/following-sibling::*[upper-case(local-name())='NDJSONBODY'][1])"/>
  </xsl:template>
</xsl:stylesheet>
