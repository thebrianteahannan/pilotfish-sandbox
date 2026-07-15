<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output indent="yes" omit-xml-declaration="yes" />
  <xsl:param name="DefaultSplitCode" />
  <xsl:template match="Import">
    <Import>
      <xsl:for-each-group group-by="XCSRecord/@row" select="Client">
        <xsl:sequence select="." />
      </xsl:for-each-group>
      <!--<xsl:for-each-group group-by="XCSRecord/@row" select="Client[SplitCode != $DefaultSplitCode]">-->
      <!--<xsl:sequence select="." />-->
      <!--</xsl:for-each-group>-->
    </Import>
  </xsl:template>
</xsl:stylesheet>

