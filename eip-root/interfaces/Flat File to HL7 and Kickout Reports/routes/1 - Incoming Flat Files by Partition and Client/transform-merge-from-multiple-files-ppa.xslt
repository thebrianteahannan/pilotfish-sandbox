<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Handle the root element -->
  <xsl:template match="/">
    <XCSData>
      <Demographics>
        <xsl:apply-templates select="/XCSData/AP_Demographics/XCSData/XCSRecord" />
        <xsl:apply-templates select="/XCSData/CP_Demographics/XCSData/XCSRecord" />
      </Demographics>
      <Charges>
        <xsl:apply-templates select="/XCSData/AP_Charges/XCSData/XCSRecord" />
        <xsl:apply-templates select="/XCSData/CP_Charges/XCSData/XCSRecord" />
      </Charges>
    </XCSData>
  </xsl:template>
  <!-- Copy XCSRecord elements -->
  <xsl:template match="XCSRecord">
    <xsl:copy-of select="." />
  </xsl:template>
</xsl:stylesheet>

