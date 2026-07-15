<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="SplitListXML" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="XCSData">
    <Splits>
      <xsl:variable name="Data" select="." />
      <xsl:variable name="SplitList" select="parse-xml($SplitListXML)" />
      <xsl:for-each select="$SplitList//Split">
        <xsl:variable name="SplitName" select="@name" />
        <xsl:variable name="SplitPrefix" select="@prefix" />
        <xsl:variable name="SplitShortName" select="@shortname" />
        <xsl:variable name="SplitCodes" select="Codes" />
        <xsl:for-each select="$SplitCodes/Code">
          <xsl:variable name="SplitCode" select="." />
          <xsl:for-each select="$Data/XCSRecord">
            <xsl:variable name="Record" select="." />
            <xsl:variable name="SpecimenAlpha" select="tokenize(translate($Record/SpecimenNumber,'-',':'),':')[2]" />
            <xsl:choose>
              <xsl:when test="$SpecimenAlpha = $SplitCode">
                <Split>
                  <Name>
                    <xsl:value-of select="$SplitName" />
                  </Name>
                  <Prefix>
                    <xsl:value-of select="$SplitPrefix" />
                  </Prefix>
                  <ShortName>
                    <xsl:value-of select="$SplitShortName" />
                  </ShortName>
                  <SplitCode>
                    <xsl:value-of select="$SplitCode" />
                  </SplitCode>
                  <Record>
                    <xsl:copy-of select="." />
                    <SpecimenAlpha>
                      <xsl:value-of select="$SpecimenAlpha" />
                    </SpecimenAlpha>
                  </Record>
                </Split>
              </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </Splits>
  </xsl:template>
</xsl:stylesheet>

