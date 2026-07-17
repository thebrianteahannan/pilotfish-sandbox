<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//XCSRecord">
    <Client>
      <xsl:attribute name="client_code" select="Location" />
      <xsl:copy-of select="." />
    </Client>
  </xsl:template>
</xsl:stylesheet>

