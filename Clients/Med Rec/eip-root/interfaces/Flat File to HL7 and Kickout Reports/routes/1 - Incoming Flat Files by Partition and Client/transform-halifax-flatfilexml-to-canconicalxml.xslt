<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:pf="http://pilotfishtechnology.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="dtFormatter" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Unknown />
        <Header>
          <FacilityName>Halifax Med Ctr</FacilityName>
        </Header>
      </Group>
      <!-- Process each Group element from the input -->
      <xsl:for-each select="//Group">
        <Group key="{@key}">
          <!-- Patient Demographics -->
          <PatientDemographics>
            <absadmitdiag>
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_DIAGNOSIS_CODE" />
            </absadmitdiag>
            <admpatstate>
              <!--ALREADY STATE CODE ABBR-->
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_STATE" />
            </admpatstate>
            <absAdmitdate>
              <xsl:variable name="AdmitDate">
                <xsl:choose>
                  <xsl:when test="string-length(Demographics/XCSRecord[1]/ADM_DATE_TIME) != 10">
                    <!--WE KNOW WE NEED TO PAD WITH ZERO-->
                    <xsl:value-of select="pf:padDate(Demographics/XCSRecord[1]/ADM_DATE)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="Demographics/XCSRecord[1]/ADM_DATE" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:if test="string-length($AdmitDate) != 0 and not(contains($AdmitDate,'NaN'))">
                <xsl:if test="string-length(translate($AdmitDate, '/', '')) != 0">
                  <xsl:value-of select="dtFormatter:format(translate($AdmitDate, '/', ''),'MMddyyyy','yyyyMMdd')" />
                </xsl:if>
              </xsl:if>
            </absAdmitdate>
            <absattendingdocupin />
            <absdischargedate>
              <xsl:variable name="DischargeDate">
                <xsl:choose>
                  <xsl:when test="string-length(Demographics/XCSRecord[1]/DISCH_DATE_TIME) != 10">
                    <xsl:value-of select="pf:padDate(Demographics/XCSRecord[1]/DISCH_DATE_TIME)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="Demographics/XCSRecord[1]/DISCH_DATE_TIME" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:if test="string-length($DischargeDate) != 0 and not(contains($DischargeDate,'NaN'))">
                <xsl:if test="string-length(translate($DischargeDate, '/', '')) != 0">
                  <xsl:value-of select="dtFormatter:format(translate($DischargeDate, '/', ''),'MMddyyyy','yyyyMMdd')" />
                </xsl:if>
              </xsl:if>
            </absdischargedate>
            <admemplname />
            <admzipcode>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_ZIP" />
            </admzipcode>
            <absattendingdocmnem />
            <absattendingdocname>
              <xsl:value-of select="Demographics/XCSRecord[1]/ATTEND_PROV_NAME" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="Demographics/XCSRecord[1]/HSP_CSN" />
            </admAcctNum>
            <admbirthdate>
              <xsl:variable name="PatDOB">
                <xsl:choose>
                  <xsl:when test="string-length(Demographics/XCSRecord[1]/PAT_DOB) != 10">
                    <!--WE KNOW WE NEED TO PAD WITH ZERO-->
                    <xsl:value-of select="pf:padDate(Demographics/XCSRecord[1]/PAT_DOB)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="Demographics/XCSRecord[1]/PAT_DOB" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:if test="string-length($PatDOB) != 0 and not(contains($PatDOB,'NaN'))">
                <xsl:choose>
                  <xsl:when test="contains($PatDOB, '-')">
                    <xsl:value-of select="translate($PatDOB, '-', '')" />
                  </xsl:when>
                  <xsl:when test="string-length(translate($PatDOB, '/', '')) != 0">
                    <xsl:value-of select="dtFormatter:format(translate($PatDOB, '/', ''), 'MMddyyyy', 'yyyyMMdd')" />
                  </xsl:when>
                </xsl:choose>
              </xsl:if>
            </admbirthdate>
            <admLocation>
              <xsl:variable name="deptAbbr" select="Demographics/XCSRecord[1]/DEPARTMENT_ABBR" />
              <xsl:variable name="locationAbbr" select="Demographics/XCSRecord[1]/LOCATION_ABBR" />
              <xsl:choose>
                <xsl:when test="$locationAbbr = 'EMSHM' and $deptAbbr = 'ND FSED ED'">
                  <xsl:value-of select="'HED'" />
                </xsl:when>
                <xsl:when test="$locationAbbr = 'EMSHM' and $deptAbbr = 'PO FSED ED'">
                  <xsl:value-of select="'PXE'" />
                </xsl:when>
                <xsl:when test="$locationAbbr = 'HMC'">
                  <xsl:value-of select="'HAX'" />
                </xsl:when>
                <xsl:when test="$locationAbbr = 'MCD'">
                  <xsl:value-of select="'DEX'" />
                </xsl:when>
                <xsl:when test="$locationAbbr = 'HPO'">
                  <xsl:value-of select="'POX'" />
                </xsl:when>
                <xsl:when test="$locationAbbr = 'EMSHC'">
                  <xsl:value-of select="'PXE'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'HAX'" />
                </xsl:otherwise>
              </xsl:choose>
            </admLocation>
            <admpatsex>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_SEX" />
            </admpatsex>
            <admpatphone>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_HOME_PHONE" />
            </admpatphone>
            <admssn>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_SSN" />
            </admssn>
            <admname>
              <xsl:value-of select="Demographics/XCSRecord[1]/HSP_ACCOUNT_NAME" />
            </admname>
            <admemplcity />
            <admpatcity>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_CITY" />
            </admpatcity>
            <admFinClass>
              <xsl:value-of select="Demographics/XCSRecord[1]/ACCT_FIN_CLASS" />
            </admFinClass>
            <AttendDrNPI>
              <xsl:value-of select="Demographics/XCSRecord[1]/ATTENDING_PROV_NPI" />
            </AttendDrNPI>
            <absPatientUnit />
            <admpatienttype>
              <xsl:variable name="class" select="Demographics/XCSRecord[1]/PAT_CLASS" />
              <xsl:value-of select="substring($class,0,23)" />
              <!--<xsl:choose>-->
              <!--<xsl:when test="$baseClass = ('Billing Encounter','Erroneous Encounter','Lab Requisition','Outpatient','Outpatient Surgery','Pre-Admission Testing','Treatment Series','Radiation/Oncology Series')">-->
              <!--<xsl:value-of select="'O'" />-->
              <!--</xsl:when>-->
              <!--<xsl:when test="$baseClass = ('Inpatient','Inpatient Psych','Inpatient Rehab','Newborn','Observation','Surgery Admit','Hospice - Inpatient')">-->
              <!--<xsl:value-of select="'I'" />-->
              <!--</xsl:when>-->
              <!--<xsl:when test="$baseClass = ('Emergency')">-->
              <!--<xsl:value-of select="'E'" />-->
              <!--</xsl:when>-->
              <!--<xsl:otherwise>-->
              <!--<xsl:value-of select="'NA'" />-->
              <!--</xsl:otherwise>-->
              <!--</xsl:choose>-->
            </admpatienttype>
            <admstreet>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_STREET" />
            </admstreet>
            <admstreet2>
              <xsl:value-of select="Demographics/XCSRecord[1]/PAT_STREET_2" />
            </admstreet2>
            <admemplzip />
            <ChiefComplaint />
            <admaccidentdate />
            <Filler2 />
            <admmaritalstatus>
              <xsl:variable name="status" select="Demographics/XCSRecord[1]/PAT_MARITAL_STAT" />
              <xsl:choose>
                <xsl:when test="$status = 'Divorced'">
                  <xsl:value-of select="'D'" />
                </xsl:when>
                <xsl:when test="$status = 'Married'">
                  <xsl:value-of select="'M'" />
                </xsl:when>
                <xsl:when test="$status = 'Separated'">
                  <xsl:value-of select="'X'" />
                </xsl:when>
                <xsl:when test="$status = 'Significant Other'">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$status = 'Single'">
                  <xsl:value-of select="'S'" />
                </xsl:when>
                <xsl:when test="$status = 'Unknown'">
                  <xsl:value-of select="'U'" />
                </xsl:when>
                <xsl:when test="$status = 'Widowed'">
                  <xsl:value-of select="'W'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'U'" />
                </xsl:otherwise>
              </xsl:choose>
            </admmaritalstatus>
          </PatientDemographics>
          <!-- Process each charge record in the group -->
          <xsl:for-each select="Charges/XCSRecord[QUANTITY]">
            <Charge>
              <radNumOfTimes>
                <xsl:value-of select="QUANTITY" />
              </radNumOfTimes>
              <radExamServDate>
                <xsl:variable name="ServiceDateVal" select="SERVICE_DATE" />
                <xsl:if test="string-length(translate($ServiceDateVal, '/', '')) != 0">
                  <xsl:variable name="CollectionDate">
                    <xsl:choose>
                      <xsl:when test="string-length($ServiceDateVal) != 10">
                        <!--WE KNOW WE NEED TO PAD WITH ZERO-->
                        <xsl:value-of select="pf:padDate($ServiceDateVal)" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$ServiceDateVal" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:if test="string-length($CollectionDate) != 0 and not(contains($CollectionDate,'NaN'))">
                    <xsl:value-of select="dtFormatter:format(translate($CollectionDate, '/', ''),'MMddyyyy','yyyyMMdd')" />
                  </xsl:if>
                </xsl:if>
              </radExamServDate>
              <radPatientName>
                <xsl:value-of select="HSP_ACCOUNT_NAME" />
              </radPatientName>
              <radAcctNum>
                <xsl:value-of select="HSP_CSN" />
              </radAcctNum>
              <radExamBillingCode>
                <xsl:value-of select="CPT_CODE" />
              </radExamBillingCode>
              <CDM>
                <xsl:value-of select="*[local-name()='PROC_CODE_CDM']" />
              </CDM>
              <radExamCPT>
                <xsl:value-of select="CPT_CODE" />
              </radExamCPT>
              <examdesc>
                <xsl:value-of select="PROCEDUREDESCRIPTION" />
              </examdesc>
              <radOrderingPhyLic>
                <xsl:value-of select="BILLINGPROVIDERNPI" />
              </radOrderingPhyLic>
              <absPatientUnit />
              <radOrderingPhyMne>
                <xsl:value-of select="BILLINGPROVIDERNAME" />
              </radOrderingPhyMne>
              <ExamHCPCCode />
              <orderingDrNPI>
                <xsl:value-of select="BILLINGPROVIDERNPI" />
              </orderingDrNPI>
              <misOrderingPhyCity />
              <radOrderingPhyUPIN />
              <misOrderingPhyName>
                <xsl:value-of select="BILLINGPROVIDERNAME" />
              </misOrderingPhyName>
              <misOrderingPhyAddr />
            </Charge>
          </xsl:for-each>
          <!-- Guarantor Information -->
          <Guarantor>
            <admGuarCity>
              <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_CITY" />
            </admGuarCity>
            <admGuarEmployer />
            <admGuarAddr1>
              <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_STREET" />
            </admGuarAddr1>
            <admGuarAddr2>
              <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_STREET_2" />
            </admGuarAddr2>
            <admGuarHomePhone>
              <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_HOME_PHONE" />
            </admGuarHomePhone>
            <admGuarZip>
              <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_ZIP" />
            </admGuarZip>
            <admPatientUnit />
            <admGuarEmplCity />
            <admGuarEmplState />
            <admGuarEmplZip />
            <admGuarRel>
              <xsl:variable name="guarRel" select="Demographics/XCSRecord[1]/GUAR_RELATION" />
              <xsl:value-of select="substring(upper-case($guarRel),1,2)" />
            </admGuarRel>
            <admGuarName>
              <xsl:choose>
                <xsl:when test="not(contains(Demographics/XCSRecord[1]/GUAR_NAME,','))">
                  <xsl:choose>
                    <xsl:when test="string-length(Demographics/XCSRecord[1]/GUAR_NAME) != 0">
                      <xsl:value-of select="concat(',',Demographics/XCSRecord[1]/GUAR_NAME)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="''" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_NAME" />
                </xsl:otherwise>
              </xsl:choose>
            </admGuarName>
            <npr1 />
            <admGuarState>
              <xsl:value-of select="pf:GetStateAbbreviation(Demographics/XCSRecord[1]/GUAR_STATE)" />
            </admGuarState>
            <admAcctNum />
            <admGuarEmplAddr1 />
            <admGuarSSN>
              <xsl:value-of select="Demographics/XCSRecord[1]/GUAR_SSN" />
            </admGuarSSN>
            <admGuarEmplPhone />
          </Guarantor>
          <!-- Diagnosis Codes -->
          <DiagnosisCodes>
            <xsl:if test="Demographics/XCSRecord[1]/PRIM_DIAGNOSIS_CODE">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_DIAGNOSIS_CODE" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_1">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_1" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_2">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_2" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_3">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_3" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_4">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_4" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_5">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_5" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_6">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_6" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_7">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_7" />
              </Diag>
            </xsl:if>
            <xsl:if test="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_8">
              <Diag>
                <xsl:value-of select="Demographics/XCSRecord[1]/SECONDARY_DIAG_CODE_8" />
              </Diag>
            </xsl:if>
          </DiagnosisCodes>
          <!-- Insurance Information -->
          <Insurance1>
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation(Demographics/XCSRecord[1]/PRIM_COV_STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_COV_SUBSCR_POLICY_NUM" />
            </adminspolicy>
            <subscribername>
              <xsl:variable name="subscriberFullName" select="Demographics/XCSRecord[1]/PRIM_COV_SUBSCR_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </subscribername>
            <adminszip>
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_COV_ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:choose>
                <xsl:when test="Demographics/XCSRecord[1]/PRIM_PAYOR_NAME = 'Not Applicable' or Demographics/XCSRecord[1]/PRIM_PAYOR_NAME = 'Self-Pay'">
                  <xsl:value-of select="''" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_PAYOR_NAME" />
                </xsl:otherwise>
              </xsl:choose>
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:variable name="subscriberRel" select="Demographics/XCSRecord[1]/PRIM_COV_REL_TO_SUB" />
              <xsl:choose>
                <xsl:when test="$subscriberRel = '1' or $subscriberRel = '01'">
                  <xsl:value-of select="'SE'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$subscriberRel" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_COV_STREET" />
            </adminsstreet>
            <admingroup>
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_COV_GROUP_NUM" />
            </admingroup>
            <adminscity>
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_COV_CITY" />
            </adminscity>
            <adminsmne>
              <xsl:choose>
                <xsl:when test="string-length(Demographics/XCSRecord[1]/PRIMARY_PLAN_ID) != 0 and Demographics/XCSRecord[1]/PRIMARY_PLAN_ID != 'Self-Pay'">
                  <xsl:value-of select="Demographics/XCSRecord[1]/PRIMARY_PLAN_ID" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'BLANK'" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="Demographics/XCSRecord[1]/PRIM_COV_SUBSCR_NAME" />
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
              <xsl:value-of select="Demographics/XCSRecord[1]/PRIM_COV_PHONE" />
            </admInsPhone>
            <authnumber>
              <xsl:value-of select="Demographics/XCSRecord[1]/AUTHORIZATION_NUMBER" />
            </authnumber>
          </Insurance1>
          <Insurance2>
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation(Demographics/XCSRecord[1]/SEC_COV_STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_COV_SUBSCR_NUM" />
            </adminspolicy>
            <subscribername>
              <xsl:variable name="subscriberFullName" select="Demographics/XCSRecord[1]/SEC_COV_SUBSCR_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </subscribername>
            <adminszip>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_COV_ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_PAYOR_NAME" />
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:variable name="secondarySubscriberRel" select="Demographics/XCSRecord[1]/SEC_COV_REL_TO_SUB" />
              <xsl:choose>
                <xsl:when test="$secondarySubscriberRel = '1' or $secondarySubscriberRel = '01'">
                  <xsl:value-of select="'SE'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$secondarySubscriberRel" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_COV_STREET" />
            </adminsstreet>
            <admingroup>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_COV_GROUP_NUM" />
            </admingroup>
            <adminscity>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_COV_CITY" />
            </adminscity>
            <adminsmne>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_PLAN_ID" />
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="Demographics/XCSRecord[1]/SEC_COV_SUBSCR_NAME" />
              <!--<xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />-->
              <xsl:value-of select="$subscriberFullName" />
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="Demographics/XCSRecord[1]/SEC_COV_PHONE" />
            </admInsPhone>
          </Insurance2>
          <Insurance3>
            <admAcctNum />
            <absPatientUnit />
          </Insurance3>
        </Group>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
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
  <xsl:function as="xs:string" name="pf:padDate">
    <xsl:param as="xs:string" name="date" />
    <xsl:variable name="parts" select="tokenize($date, '/')" />
    <xsl:value-of select="concat(format-number(number($parts[1]), '00'),'/',format-number(number($parts[2]),'00'),'/',$parts[3])" />
  </xsl:function>
</xsl:stylesheet>

