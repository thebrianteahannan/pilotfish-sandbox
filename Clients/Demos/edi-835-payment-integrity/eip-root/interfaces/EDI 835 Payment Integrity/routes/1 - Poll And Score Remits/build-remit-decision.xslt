<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xsl xs">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:param name="ClaimControlNumber" select="''"/>
  <xsl:param name="PaidAmount" select="'0'"/>
  <xsl:param name="ChargeAmount" select="'0'"/>
  <xsl:param name="CasCodes" select="''"/>
  <xsl:param name="ExpectedPaid" select="''"/>
  <xsl:param name="PatientName" select="''"/>
  <xsl:param name="SourceFile" select="''"/>

  <xsl:variable name="paid" select="if ($PaidAmount castable as xs:decimal) then xs:decimal($PaidAmount) else xs:decimal(0)"/>
  <xsl:variable name="expectedRaw" select="normalize-space($ExpectedPaid)"/>
  <xsl:variable name="arFound" select="string(string-length($expectedRaw) &gt; 0)"/>
  <xsl:variable name="expected" select="if ($expectedRaw castable as xs:decimal) then xs:decimal($expectedRaw) else xs:decimal(0)"/>
  <xsl:variable name="variance" select="if ($arFound = 'true') then ($paid - $expected) else xs:decimal(0)"/>
  <xsl:variable name="underpay" select="if ($arFound = 'true' and $variance &lt; xs:decimal('-0.01')) then 'true' else 'false'"/>
  <xsl:variable name="matchBucket" select="
    if ($arFound != 'true') then 'exception'
    else if (abs($variance) &lt;= xs:decimal('0.01')) then 'matched'
    else 'exception'"/>
  <xsl:variable name="reason" select="
    if ($arFound != 'true') then 'NO_AR'
    else if (abs($variance) &lt;= xs:decimal('0.01')) then 'MATCHED'
    else if ($variance &lt; xs:decimal('-0.01')) then 'UNDERPAY'
    else 'OVERPAY_OR_MISMATCH'"/>

  <xsl:template match="/">
    <RemitDecision>
      <ClaimControlNumber><xsl:value-of select="$ClaimControlNumber"/></ClaimControlNumber>
      <PatientName><xsl:value-of select="$PatientName"/></PatientName>
      <ChargeAmount><xsl:value-of select="$ChargeAmount"/></ChargeAmount>
      <PaidAmount><xsl:value-of select="format-number($paid, '0.00')"/></PaidAmount>
      <ExpectedPaid><xsl:value-of select="$ExpectedPaid"/></ExpectedPaid>
      <Variance>
        <xsl:choose>
          <xsl:when test="$arFound = 'true'"><xsl:value-of select="format-number($variance, '0.00')"/></xsl:when>
          <xsl:otherwise/>
        </xsl:choose>
      </Variance>
      <CasCodes><xsl:value-of select="$CasCodes"/></CasCodes>
      <ArFound><xsl:value-of select="$arFound"/></ArFound>
      <MatchBucket><xsl:value-of select="$matchBucket"/></MatchBucket>
      <UnderpayFlag><xsl:value-of select="$underpay"/></UnderpayFlag>
      <Reason><xsl:value-of select="$reason"/></Reason>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
    </RemitDecision>
  </xsl:template>
</xsl:stylesheet>
