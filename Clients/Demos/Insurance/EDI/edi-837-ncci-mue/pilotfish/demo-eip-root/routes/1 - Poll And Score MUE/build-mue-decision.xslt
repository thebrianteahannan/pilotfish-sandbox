<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl xs">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:param name="ClaimControlNumber" select="''"/>
  <xsl:param name="ProcedureCode" select="''"/>
  <xsl:param name="Units" select="''"/>
  <xsl:param name="MaxUnits" select="''"/>
  <xsl:param name="Mai" select="''"/>
  <xsl:param name="CatalogDescription" select="''"/>
  <xsl:param name="SourceFile" select="''"/>

  <xsl:variable name="unitsNum" select="if ($Units castable as xs:decimal) then xs:decimal($Units) else xs:decimal(0)"/>
  <xsl:variable name="maxRaw" select="normalize-space($MaxUnits)"/>
  <xsl:variable name="catalogFound" select="string(string-length($maxRaw) &gt; 0)"/>
  <xsl:variable name="maxNum" select="if ($maxRaw castable as xs:decimal) then xs:decimal($maxRaw) else xs:decimal(0)"/>
  <xsl:variable name="exceeded" select="$catalogFound = 'true' and $unitsNum &gt; $maxNum"/>
  <xsl:variable name="matchBucket" select="if ($exceeded) then 'kickout' else 'pass'"/>
  <xsl:variable name="reason" select="
    if ($exceeded) then 'MUE_UNITS_EXCEEDED'
    else if ($catalogFound != 'true') then 'MUE_NOT_IN_CATALOG'
    else 'MUE_WITHIN_LIMIT'"/>

  <xsl:template match="/">
    <MueDecision>
      <ClaimControlNumber><xsl:value-of select="$ClaimControlNumber"/></ClaimControlNumber>
      <ProcedureCode><xsl:value-of select="$ProcedureCode"/></ProcedureCode>
      <Units><xsl:value-of select="$Units"/></Units>
      <MaxUnits><xsl:value-of select="$MaxUnits"/></MaxUnits>
      <Mai><xsl:value-of select="$Mai"/></Mai>
      <CatalogFound><xsl:value-of select="$catalogFound"/></CatalogFound>
      <CatalogDescription><xsl:value-of select="$CatalogDescription"/></CatalogDescription>
      <MatchBucket><xsl:value-of select="$matchBucket"/></MatchBucket>
      <Reason><xsl:value-of select="$reason"/></Reason>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
    </MueDecision>
  </xsl:template>
</xsl:stylesheet>
