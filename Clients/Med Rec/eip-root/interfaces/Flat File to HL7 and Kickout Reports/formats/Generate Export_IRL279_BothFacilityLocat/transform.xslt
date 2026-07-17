<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_IRL279_BothFacilityLocat">
        <XCSExcelRow>
          <admAcctNum>admAcctNum</admAcctNum>
          <admName>admName</admName>
          <admLocation>admLocation</admLocation>
          <Filler2>Filler2</Filler2>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group[@stripped = 'false']/PatientDemographics[string-length(Filler2) &gt; 0 and (admLocation = 'F.RLAB' or admLocation = 'F.LAB')]">
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

