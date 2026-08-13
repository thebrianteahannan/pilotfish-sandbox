<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xsl">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:param name="ClaimControlNumber" select="''"/>
  <xsl:param name="ProcedureCode1" select="''"/>
  <xsl:param name="ProcedureCode2" select="''"/>
  <xsl:param name="Modifier2" select="''"/>
  <xsl:param name="ModifierIndicator" select="''"/>
  <xsl:param name="CatalogDescription" select="''"/>
  <xsl:param name="SourceFile" select="''"/>

  <xsl:variable name="pairFound" select="string(string-length(normalize-space($ModifierIndicator)) &gt; 0)"/>
  <xsl:variable name="mod" select="upper-case(normalize-space($Modifier2))"/>
  <xsl:variable name="modOk" select="$mod = '59' or $mod = 'XE' or $mod = 'XP' or $mod = 'XS' or $mod = 'XU'"/>
  <xsl:variable name="ind" select="normalize-space($ModifierIndicator)"/>
  <xsl:variable name="matchBucket" select="
    if ($pairFound != 'true') then 'pass'
    else if ($ind = '0') then 'kickout'
    else if ($ind = '1' and $modOk) then 'pass'
    else if ($ind = '1') then 'kickout'
    else 'pass'"/>
  <xsl:variable name="reason" select="
    if ($pairFound != 'true') then 'PTP_NO_PAIR'
    else if ($ind = '0') then 'PTP_NCCI_PAIR'
    else if ($ind = '1' and $modOk) then 'PTP_MODIFIER_OK'
    else if ($ind = '1') then 'PTP_NCCI_PAIR'
    else 'PTP_NOT_APPLICABLE'"/>

  <xsl:template match="/">
    <PtpDecision>
      <ClaimControlNumber><xsl:value-of select="$ClaimControlNumber"/></ClaimControlNumber>
      <ProcedureCode1><xsl:value-of select="$ProcedureCode1"/></ProcedureCode1>
      <ProcedureCode2><xsl:value-of select="$ProcedureCode2"/></ProcedureCode2>
      <Modifier2><xsl:value-of select="$Modifier2"/></Modifier2>
      <ModifierIndicator><xsl:value-of select="$ModifierIndicator"/></ModifierIndicator>
      <PairFound><xsl:value-of select="$pairFound"/></PairFound>
      <CatalogDescription><xsl:value-of select="$CatalogDescription"/></CatalogDescription>
      <MatchBucket><xsl:value-of select="$matchBucket"/></MatchBucket>
      <Reason><xsl:value-of select="$reason"/></Reason>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
    </PtpDecision>
  </xsl:template>
</xsl:stylesheet>
