<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_MUE_Edits_NoInsPlansFound_Report">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <Insurance1>Ins1</Insurance1>
          <Insurance2>Ins2</Insurance2>
          <Insurance3>Ins3</Insurance3>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group[@stripped = 'false']">
          <xsl:if test="(count(Insurance1/adminspolicy) + count(Insurance2/adminspolicy) + count(Insurance3/adminspolicy)) = 0">
            <XCSExcelRow>
              <AccountNumber>
                <xsl:value-of select="PatientDemographics/admAcctNum" />
              </AccountNumber>
              <Insurance1>
                <xsl:value-of select="Insurance1/adminspolicy" />
              </Insurance1>
              <Insurance2>
                <xsl:value-of select="Insurance2/adminspolicy" />
              </Insurance2>
              <Insurance3>
                <xsl:value-of select="Insurance3/adminspolicy" />
              </Insurance3>
            </XCSExcelRow>
          </xsl:if>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

