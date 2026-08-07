<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="CRLDOCUMENTID">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <CRLDOCUMENTID id="{@id}">
      <xsl:value-of select="converter:getEnhancedExpression('{attribute:com.pilotfish.temp.incomingresult}')" />
    </CRLDOCUMENTID>
  </xsl:template>
  <xsl:template match="MIMETYPE">
    <MIMETYPE>
      <xsl:text>image/tiff</xsl:text>
    </MIMETYPE>
  </xsl:template>
  <xsl:template match="TYPETXT">
    <TYPETXT>
      <xsl:text>TIFF</xsl:text>
    </TYPETXT>
  </xsl:template>
</xsl:stylesheet>

