<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  <xsl:variable name="c" select="(//CLAIM | //Claim | /CLAIM | /Claim)[1]"/>
  <xsl:variable name="claimId" select="normalize-space(($c/CLAIMID | $c/ClaimId)[1])"/>
  <xsl:variable name="claimNumber" select="normalize-space(($c/CLAIMNUMBER | $c/ClaimNumber)[1])"/>
  <xsl:variable name="payerId" select="normalize-space(($c/PAYERID | $c/PayerId)[1])"/>
  <xsl:variable name="payerName" select="normalize-space(($c/PAYERNAME | $c/PayerName)[1])"/>
  <xsl:variable name="pos" select="normalize-space(($c/PLACEOFSERVICE | $c/PlaceOfService)[1])"/>
  <xsl:variable name="refNpi" select="normalize-space(($c/REFERRINGNPI | $c/ReferringNpi)[1])"/>
  <xsl:variable name="requireRef" select="if ($payerId = '66783JJT') then true() else false()"/>
  <xsl:variable name="allowedPos"
                select="if ($payerId = '66783JJT') then ('11','12')
                        else if ($payerId = 'MDCAID01') then ('11','21','22')
                        else ('11')"/>

  <xsl:template match="/">
    <xsl:variable name="missingRef" select="$requireRef and $refNpi = ''"/>
    <xsl:variable name="invalidPos" select="not($pos = $allowedPos)"/>
    <xsl:variable name="kick" select="$missingRef or $invalidPos"/>
    <ClaimScrubDecision>
      <ClaimId><xsl:value-of select="$claimId"/></ClaimId>
      <ClaimNumber><xsl:value-of select="$claimNumber"/></ClaimNumber>
      <PayerId><xsl:value-of select="$payerId"/></PayerId>
      <PayerName><xsl:value-of select="$payerName"/></PayerName>
      <PlaceOfService><xsl:value-of select="$pos"/></PlaceOfService>
      <ReferringNpi><xsl:value-of select="$refNpi"/></ReferringNpi>
      <RequireReferringNpi><xsl:value-of select="if ($requireRef) then 'true' else 'false'"/></RequireReferringNpi>
      <AllowedPosList><xsl:value-of select="string-join($allowedPos, ',')"/></AllowedPosList>
      <MatchBucket><xsl:value-of select="if ($kick) then 'kickout' else 'clean'"/></MatchBucket>
      <Disposition><xsl:value-of select="if ($kick) then 'KICKOUT' else 'PASS'"/></Disposition>
      <Reasons>
        <xsl:if test="$missingRef">
          <Reason code="MISSING_REFERRING_NPI">
            <xsl:value-of select="concat($payerName, ' requires a referring provider NPI before clearinghouse submit.')"/>
          </Reason>
        </xsl:if>
        <xsl:if test="$invalidPos">
          <Reason code="INVALID_POS">
            <xsl:value-of select="concat('Place of Service ', $pos, ' is not allowed for ', $payerName,
              ' (allowed: ', string-join($allowedPos, ', '), ').')"/>
          </Reason>
        </xsl:if>
      </Reasons>
      <ReasonSummary>
        <xsl:choose>
          <xsl:when test="$kick">
            <xsl:value-of select="string-join(for $r in (if ($missingRef) then 'MISSING_REFERRING_NPI' else (),
                                                        if ($invalidPos) then 'INVALID_POS' else ()) return $r, '|')"/>
          </xsl:when>
          <xsl:otherwise>PASS</xsl:otherwise>
        </xsl:choose>
      </ReasonSummary>
      <HumanSummary>
        <xsl:choose>
          <xsl:when test="$kick">
            <xsl:text>Claim </xsl:text>
            <xsl:value-of select="$claimNumber"/>
            <xsl:text> held before clearinghouse.</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>Claim </xsl:text>
            <xsl:value-of select="$claimNumber"/>
            <xsl:text> passed payer edits; continue to 837 and SNIP outbound.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </HumanSummary>
    </ClaimScrubDecision>
  </xsl:template>
</xsl:stylesheet>
