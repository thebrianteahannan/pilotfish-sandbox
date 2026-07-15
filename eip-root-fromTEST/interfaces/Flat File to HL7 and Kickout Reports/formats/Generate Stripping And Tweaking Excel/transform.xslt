<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:template match="/StripsAndTweaks">
    <XCSExcelBook>
      <XCSExcelSheet name="E22 Accounts">
        <XCSExcelRow>
          <AccountNumber>AccountNumber</AccountNumber>
          <admName>admName</admName>
          <admInsMne>admInsMne</admInsMne>
          <admPatientType>admPatientType</admPatientType>
        </XCSExcelRow>
        <xsl:for-each select="Tweaked/TweakedDemographics[./Group/PatientDemographics/@tweaked_reason = 'Tweaked Patient Demographics: For insurance planchange E to E22 because Insurance1 matches a Medicaid2223 code in the database.']/Group">
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
      </XCSExcelSheet>
      <XCSExcelSheet name="FLG Location Charges">
        <XCSExcelRow>
          <Partition>Partition</Partition>
          <Interface_Type>Interface_Type</Interface_Type>
          <Location>Location</Location>
          <Account_Number>Account_Number</Account_Number>
          <Patient_Name>Patient_Name</Patient_Name>
          <DOS>DOS</DOS>
          <Units>Units</Units>
          <CDM>CDM</CDM>
          <CPT>CPT</CPT>
        </XCSExcelRow>
        <xsl:for-each select="Stripped/StrippedCharges/Charge[@stripped_reason = 'Strip Charge: Strip flagged accounts, flagged locations, F.LAB accounts, F.RLAB accounts' and (@stripped_flagged_accounts = 'true' or @stripped_flagged_locations = 'true')]">
          <XCSExcelRow>
            <Partition>
              <xsl:value-of select="$Partition" />
            </Partition>
            <Interface_Type>
              <xsl:value-of select="$Client" />
            </Interface_Type>
            <Location>
              <xsl:value-of select="PatientDemographics/admLocation" />
            </Location>
            <AccountNumber>
              <xsl:value-of select="PatientDemographics/admAcctNum" />
            </AccountNumber>
            <Patient_Name>
              <xsl:value-of select="PatientDemographics/admname" />
            </Patient_Name>
            <DOS>
              <xsl:value-of select="PatientDemographics/absAdmitdate" />
            </DOS>
            <Units>
              <xsl:value-of select="Charge/radNumOfTimes" />
            </Units>
            <CDM>
              <xsl:variable name="CDM" select="Charge/radExamBillingCode[1]" />
              <xsl:choose>
                <xsl:when test="string-length($CDM) &gt; 0">
                  <xsl:value-of select="$CDM" />
                </xsl:when>
                <xsl:otherwise>BLANK</xsl:otherwise>
              </xsl:choose>
            </CDM>
            <CPT>
              <xsl:value-of select="Charge/radExamCPT[1]" />
            </CPT>
          </XCSExcelRow>
        </xsl:for-each>
        <!--<xsl:for-each select="Stripped/StrippedGroups/Group[@stripped = 'true' and @stripped_reason = 'Strip Group: No charge data.']">-->
        <!--<XCSExcelRow>-->
        <!--<Partition>-->
        <!--<xsl:value-of select="$Partition" />-->
        <!--</Partition>-->
        <!--<Interface_Type>-->
        <!--<xsl:value-of select="$Client" />-->
        <!--</Interface_Type>-->
        <!--<Location>-->
        <!--<xsl:value-of select="PatientDemographics/admLocation" />-->
        <!--</Location>-->
        <!--<AccountNumber>-->
        <!--<xsl:value-of select="PatientDemographics/admAcctNum" />-->
        <!--</AccountNumber>-->
        <!--<Patient_Name>-->
        <!--<xsl:value-of select="PatientDemographics/admname" />-->
        <!--</Patient_Name>-->
        <!--<DOS>-->
        <!--<xsl:value-of select="PatientDemographics/absAdmitdate" />-->
        <!--</DOS>-->
        <!--<Units>-->
        <!--<xsl:value-of select="Charge/radNumOfTimes" />-->
        <!--</Units>-->
        <!--<CDM>-->
        <!--<xsl:variable name="CDM" select="Charge/radExamBillingCode[1]" />-->
        <!--<xsl:choose>-->
        <!--<xsl:when test="string-length($CDM) &gt; 0">-->
        <!--<xsl:value-of select="$CDM" />-->
        <!--</xsl:when>-->
        <!--<xsl:otherwise>BLANK</xsl:otherwise>-->
        <!--</xsl:choose>-->
        <!--</CDM>-->
        <!--<CPT>-->
        <!--<xsl:value-of select="Charge/radExamCPT[1]" />-->
        <!--</CPT>-->
        <!--</XCSExcelRow>-->
        <!--</xsl:for-each>-->
      </XCSExcelSheet>
      <XCSExcelSheet name="FLAB_Stripped_Accounts">
        <XCSExcelRow>
          <admAcctNum>admAcctNum</admAcctNum>
          <admName>admName</admName>
          <admLocation>admLocation</admLocation>
          <Filler2>Filler2</Filler2>
        </XCSExcelRow>
        <xsl:for-each select="Stripped/StrippedDemographics/PatientDemographics[@stripped_both_accounts = 'true' and ./admLocation = 'F.LAB']">
          <XCSExcelRow>
            <admAcctNum>
              <xsl:value-of select="admAcctNum" />
            </admAcctNum>
            <admName>
              <xsl:value-of select="admname" />
            </admName>
            <admLocation>
              <xsl:value-of select="admLocation" />
            </admLocation>
            <Filler2>
              <xsl:value-of select="Filler2" />
            </Filler2>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
      <XCSExcelSheet name="FRLAB_Stripped_Accounts">
        <XCSExcelRow>
          <admAcctNum>admAcctNum</admAcctNum>
          <admName>admName</admName>
          <admLocation>admLocation</admLocation>
          <Filler2>Filler2</Filler2>
        </XCSExcelRow>
        <xsl:for-each select="Stripped/StrippedDemographics/PatientDemographics[@stripped_both_accounts = 'true' and ./admLocation = 'F.RLAB']">
          <XCSExcelRow>
            <admAcctNum>
              <xsl:value-of select="admAcctNum" />
            </admAcctNum>
            <admName>
              <xsl:value-of select="admname" />
            </admName>
            <admLocation>
              <xsl:value-of select="admLocation" />
            </admLocation>
            <Filler2>
              <xsl:value-of select="Filler2" />
            </Filler2>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
      <XCSExcelSheet name="Stripped_Both_Locations">
        <XCSExcelRow>
          <admAcctNum>admAcctNum</admAcctNum>
          <admName>admName</admName>
          <admLocation>admLocation</admLocation>
          <Filler2>Filler2</Filler2>
        </XCSExcelRow>
        <xsl:for-each select="Stripped/StrippedDemographics/PatientDemographics[@stripped_both_accounts = 'true' and @stripped_reason='Strip Demographics: Filter primary and secondary locations for patient demographic data']">
          <XCSExcelRow>
            <admAcctNum>
              <xsl:value-of select="admAcctNum" />
            </admAcctNum>
            <admName>
              <xsl:value-of select="admname" />
            </admName>
            <admLocation>
              <xsl:value-of select="admLocation" />
            </admLocation>
            <Filler2>
              <xsl:value-of select="Filler2" />
            </Filler2>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
      <XCSExcelSheet name="Stripped_Performing_Site_Locations">
        <XCSExcelRow>
          <DateOfService>DateOfService</DateOfService>
          <AccountNumber>AccountNumber</AccountNumber>
          <PatientName>PatientName</PatientName>
          <PerformingSite>PerformingSite</PerformingSite>
          <CPT>CPT</CPT>
          <Units>Units</Units>
        </XCSExcelRow>
        <xsl:for-each select="Stripped/StrippedCharges/Charge[@stripped = 'true' and @stripped_reason='Strip Charge: Strip performing site locations']">
          <XCSExcelRow>
            <DateOfService>
              <xsl:value-of select="Charge/radExamServDate" />
            </DateOfService>
            <AccountNumber>
              <xsl:value-of select="Charge/radAcctNum" />
            </AccountNumber>
            <PatientName>
              <xsl:value-of select="Charge/radPatientName" />
            </PatientName>
            <PerformingSite>
              <xsl:value-of select="Charge/performingSite" />
            </PerformingSite>
            <CPT>
              <xsl:value-of select="Charge/radExamBillingCode" />
            </CPT>
            <Units>
              <xsl:value-of select="Charge/radNumOfTimes" />
            </Units>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
      <xsl:if test="$Partition = 'NHL' and $Client = 'SPG'">
        <XCSExcelSheet name="Voided or Deleted">
          <XCSExcelRow>
            <DateOfService>DateOfService</DateOfService>
            <AccountNumber>AccountNumber</AccountNumber>
            <PatientName>PatientName</PatientName>
            <PerformingSite>ChargeStatus</PerformingSite>
            <CPT>CPT</CPT>
            <Units>Units</Units>
          </XCSExcelRow>
          <xsl:for-each select="Stripped/StrippedCharges/Charge[@stripped = 'true' and @stripped_reason='Strip Charge: Strip charge status voided or deleted']">
            <XCSExcelRow>
              <DateOfService>
                <xsl:value-of select="Charge/radExamServDate" />
              </DateOfService>
              <AccountNumber>
                <xsl:value-of select="Charge/radAcctNum" />
              </AccountNumber>
              <PatientName>
                <xsl:value-of select="Charge/radPatientName" />
              </PatientName>
              <PerformingSite>
                <xsl:value-of select="Charge/chargeStatus" />
              </PerformingSite>
              <CPT>
                <xsl:value-of select="Charge/radExamBillingCode" />
              </CPT>
              <Units>
                <xsl:value-of select="Charge/radNumOfTimes" />
              </Units>
            </XCSExcelRow>
          </xsl:for-each>
        </XCSExcelSheet>
      </xsl:if>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

