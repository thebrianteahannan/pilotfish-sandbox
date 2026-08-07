<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bo="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.10.00.XSD">
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="*[namespace-uri()='']">
    <xsl:element name="bo:{name()}" namespace="http://ACORD.org/Standards/Life/2">
      <xsl:apply-templates select="@* | node()" />
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>

