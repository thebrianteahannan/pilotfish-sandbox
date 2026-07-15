<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="SoftwareID" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="Charge[radExamDept != '797' or string-length(radExamDept) = 0]">
    <!-- REMOVE ANY CHARGES WHERE radExamDept != 797 -->
  </xsl:template>
</xsl:stylesheet>

