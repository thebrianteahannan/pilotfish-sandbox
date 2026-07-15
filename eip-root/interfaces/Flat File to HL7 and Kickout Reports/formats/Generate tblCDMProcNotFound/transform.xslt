<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="clientName" />
  <xsl:template match="/XCSData">
    <xsl:variable name="stripLocations" select="query_results/TBLIRL279_STRIPLOCATIONS/TBLIRL279_STRIPLOCATIONS" />
    <XCSExcelBook>
      <XCSExcelSheet name="tblCDMProcNotFound">
        <xsl:for-each select="Import/Group/Charge[../PatientDemographics/admAcctNum = radAcctNum]">
          <xsl:variable name="CDM" select="radExamBillingCode" />
          <xsl:variable name="radAcctNum" select="radAcctNum" />
          <xsl:variable name="admAcctNum" select="../PatientDemographics/admAcctNum" />
          <xsl:variable name="admLocation" select="../PatientDemographics/admLocation" />
          <xsl:variable name="filler2" select="../PatientDemographics/Filler2" />
          <xsl:variable name="StripLocationCount" select="count(//query_results/TBLIRL279_STRIPLOCATIONS/TBLIRL279_STRIPLOCATIONS[LOCATION = $admLocation and LOCATION2 = $filler2])" />
          <xsl:if test="count(/XCSData/query_results/CDMLIST/CDMLIST[lower-case(CDM) = lower-case($CDM)]) = 0">
            <xsl:choose>
              <xsl:when test="($admLocation = 'F.LAB' and $StripLocationCount = 0) or ($admLocation != 'F.RLAB' and $admLocation != 'F.LAB') or ($admLocation != 'F.RLAB' and string-length($filler2) = 0) or ($admLocation != 'F.LAB' and string-length($filler2) = 0) or ($admLocation  = 'F.RLAB' and string-length($filler2) = 0)">
                <XCSExcelRow>
                  <CDM>
                    <xsl:value-of select="radExamBillingCode" />
                  </CDM>
                  <CPT>
                    <xsl:value-of select="radExamCPT" />
                  </CPT>
                  <Department>
                    <xsl:value-of select="radExamDept" />
                  </Department>
                  <Description>
                    <xsl:value-of select="examdesc" />
                  </Description>
                  <Interface_Type>
                    <xsl:value-of select="$clientName" />
                  </Interface_Type>
                  <Facility_Code>
                    <xsl:value-of select="'TBD'" />
                  </Facility_Code>
                  <ADMLOCATION>
                    <xsl:value-of select="$admLocation" />
                  </ADMLOCATION>
                  <STRIPLOCATION1>
                    <xsl:value-of select="$StripLocationCount" />
                  </STRIPLOCATION1>
                  <FILLER2>
                    <xsl:value-of select="$filler2" />
                  </FILLER2>
                  <AccountNum>
                    <xsl:value-of select="radAcctNum" />
                  </AccountNum>
                  <FilterMe />
                </XCSExcelRow>
              </xsl:when>
              <xsl:otherwise>
                <!--FILTERED ROWS - DON'T OUTPUT ANYTHING-->
                <XCSExcelRow>
                  <CDM>
                    <xsl:value-of select="radExamBillingCode" />
                  </CDM>
                  <CPT>
                    <xsl:value-of select="radExamCPT" />
                  </CPT>
                  <Department>
                    <xsl:value-of select="radExamDept" />
                  </Department>
                  <Description>
                    <xsl:value-of select="examdesc" />
                  </Description>
                  <Interface_Type>
                    <xsl:value-of select="$clientName" />
                  </Interface_Type>
                  <Facility_Code>
                    <xsl:value-of select="'TBD'" />
                  </Facility_Code>
                  <ADMLOCATION>
                    <xsl:value-of select="$admLocation" />
                  </ADMLOCATION>
                  <STRIPLOCATION1>
                    <xsl:value-of select="$StripLocationCount" />
                  </STRIPLOCATION1>
                  <FILLER2>
                    <xsl:value-of select="$filler2" />
                  </FILLER2>
                  <AccountNum>
                    <xsl:value-of select="radAcctNum" />
                  </AccountNum>
                  <FilterMe>Yes</FilterMe>
                </XCSExcelRow>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

