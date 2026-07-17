<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XCSExcelBook>
      <XCSExcelSheet name="Ref_Phys">
        <XCSExcelRow>
          <admAcctNum>
            <xsl:text>admAcctNum</xsl:text>
          </admAcctNum>
          <NPI>NPI</NPI>
          <RefPhys>
            <xsl:text>RefPhys</xsl:text>
          </RefPhys>
          <PatientName>
            <xsl:text>PatientName</xsl:text>
          </PatientName>
        </XCSExcelRow>
        <xsl:for-each select="//PV1.8">
          <xsl:sort select="admAcctNum" />
          <xsl:variable name="PatientAccountNumber" select="../../PID/PID.3[CX.5='PT']/CX.1" />
          <XCSExcelRow>
            <admAcctNum>
              <xsl:value-of select="$PatientAccountNumber" />
            </admAcctNum>
            <NPI>
              <xsl:value-of select="XCN.1" />
            </NPI>
            <RefPhys>
              <xsl:value-of select="concat(XCN.3,' ',XCN.2)" />
            </RefPhys>
            <PatientName>
              <xsl:value-of select="../../PID[PID.3/CX.5='PT']/PID.5" />
            </PatientName>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

