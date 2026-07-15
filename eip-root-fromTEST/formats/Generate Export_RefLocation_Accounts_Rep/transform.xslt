<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_RefLocation_Accounts_Rep">
        <XCSExcelRow>
          <admAcctNum>
            <xsl:text>admAcctNum</xsl:text>
          </admAcctNum>
          <admName>
            <xsl:text>admName</xsl:text>
          </admName>
          <admLocation>
            <xsl:text>admLocation</xsl:text>
          </admLocation>
          <Filler2>
            <xsl:text>Filler2</xsl:text>
          </Filler2>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group/PatientDemographics">
        <!-- <xsl:for-each select="Import/Group[@stripped = 'false']/PatientDemographics[string-length(admAcctNum) != 0]"> -->
          <xsl:sort select="admAcctNum" />
          <XCSExcelRow>
            <admAcctNum>
              <xsl:value-of select="admAcctNum" />
            </admAcctNum>
            <admName>
              <xsl:value-of select="admname" />
            </admName>
            <admLocation>
              <xsl:value-of select="admLocation" />
            </admLocation>
            <Filler2>
              <xsl:value-of select="Filler2" />
            </Filler2>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

