<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xsl">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:template name="cpt-from-sv1">
    <xsl:param name="sv1"/>
    <xsl:variable name="sv101" select="$sv1/*[local-name()='SV101']"/>
    <xsl:variable name="nested" select="normalize-space(string((
      $sv101/*[local-name()='SV101_02' or local-name()='SV101-02' or local-name()='SV101_2']
      | $sv1/*[local-name()='SV101_02' or local-name()='SV101-02']
    )[1]))"/>
    <xsl:variable name="text" select="normalize-space(string($sv101))"/>
    <xsl:choose>
      <xsl:when test="string-length($nested) &gt; 0"><xsl:value-of select="$nested"/></xsl:when>
      <xsl:when test="contains($text, ':')"><xsl:value-of select="tokenize($text, ':')[2]"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="mod-from-sv1">
    <xsl:param name="sv1"/>
    <xsl:variable name="sv101" select="$sv1/*[local-name()='SV101']"/>
    <xsl:variable name="nested" select="normalize-space(string((
      $sv101/*[local-name()='SV101_03' or local-name()='SV101-03' or local-name()='SV101_3']
      | $sv1/*[local-name()='SV101_03' or local-name()='SV101-03']
    )[1]))"/>
    <xsl:variable name="text" select="normalize-space(string($sv101))"/>
    <xsl:choose>
      <xsl:when test="string-length($nested) &gt; 0"><xsl:value-of select="$nested"/></xsl:when>
      <xsl:when test="contains($text, ':') and count(tokenize($text, ':')) &gt;= 3">
        <xsl:value-of select="tokenize($text, ':')[3]"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/">
    <xsl:variable name="clm" select="(//*[local-name()='CLM'])[1]"/>
    <xsl:variable name="sv1a" select="(//*[local-name()='SV1'])[1]"/>
    <xsl:variable name="sv1b" select="(//*[local-name()='SV1'])[2]"/>
    <ClaimPair>
      <ClaimControlNumber>
        <xsl:value-of select="normalize-space(string(($clm/*[local-name()='CLM01'] | //*[local-name()='CLM01'])[1]))"/>
      </ClaimControlNumber>
      <ProcedureCode1>
        <xsl:call-template name="cpt-from-sv1"><xsl:with-param name="sv1" select="$sv1a"/></xsl:call-template>
      </ProcedureCode1>
      <ProcedureCode2>
        <xsl:if test="$sv1b">
          <xsl:call-template name="cpt-from-sv1"><xsl:with-param name="sv1" select="$sv1b"/></xsl:call-template>
        </xsl:if>
      </ProcedureCode2>
      <Modifier2>
        <xsl:if test="$sv1b">
          <xsl:call-template name="mod-from-sv1"><xsl:with-param name="sv1" select="$sv1b"/></xsl:call-template>
        </xsl:if>
      </Modifier2>
    </ClaimPair>
  </xsl:template>
</xsl:stylesheet>
