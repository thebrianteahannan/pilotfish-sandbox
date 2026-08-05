<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/">
    <xsl:variable name="root" select="(//*[local-name()='Transaction'])[1]"/>
    <xsl:text>{"documentType":"</xsl:text>
    <xsl:value-of select="normalize-space(string(($root/@DocType)[1]))"/>
    <xsl:text>","controlNumber":"</xsl:text>
    <xsl:value-of select="normalize-space(string(($root/@ControlNumber)[1]))"/>
    <xsl:text>","source":"pilotfish-edi-835-oci-demo","segments":[</xsl:text>
    <xsl:for-each select="$root/*">
      <xsl:if test="position() &gt; 1">,</xsl:if>
      <xsl:text>{"id":"</xsl:text>
      <xsl:value-of select="local-name()"/>
      <xsl:text>"</xsl:text>
      <xsl:if test="@SegIdx">
        <xsl:text>,"segIdx":</xsl:text>
        <xsl:value-of select="@SegIdx"/>
      </xsl:if>
      <xsl:text>,"elements":{</xsl:text>
      <xsl:for-each select=".//*[not(*)][normalize-space(.) != '']">
        <xsl:if test="position() &gt; 1">,</xsl:if>
        <xsl:text>"</xsl:text>
        <xsl:value-of select="local-name()"/>
        <xsl:text>":"</xsl:text>
        <xsl:value-of select="replace(replace(normalize-space(.), '\\', '\\\\'), '&quot;', '\\&quot;')"/>
        <xsl:text>"</xsl:text>
      </xsl:for-each>
      <xsl:text>}}</xsl:text>
    </xsl:for-each>
    <xsl:text>]}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
