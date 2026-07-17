<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="SU Accounts">
        <XCSExcelRow>
          <PatientName>
            <xsl:text>Patient Name</xsl:text>
          </PatientName>
          <SpecimenNumber>
            <xsl:text>Specimen#</xsl:text>
          </SpecimenNumber>
          <PatientAccountNumber>
            <xsl:text>Patient Acct#</xsl:text>
          </PatientAccountNumber>
          <OrigSOUTDate>
            <xsl:text>Orig SOUT Date</xsl:text>
          </OrigSOUTDate>
        </XCSExcelRow>
        <xsl:for-each select="XCSRecord[PerformingDoctors = 'SU']">
          <xsl:sort select="PatientAcctNum" />
          <XCSExcelRow>
            <PatientName>
              <xsl:value-of select="PatientName" />
            </PatientName>
            <SpecimenNumber>
              <xsl:value-of select="SpecimenNumber" />
            </SpecimenNumber>
            <PatientAccountNumber>
              <xsl:value-of select="PatientAcctNum" />
            </PatientAccountNumber>
            <OrigSOUTDate>
              <xsl:value-of select="OrigSOUTDate" />
            </OrigSOUTDate>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

