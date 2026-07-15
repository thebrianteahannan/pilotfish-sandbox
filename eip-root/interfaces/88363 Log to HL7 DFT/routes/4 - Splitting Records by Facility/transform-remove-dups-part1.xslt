<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="/">
    <Import>
      <!--REMOVE DUPLICATE CLIENT ELEMENTS BASED ON THE GROUP KEY-->
      <xsl:for-each select="//Client[not(./Group/@key=preceding-sibling::Client/Group/@key)]">
        <!--ONLY GRAB THE FIRST ONE, SO BASICALLY IF IT DOESN'T HAVE A PRECENDING SIBLING IT'S THE FIRST ONE AND WE ONLY USE THAT ONE-->
        <xsl:copy-of select="." />
      </xsl:for-each>
    </Import>
  </xsl:template>
</xsl:stylesheet>

