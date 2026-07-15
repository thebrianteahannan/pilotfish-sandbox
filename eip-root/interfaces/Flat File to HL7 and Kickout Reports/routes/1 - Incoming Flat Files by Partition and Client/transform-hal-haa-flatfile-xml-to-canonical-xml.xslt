<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:pf="http://pilotfishtechnology.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="dtFormatter" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Field mapping: AP_Halifax_20260323.csv (row 1 = source columns, row 2 = target elements). -->
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Unknown />
        <Header>
          <FacilityName>Halifax Med Ctr</FacilityName>
        </Header>
      </Group>
      <xsl:for-each-group group-by="normalize-space(HSP_CSN)" select="/XCSData/XCSRecord[@row]">
        <xsl:variable name="acctRecords" select="current-group()" />
        <xsl:variable name="header" select="$acctRecords[1]" />
        <Group key="{normalize-space($header/HSP_CSN)}">
          <xsl:for-each select="$header">
            <PatientDemographics>
              <absadmitdiag>
                <xsl:value-of select="PRIM_DIAGNOSIS_CODE" />
              </absadmitdiag>
              <admpatstate>
                <xsl:value-of select="pf:GetStateAbbreviation(pf:beforeBracket(PAT_STATE))" />
              </admpatstate>
              <absAdmitdate>
                <xsl:variable name="AdmitDate">
                  <xsl:choose>
                    <xsl:when test="string-length(ADM_DATE) != 10">
                      <xsl:value-of select="pf:padDate(ADM_DATE)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="ADM_DATE" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:if test="string-length($AdmitDate) != 0 and not(contains($AdmitDate,'NaN'))">
                  <xsl:if test="string-length(translate($AdmitDate, '/', '')) != 0">
                    <xsl:variable name="adDigits" select="translate($AdmitDate, '/', '')" />
                    <xsl:if test="string-length($adDigits) = 8 and translate($adDigits,'0123456789','') = ''">
                      <xsl:value-of select="dtFormatter:format($adDigits,'MMddyyyy','yyyyMMdd')" />
                    </xsl:if>
                  </xsl:if>
                </xsl:if>
              </absAdmitdate>
              <absattendingdocupin />
              <absdischargedate>
                <xsl:variable name="DischargeDate">
                  <xsl:choose>
                    <xsl:when test="string-length(DISCH_DATE_TIME) != 10">
                      <xsl:value-of select="pf:padDate(DISCH_DATE_TIME)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="DISCH_DATE_TIME" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:if test="string-length($DischargeDate) != 0 and not(contains($DischargeDate,'NaN'))">
                  <xsl:if test="string-length(translate($DischargeDate, '/', '')) != 0">
                    <xsl:variable name="ddDigits" select="translate($DischargeDate, '/', '')" />
                    <xsl:if test="string-length($ddDigits) = 8 and translate($ddDigits,'0123456789','') = ''">
                      <xsl:value-of select="dtFormatter:format($ddDigits,'MMddyyyy','yyyyMMdd')" />
                    </xsl:if>
                  </xsl:if>
                </xsl:if>
              </absdischargedate>
              <admemplname />
              <admzipcode>
                <xsl:value-of select="PAT_ZIPCODE" />
              </admzipcode>
              <absattendingdocmnem />
              <absattendingdocname>
                <xsl:choose>
                  <xsl:when test="string-length(ADM_PROV_NPI) != 0">
                    <xsl:value-of select="ADMIT_PROV" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="string-length(ATTEND_PROVI_NPI) != 0">
                        <xsl:value-of select="ATTEN_PROVI" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="REFER_PROV" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </absattendingdocname>
              <admemplstreet />
              <admAcctNum>
                <xsl:value-of select="HSP_CSN" />
              </admAcctNum>
              <admbirthdate>
                <xsl:variable name="PatDOB">
                  <xsl:choose>
                    <xsl:when test="string-length(PAT_DOB) != 10">
                      <xsl:value-of select="pf:padDate(PAT_DOB)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="PAT_DOB" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:if test="string-length($PatDOB) != 0 and not(contains($PatDOB,'NaN'))">
                  <xsl:choose>
                    <xsl:when test="contains($PatDOB, '-')">
                      <xsl:value-of select="translate($PatDOB, '-', '')" />
                    </xsl:when>
                    <xsl:when test="string-length(translate($PatDOB, '/', '')) != 0">
                      <xsl:variable name="dobDigits" select="translate($PatDOB, '/', '')" />
                      <xsl:if test="string-length($dobDigits) = 8 and translate($dobDigits,'0123456789','') = ''">
                        <xsl:value-of select="dtFormatter:format($dobDigits, 'MMddyyyy', 'yyyyMMdd')" />
                      </xsl:if>
                    </xsl:when>
                  </xsl:choose>
                </xsl:if>
              </admbirthdate>
              <admLocation>
                <xsl:value-of select="LOCATION" />
              </admLocation>
              <admpatsex>
                <xsl:variable name="sx" select="pf:beforeBracket(PAT_SEX)" />
                <xsl:choose>
                  <xsl:when test="starts-with(upper-case(normalize-space($sx)),'M')">
                    <xsl:value-of select="'M'" />
                  </xsl:when>
                  <xsl:when test="starts-with(upper-case(normalize-space($sx)),'F')">
                    <xsl:value-of select="'F'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space($sx)" />
                  </xsl:otherwise>
                </xsl:choose>
              </admpatsex>
              <admpatphone>
                <xsl:value-of select="PAT_HOMEPHONE" />
              </admpatphone>
              <admssn>
                <xsl:value-of select="translate(PAT_SSN,'-','')" />
              </admssn>
              <admname>
                <xsl:value-of select="HSP_ACCOUNT_NAME" />
              </admname>
              <admemplcity />
              <admpatcity>
                <xsl:value-of select="PAT_CITY" />
              </admpatcity>
              <admFinClass>
                <xsl:value-of select="pf:beforeBracket(ACCT_FIN_CLASS)" />
              </admFinClass>
              <AttendDrNPI>
                <xsl:choose>
                  <xsl:when test="string-length(ADM_PROV_NPI) != 0">
                    <xsl:value-of select="ADM_PROV_NPI" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="string-length(ATTEND_PROVI_NPI) != 0">
                        <xsl:value-of select="ATTEND_PROVI_NPI" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="REFER_PROVI_NPI" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </AttendDrNPI>
              <absPatientUnit />
              <admpatienttype>
                <xsl:variable name="class" select="pf:beforeBracket(PAT_CLASS)" />
                <!--FIRST 24 CHARACTERS-->
                <xsl:value-of select="substring($class,0,23)" />
                <!--<xsl:choose>-->
                <!--<xsl:when test="$baseClass = ('Billing Encounter','Erroneous Encounter','Lab Requisition','Outpatient','Outpatient Surgery','Pre-Admission Testing','Treatment Series','Observation','Radiation/Oncology Series')">-->
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
                <xsl:value-of select="PAT_ADDRESS" />
              </admstreet>
              <admstreet2 />
              <admemplzip />
              <ChiefComplaint />
              <admaccidentdate />
              <Filler2 />
              <admmaritalstatus>
                <xsl:variable name="status" select="pf:beforeBracket(PAT_MARITAL_STAT)" />
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
                  <xsl:when test="$status = 'Unmarried'">
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
          </xsl:for-each>
          <xsl:for-each select="$acctRecords">
            <xsl:if test="QUANTITY != '' and QUANTITY != 'Quantity'">
              <xsl:variable name="chargeRow" select="." />
              <xsl:variable name="qtyNum" select="number(QUANTITY)" />
              <xsl:variable as="xs:integer" name="repeatCount" select="if ($qtyNum = $qtyNum and $qtyNum &gt; 0) then max((1, xs:integer(floor($qtyNum)))) else 1" />
              <xsl:for-each select="1 to $repeatCount">
                <Charge>
                  <radNumOfTimes>1</radNumOfTimes>
                  <radExamServDate>
                    <xsl:variable name="sd" select="string($chargeRow/SERVICE_DATE)" />
                    <xsl:choose>
                      <xsl:when test="string-length($sd) = 8 and translate($sd,'0123456789','') = ''">
                        <xsl:value-of select="dtFormatter:format($sd,'MMddyyyy','yyyyMMdd')" />
                      </xsl:when>
                      <xsl:when test="string-length(translate($sd, '/', '')) != 0">
                        <xsl:variable name="CollectionDate">
                          <xsl:choose>
                            <xsl:when test="string-length($sd) != 10">
                              <xsl:value-of select="pf:padDate($sd)" />
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="$sd" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <xsl:if test="string-length($CollectionDate) != 0 and not(contains($CollectionDate,'NaN'))">
                          <xsl:variable name="cdDigits" select="translate($CollectionDate, '/', '')" />
                          <xsl:if test="string-length($cdDigits) = 8 and translate($cdDigits,'0123456789','') = ''">
                            <xsl:value-of select="dtFormatter:format($cdDigits,'MMddyyyy','yyyyMMdd')" />
                          </xsl:if>
                        </xsl:if>
                      </xsl:when>
                    </xsl:choose>
                  </radExamServDate>
                  <radPatientName>
                    <xsl:value-of select="$chargeRow/HSP_ACCOUNT_NAME" />
                  </radPatientName>
                  <radAcctNum>
                    <xsl:value-of select="$chargeRow/HSP_CSN" />
                  </radAcctNum>
                  <radExamBillingCode>
                    <xsl:value-of select="$chargeRow/PROCEDURE_CODE" />
                  </radExamBillingCode>
                  <CDM />
                  <radExamCPT>
                    <xsl:value-of select="$chargeRow/PROCEDURE_CODE" />
                  </radExamCPT>
                  <examdesc>
                    <xsl:value-of select="$chargeRow/SPECIMEN_EXTERNAL_ID" />
                  </examdesc>
                  <radOrderingPhyLic>
                    <xsl:value-of select="$chargeRow/BILLING_PROV_NPI" />
                  </radOrderingPhyLic>
                  <absPatientUnit />
                  <radOrderingPhyMne>
                    <xsl:value-of select="$chargeRow/BILLING_PROV" />
                  </radOrderingPhyMne>
                  <ExamHCPCCode />
                  <orderingDrNPI>
                    <xsl:value-of select="$chargeRow/BILLING_PROV_NPI" />
                  </orderingDrNPI>
                  <misOrderingPhyCity />
                  <radOrderingPhyUPIN />
                  <misOrderingPhyName>
                    <xsl:value-of select="$chargeRow/BILLING_PROV" />
                  </misOrderingPhyName>
                  <misOrderingPhyAddr />
                  <specimenNo>
                    <xsl:value-of select="$chargeRow/SPECIMEN_EXTERNAL_ID" />
                  </specimenNo>
                  <pathologist>
                    <xsl:value-of select="$chargeRow/ADMIT_PROV" />
                  </pathologist>
                </Charge>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>
          <xsl:for-each select="$header">
            <Guarantor>
              <admGuarCity>
                <xsl:value-of select="GUAR_CITY" />
              </admGuarCity>
              <admGuarEmployer />
              <admGuarAddr1>
                <xsl:value-of select="GUAR_STREET" />
              </admGuarAddr1>
              <admGuarAddr2 />
              <admGuarHomePhone>
                <xsl:value-of select="GUAR_HOME_PHONE" />
              </admGuarHomePhone>
              <admGuarZip>
                <xsl:value-of select="GUAR_ZIPCODE" />
              </admGuarZip>
              <admPatientUnit />
              <admGuarEmplCity />
              <admGuarEmplState />
              <admGuarEmplZip />
              <admGuarRel>
                <xsl:value-of select="substring(upper-case(normalize-space(GUAR_RELA_TO_PAT)),1,2)" />
              </admGuarRel>
              <admGuarName>
                <xsl:choose>
                  <xsl:when test="not(contains(GUAR_NAME,',')) and string-length(GUAR_NAME) != 0">
                    <xsl:value-of select="concat(substring-after(GUAR_NAME,' '),', ',substring-before(GUAR_NAME,' '))" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="contains(GUAR_NAME,',') and not(contains(GUAR_NAME,', '))">
                        <xsl:value-of select="replace(GUAR_NAME,',',', ')" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="GUAR_NAME" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </admGuarName>
              <npr1 />
              <admGuarState>
                <xsl:value-of select="pf:GetStateAbbreviation(pf:beforeBracket(GUAR_STATE))" />
              </admGuarState>
              <admAcctNum />
              <admGuarEmplAddr1 />
              <admGuarSSN />
              <admGuarEmplPhone />
            </Guarantor>
            <DiagnosisCodes>
              <xsl:if test="PRIM_DIAGNOSIS_CODE">
                <Diag>
                  <xsl:value-of select="PRIM_DIAGNOSIS_CODE" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAGNOSIS_CODE1">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAGNOSIS_CODE1" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE2">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE2" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE3">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE3" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE4">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE4" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE5">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE5" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE6">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE6" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE7">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE7" />
                </Diag>
              </xsl:if>
              <xsl:if test="SECONDARY_DIAG_CODE8">
                <Diag>
                  <xsl:value-of select="SECONDARY_DIAG_CODE8" />
                </Diag>
              </xsl:if>
            </DiagnosisCodes>
            <Insurance1>
              <adminsstate>
                <xsl:value-of select="pf:GetStateAbbreviation(pf:beforeBracket(PAYER_STATE))" />
              </adminsstate>
              <adminspolicy>
                <xsl:value-of select="PRIM_COVG_SBUS_NUMB" />
              </adminspolicy>
              <subscribername>
                <xsl:variable name="sn" select="PRIMARY_COVERAVE_SUBSCRIBERNAME" />
                <xsl:choose>
                  <xsl:when test="string-length($sn) = 0">
                    <xsl:value-of select="HSP_ACCOUNT_NAME" />
                  </xsl:when>
                  <xsl:when test="contains($sn, ',')">
                    <xsl:value-of select="normalize-space($sn)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="concat(substring-after($sn,' '),',',substring-before($sn,' '))" />
                  </xsl:otherwise>
                </xsl:choose>
              </subscribername>
              <subscriberbirthdate>
                <xsl:variable name="SubDOB">
                  <xsl:choose>
                    <xsl:when test="string-length(PRIM_COV_SUBSCRIBERDOB) != 10">
                      <xsl:value-of select="pf:padDate(PRIM_COV_SUBSCRIBERDOB)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="PRIM_COV_SUBSCRIBERDOB" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:if test="string-length($SubDOB) != 0 and not(contains($SubDOB,'NaN'))">
                  <xsl:choose>
                    <xsl:when test="contains($SubDOB, '-')">
                      <xsl:value-of select="translate($SubDOB, '-', '')" />
                    </xsl:when>
                    <xsl:when test="string-length(translate($SubDOB, '/', '')) != 0">
                      <xsl:variable name="subDobDigits" select="translate($SubDOB, '/', '')" />
                      <xsl:if test="string-length($subDobDigits) = 8 and translate($subDobDigits,'0123456789','') = ''">
                        <xsl:value-of select="dtFormatter:format($subDobDigits, 'MMddyyyy', 'yyyyMMdd')" />
                      </xsl:if>
                    </xsl:when>
                  </xsl:choose>
                </xsl:if>
              </subscriberbirthdate>
              <subscriberdgender>
                <xsl:value-of select="pf:beforeBracket(PRIM_COV_SUBSCRIBERGENDER)" />
              </subscriberdgender>
              <adminszip>
                <xsl:value-of select="PAYER_ZIPCODE" />
              </adminszip>
              <adminsPaCode />
              <absPatientUnit />
              <admInsName>
                <xsl:choose>
                  <xsl:when test="PRIMARY_PAYER_NAME = 'Not Applicable' or PRIMARY_PAYER_NAME = 'Self-Pay'">
                    <xsl:value-of select="''" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="PRIMARY_PAYER_NAME" />
                  </xsl:otherwise>
                </xsl:choose>
              </admInsName>
              <admInspayorID>
                <xsl:value-of select="PRIMARY_PAYOR" />
              </admInspayorID>
              <admAcctNum />
              <adminsinsuredrel>
                <xsl:variable name="subscriberRel" select="PRIM_COV_REL_TO_SUBS" />
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
                <xsl:value-of select="PRIM_COV_STREET" />
              </adminsstreet>
              <admingroup>
                <xsl:value-of select="PRIM_COV_GRP_NUM" />
              </admingroup>
              <adminscity>
                <xsl:value-of select="PAYOR_CITY" />
              </adminscity>
              <adminsmne>
                <xsl:choose>
                  <xsl:when test="string-length(PRIMARY_PLAN_ID) != 0 and PRIMARY_PLAN_ID != 'Self-Pay'">
                    <xsl:value-of select="PRIMARY_PLAN_ID" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="'BLANK'" />
                  </xsl:otherwise>
                </xsl:choose>
              </adminsmne>
              <adminsinsuredname>
                <xsl:value-of select="PRIMARY_COVERAVE_SUBSCRIBERNAME" />
              </adminsinsuredname>
              <admInsPhone>
                <xsl:value-of select="PRIM_COV_PHONE" />
              </admInsPhone>
              <authnumber>
                <xsl:value-of select="AUTH_NUMB" />
              </authnumber>
            </Insurance1>
            <Insurance2>
              <adminsstate>
                <xsl:value-of select="pf:GetStateAbbreviation(pf:beforeBracket(SEC_COV_STATE))" />
              </adminsstate>
              <adminspolicy>
                <xsl:value-of select="EC_COV_SUBS_NUM" />
              </adminspolicy>
              <subscribername />
              <adminszip>
                <xsl:value-of select="SEC_COV_ZIP" />
              </adminszip>
              <adminsPaCode />
              <absPatientUnit />
              <admInsName>
                <xsl:value-of select="SEC_PAYOR_NAME" />
              </admInsName>
              <secInspayorID>
                <xsl:value-of select="SEC_PAYOR_ID" />
              </secInspayorID>
              <admAcctNum />
              <adminsinsuredrel>
                <xsl:variable name="secondarySubscriberRel" select="SEC_COV_REL_TO_SUB" />
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
                <xsl:value-of select="SEC_COV_STREET" />
              </adminsstreet>
              <admingroup>
                <xsl:value-of select="SEC_COV_SUB_GRUP_NUMB" />
              </admingroup>
              <adminscity>
                <xsl:value-of select="SEC_COV_CITY" />
              </adminscity>
              <adminsmne>
                <xsl:value-of select="SEC_PLAN_ID" />
              </adminsmne>
              <adminsinsuredname />
              <admInsPhone>
                <xsl:value-of select="SEC_COV_PHONE" />
              </admInsPhone>
            </Insurance2>
            <Insurance3>
              <admAcctNum />
              <absPatientUnit />
            </Insurance3>
          </xsl:for-each>
        </Group>
      </xsl:for-each-group>
    </XCSData>
  </xsl:template>
  <xsl:function as="xs:string" name="pf:beforeBracket">
    <xsl:param as="item()*" name="s" />
    <xsl:variable as="xs:string" name="t" select="if (empty($s)) then '' else string($s[1])" />
    <xsl:sequence select="if (contains($t,' [')) then substring-before($t,' [') else $t" />
  </xsl:function>
  <!--
		pf:haaAdmLocation: AP_Halifax_20260323.csv maps adm location ← Location (parent codes in brackets).
	-->
  <xsl:function as="xs:string" name="pf:haaAdmLocation">
    <xsl:param as="item()*" name="department" />
    <xsl:param as="item()*" name="location" />
    <xsl:variable as="xs:string" name="dept" select="if (empty($department)) then '' else string($department[1])" />
    <xsl:variable as="xs:string" name="loc" select="if (empty($location)) then '' else string($location[1])" />
    <xsl:choose>
      <xsl:when test="contains($loc,'[10004]') or contains(upper-case($loc),'PORT ORANGE')">
        <xsl:value-of select="'HAA'" />
      </xsl:when>
      <xsl:when test="contains($loc,'[10001]') or contains(upper-case($loc),'DAYTONA')">
        <xsl:value-of select="'HAA'" />
      </xsl:when>
      <xsl:when test="contains($loc,'[10051]') or contains(upper-case($loc),'DELTONA')">
        <xsl:value-of select="'HAA'" />
      </xsl:when>
      <xsl:when test="$dept = '101003601'">
        <xsl:value-of select="'HAA'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'HAA'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="pf:GetStateAbbreviation">
    <xsl:param as="item()*" name="StateName" />
    <xsl:variable as="xs:string" name="sn" select="if (empty($StateName)) then '' else string($StateName[1])" />
    <xsl:choose>
      <xsl:when test="string-length($sn) != 2">
        <xsl:choose>
          <xsl:when test="$sn = 'Alabama'">
            <xsl:value-of select="'AL'" />
          </xsl:when>
          <xsl:when test="$sn = 'Alaska'">
            <xsl:value-of select="'AK'" />
          </xsl:when>
          <xsl:when test="$sn = 'Arizona'">
            <xsl:value-of select="'AZ'" />
          </xsl:when>
          <xsl:when test="$sn = 'Arkansas'">
            <xsl:value-of select="'AR'" />
          </xsl:when>
          <xsl:when test="$sn = 'California'">
            <xsl:value-of select="'CA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Colorado'">
            <xsl:value-of select="'CO'" />
          </xsl:when>
          <xsl:when test="$sn = 'Connecticut'">
            <xsl:value-of select="'CT'" />
          </xsl:when>
          <xsl:when test="$sn = 'Delaware'">
            <xsl:value-of select="'DE'" />
          </xsl:when>
          <xsl:when test="$sn = 'District of Columbia'">
            <xsl:value-of select="'DC'" />
          </xsl:when>
          <xsl:when test="$sn = 'Florida'">
            <xsl:value-of select="'FL'" />
          </xsl:when>
          <xsl:when test="$sn = 'Georgia'">
            <xsl:value-of select="'GA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Hawaii'">
            <xsl:value-of select="'HI'" />
          </xsl:when>
          <xsl:when test="$sn = 'Idaho'">
            <xsl:value-of select="'ID'" />
          </xsl:when>
          <xsl:when test="$sn = 'Illinois'">
            <xsl:value-of select="'IL'" />
          </xsl:when>
          <xsl:when test="$sn = 'Indiana'">
            <xsl:value-of select="'IN'" />
          </xsl:when>
          <xsl:when test="$sn = 'Iowa'">
            <xsl:value-of select="'IA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Kansas'">
            <xsl:value-of select="'KS'" />
          </xsl:when>
          <xsl:when test="$sn = 'Kentucky'">
            <xsl:value-of select="'KY'" />
          </xsl:when>
          <xsl:when test="$sn = 'Lousiana'">
            <xsl:value-of select="'LA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Maine'">
            <xsl:value-of select="'ME'" />
          </xsl:when>
          <xsl:when test="$sn = 'Maryland'">
            <xsl:value-of select="'MD'" />
          </xsl:when>
          <xsl:when test="$sn = 'Massachusetts'">
            <xsl:value-of select="'MA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Michigan'">
            <xsl:value-of select="'MI'" />
          </xsl:when>
          <xsl:when test="$sn = 'Minnesota'">
            <xsl:value-of select="'MN'" />
          </xsl:when>
          <xsl:when test="$sn = 'Mississippi'">
            <xsl:value-of select="'MS'" />
          </xsl:when>
          <xsl:when test="$sn = 'Missouri'">
            <xsl:value-of select="'MO'" />
          </xsl:when>
          <xsl:when test="$sn = 'Montana'">
            <xsl:value-of select="'MT'" />
          </xsl:when>
          <xsl:when test="$sn = 'Nebraska'">
            <xsl:value-of select="'NE'" />
          </xsl:when>
          <xsl:when test="$sn = 'Nevada'">
            <xsl:value-of select="'NV'" />
          </xsl:when>
          <xsl:when test="$sn = 'New Hampshire'">
            <xsl:value-of select="'NH'" />
          </xsl:when>
          <xsl:when test="$sn = 'New Jersey'">
            <xsl:value-of select="'NJ'" />
          </xsl:when>
          <xsl:when test="$sn = 'New Mexico'">
            <xsl:value-of select="'NM'" />
          </xsl:when>
          <xsl:when test="$sn = 'New York'">
            <xsl:value-of select="'NY'" />
          </xsl:when>
          <xsl:when test="$sn = 'North Carolina'">
            <xsl:value-of select="'NC'" />
          </xsl:when>
          <xsl:when test="$sn = 'North Dakota'">
            <xsl:value-of select="'ND'" />
          </xsl:when>
          <xsl:when test="$sn = 'Ohio'">
            <xsl:value-of select="'OH'" />
          </xsl:when>
          <xsl:when test="$sn = 'Oklahoma'">
            <xsl:value-of select="'OK'" />
          </xsl:when>
          <xsl:when test="$sn = 'Oregon'">
            <xsl:value-of select="'OR'" />
          </xsl:when>
          <xsl:when test="$sn = 'Pennsylvania'">
            <xsl:value-of select="'PA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Rhode Island'">
            <xsl:value-of select="'RI'" />
          </xsl:when>
          <xsl:when test="$sn = 'South Carolina'">
            <xsl:value-of select="'SC'" />
          </xsl:when>
          <xsl:when test="$sn = 'South Dakota'">
            <xsl:value-of select="'SD'" />
          </xsl:when>
          <xsl:when test="$sn = 'Tennessee'">
            <xsl:value-of select="'TN'" />
          </xsl:when>
          <xsl:when test="$sn = 'Texas'">
            <xsl:value-of select="'TX'" />
          </xsl:when>
          <xsl:when test="$sn = 'Utah'">
            <xsl:value-of select="'UT'" />
          </xsl:when>
          <xsl:when test="$sn = 'Vermont'">
            <xsl:value-of select="'VT'" />
          </xsl:when>
          <xsl:when test="$sn = 'Virginia'">
            <xsl:value-of select="'VA'" />
          </xsl:when>
          <xsl:when test="$sn = 'Washington'">
            <xsl:value-of select="'WA'" />
          </xsl:when>
          <xsl:when test="$sn = 'West Virginia'">
            <xsl:value-of select="'WV'" />
          </xsl:when>
          <xsl:when test="$sn = 'Wisconsin'">
            <xsl:value-of select="'WI'" />
          </xsl:when>
          <xsl:when test="$sn = 'Wyoming'">
            <xsl:value-of select="'WY'" />
          </xsl:when>
          <xsl:when test="$sn = ''">
            <xsl:value-of select="''" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="''" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sn" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function as="xs:string" name="pf:padDate">
    <xsl:param as="item()*" name="date" />
    <xsl:variable as="xs:string" name="d" select="if (empty($date)) then '' else string($date[1])" />
    <xsl:variable name="parts" select="tokenize($d, '/')" />
    <xsl:sequence select="if (count($parts) ne 3) then '' else concat(format-number(number($parts[1]), '00'),'/',format-number(number($parts[2]),'00'),'/',$parts[3])" />
  </xsl:function>
</xsl:stylesheet>

