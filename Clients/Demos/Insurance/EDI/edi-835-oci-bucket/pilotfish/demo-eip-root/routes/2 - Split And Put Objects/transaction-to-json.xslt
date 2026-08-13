<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:variable name="st" select="normalize-space(string((/*/@ControlNumber | //ST/ST02 | //*[local-name()='ST']/*[local-name()='ST02'])[1]))"/>
    <xsl:variable name="clp" select="normalize-space(string((//CLP/CLP01 | //*[local-name()='CLP']/*[local-name()='CLP01'])[1]))"/>
    <xsl:variable name="paid" select="normalize-space(string((//CLP/CLP04 | //*[local-name()='CLP']/*[local-name()='CLP04'])[1]))"/>
    <xsl:variable name="charge" select="normalize-space(string((//CLP/CLP03 | //*[local-name()='CLP']/*[local-name()='CLP03'])[1]))"/>
    <xsl:text>{</xsl:text>
    <xsl:text>"stControlNumber":"</xsl:text><xsl:value-of select="replace($st,'&quot;','')"/><xsl:text>",</xsl:text>
    <xsl:text>"claimControlNumber":"</xsl:text><xsl:value-of select="replace($clp,'&quot;','')"/><xsl:text>",</xsl:text>
    <xsl:text>"chargeAmount":"</xsl:text><xsl:value-of select="$charge"/><xsl:text>",</xsl:text>
    <xsl:text>"paidAmount":"</xsl:text><xsl:value-of select="$paid"/><xsl:text>"</xsl:text>
    <xsl:text>}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
