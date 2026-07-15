<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_MUE_Edits_Report">
        <XCSExcelRow>
          <AccountNumber>Account Number</AccountNumber>
          <PatientName>Patient Name</PatientName>
          <ServiceDate>Service Date</ServiceDate>
          <InsPlan>Insurance Plan</InsPlan>
          <InsName>Insurance Name</InsName>
          <CDMCode>CDM</CDMCode>
          <CPTCode>CPT</CPTCode>
          <TotalUnits>Total Units</TotalUnits>
          <MaxUnitsPerLine>Max Units Per Line</MaxUnitsPerLine>
          <NumChargesSplitInto>Num Charges Split Into</NumChargesSplitInto>
        </XCSExcelRow>
        <xsl:for-each select="//MUE_EDIT_LOG[AccountNumber]">
          <XCSExcelRow>
            <AccountNumber>
              <xsl:value-of select="AccountNumber" />
            </AccountNumber>
            <PatientName>
              <xsl:value-of select="PatientName" />
            </PatientName>
            <ServiceDate>
              <xsl:value-of select="ServiceDate" />
            </ServiceDate>
            <InsPlan>
              <xsl:value-of select="InsurancePlan" />
            </InsPlan>
            <InsName>
              <xsl:value-of select="InsuranceName" />
            </InsName>
            <CDMCode>
              <xsl:value-of select="CDM_ORIG" />
            </CDMCode>
            <CPTCode>
              <xsl:choose>
                <xsl:when test="CDM != CDM_ORIG">
                  <xsl:value-of select="CDM" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="CPT" />
                </xsl:otherwise>
              </xsl:choose>
            </CPTCode>
            <TotalUnits>
              <xsl:value-of select="@sum_num" />
            </TotalUnits>
            <MaxUnitsPerLine>
              <xsl:value-of select="@max_value_per_line" />
            </MaxUnitsPerLine>
            <NumChargesSplitInto>
              <xsl:value-of select="@num_broken_down_charges" />
            </NumChargesSplitInto>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

