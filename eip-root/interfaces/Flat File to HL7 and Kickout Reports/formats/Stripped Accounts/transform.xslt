<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="qsel_E22">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <admName>admName</admName>
          <admInsMne>admInsMne</admInsMne>
          <admPatientType>admPatientType</admPatientType>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group[@stripped = 'false']">
          <xsl:variable name="ins" select="Insurance1/adminsmne" />
          <xsl:for-each select=".[string-length((Guarantor/admGuarName)[1]) != 0][PatientDemographics/admpatienttype = 'E' and count(/XCSData/query_results/MEDICAID2223_CODES/MEDICAID2223_CODES[INS_PLANS = $ins]) != 0]">
            <XCSExcelRow>
              <AccountNumber>
                <xsl:value-of select="PatientDemographics/admAcctNum" />
              </AccountNumber>
              <admName>
                <xsl:value-of select="PatientDemographics/admname" />
              </admName>
              <admInsMne>
                <xsl:value-of select="Insurance1/adminsmne" />
              </admInsMne>
              <admPatientType>
                <xsl:value-of select="PatientDemographics/admpatienttype" />
              </admPatientType>
            </XCSExcelRow>
          </xsl:for-each>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

