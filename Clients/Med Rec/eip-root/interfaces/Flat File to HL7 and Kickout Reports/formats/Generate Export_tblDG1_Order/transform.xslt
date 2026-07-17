<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_tblDG1_Order">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <Diag_Code>Diag_Code</Diag_Code>
        </XCSExcelRow>
        <xsl:for-each-group group-by="concat(../../PatientDemographics/admAcctNum, .)" select="Import/Group[not(@stripped = 'true')]/DiagnosisCodes/Diag">
          <xsl:sort select="../../PatientDemographics/admAcctNum" />
          <xsl:variable name="AccountNumber" select="../../PatientDemographics/admAcctNum" />
          <xsl:if test="string-length(.) != 0 and string-length($AccountNumber) != 0">
            <XCSExcelRow>
              <AccountNumber>
                <xsl:value-of select="$AccountNumber" />
              </AccountNumber>
              <Diag_Code>
                <xsl:value-of select="." />
              </Diag_Code>
            </XCSExcelRow>
          </xsl:if>
        </xsl:for-each-group>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

