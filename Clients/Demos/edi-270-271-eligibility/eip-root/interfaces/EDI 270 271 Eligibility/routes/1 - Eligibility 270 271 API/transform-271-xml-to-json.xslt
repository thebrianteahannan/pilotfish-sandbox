<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="urn:pilotfish:eligibility"
                exclude-result-prefixes="xs pf">
  <!--
    Parse wrapped raw X12 271 text → clinic JSON.
    Used instead of EDITransformationProcessor EDI→XML when 23R1 trial X12
    tables cannot resolve 005010X279A1 (see DESIGN.md Risks).
    Input: <EdiPayload>ISA*...~ST*271*...</EdiPayload>
  -->
  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:variable name="raw" select="normalize-space(string((/EdiPayload | //EdiPayload)[1]))"/>
  <xsl:variable name="norm" select="translate($raw, '&#13;&#10;', '')"/>
  <xsl:variable name="segs" select="tokenize($norm, '~')[normalize-space(.) != '']"/>
  <xsl:variable name="nm1il" select="$segs[starts-with(., 'NM1*IL*') or starts-with(., 'NM1|IL|')][1]"/>
  <xsl:variable name="aaa" select="$segs[starts-with(., 'AAA*') or starts-with(., 'AAA|')][1]"/>
  <xsl:variable name="ebSegs" select="$segs[starts-with(., 'EB*') or starts-with(., 'EB|')]"/>

  <xsl:function name="pf:parts" as="xs:string*">
    <xsl:param name="seg" as="xs:string?"/>
    <xsl:sequence select="tokenize(string($seg), '\*')"/>
  </xsl:function>

  <xsl:function name="pf:jesc" as="xs:string">
    <xsl:param name="s" as="xs:string?"/>
    <xsl:sequence select="replace(replace(replace(string($s),'\\','\\\\'),'&quot;','\\&quot;'),'&#10;','\\n')"/>
  </xsl:function>

  <xsl:variable name="il" select="pf:parts($nm1il)"/>
  <xsl:variable name="aa" select="pf:parts($aaa)"/>
  <xsl:variable name="memberId" select="string($il[10])"/>
  <xsl:variable name="last" select="string($il[4])"/>
  <xsl:variable name="first" select="string($il[5])"/>
  <xsl:variable name="aaaCode" select="string($aa[4])"/>
  <xsl:variable name="hasAaa" select="exists($aaa)"/>
  <xsl:variable name="hasEb" select="exists($ebSegs)"/>

  <xsl:template match="/">
    <xsl:text>{</xsl:text>
    <xsl:text>"status":"</xsl:text>
    <xsl:choose>
      <xsl:when test="$hasAaa"><xsl:text>rejected</xsl:text></xsl:when>
      <xsl:when test="$hasEb"><xsl:text>active</xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>unknown</xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:text>",</xsl:text>
    <xsl:text>"theater":"</xsl:text>
    <xsl:choose>
      <xsl:when test="$hasAaa"><xsl:text>aaa_error</xsl:text></xsl:when>
      <xsl:when test="$hasEb"><xsl:text>success</xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>none</xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:text>",</xsl:text>
    <xsl:text>"memberId":"</xsl:text><xsl:value-of select="pf:jesc($memberId)"/><xsl:text>",</xsl:text>
    <xsl:text>"lastName":"</xsl:text><xsl:value-of select="pf:jesc($last)"/><xsl:text>",</xsl:text>
    <xsl:text>"firstName":"</xsl:text><xsl:value-of select="pf:jesc($first)"/><xsl:text>",</xsl:text>
    <xsl:text>"aaa":</xsl:text>
    <xsl:choose>
      <xsl:when test="$hasAaa">
        <xsl:text>[{"validRequest":"</xsl:text><xsl:value-of select="pf:jesc(string($aa[2]))"/>
        <xsl:text>","rejectReason":"</xsl:text><xsl:value-of select="pf:jesc($aaaCode)"/>
        <xsl:text>","followUp":"</xsl:text><xsl:value-of select="pf:jesc(string($aa[5]))"/>
        <xsl:text>","rejectReasonLabel":"</xsl:text>
        <xsl:choose>
          <xsl:when test="$aaaCode='72'"><xsl:text>Invalid/Missing Subscriber/Insured ID</xsl:text></xsl:when>
          <xsl:when test="$aaaCode='75'"><xsl:text>Subscriber/Insured Not Found</xsl:text></xsl:when>
          <xsl:when test="$aaaCode='73'"><xsl:text>Invalid/Missing Subscriber/Insured Name</xsl:text></xsl:when>
          <xsl:when test="$aaaCode='71'"><xsl:text>Patient Birth Date Does Not Match</xsl:text></xsl:when>
          <xsl:otherwise><xsl:text>AAA </xsl:text><xsl:value-of select="pf:jesc($aaaCode)"/></xsl:otherwise>
        </xsl:choose>
        <xsl:text>"}]</xsl:text>
      </xsl:when>
      <xsl:otherwise><xsl:text>[]</xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:text>,</xsl:text>
    <xsl:text>"benefits":[</xsl:text>
    <xsl:for-each select="$ebSegs">
      <xsl:if test="position()&gt;1"><xsl:text>,</xsl:text></xsl:if>
      <xsl:variable name="e" select="pf:parts(.)"/>
      <xsl:variable name="c" select="string($e[2])"/>
      <xsl:text>{"eb01":"</xsl:text><xsl:value-of select="pf:jesc($c)"/><xsl:text>",</xsl:text>
      <xsl:text>"eb02":"</xsl:text><xsl:value-of select="pf:jesc(string($e[3]))"/><xsl:text>",</xsl:text>
      <xsl:text>"eb03":"</xsl:text><xsl:value-of select="pf:jesc(string($e[4]))"/><xsl:text>",</xsl:text>
      <xsl:text>"label":"</xsl:text>
      <xsl:choose>
        <xsl:when test="$c='1'"><xsl:text>Active Coverage</xsl:text></xsl:when>
        <xsl:when test="$c='B'"><xsl:text>Co-Insurance</xsl:text></xsl:when>
        <xsl:when test="$c='C'"><xsl:text>Deductible</xsl:text></xsl:when>
        <xsl:when test="$c='A'"><xsl:text>Co-Payment</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>Benefit </xsl:text><xsl:value-of select="pf:jesc($c)"/></xsl:otherwise>
      </xsl:choose>
      <xsl:text>"}</xsl:text>
    </xsl:for-each>
    <xsl:text>],</xsl:text>
    <xsl:text>"parseMode":"structural-x12-xslt",</xsl:text>
    <xsl:text>"message":"</xsl:text>
    <xsl:choose>
      <xsl:when test="$hasAaa"><xsl:text>Eligibility rejected (AAA). Fix the member ID / demographics and resubmit.</xsl:text></xsl:when>
      <xsl:when test="$hasEb"><xsl:text>Member is active. Benefits (EB) returned from payer 271.</xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>Parsed 271 but found neither AAA nor EB — inspect wire artifact.</xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:text>"}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
