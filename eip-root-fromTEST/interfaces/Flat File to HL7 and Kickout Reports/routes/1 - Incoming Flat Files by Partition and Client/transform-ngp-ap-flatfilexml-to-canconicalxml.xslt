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
              <xsl:value-of select="PRIM_DX_CODE" />
            </absadmitdiag>
            <admpatstate>
              <!--ALREADY STATE CODE ABBR-->
              <xsl:value-of select="PAT_STATE" />
            </admpatstate>
            <absAdmitdate>
              <xsl:variable name="AdmitDate">
                <xsl:choose>
                  <xsl:when test="string-length(SERVICEDATE) != 10">
                    <!--WE KNOW WE NEED TO PAD WITH ZERO-->
                    <xsl:value-of select="pf:padDate(SERVICEDATE)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="SERVICEDATE" />
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
            <absdischargedate />
            <admemplname />
            <admzipcode>
              <xsl:value-of select="PAT_ZIP" />
            </admzipcode>
            <absattendingdocmnem />
            <absattendingdocname>
              <xsl:value-of select="ATTEND_PROV" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="CSN" />
            </admAcctNum>
            <admbirthdate />
            <admLocation>
              <xsl:value-of select="PATIENT_LOCATION" />
            </admLocation>
            <LabName>
              <xsl:value-of select="LABNAME" />
            </LabName>
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
              <xsl:value-of select="PATIENTNAME" />
            </admname>
            <admemplcity />
            <admpatcity>
              <xsl:value-of select="PAT_CITY" />
            </admpatcity>
            <admFinClass>
              <xsl:value-of select="ACCT_FIN_CLASS" />
            </admFinClass>
            <AttendDrNPI>
              <xsl:value-of select="READINGDOCTORNPI" />
            </AttendDrNPI>
            <absPatientUnit />
            <admpatienttype>
              <xsl:choose>
                <xsl:when test="contains(BASE_CLASS,'IP')">
                  <xsl:value-of select="'Inp'" />
                </xsl:when>
                <xsl:when test="contains(BASE_CLASS,'OP')">
                  <xsl:value-of select="'Out'" />
                </xsl:when>
                <xsl:when test="contains(BASE_CLASS,'ED')">
                  <xsl:value-of select="'Eme'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'NA'" />
                </xsl:otherwise>
              </xsl:choose>
            </admpatienttype>
            <admstreet>
              <xsl:value-of select="PAT_STREET" />
            </admstreet>
            <admstreet2 />
            <admemplzip />
            <ChiefComplaint />
            <admaccidentdate />
            <Filler2 />
            <admmaritalstatus>
              <xsl:variable name="status" select="PAT_MARITAL_STAT" />
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
              </xsl:choose>
            </admmaritalstatus>
          </PatientDemographics>
          <!-- Process each charge record in the group -->
          <!--<xsl:for-each select="//XCSRecord[QUANTITY]">-->
          <xsl:if test="QUANTITY != 'Quantity'">
            <Charge>
              <radNumOfTimes>
                <xsl:value-of select="QUANTITY" />
              </radNumOfTimes>
              <radExamServDate>
                <xsl:if test="string-length(translate(SERVICEDATE, '/', '')) != 0">
                  <xsl:variable name="CollectionDate">
                    <xsl:choose>
                      <xsl:when test="string-length(SERVICEDATE) != 10">
                        <!--WE KNOW WE NEED TO PAD WITH ZERO-->
                        <xsl:value-of select="pf:padDate(SERVICEDATE)" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="SERVICEDATE" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:if test="string-length($CollectionDate) != 0 and not(contains($CollectionDate,'NaN'))">
                    <xsl:value-of select="dtFormatter:format(translate($CollectionDate, '/', ''),'MMddyyyy','yyyyMMdd')" />
                  </xsl:if>
                </xsl:if>
              </radExamServDate>
              <radPatientName>
                <xsl:value-of select="PATIENTNAME" />
              </radPatientName>
              <radAcctNum>
                <xsl:value-of select="CSN" />
              </radAcctNum>
              <radExamBillingCode>
                <xsl:value-of select="CDM_CODE" />
              </radExamBillingCode>
              <radExamCPT>
                <xsl:value-of select="CPTCODE" />
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
                <xsl:value-of select="READINGDOCTORNPI" />
              </orderingDrNPI>
              <misOrderingPhyCity />
              <radOrderingPhyUPIN />
              <misOrderingPhyName>
                <!--<xsl:value-of select="READINGDOCTORNAME" />-->
                <xsl:value-of select="PATIENT_LOCATION" />
              </misOrderingPhyName>
              <misOrderingPhyAddr />
            </Charge>
          </xsl:if>
          <!--</xsl:for-each>-->
          <!-- Guarantor Information -->
          <Guarantor>
            <admGuarCity>
              <xsl:value-of select="GUAR_CITY" />
            </admGuarCity>
            <admGuarEmployer />
            <admGuarAddr1>
              <xsl:value-of select="GUAR_STREET" />
            </admGuarAddr1>
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
              <xsl:choose>
                <xsl:when test="string-length(GUAR_REL_TO_PAT_ID) = 0">
                  <!--DEFAULT TO 15 IF THERE IS NO RELATION PATIENT ID-->
                  <xsl:value-of select="'15'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="GUAR_REL_TO_PAT_ID" />
                </xsl:otherwise>
              </xsl:choose>
            </admGuarRel>
            <admGuarName>
              <xsl:value-of select="GUAR_NAME" />
            </admGuarName>
            <npr1 />
            <admGuarState>
              <xsl:value-of select="pf:GetStateAbbreviation(GUAR_STATE)" />
            </admGuarState>
            <admAcctNum />
            <admGuarEmplAddr1 />
            <admGuarSSN />
            <admGuarEmplPhone />
          </Guarantor>
          <!-- Diagnosis Codes -->
          <DiagnosisCodes>
            <xsl:if test="PRIM_DX_CODE">
              <Diag>
                <xsl:value-of select="PRIM_DX_CODE" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX02">
              <Diag>
                <xsl:value-of select="DX02" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX03">
              <Diag>
                <xsl:value-of select="DX03" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX04">
              <Diag>
                <xsl:value-of select="DX04" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX05">
              <Diag>
                <xsl:value-of select="DX05" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX06">
              <Diag>
                <xsl:value-of select="DX06" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX07">
              <Diag>
                <xsl:value-of select="DX07" />
              </Diag>
            </xsl:if>
            <xsl:if test="DX08">
              <Diag>
                <xsl:value-of select="DX08" />
              </Diag>
            </xsl:if>
          </DiagnosisCodes>
          <!-- Insurance Information -->
          <Insurance1>
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation(PRIM_COV_STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="PRIM_COV_SUBSCR_NUM" />
            </adminspolicy>
            <subscribername>
              <xsl:variable name="subscriberFullName" select="PRIM_COV_SUBSCR_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </subscribername>
            <adminszip>
              <xsl:value-of select="PRIM_COV_ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:value-of select="PRIM_PAYOR_PLAN_NAME" />
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:value-of select="PRIM_COV_REL_TO_SUB" />
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="PRIM_COV_STREET" />
            </adminsstreet>
            <adminsgroup>
              <xsl:value-of select="PRIM_COV_GROUP_NUM" />
            </adminsgroup>
            <adminscity>
              <xsl:value-of select="PRIM_COV_CITY" />
            </adminscity>
            <adminsmne>
              <xsl:choose>
                <xsl:when test="string-length(PRIMARY_PLAN_ID) != 0">
                  <xsl:value-of select="PRIMARY_PLAN_ID" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="'BLANK'" />
                </xsl:otherwise>
              </xsl:choose>
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="PRIM_COV_SUBSCR_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="PRIM_COV_PHONE" />
            </admInsPhone>
            <authnumber>
              <xsl:value-of select="AUTHNUMBER" />
            </authnumber>
          </Insurance1>
          <Insurance2>
            <adminsstate>
              <xsl:value-of select="pf:GetStateAbbreviation(SEC_COV_STATE)" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="SEC_COV_SUBSCR_NUM" />
            </adminspolicy>
            <subscribername>
              <xsl:variable name="subscriberFullName" select="SEC_COV_SUBSCR_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </subscribername>
            <adminszip>
              <xsl:value-of select="SEC_COV_ZIP" />
            </adminszip>
            <adminsPaCode />
            <absPatientUnit />
            <admInsName>
              <xsl:value-of select="SEC_PAYOR_PLAN_NAME" />
            </admInsName>
            <admAcctNum />
            <adminsinsuredrel>
              <xsl:value-of select="SEC_COV_REL_TO_SUB" />
            </adminsinsuredrel>
            <adminsstreet>
              <xsl:value-of select="SEC_COV_STREET" />
            </adminsstreet>
            <adminsgroup>
              <xsl:value-of select="SEC_COV_GROUP_NUM" />
            </adminsgroup>
            <adminscity>
              <xsl:value-of select="SEC_COV_CITY" />
            </adminscity>
            <adminsmne>
              <xsl:value-of select="SEC_PLAN_ID" />
            </adminsmne>
            <adminsinsuredname>
              <xsl:variable name="subscriberFullName" select="SEC_COV_SUBSCR_NAME" />
              <xsl:value-of select="concat(substring-after($subscriberFullName,' '),',',substring-before($subscriberFullName,' '))" />
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="SEC_COV_PHONE" />
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

