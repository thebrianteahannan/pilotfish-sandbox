<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>
  <xsl:param name="AckType"/>
  <xsl:param name="StControlNumber"/>
  <xsl:param name="Ak9Code"/>
  <xsl:param name="Ta1Code"/>
  <xsl:param name="RejectCount"/>
  <xsl:param name="SourceFile"/>
  <xsl:template match="/">
    <xsl:variable name="rejects" select="number(concat('0', translate(string($RejectCount), translate(string($RejectCount), '0123456789', ''), '')))"/>
    <xsl:variable name="bucket">
      <xsl:choose>
        <xsl:when test="normalize-space($Ta1Code) = 'A'">accepted</xsl:when>
        <xsl:when test="normalize-space($Ta1Code) != '' and normalize-space($Ta1Code) != 'A'">rejected</xsl:when>
        <xsl:when test="normalize-space($Ak9Code) = 'A' and $rejects = 0">accepted</xsl:when>
        <xsl:when test="contains('REP', normalize-space($Ak9Code)) or $rejects &gt; 0">rejected</xsl:when>
        <xsl:otherwise>error</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <AckDecision>
      <AckType><xsl:value-of select="$AckType"/></AckType>
      <StControlNumber><xsl:value-of select="$StControlNumber"/></StControlNumber>
      <Ak9Code><xsl:value-of select="$Ak9Code"/></Ak9Code>
      <Ta1Code><xsl:value-of select="$Ta1Code"/></Ta1Code>
      <RejectCount><xsl:value-of select="$RejectCount"/></RejectCount>
      <SourceFile><xsl:value-of select="$SourceFile"/></SourceFile>
      <DecisionBucket><xsl:value-of select="$bucket"/></DecisionBucket>
    </AckDecision>
  </xsl:template>
</xsl:stylesheet>
