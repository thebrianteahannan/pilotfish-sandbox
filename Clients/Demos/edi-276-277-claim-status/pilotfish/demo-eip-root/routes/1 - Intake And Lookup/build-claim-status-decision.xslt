<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl xs">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:param name="TraceNumber" select="''"/>
  <xsl:param name="MemberId" select="''"/>
  <xsl:param name="ClaimId" select="''"/>
  <xsl:param name="Amount" select="''"/>
  <xsl:param name="SourceFile" select="''"/>

  <xsl:variable name="trace" select="normalize-space($TraceNumber)"/>
  <xsl:variable name="member" select="normalize-space($MemberId)"/>
  <xsl:variable name="complete" select="string-length($trace) &gt; 0 and string-length($member) &gt; 0"/>

  <xsl:variable name="catalogFound" select="
    if ($trace = 'ABCXYZ1' or $trace = 'ABCXYZ2') then true()
    else false()"/>
  <xsl:variable name="statusCode" select="
    if ($trace = 'ABCXYZ1') then 'F1'
    else if ($trace = 'ABCXYZ2') then 'P1'
    else if ($trace = 'ABCXYZ3') then 'E1'
    else if ($trace = '') then 'E1'
    else 'E1'"/>
  <xsl:variable name="statusMessage" select="
    if ($trace = 'ABCXYZ1') then 'Finalized paid'
    else if ($trace = 'ABCXYZ2') then 'Pending adjudication'
    else if ($trace = 'ABCXYZ3') then 'Claim not on file'
    else if ($trace = '') then 'Missing trace number'
    else 'Claim not on file'"/>
  <xsl:variable name="catalogBucket" select="
    if ($trace = '') then 'error'
    else if ($trace = 'ABCXYZ1' or $trace = 'ABCXYZ2') then 'found'
    else 'not-found'"/>
  <xsl:variable name="decisionBucket" select="
    if (not($complete)) then 'error'
    else $catalogBucket"/>
  <xsl:variable name="reason" select="
    if (not($complete)) then 'MISSING_IDENTITY'
    else if ($trace = 'ABCXYZ1') then 'CLAIM_FINALIZED'
    else if ($trace = 'ABCXYZ2') then 'CLAIM_PENDING'
    else if ($trace = 'ABCXYZ3') then 'CLAIM_NOT_ON_FILE'
    else if ($catalogFound) then 'CLAIM_FOUND'
    else 'CLAIM_NOT_ON_FILE'"/>

  <xsl:template match="/">
    <ClaimStatusDecision>
      <TraceNumber><xsl:value-of select="$trace"/></TraceNumber>
      <MemberId><xsl:value-of select="$member"/></MemberId>
      <ClaimId><xsl:value-of select="normalize-space($ClaimId)"/></ClaimId>
      <Amount><xsl:value-of select="normalize-space($Amount)"/></Amount>
      <StatusCode><xsl:value-of select="if (not($complete)) then 'E1' else $statusCode"/></StatusCode>
      <StatusMessage><xsl:value-of select="if (not($complete)) then 'Missing identity' else $statusMessage"/></StatusMessage>
      <CompletenessOk><xsl:value-of select="if ($complete) then 'true' else 'false'"/></CompletenessOk>
      <DecisionBucket><xsl:value-of select="$decisionBucket"/></DecisionBucket>
      <Reason><xsl:value-of select="$reason"/></Reason>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
    </ClaimStatusDecision>
  </xsl:template>
</xsl:stylesheet>
