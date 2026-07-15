<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_MUE_Edits_Report">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <PatientName>Patient Name</PatientName>
          <ServiceDate>ServiceDate</ServiceDate>
          <CDMCode>CDMCode</CDMCode>
          <CPTCode>CPTCode</CPTCode>
          <Units>Units</Units>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group[@stripped = 'false']">
          <XCSExcelRow>
            <AccountNumber>
              <xsl:value-of select="PatientDemographics/admAcctNum" />
            </AccountNumber>
            <PatientName>
              <xsl:value-of select="PatientDemographics/admname" />
            </PatientName>
            <ServiceDate />
            <CDMCode />
            <CPTCode />
            <Units />
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

