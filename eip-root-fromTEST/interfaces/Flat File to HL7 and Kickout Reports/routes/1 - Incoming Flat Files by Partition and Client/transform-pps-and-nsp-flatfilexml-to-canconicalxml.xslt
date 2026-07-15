<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:pf="http://pilotfishtechnology.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="dtFormatter" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <xsl:param name="PartitionName" />
  <xsl:param name="FacilityCode" />
  <!-- Build a key on Charges by HSP_FIN so we can match them to Demographics records efficiently -->
  <xsl:key match="/XCSData/Charges/XCSData/XCSRecord" name="chargesByFin" use="HSP_FIN" />
  <!-- Indexes used to "borrow" an insurance address from another source row that has the same
       payor and a populated address. The match filters rows down to only those that already have
       a street, so the first hit returned by key() is guaranteed to be a usable donor row. -->
  <xsl:key match="/XCSData/Demographics/XCSData/XCSRecord[normalize-space(PRIM_COV_STREET) != '']" name="primCovByPayor" use="normalize-space(PRIMARY_PAYOR_ID)" />
  <xsl:key match="/XCSData/Demographics/XCSData/XCSRecord[normalize-space(SEC_COV_STREET) != '']" name="secCovByPayor" use="normalize-space(SEC_PAYOR_ID)" />
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Unknown />
        <Header>
          <FacilityName>
            <xsl:value-of select="$PartitionName" />
          </FacilityName>
        </Header>
      </Group>
      <!-- Process each Demographics record from the input -->
      <xsl:for-each select="/XCSData/Demographics/XCSData/XCSRecord">
        <xsl:variable name="hspFin" select="HSP_FIN" />
        <Group key="{$hspFin}">
          <!-- Patient Demographics -->
          <PatientDemographics>
            <absadmitdiag>
              <xsl:value-of select="PRIM_DIAGNOSIS_CODE" />
            </absadmitdiag>
            <admpatstate>
              <!--ALREADY STATE CODE ABBR-->
              <xsl:value-of select="PAT_STATE" />
            </admpatstate>
            <absAdmitdate>
              <xsl:choose>
                <xsl:when test="string-length(normalize-space(ADM_DATE)) != 0">
                  <xsl:value-of select="pf:isoDate(ADM_DATE)" />
                </xsl:when>
                <xsl:otherwise>
                  <!--No admit date: fall back to the earliest service date among this patient's charges-->
                  <xsl:value-of select="min(for $charge in key('chargesByFin', $hspFin)[string-length(normalize-space(SERVICE_DATE)) != 0] return pf:isoDate($charge/SERVICE_DATE))" />
                </xsl:otherwise>
              </xsl:choose>
            </absAdmitdate>
            <absattendingdocupin />
            <absdischargedate>
              <xsl:value-of select="pf:isoDate(DISCH_DATE_TIME)" />
            </absdischargedate>
            <admemplname />
            <admzipcode>
              <xsl:value-of select="PAT_ZIP" />
            </admzipcode>
            <absattendingdocmnem />
            <absattendingdocname>
              <xsl:value-of select="ATTEND_PROV_NAME" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="HSP_FIN" />
            </admAcctNum>
            <admbirthdate>
              <xsl:value-of select="pf:isoDate(PAT_DOB)" />
            </admbirthdate>
            <admLocation>
              <xsl:value-of select="$FacilityCode" />
            </admLocation>
            <admpatsex>
              <xsl:value-of select="PAT_SEX" />
            </admpatsex>
            <admpatphone>
              <xsl:value-of select="PAT_HOME_PHONE" />
            </admpatphone>
            <admssn>
              <xsl:value-of select="PAT_SSN" />
            </admssn>
            <admname>
              <xsl:value-of select="HSP_ACCOUNT_NAME" />
            </admname>
            <admemplcity />
            <admpatcity>
              <xsl:value-of select="PAT_CITY" />
            </admpatcity>
            <admFinClass>
              <xsl:value-of select="ACCT_FIN_CLASS" />
            </admFinClass>
            <AttendDrNPI>
              <xsl:value-of select="ATTENDING_PROV_NPI" />
            </AttendDrNPI>
            <absPatientUnit />
            <admpatienttype>
              <xsl:variable name="class" select="PAT_CLASS" />
              <xsl:value-of select="substring($class,0,23)" />
            </admpatienttype>
            <admstreet>
              <xsl:value-of select="PAT_STREET" />
            </admstreet>
            <admstreet2>
              <xsl:value-of select="PAT_STREET_2" />
            </admstreet2>
            <admemplzip />
            <ChiefComplaint />
            <admaccidentdate />
            <Filler2 />
            <admmaritalstatus>
              <xsl:variable name="status" select="normalize-space(PAT_MARITAL_STAT)" />
              <xsl:choose>
                <!--Source values are already single-letter Epic codes-->
                <xsl:when test="$status = 'D' or $status = 'Divorced'">
                  <xsl:value-of select="'D'" />
                </xsl:when>
                <xsl:when test="$status = 'M' or $status = 'Married'">
                  <xsl:value-of select="'M'" />
                </xsl:when>
                <xsl:when test="$status = 'X' or $status = 'Separated'">
                  <xsl:value-of select="'X'" />
                </xsl:when>
                <xsl:when test="$status = 'P' or $status = 'Significant Other'">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$status = 'S' or $status = 'Single'">
                  <xsl:value-of select="'S'" />
                </xsl:when>
                <xsl:when test="$status = 'U' or $status = 'Unknown'">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$status = 'W' or $status = 'Widowed'">
                  <xsl:value-of select="'W'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'U'" />
                </xsl:otherwise>
              </xsl:choose>
            </admmaritalstatus>
          </PatientDemographics>
          <!-- Process each charge record that matches this Demographics record by HSP_FIN -->
          <xsl:for-each select="key('chargesByFin', $hspFin)[QUANTITY]">
            <Charge>
              <radNumOfTimes>
                <xsl:value-of select="QUANTITY" />
              </radNumOfTimes>
              <radExamServDate>
                <xsl:value-of select="pf:isoDate(SERVICE_DATE)" />
              </radExamServDate>
              <radPatientName>
                <xsl:value-of select="HSP_ACCOUNT_NAME" />
              </radPatientName>
              <radAcctNum>
                <xsl:value-of select="HSP_FIN" />
              </radAcctNum>
              <radExamBillingCode>
                <xsl:value-of select="PROC_CODE__CDM_" />
              </radExamBillingCode>
              <CDM>
                <xsl:value-of select="PROC_CODE__CDM_" />
              </CDM>
              <radExamCPT>
                <xsl:value-of select="CPT_CODE" />
              </radExamCPT>
              <examdesc />
              <radOrderingPhyLic>
                <xsl:value-of select="PATH_NPI" />
              </radOrderingPhyLic>
              <absPatientUnit />
              <radOrderingPhyMne>
                <xsl:value-of select="PATH_NAME" />
              </radOrderingPhyMne>
              <ExamHCPCCode />
              <orderingDrNPI>
                <xsl:value-of select="PATH_NPI" />
              </orderingDrNPI>
              <misOrderingPhyCity />
              <radOrderingPhyUPIN />
              <misOrderingPhyName>
                <xsl:value-of select="PATH_NAME" />
              </misOrderingPhyName>
              <misOrderingPhyAddr />
              <specimenNo>
                <xsl:value-of select="ACCESSION_NUMBER" />
              </specimenNo>
              <pathologist>
                <xsl:value-of select="PATH_NAME" />
              </pathologist>
            </Charge>
          </xsl:for-each>
          <!-- Guarantor Information -->
          <Guarantor>
            <admGuarCity>
              <xsl:value-of select="GUAR_CITY" />
            </admGuarCity>
            <admGuarEmployer />
            <admGuarAddr1>
              <xsl:value-of select="GUAR_STREET" />
            </admGuarAddr1>
            <admGuarAddr2>
              <xsl:value-of select="GUAR_STREET_2" />
            </admGuarAddr2>
            <admGuarHomePhone>
              <xsl:value-of select="GUAR_HOME_PHONE" />
            </admGuarHomePhone>
            <admGuarZip>
              <xsl:value-of select="GUAR_ZIP" />
            </admGuarZip>
            <admPatientUnit />
            <admGuarEmplCity />
            <admGuarEmplState />
            <admGuarEmplZip />
            <admGuarRel>
              <xsl:variable name="guarRel" select="GUAR_RELATION" />
              <xsl:value-of select="substring(upper-case($guarRel),1,2)" />
            </admGuarRel>
            <admGuarName>
              <xsl:choose>
                <xsl:when test="not(contains(GUAR_NAME,','))">
                  <xsl:choose>
                    <xsl:when test="string-length(GUAR_NAME) != 0">
                      <xsl:value-of select="concat(',',GUAR_NAME)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="''" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="GUAR_NAME" />
                </xsl:otherwise>
              </xsl:choose>
            </admGuarName>
            <npr1 />
            <admGuarState>
              <xsl:value-of select="pf:GetStateAbbreviation(GUAR_STATE)" />
            </admGuarState>
            <admAcctNum />
            <admGuarEmplAddr1 />
            <admGuarSSN>
              <xsl:value-of select="GUAR_SSN" />
            </admGuarSSN>
            <admGuarEmplPhone />
          </Guarantor>
          <!-- Diagnosis Codes -->
          <DiagnosisCodes>
            <xsl:if test="string-length(PRIM_DIAGNOSIS_CODE) != 0">
              <Diag>
                <xsl:value-of select="PRIM_DIAGNOSIS_CODE" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_1) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_1" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_2) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_2" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_3) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_3" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_4) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_4" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_5) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_5" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_6) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_6" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_7) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_7" />
              </Diag>
            </xsl:if>
            <xsl:if test="string-length(SECONDARY_DIAG_CODE_8) != 0">
              <Diag>
                <xsl:value-of select="SECONDARY_DIAG_CODE_8" />
              </Diag>
            </xsl:if>
          </DiagnosisCodes>
          <!-- Insurance Information -->
          <Insurance1>
            <!--Pick the row to source the insurance address fields from. Use this row when it has
                a non-blank street; otherwise borrow from another source row with the same payor.-->
            <xsl:variable as="element()?" name="primAddrSource" select="if (string-length(normalize-space(PRIM_COV_STREET)) != 0) then . else if (string-length(normalize-space(PRIMARY_PAYOR_ID)) != 0) then key('primCovByPayor', normalize-space(PRIMARY_PAYOR_ID))[1] else ()" />
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation($primAddrSource/PRIM_COV_STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="PRIM_COV_SUBSCR_POLICY_NUM" />
            </adminspolicy>
            <subscribername>
              <!--Fall back to the patient name for self-pay/empty-subscriber accounts-->
              <xsl:choose>
                <xsl:when test="string-length(normalize-space(PRIM_COV_SUBSCR_NAME)) != 0">
                  <xsl:value-of select="PRIM_COV_SUBSCR_NAME" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="HSP_ACCOUNT_NAME" />
                </xsl:otherwise>
              </xsl:choose>
            </subscribername>
            <adminszip>
              <xsl:value-of select="$primAddrSource/PRIM_COV_ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:choose>
                <!--Only truly-absent coverage is blanked; Self Pay must flow through so an
                    IN1 segment is still generated for self-pay primary accounts.-->
                <xsl:when test="PRIM_PAYOR_NAME = 'Not Applicable'">
                  <xsl:value-of select="''" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="PRIM_PAYOR_NAME" />
                </xsl:otherwise>
              </xsl:choose>
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:variable name="subscriberRel" select="normalize-space(PRIM_COV_REL_TO_SUB_ID)" />
              <xsl:variable name="subscriberRelText" select="normalize-space(PRIM_COV_REL_TO_SUB)" />
              <xsl:choose>
                <xsl:when test="$subscriberRel = 'SP' or $subscriberRel = '1' or $subscriberRel = '01' or starts-with($subscriberRelText, 'Self')">
                  <xsl:value-of select="'SE'" />
                </xsl:when>
                <xsl:when test="string-length($subscriberRel) != 0">
                  <xsl:value-of select="$subscriberRel" />
                </xsl:when>
                <xsl:otherwise>
                  <!--Default to self for self-pay/empty-relationship accounts-->
                  <xsl:value-of select="'SE'" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="$primAddrSource/PRIM_COV_STREET" />
            </adminsstreet>
            <admingroup>
              <xsl:value-of select="PRIM_COV_GROUP_NUM" />
            </admingroup>
            <adminscity>
              <xsl:value-of select="$primAddrSource/PRIM_COV_CITY" />
            </adminscity>
            <adminsmne>
              <xsl:choose>
                <xsl:when test="string-length(PRIMARY_PLAN_ID) != 0 and PRIMARY_PLAN_ID != 'Self-Pay' and PRIMARY_PLAN_ID != 'SP'">
                  <xsl:value-of select="PRIMARY_PLAN_ID" />
                </xsl:when>
                <!--Self-pay primary: emit the SP mnemonic (instead of 'BLANK') so the
                    downstream HL7 generator still produces an IN1 segment.-->
                <xsl:when test="PRIMARY_PLAN_ID = 'SP' or PRIMARY_PLAN_ID = 'Self-Pay' or PRIM_PAYOR_NAME = 'Self Pay' or PRIM_PAYOR_NAME = 'Self-Pay'">
                  <xsl:value-of select="'SP'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'BLANK'" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="PRIM_COV_SUBSCR_NAME" />
              <xsl:choose>
                <xsl:when test="string-length($subscriberFullName) = 0">
                  <xsl:value-of select="HSP_ACCOUNT_NAME" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$subscriberFullName" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="PRIM_COV_PHONE" />
            </admInsPhone>
            <authnumber>
              <xsl:value-of select="AUTHORIZATION_NUMBER" />
            </authnumber>
          </Insurance1>
          <!--Determine self-pay status for both payors. When the secondary payor is self-pay but
                a real (non-self-pay) primary payor exists, the secondary self-pay block is redundant
                and is omitted entirely.-->
          <xsl:variable name="primIsSelfPay" select="normalize-space(PRIM_PAYOR_NAME) = 'Self Pay' or normalize-space(PRIM_PAYOR_NAME) = 'Self-Pay' or normalize-space(PRIM_PAYOR_NAME) = 'Not Applicable' or normalize-space(PRIMARY_PLAN_ID) = 'SP' or normalize-space(PRIMARY_PAYOR_ID) = 'SP'" />
          <xsl:variable name="secIsSelfPay" select="normalize-space(SEC_PAYOR_NAME) = 'Self Pay' or normalize-space(SEC_PAYOR_NAME) = 'Self-Pay' or normalize-space(SEC_PLAN_ID) = 'SP' or normalize-space(SEC_PAYOR_ID) = 'SP'" />
          <xsl:if test="not($secIsSelfPay and not($primIsSelfPay))">
            <Insurance2>
              <!--Subscriber name/relationship fall back to the patient only for self-pay rows
                (avoid fabricating names on real secondary coverage).-->
              <!--Pick the row to source the insurance address fields from. Use this row when it has
                a non-blank street; otherwise borrow from another source row with the same payor.-->
              <xsl:variable as="element()?" name="secAddrSource" select="if (string-length(normalize-space(SEC_COV_STREET)) != 0) then . else if (string-length(normalize-space(SEC_PAYOR_ID)) != 0) then key('secCovByPayor', normalize-space(SEC_PAYOR_ID))[1] else ()" />
              <adminsstate>
                <xsl:value-of select="pf:GetStateAbbreviation($secAddrSource/SEC_COV_STATE)" />
              </adminsstate>
              <adminspolicy>
                <xsl:value-of select="SEC_COV_SUBSCR_NUM" />
              </adminspolicy>
              <subscribername>
                <!--Fall back to the patient name for self-pay/empty-subscriber accounts-->
                <xsl:choose>
                  <xsl:when test="string-length(normalize-space(SEC_COV_SUBSCR_NAME)) != 0">
                    <xsl:value-of select="SEC_COV_SUBSCR_NAME" />
                  </xsl:when>
                  <xsl:when test="$secIsSelfPay">
                    <xsl:value-of select="HSP_ACCOUNT_NAME" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="''" />
                  </xsl:otherwise>
                </xsl:choose>
              </subscribername>
              <adminszip>
                <xsl:value-of select="$secAddrSource/SEC_COV_ZIP" />
              </adminszip>
              <adminsPaCode />
              <absPatientUnit />
              <admInsName>
                <xsl:value-of select="SEC_PAYOR_NAME" />
              </admInsName>
              <admAcctNum />
              <adminsinsuredrel>
                <xsl:variable name="secondarySubscriberRel" select="normalize-space(SEC_COV_REL_TO_SUB_ID)" />
                <xsl:variable name="secondarySubscriberRelText" select="normalize-space(SEC_COV_REL_TO_SUB)" />
                <xsl:choose>
                  <xsl:when test="$secondarySubscriberRel = 'SP' or $secondarySubscriberRel = '1' or $secondarySubscriberRel = '01' or starts-with($secondarySubscriberRelText, 'Self')">
                    <xsl:value-of select="'SE'" />
                  </xsl:when>
                  <xsl:when test="string-length($secondarySubscriberRel) != 0">
                    <xsl:value-of select="$secondarySubscriberRel" />
                  </xsl:when>
                  <xsl:when test="$secIsSelfPay">
                    <!--Default to self for self-pay/empty-relationship accounts-->
                    <xsl:value-of select="'SE'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="''" />
                  </xsl:otherwise>
                </xsl:choose>
              </adminsinsuredrel>
              <adminsstreet>
                <xsl:value-of select="$secAddrSource/SEC_COV_STREET" />
              </adminsstreet>
              <admingroup>
                <xsl:value-of select="SEC_COV_GROUP_NUM" />
              </admingroup>
              <adminscity>
                <xsl:value-of select="$secAddrSource/SEC_COV_CITY" />
              </adminscity>
              <adminsmne>
                <xsl:value-of select="SEC_PLAN_ID" />
              </adminsmne>
              <adminsinsuredname>
                <xsl:choose>
                  <xsl:when test="string-length(normalize-space(SEC_COV_SUBSCR_NAME)) != 0">
                    <xsl:value-of select="SEC_COV_SUBSCR_NAME" />
                  </xsl:when>
                  <xsl:when test="$secIsSelfPay">
                    <xsl:value-of select="HSP_ACCOUNT_NAME" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="''" />
                  </xsl:otherwise>
                </xsl:choose>
              </adminsinsuredname>
              <admInsPhone>
                <xsl:value-of select="SEC_COV_PHONE" />
              </admInsPhone>
            </Insurance2>
          </xsl:if>
          <Insurance3>
            <admAcctNum />
            <absPatientUnit />
          </Insurance3>
        </Group>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <!-- Converts an ISO datetime string (yyyy-MM-dd[ HH:mm:ss[.fffffff]]) into yyyyMMdd.
       Returns an empty string for empty/invalid inputs. -->
  <xsl:function as="xs:string" name="pf:isoDate">
    <xsl:param name="date" />
    <xsl:choose>
      <xsl:when test="string-length($date) &gt;= 10">
        <xsl:value-of select="translate(substring($date, 1, 10), '-', '')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="''" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="pf:GetStateAbbreviation">
    <xsl:param name="StateName" />
    <xsl:choose>
      <xsl:when test="string-length($StateName) != 2">
        <xsl:choose>
          <xsl:when test="$StateName = 'Alabama'">
            <xsl:value-of select="'AL'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Alaska'">
            <xsl:value-of select="'AK'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Arizona'">
            <xsl:value-of select="'AZ'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Arkansas'">
            <xsl:value-of select="'AR'" />
          </xsl:when>
          <xsl:when test="$StateName = 'California'">
            <xsl:value-of select="'CA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Colorado'">
            <xsl:value-of select="'CO'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Connecticut'">
            <xsl:value-of select="'CT'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Delaware'">
            <xsl:value-of select="'DE'" />
          </xsl:when>
          <xsl:when test="$StateName = 'District of Columbia'">
            <xsl:value-of select="'DC'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Florida'">
            <xsl:value-of select="'FL'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Georgia'">
            <xsl:value-of select="'GA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Hawaii'">
            <xsl:value-of select="'HI'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Idaho'">
            <xsl:value-of select="'ID'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Illinois'">
            <xsl:value-of select="'IL'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Indiana'">
            <xsl:value-of select="'IN'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Iowa'">
            <xsl:value-of select="'IA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Kansas'">
            <xsl:value-of select="'KS'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Kentucky'">
            <xsl:value-of select="'KY'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Lousiana'">
            <xsl:value-of select="'LA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Maine'">
            <xsl:value-of select="'ME'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Maryland'">
            <xsl:value-of select="'MD'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Massachusetts'">
            <xsl:value-of select="'MA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Michigan'">
            <xsl:value-of select="'MI'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Minnesota'">
            <xsl:value-of select="'MN'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Mississippi'">
            <xsl:value-of select="'MS'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Missouri'">
            <xsl:value-of select="'MO'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Montana'">
            <xsl:value-of select="'MT'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Nebraska'">
            <xsl:value-of select="'NE'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Nevada'">
            <xsl:value-of select="'NV'" />
          </xsl:when>
          <xsl:when test="$StateName = 'New Hampshire'">
            <xsl:value-of select="'NH'" />
          </xsl:when>
          <xsl:when test="$StateName = 'New Jersey'">
            <xsl:value-of select="'NJ'" />
          </xsl:when>
          <xsl:when test="$StateName = 'New Mexico'">
            <xsl:value-of select="'NM'" />
          </xsl:when>
          <xsl:when test="$StateName = 'New York'">
            <xsl:value-of select="'NY'" />
          </xsl:when>
          <xsl:when test="$StateName = 'North Carolina'">
            <xsl:value-of select="'NC'" />
          </xsl:when>
          <xsl:when test="$StateName = 'North Dakota'">
            <xsl:value-of select="'ND'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Ohio'">
            <xsl:value-of select="'OH'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Oklahoma'">
            <xsl:value-of select="'OK'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Oregon'">
            <xsl:value-of select="'OR'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Pennsylvania'">
            <xsl:value-of select="'PA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Rhode Island'">
            <xsl:value-of select="'RI'" />
          </xsl:when>
          <xsl:when test="$StateName = 'South Carolina'">
            <xsl:value-of select="'SC'" />
          </xsl:when>
          <xsl:when test="$StateName = 'South Dakota'">
            <xsl:value-of select="'SD'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Tennessee'">
            <xsl:value-of select="'TN'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Texas'">
            <xsl:value-of select="'TX'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Utah'">
            <xsl:value-of select="'UT'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Vermont'">
            <xsl:value-of select="'VT'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Virginia'">
            <xsl:value-of select="'VA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Washington'">
            <xsl:value-of select="'WA'" />
          </xsl:when>
          <xsl:when test="$StateName = 'West Virginia'">
            <xsl:value-of select="'WV'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Wisconsin'">
            <xsl:value-of select="'WI'" />
          </xsl:when>
          <xsl:when test="$StateName = 'Wyoming'">
            <xsl:value-of select="'WY'" />
          </xsl:when>
          <xsl:when test="$StateName = ''">
            <xsl:value-of select="''" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="''" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$StateName" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>

