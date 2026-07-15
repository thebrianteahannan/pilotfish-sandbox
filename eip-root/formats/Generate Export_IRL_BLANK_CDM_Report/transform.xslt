<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_IRL_BLANK_CDM_Report">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <Patient_Name>Patient_Name</Patient_Name>
          <DOS>DOS</DOS>
          <Units>Units</Units>
          <CDM>CDM</CDM>
          <Interface_Type>Interface_Type</Interface_Type>
          <Facility>Facility</Facility>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group[@stripped = 'false']">
          <xsl:sort select="PatientDemographics/admAcctNum" />
          <xsl:for-each-group group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radAcctNum)" select="Charge">
            <xsl:sort select="radExamBillingCode" />
            <xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)" />
            <xsl:if test="number($sumNum) &gt; 0">
              <xsl:for-each select="(current-group())[1]">
                <xsl:sort select="radExamBillingCode" />
                <xsl:variable name="CDM" select="radExamBillingCode" />
                <xsl:if test="count(/XCSData/query_results/CDMLIST/CDMLIST[lower-case(CDM) = lower-case($CDM)]) = 0">
                  <xsl:if test="radExamBillingCode = 'BLANK'">
                  <XCSExcelRow>
                    <AccountNumber>
                      <xsl:value-of select="radAcctNum" />
                    </AccountNumber>
                    <Patient_Name>
                      <xsl:value-of select="../PatientDemographics/admname" />
                    </Patient_Name>
                    <DOS>
                      <xsl:value-of select="radExamServDate" />
                    </DOS>
                    <Units>
                      <xsl:value-of select="radNumOfTimes" />
                    </Units>
                    <CDM>
                      <xsl:value-of select="radExamBillingCode" />
                    </CDM>
                    <Interface_Type>
                      <xsl:value-of select="''" />
                    </Interface_Type>
                    <Facility>
                      <xsl:value-of select="''" />
                    </Facility>
                  </XCSExcelRow>
				  </xsl:if>
                </xsl:if>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

