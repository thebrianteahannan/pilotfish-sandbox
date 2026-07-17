<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="CMD Appended A">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <AltnernateAccountNumbers>AlternateAccountNumber</AltnernateAccountNumbers>
          <PatienetName>Patient Name</PatienetName>
          <PatientDOB>Patient DOB</PatientDOB>
          <DateOfService>Date of Service</DateOfService>
          <CPT>CPT</CPT>
          <Units>Units</Units>
          <PatientType>PatientType</PatientType>
        </XCSExcelRow>
        <xsl:for-each select="//FT1[FT1.25/@cdm-appended-a = 'yes']">
          <XCSExcelRow>
            <AccountNumber>
              <xsl:value-of select="../PID/PID.3/CX.1" />
            </AccountNumber>
            <AltnernateAccountNumbers>
              <xsl:value-of select="FT1.25/@alternate-account-numbers" />
            </AltnernateAccountNumbers>
            <PatientName>
              <xsl:value-of select="concat(../PID/PID.5/XPN.1,', ',../PID/PID.5/XPN.2)" />
            </PatientName>
            <PatientDOB>
              <xsl:value-of select="../PID/PID.7" />
            </PatientDOB>
            <DateOfService>
              <xsl:value-of select="FT1.4" />
            </DateOfService>
            <CPT>
              <xsl:value-of select="FT1.25" />
            </CPT>
            <Units>
              <xsl:value-of select="FT1.10" />
            </Units>
            <Units>
              <xsl:value-of select="FT1.10" />
            </Units>
            <PatientType>
              <xsl:value-of select="@patient-type" />
            </PatientType>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

