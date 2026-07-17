<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output indent="yes" omit-xml-declaration="yes" />
  <xsl:param name="DefaultSplitCode" select="'TRD'" />
  <xsl:param name="DefaultFacilityCode" select="'NE'" />
  <xsl:param name="DefaultAccountNumAlpha" select="'F'" />
  <xsl:template match="/*">
    <XCSData>
      <xsl:copy-of select="query_results" />
      <Import>
        <xsl:variable name="ClientCodesWithSplitCodes" select="//Import/Client[string-length(SplitCode) !=  0]/@client_code" />
        <xsl:for-each-group group-by="XCSRecord/PatientAcctNum" select="Import/Client[not(@client_code = $ClientCodesWithSplitCodes)]">
          <xsl:copy select=".">
            <xsl:apply-templates select="@*|node()" />
            <SplitCode>
              <xsl:value-of select="$DefaultSplitCode" />
            </SplitCode>
            <FacilityCode>
              <xsl:value-of select="$DefaultFacilityCode" />
            </FacilityCode>
            <AccountNumAlpha>
              <xsl:value-of select="$DefaultAccountNumAlpha" />
            </AccountNumAlpha>
          </xsl:copy>
        </xsl:for-each-group>
        <xsl:for-each-group group-by="SplitCode" select="//Import/Client[@client_code = $ClientCodesWithSplitCodes]">
          <xsl:for-each select="current-group()">
            <xsl:copy-of select="." />
          </xsl:for-each>
        </xsl:for-each-group>
      </Import>
    </XCSData>
  </xsl:template>
  <!-- Generic identity template -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

