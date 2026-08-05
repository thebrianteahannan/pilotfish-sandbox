<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:pf="urn:pilotfish:fhir" xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="pf xs">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:function name="pf:jesc" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:sequence select="replace(replace(replace(string($s),'\\','\\\\'),'&quot;','\\&quot;'),'&#10;','\\n')"/>
  </xsl:function>
  <xsl:template match="/">
    <xsl:variable name="rows" select="//*[local-name()='ROW' or local-name()='row' or local-name()='Table']/*[
        (*[upper-case(local-name())='RAWFHIR'] and normalize-space(*[upper-case(local-name())='RAWFHIR'][1])!='')
        or self::*[upper-case(local-name())='RAWFHIR']
      ] | //*[upper-case(local-name())='RAWFHIR'][normalize-space(.)!='']/.."/>
    <!-- Prefer distinct parents of RAWFHIR cells -->
    <xsl:variable name="parents" select="//*[upper-case(local-name())='RAWFHIR'][normalize-space(.)!='']/parent::*"/>
    <xsl:text>{"resourceType":"Bundle","type":"searchset","total":</xsl:text>
    <xsl:value-of select="count($parents)"/>
    <xsl:text>,"entry":[</xsl:text>
    <xsl:for-each select="$parents">
      <xsl:if test="position()!=1"><xsl:text>,</xsl:text></xsl:if>
      <xsl:variable name="t" select="normalize-space(string(*[upper-case(local-name())='RESOURCETYPE'][1]))"/>
      <xsl:variable name="i" select="normalize-space(string(*[upper-case(local-name())='RESOURCEID'][1]))"/>
      <xsl:text>{"fullUrl":"</xsl:text>
      <xsl:value-of select="pf:jesc(concat($t,'/',$i))"/>
      <xsl:text>","resource":</xsl:text>
      <xsl:value-of select="string(*[upper-case(local-name())='RAWFHIR'][1])"/>
      <xsl:text>}</xsl:text>
    </xsl:for-each>
    <xsl:text>]}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
