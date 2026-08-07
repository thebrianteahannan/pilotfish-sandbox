<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.1">
  <xsl:output cdata-section-elements="Text" indent="yes" method="xml" />
  <xsl:template match="/">
    <errors>
      <xsl:apply-templates select="//Path" />
    </errors>
  </xsl:template>
  <xsl:template match="Path">
    <error>
      <Text>
        <xsl:copy-of copy-namespaces="no" select="./ancestor::EdiValidationRuleResult[1]/item[1]/text()" />
      </Text>
      <xsl:choose>
        <!--Used the Message from current item instead of parameterMap-->
        <xsl:when test="exists(./../Message)">
          <xsl:copy-of copy-namespaces="no" select="./ancestor::EdiValidationRuleResult[1]/item[2]/parameterMap/*[name() ne 'Message']" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of copy-namespaces="no" select="./ancestor::EdiValidationRuleResult[1]/item[2]/parameterMap/*" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="./ancestor::EdiValidationRuleResult[1]/item[2]/parameterMap/ValidationLevel[. = '4']">
        <xsl:copy-of copy-namespaces="no" select="./parent::item/ContextInfo[1]/Segment[1]/SegPosition[1]" />
      </xsl:if>
      <xsl:copy-of copy-namespaces="no" select="./parent::item/*" />
      <xsl:variable name="group" select="for $a in tokenize(., '/') return if (contains($a,'Group[')) then $a else null" />
      <xsl:variable name="group-number" select="for $a in tokenize($group, '[\[\]]') return if ($a castable as xs:integer) then $a else null" />
      <Group>
        <xsl:value-of select="if (string-length($group-number) &gt;0) then $group-number else 0" />
      </Group>
      <xsl:variable name="transaction" select="for $a in tokenize(., '/') return if (contains($a,'Transaction')) then $a else null" />
      <xsl:variable name="transaction-number" select="for $a in tokenize($transaction, '[\[\]]') return if ($a castable as xs:integer) then $a else null" />
      <Transaction>
        <xsl:value-of select="if (string-length($transaction-number)&gt; 0) then $transaction-number else 0" />
      </Transaction>
    </error>
  </xsl:template>
</xsl:stylesheet>

