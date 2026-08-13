<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xsl">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:template match="/">
    <xsl:variable name="clm" select="(//*[local-name()='CLM'])[1]"/>
    <xsl:variable name="sv1" select="(//*[local-name()='SV1'])[1]"/>
    <xsl:variable name="sv101" select="$sv1/*[local-name()='SV101']"/>
    <xsl:variable name="cptNested" select="normalize-space(string((
      $sv101/*[local-name()='SV101_02' or local-name()='SV101-02' or local-name()='SV101_2']
      | $sv1/*[local-name()='SV101_02' or local-name()='SV101-02']
    )[1]))"/>
    <xsl:variable name="sv101Text" select="normalize-space(string($sv101))"/>
    <xsl:variable name="cpt" select="
      if (string-length($cptNested) &gt; 0) then $cptNested
      else if (contains($sv101Text, ':')) then tokenize($sv101Text, ':')[2]
      else $sv101Text"/>
    <ClaimLine>
      <ClaimControlNumber>
        <xsl:value-of select="normalize-space(string(($clm/*[local-name()='CLM01'] | //*[local-name()='CLM01'])[1]))"/>
      </ClaimControlNumber>
      <ProcedureCode><xsl:value-of select="$cpt"/></ProcedureCode>
      <Units>
        <xsl:value-of select="normalize-space(string(($sv1/*[local-name()='SV104'] | //*[local-name()='SV104'])[1]))"/>
      </Units>
    </ClaimLine>
  </xsl:template>
</xsl:stylesheet>
