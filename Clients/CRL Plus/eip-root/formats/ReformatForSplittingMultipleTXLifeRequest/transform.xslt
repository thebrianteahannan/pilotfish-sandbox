<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns2="http://ACORD.org/Standards/Life/2" version="1.0">
  <xsl:template match="/ns2:TXLife[count(ns2:TXLifeRequest) &gt; 1]">
    <root>
      <xsl:for-each select="ns2:TXLifeRequest">
        <ns2:TXLife>
          <xsl:apply-templates select="../@*" />
          <ns2:TXLifeRequest>
            <xsl:apply-templates select="@*" />
            <xsl:apply-templates select="../ns2:UserAuthRequest" />
            <xsl:apply-templates select="." />
          </ns2:TXLifeRequest>
        </ns2:TXLife>
      </xsl:for-each>
    </root>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

