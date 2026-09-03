<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>

  <xsl:function name="pf:text" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pf="http://pilotfish.hl7demo">
    <xsl:param name="nodes"/>
    <xsl:value-of select="normalize-space(string(($nodes[normalize-space()])[1]))"/>
  </xsl:function>

  <xsl:function name="pf:iso-date" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pf="http://pilotfish.hl7demo">
    <xsl:param name="raw"/>
    <xsl:variable name="d" select="replace(string($raw), '[^0-9]', '')"/>
    <xsl:value-of select="if (string-length($d) ge 8)
      then concat(substring($d,1,4), '-', substring($d,5,2), '-', substring($d,7,2))
      else normalize-space(string($raw))"/>
  </xsl:function>

  <xsl:template match="/">
    <xsl:variable name="pid5" select="(//*[local-name()='PID.5'])[1]"/>
    <xsl:variable name="last" select="(
      $pid5//*[local-name()='FN.1'],
      $pid5//*[local-name()='XPN.1'],
      $pid5/*[local-name()='PID.5.1'],
      $pid5
    )"/>
    <xsl:variable name="first" select="(
      $pid5//*[local-name()='XPN.2'],
      $pid5/*[local-name()='PID.5.2']
    )"/>
    <xsl:variable name="pid7" select="(
      //*[local-name()='PID.7']//*[local-name()='TS.1'],
      //*[local-name()='PID.7']
    )"/>
    <xsl:variable name="pid3" select="(
      //*[local-name()='PID.3']//*[local-name()='CX.1'],
      //*[local-name()='PID.3']
    )"/>
    <xsl:variable name="msh10" select="(
      //*[local-name()='MSH.10']//*[local-name()='ST.1'],
      //*[local-name()='MSH.10']
    )"/>
    <Patient>
      <LastName>
        <xsl:variable name="raw" select="normalize-space(string(($last[normalize-space()])[1]))"/>
        <xsl:value-of select="if (contains($raw, '^')) then substring-before($raw, '^') else $raw"/>
      </LastName>
      <FirstName>
        <xsl:variable name="raw" select="normalize-space(string(($first[normalize-space()])[1]))"/>
        <xsl:choose>
          <xsl:when test="string-length($raw) gt 0">
            <xsl:value-of select="if (contains($raw, '^')) then tokenize($raw, '\^')[2] else $raw"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="comp" select="normalize-space(string(($last[normalize-space()])[1]))"/>
            <xsl:value-of select="if (contains($comp, '^')) then tokenize($comp, '\^')[2] else ''"/>
          </xsl:otherwise>
        </xsl:choose>
      </FirstName>
      <DateOfBirth>
        <xsl:value-of xmlns:pf="http://pilotfish.hl7demo"
          select="pf:iso-date(($pid7[normalize-space()])[1])"/>
      </DateOfBirth>
      <PatientId>
        <xsl:variable name="raw" select="normalize-space(string(($pid3[normalize-space()])[1]))"/>
        <xsl:value-of select="if (contains($raw, '^')) then substring-before($raw, '^') else $raw"/>
      </PatientId>
      <MessageControlId>
        <xsl:value-of select="normalize-space(string(($msh10[normalize-space()])[1]))"/>
      </MessageControlId>
    </Patient>
  </xsl:template>
</xsl:stylesheet>
