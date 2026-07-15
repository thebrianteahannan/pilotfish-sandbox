<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="AccountNumber" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--FILTER OUT ONLY THE ACCOUNT NUMBER YOU WANT-->
  <xsl:template match="XCSData/ADT_A01[not(PID/PID.3/CX.1 = $AccountNumber)]" />
</xsl:stylesheet>

