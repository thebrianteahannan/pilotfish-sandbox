<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:pf="http://pilotfishtechnology.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="dtFormatter" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Unknown />
        <Header>
          <FacilityName>NextGen Pathology</FacilityName>
        </Header>
      </Group>
      <!-- Process each Group element from the input -->
      <xsl:for-each select="//XCSRecord">
        <Group>
          <xsl:attribute name="key" select="CSN" />
          <!-- Patient Demographics -->
          <PatientDemographics>
            <absadmitdiag>
              <!--<xsl:value-of select="DIAGNOSIS__1_CODE" />-->
            </absadmitdiag>
            <admpatstate>
              <xsl:value-of select="PATIENT_ADDRESS__STATE" />
            </admpatstate>
            <absAdmitdate>
              <xsl:variable name="AdmitDate">
                <xsl:choose>
                  <xsl:when test="string-length(SVC_DATE) != 10">
                    <xsl:value-of select="pf:padDate(SVC_DATE)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="SVC_DATE" />
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
              <!--THE SECOND DISCHARGE DATE IS THE ONE WE WANT-->
              <xsl:variable name="DischargeDate">
                <xsl:choose>
                  <xsl:when test="string-length(DISCHARGE_DATE[2]) != 10">
                    <!--WE KNOW WE NEED TO PAD WITH ZERO-->
                    <xsl:value-of select="pf:padDate(DISCHARGE_DATE[2])" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="DISCHARGE_DATE[2]" />
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
              <xsl:value-of select="PATIENT_ADDRESS__ZIP" />
            </admzipcode>
            <absattendingdocmnem />
            <absattendingdocname>
              <xsl:value-of select="SERVICE_PROVIDER" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="CSN" />
            </admAcctNum>
            <admbirthdate>
              <xsl:variable name="PatDOB">
                <xsl:choose>
                  <xsl:when test="string-length(PATIENT_DATE_OF_BIRTH) != 10">
                    <xsl:value-of select="pf:padDate(PATIENT_DATE_OF_BIRTH)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="PATIENT_DATE_OF_BIRTH" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:if test="string-length($PatDOB) != 0 and not(contains($PatDOB,'NaN'))">
                <xsl:if test="string-length(translate($PatDOB, '/', '')) != 0">
                  <xsl:value-of select="dtFormatter:format(translate($PatDOB, '/', ''),'MMddyyyy','yyyyMMdd')" />
                </xsl:if>
              </xsl:if>
            </admbirthdate>
            <admLocation>
              <xsl:variable name="Location" select="SPECIMEN_COLLECTION_DEPARTMENT" />
              <xsl:choose>
                <xsl:when test="$Location = 'CC 2N PCU' or $Location = 'CC 4W MEDICAL' or $Location = 'CC 7N SURG/ORTHO' or $Location = 'CC BREAST IMAGING' or $Location = 'CC CARDIAC CATH LAB' or $Location = 'CC EMERGENCY' or $Location = 'CC ENDOSCOPY' or $Location = 'CC IR IMAGING' or $Location = 'CC LAB' or $Location = 'CC MAIN OR' or $Location = 'CC MICU'">
                  <xsl:value-of select="'Cape Canaveral Hospital'" />
                </xsl:when>
                <xsl:when test="$Location = 'HR A3W ONCOLOGY' or $Location = 'HR A4 SURGICAL ICU' or $Location = 'HR A4W PCU' or $Location = 'HR A5E MED/SURG' or $Location = 'HR A5W MED/SURG' or $Location = 'HR A6E MED/SURG' or $Location = 'HR A7E PCU' or $Location = 'HR A7W OBSERVATION' or $Location = 'HR A8W JOINT CENTER/WOMEN''S SURGERY' or $Location = 'HR C3 PCU' or $Location = 'HR CARDIAC CATH LAB' or $Location = 'HR D2 CVICU' or $Location = 'HR D4 MICU' or $Location = 'HR D5 CARDIOVASCULAR PCU' or $Location = 'HR D6 CARDIAC PCU' or $Location = 'HR D7 PCU' or $Location = 'HR D8 NEURO PCU' or $Location = 'HR DIALYSIS' or $Location = 'HR EMERGENCY' or $Location = 'HR ENDOSCOPY' or $Location = 'HR INTER PREP/RECOVERY' or $Location = 'HR LAB' or $Location = 'HR LABOR &amp; DELIVERY' or $Location = 'HR MAIN OR' or $Location = 'HR MOTHER BABY' or $Location = 'HR NURSERY' or $Location = 'HR RHU'">
                  <xsl:value-of select="'Holmes Regional Medical Center'" />
                </xsl:when>
                <xsl:when test="$Location = 'PB 2 SOUTH PCU' or $Location = 'PB 2N TCU' or $Location = 'PB 3 SOUTH MEDSURG' or $Location = 'PB EMERGENCY' or $Location = 'PB ENDOSCOPY' or $Location = 'PB LAB' or $Location = 'PB MAIN OR' or $Location = 'PB MICU' or $Location = 'HFCI PALM BAY LAB'">
                  <xsl:value-of select="'Palm Bay Hospital'" />
                </xsl:when>
                <xsl:when test="$Location = 'VH 2 MAIN OR' or $Location = 'VH 3A MICU' or $Location = 'VH 3B PROGRESSIVE CARE' or $Location = 'VH 4A JOINT CENTER' or $Location = 'VH 4B MED SURG' or $Location = 'VH 5 LABOR &amp; DELIVERY' or $Location = 'VH 5 NURSERY' or $Location = 'VH CT IMAGING' or $Location = 'VH EMERGENCY' or $Location = 'VH ENDOSCOPY' or $Location = 'VH LAB' or $Location = 'VH US IMAGING'  or $Location = 'VIERA MOB LAB' or $Location = 'HFCI VIERA STE 200 HEMATOLOGY ONCOLOGY'">
                  <xsl:value-of select="'Viera Hospital'" />
                </xsl:when>
                <!--SEE YELLOWS IN CROSSWALK SPREADSHEET-->
                <xsl:when test="$Location = 'INTRACOASTAL SURGERY CENTER' or $Location = 'HFMG KNOX MCRAE LAB' or $Location = 'HFMG KNOX MCRAE PRIMARY CARE' or $Location = 'HFMG KNOX MCRAE LAB' or $Location = 'HFMG KNOX MCRAE PRIMARY CARE' or $Location = 'BABCOCK GASTROENTEROLOGY' or $Location = 'GBC BREAST IMAGING' or $Location = 'HFCI MELBOURNE INFUSION' or $Location = 'HFCI MELBOURNE LAB' or $Location = 'HFCI MERRITT ISLAND LAB' or $Location = 'HFMG ELDRON LAB' or $Location = 'HFMG ELDRON UROGYNECOLOGY' or $Location = 'HFMG GATEWAY LAB' or $Location = 'HFMG GATEWAY STE 1D OBGYN' or $Location = 'HFMG GATEWAY STE 1E OTOLARYNGOLOGY' or $Location = 'HFMG GATEWAY STE 2A UROLOGY' or $Location = 'HFMG KNOCK MCRAE LAB' or $Location = 'HFMG KNOCK MCRAE PRIMARY CARE' or $Location = 'HFMG MALABAR LAB' or $Location = 'HFMG MALABAR STE B UROGYNECOLOGY' or $Location = 'HFMG MURRELL LAB' or $Location = 'HFMG MURRELL STE E GYN' or $Location = 'HFMG ROCKLEDGE SQUARE LAB' or $Location = 'HFMG ROCKLEDGE SQUARE STE C UROLOGY' or $Location = 'HFMG SEASIDE LAB' or $Location = 'HFMG SEASIDE PRIMARY CARE' or $Location = 'HFMG VIDINA DRIVE OBGYN' or $Location = 'HFMG VIERA MOB STE 302 UROGYNECOLOGY' or $Location = 'INSTRACOASTAL SURGERY CENTER' or $Location = 'TERRENCE A CRONIN JR' or $Location = 'VIERA MOB BREAST IMAGING' or $Location = 'VIERA MOB NUCLEAR MEDICINE' or $Location = 'CLEVENS FACE AND BODY SPECIALISTS' or $Location = 'GYNECOLOGICAL SPECIALISTS OF BREVARD' or $Location = 'HF FAMILY/INTERNAL MEDICINE' or $Location = 'HF GASTROENTEROLOGY' or $Location = 'HFCI MELBOURNE GYN ONCOLOGY' or $Location = 'HFMG GATEWAY STE 2C B UROLOGY' or $Location = 'HFMG MALABAR STE B UROLOGY' or $Location = 'HFMG SYKES CREEK STE 301 PRIMARY CARE' or $Location = 'INDIGO DERMATOLOGY' or $Location = 'ISLAND MEDICAL CENTER' or $Location = 'MALLETTE FOOT AND ANKLE' or $Location = 'SHADETREE DERMATOLOGY' or $Location = 'SUNRISE ORAL SURGERY' or $Location = 'HFCI VIERA STE 201 INFUSION' or $Location = 'HR CARDIAC ECHO/VASC' or $Location = 'HR CT IMAGING' or $Location = 'HR IR IMAGING' or $Location = 'HR TRAUMA CLINIC' or $Location = 'HR US IMAGING' or $Location = 'PB US IMAGING'">
                  <xsl:value-of select="substring-before(PLACE_OF_SERVICE,' [')" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="substring-before(PLACE_OF_SERVICE,' [')" />
                </xsl:otherwise>
              </xsl:choose>
            </admLocation>
            <admpatsex>
              <xsl:value-of select="PATIENT_SEX" />
            </admpatsex>
            <admpatphone>
              <xsl:value-of select="PATIENT_HOME_PHONE" />
            </admpatphone>
            <admssn>
              <xsl:value-of select="PATIENT_SSN" />
            </admssn>
            <admname>
              <xsl:value-of select="PATIENT_NAME" />
            </admname>
            <admemplcity />
            <admpatcity>
              <xsl:value-of select="PATIENT_ADDRESS__CITY" />
            </admpatcity>
            <admFinClass>
              <xsl:value-of select="CHARGE_FLAG" />
            </admFinClass>
            <AttendDrNPI>
              <xsl:value-of select="SERVICE_PROVIDER_NPI__CER_" />
            </AttendDrNPI>
            <absPatientUnit />
            <admpatienttype>
              <xsl:choose>
                <xsl:when test="contains(PATIENT_CLASS,'Inpatient')">
                  <xsl:value-of select="'Inp'" />
                </xsl:when>
                <xsl:when test="contains(PATIENT_CLASS,'Outpatient')">
                  <xsl:value-of select="'Out'" />
                </xsl:when>
                <xsl:when test="contains(PATIENT_CLASS,'Emergency')">
                  <xsl:value-of select="'Eme'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'NA'" />
                </xsl:otherwise>
              </xsl:choose>
            </admpatienttype>
            <admstreet>
              <xsl:value-of select="PATIENT_ADDRESS__STREET_LINE_1" />
            </admstreet>
            <admstreet2 />
            <admemplzip />
            <ChiefComplaint />
            <admaccidentdate />
            <Filler2 />
            <admmaritalstatus>
              <xsl:variable name="status" select="PATIENT_MARITAL_STATUS" />
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
                  <!--default to U-->
                  <xsl:value-of select="'U'" />
                </xsl:otherwise>
              </xsl:choose>
            </admmaritalstatus>
          </PatientDemographics>
          <!-- Process each charge record in the group -->
          <!--<xsl:for-each select="//XCSRecord[QUANTITY]">-->
          <xsl:if test="UNITS_QUANTITY != 'Quantity' and UNITS_QUANTITY != 'Units/Quantity'">
            <Charge>
              <radNumOfTimes>
                <xsl:value-of select="UNITS_QUANTITY" />
              </radNumOfTimes>
              <radCRDBIndicator>
                <xsl:choose>
                  <xsl:when test="CREDIT_INDICATOR = 'CR'">
                    <xsl:value-of select="'1'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'0'" />
                  </xsl:otherwise>
                </xsl:choose>
              </radCRDBIndicator>
              <radExamServDate>
                <xsl:if test="string-length(translate(SVC_DATE, '/', '')) != 0">
                  <xsl:variable name="CollectionDate">
                    <xsl:choose>
                      <xsl:when test="string-length(SVC_DATE) != 10">
                        <xsl:value-of select="pf:padDate(SVC_DATE)" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="SVC_DATE" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:if test="string-length($CollectionDate) != 0 and not(contains($CollectionDate,'NaN'))">
                    <xsl:value-of select="dtFormatter:format(translate($CollectionDate, '/', ''),'MMddyyyy','yyyyMMdd')" />
                  </xsl:if>
                </xsl:if>
              </radExamServDate>
              <radPatientName>
                <xsl:value-of select="PATIENT_NAME" />
              </radPatientName>
              <radAcctNum>
                <xsl:value-of select="CSN" />
              </radAcctNum>
              <radExamBillingCode>
                <xsl:value-of select="PROCEDURE_CPT_CODE" />
              </radExamBillingCode>
              <radExamCPT>
                <xsl:value-of select="PROCEDURE_CPT_CODE" />
              </radExamCPT>
              <examdesc>
                <xsl:value-of select="PROCEDURE_NAME" />
              </examdesc>
              <radOrderingPhyLic>
                <xsl:value-of select="BILLING_PROVIDER_NPI__CER_" />
              </radOrderingPhyLic>
              <absPatientUnit />
              <radOrderingPhyMne>
                <xsl:value-of select="BILLING_PROVIDER" />
              </radOrderingPhyMne>
              <ExamHCPCCode />
              <orderingDrNPI>
                <xsl:value-of select="ORDERING_PROVIDER_NPI" />
              </orderingDrNPI>
              <misOrderingPhyCity />
              <radOrderingPhyUPIN />
              <misOrderingPhyName>
                <xsl:value-of select="ORDERING_PHYSICIAN_NAME" />
              </misOrderingPhyName>
              <misOrderingPhyAddr />
            </Charge>
          </xsl:if>
          <!--</xsl:for-each>-->
          <!-- Guarantor Information -->
          <Guarantor>
            <admGuarCity>
              <xsl:value-of select="PATIENT_ADDRESS__CITY" />
            </admGuarCity>
            <admGuarEmployer />
            <admGuarAddr1>
              <xsl:value-of select="PATIENT_ADDRESS__STREET_LINE_1" />
            </admGuarAddr1>
            <admGuarHomePhone>
              <xsl:value-of select="PATIENT_HOME_PHONE" />
            </admGuarHomePhone>
            <admGuarZip>
              <xsl:value-of select="PATIENT_ADDRESS__ZIP" />
            </admGuarZip>
            <admPatientUnit />
            <admGuarEmplCity />
            <admGuarEmplState />
            <admGuarEmplZip />
            <admGuarRel>
              <xsl:choose>
                <xsl:when test="string-length(GUAR_REL_TO_PT) = 0">
                  <xsl:value-of select="'15'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="GUAR_REL_TO_PT" />
                </xsl:otherwise>
              </xsl:choose>
            </admGuarRel>
            <admGuarName>
              <xsl:value-of select="GUARANTOR_NAME[1]" />
            </admGuarName>
            <npr1 />
            <admGuarState>
              <xsl:value-of select="PATIENT_ADDRESS__STATE" />
            </admGuarState>
            <admAcctNum />
            <admGuarEmplAddr1 />
            <admGuarSSN />
            <admGuarEmplPhone />
          </Guarantor>
          <!-- Diagnosis Codes -->
          <xsl:variable name="DiagCodes" select="tokenize(DX_CODE,';')" />
          <DiagnosisCodes>
            <xsl:choose>
              <xsl:when test="string-length(DX_CODE) != 0">
                <xsl:if test="$DiagCodes[1]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[1]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[2]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[2]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[3]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[3]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[4]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[4]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[5]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[5]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[6]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[6]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[7]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[7]" />
                  </Diag1>
                </xsl:if>
                <xsl:if test="$DiagCodes[8]">
                  <Diag1>
                    <xsl:value-of select="$DiagCodes[8]" />
                  </Diag1>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <!--COLUMN BP-->
                <xsl:if test="DIAGNOSIS__1_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__1_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BQ-->
                <xsl:if test="DIAGNOSIS__2_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__2_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BR-->
                <xsl:if test="DIAGNOSIS__3_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__3_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BS-->
                <xsl:if test="DIAGNOSIS__4_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__4_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BT-->
                <xsl:if test="DIAGNOSIS__5_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__5_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BU-->
                <xsl:if test="DIAGNOSIS__6_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__6_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BV-->
                <xsl:if test="DIAGNOSIS__7_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__7_CODE" />
                  </Diag1>
                </xsl:if>
                <!--COLUMN BW-->
                <xsl:if test="DIAGNOSIS__8_CODE">
                  <Diag1>
                    <xsl:value-of select="DIAGNOSIS__8_CODE" />
                  </Diag1>
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </DiagnosisCodes>
          <!-- Insurance Information -->
          <Insurance1>
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation(PRIMARY_CVG_STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="INSURANCE__1_POLICY_NUMBER" />
            </adminspolicy>
            <subscribername>
              <xsl:variable name="subscriberFullName" select="INSURANCE__1_SUBSCRIBER_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </subscribername>
            <adminszip>
              <xsl:value-of select="PRIMARY_CVG_ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:value-of select="PRIMARY_CVG_PAYER" />
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:value-of select="INSURANCE__1_PATIENT_RELATIONSHIP_TO_SUBSCRIBER" />
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="PRIMARY_CVG_ADDRESS_1" />
            </adminsstreet>
            <adminsgroup>
              <xsl:value-of select="INSURANCE__1_COMPANY_GROUP_NUMBER" />
            </adminsgroup>
            <adminscity>
              <xsl:value-of select="PRIMARY_CVG_CITY" />
            </adminscity>
            <adminsmne>
              <xsl:choose>
                <xsl:when test="string-length(INSURANCE__1_PLAN) != 0">
                  <xsl:value-of select="INSURANCE__1_PLAN" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'BLANK'" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="INSURANCE__1_SUBSCRIBER_NAME" />
              <xsl:value-of select="$subscriberFullName" />
              <!--<xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />-->
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="PRIMARY_CVG_PHONE" />
            </admInsPhone>
            <authnumber>
              <xsl:value-of select="INSURANCE__1_AUTHORIZATION_NUMBER" />
            </authnumber>
          </Insurance1>
          <Insurance2>
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation(INSURANCE__2_COMPANY_ADDRESS__STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="INSURANCE__2_POLICY_NUMBER" />
            </adminspolicy>
            <subscribername>
              <xsl:variable name="subscriberFullName" select="INSURANCE__2_SUBSCRIBER_NAME" />
              <xsl:value-of select="$subscriberFullName" />
              <!--<xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />-->
            </subscribername>
            <adminszip>
              <xsl:value-of select="INSURANCE__2_COMPANY_ADDRESS__ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:value-of select="INSURANCE__2_COMPANY_NAME" />
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:value-of select="INSURANCE__2_PATIENT_RELATIONSHIP_TO_SUBSCRIBER" />
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="INSURANCE__2_COMPANY_ADDRESS__LINE_1" />
            </adminsstreet>
            <adminsgroup>
              <xsl:value-of select="INSURANCE__2_COMPANY_GROUP_NUMBER" />
            </adminsgroup>
            <adminscity>
              <xsl:value-of select="INSURANCE__2_COMPANY_ADDRESS__CITY" />
            </adminscity>
            <adminsmne>
              <xsl:value-of select="INSURANCE__2_PLAN" />
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="INSURANCE__2_SUBSCRIBER_NAME" />
              <xsl:value-of select="$subscriberFullName" />
              <!--<xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />-->
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="INSURANCE__2_SUBSCRIBER_PHONE" />
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

