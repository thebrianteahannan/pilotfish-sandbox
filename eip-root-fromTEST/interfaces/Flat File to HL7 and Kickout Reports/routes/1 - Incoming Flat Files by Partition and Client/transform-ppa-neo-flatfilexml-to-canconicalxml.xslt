<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pf="http://pilotfishtechnology.com" exclude-result-prefixes="pf" version="3.1">
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Unknown />
        <Header>
          <FacilityName>PPA - NEO - Precision Pathology Associates</FacilityName>
        </Header>
      </Group>
      <xsl:for-each select="//XCSRecord">
        <xsl:variable name="AccountNumber" select="Unknown_Data[6]" />
        <xsl:if test="$AccountNumber != ''">
          <Group key="{$AccountNumber}">
            <PatientDemographics>
              <absadmitdiag>
                <xsl:value-of select="Unknown_Data[1]" />
              </absadmitdiag>
              <admpatstate>
                <xsl:value-of select="pf:GetStateAbbreviation(substring-before(Unknown_Data[35],' ['))" />
              </admpatstate>
              <absAdmitdate>
                <xsl:if test="string-length(Unknown_Data[3]) != 0">
                  <xsl:value-of select="pf:formatDate(Unknown_Data[3],'MM/dd/yyyy','yyyyMMdd')" />
                </xsl:if>
              </absAdmitdate>
              <absattendingdocupin />
              <absdischargedate>
                <xsl:if test="string-length(Unknown_Data[4]) != 0">
                  <xsl:value-of select="pf:formatDate(Unknown_Data[4],'MM/dd/yyyy','yyyyMMdd')" />
                </xsl:if>
              </absdischargedate>
              <admemplname />
              <admzipcode>
                <xsl:value-of select="substring(Unknown_Data[37],1,5)" />
              </admzipcode>
              <absattendingdocmnem />
              <absattendingdocname>
                <xsl:value-of select="Unknown_Data[4]" />
              </absattendingdocname>
              <admemplstreet />
              <admAcctNum>
                <xsl:value-of select="$AccountNumber" />
              </admAcctNum>
              <admbirthdate>
                <xsl:if test="string-length(Unknown_Data[19]) != 0">
                  <xsl:value-of select="pf:formatDate(Unknown_Data[19],'MM/dd/yyyy','yyyyMMdd')" />
                </xsl:if>
              </admbirthdate>
              <admLocation>
                <xsl:value-of select="Unknown_Data[18]" />
              </admLocation>
              <admpatsex>
                <xsl:value-of select="Unknown_Data[27]" />
              </admpatsex>
              <admpatphone>
                <xsl:value-of select="Unknown_Data[38]" />
              </admpatphone>
              <admssn>
                <xsl:value-of select="Unknown_Data[9]" />
              </admssn>
              <admname>
                <xsl:value-of select="Unknown_Data[4]" />
              </admname>
              <admemplcity />
              <admpatcity>
                <xsl:value-of select="Unknown_Data[34]" />
              </admpatcity>
              <admFinClass />
              <AttendDrNPI>
                <xsl:value-of select="Unknown_Data[14]" />
              </AttendDrNPI>
              <absPatientUnit />
              <admpatienttype>
                <xsl:value-of select="substring(Unknown_Data[18],1,3)" />
              </admpatienttype>
              <admstreet>
                <xsl:value-of select="Unknown_Data[33]" />
              </admstreet>
              <admstreet2 />
              <admemplzip />
              <ChiefComplaint />
              <admaccidentdate />
              <Filler2 />
            </PatientDemographics>
            <Charge>
              <radExamServDate>
                <xsl:if test="string-length(Unknown_Data[3]) != 0">
                  <xsl:value-of select="pf:formatDate(Unknown_Data[3],'MM/dd/yyyy','yyyyMMdd')" />
                </xsl:if>
              </radExamServDate>
              <ExamApplication />
              <radExamBillingCode>
                <xsl:value-of select="NEO" />
              </radExamBillingCode>
              <radExamCPT>
                <xsl:value-of select="NEO" />
              </radExamCPT>
              <examdesc>
                <xsl:value-of select="Unknown_Data[1]" />
              </examdesc>
              <radOrderingPhyLic />
              <absPatientUnit />
              <radOrderingPhyMne>
                <xsl:value-of select="Unknown_Data[13]" />
              </radOrderingPhyMne>
              <ExamHCPCCode />
              <radNumOfTimes>
                <xsl:value-of select="Unknown_Data[2]" />
              </radNumOfTimes>
              <radPatientName>
                <xsl:value-of select="Unknown_Data[4]" />
              </radPatientName>
              <radExamDept />
              <orderingDrNPI>
                <xsl:value-of select="Unknown_Data[10]" />
              </orderingDrNPI>
              <misOrderingPhyCity />
              <radOrderingPhyUPIN />
              <radAcctNum>
                <xsl:value-of select="$AccountNumber" />
              </radAcctNum>
              <misOrderingPhyName>
                <xsl:value-of select="Unknown_Data[13]" />
              </misOrderingPhyName>
              <misOrderingPhyAddr />
              <chargeStatus>
                <xsl:value-of select="Unknown_Data[92]" />
              </chargeStatus>
              <specimenNo>
                <xsl:value-of select="H" />
              </specimenNo>
              <pathologist>
                <xsl:value-of select="Unknown_Data[9]" />
              </pathologist>
            </Charge>
            <Guarantor>
              <admGuarCity>
                <xsl:value-of select="Unknown_Data[56]" />
              </admGuarCity>
              <admGuarEmployer />
              <admGuarAddr1>
                <xsl:value-of select="Unknown_Data[55]" />
              </admGuarAddr1>
              <admGuarHomePhone>
                <xsl:value-of select="Unknown_Data[59]" />
              </admGuarHomePhone>
              <admGuarZip>
                <xsl:value-of select="Unknown_Data[58]" />
              </admGuarZip>
              <admPatientUnit />
              <admGuarEmplCity />
              <admGuarEmplState />
              <admGuarEmplZip />
              <admGuarRel>
                <xsl:value-of select="substring-before(substring-after(Unknown_Data[54],'['),']')" />
              </admGuarRel>
              <admGuarName>
                <xsl:choose>
                  <xsl:when test="_600 = 'SYSTEM GENERATED' or string-length(_600) = 0">
                    <xsl:value-of select="Unknown_Data[4]" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="_600" />
                  </xsl:otherwise>
                </xsl:choose>
              </admGuarName>
              <npr1 />
              <admGuarState>
                <xsl:value-of select="pf:GetStateAbbreviation(substring-before(Unknown_Data[57],' ['))" />
              </admGuarState>
              <admAcctNum />
              <admGuarEmplAddr1 />
              <admGuarSSN />
              <admGuarEmplPhone />
            </Guarantor>
            <DiagnosisCodes>
              <Diag1CodeSet>ICD10</Diag1CodeSet>
              <radAcctNum>
                <xsl:value-of select="$AccountNumber" />
              </radAcctNum>
              <xsl:variable name="diags" select="tokenize(Unknown_Data[12],',')" />
              <xsl:for-each select="$diags">
                <Diag1>
                  <xsl:value-of select="." />
                </Diag1>
              </xsl:for-each>
            </DiagnosisCodes>
            <Insurance1>
              <adminsstate>
                <xsl:value-of select="pf:GetStateAbbreviation(substring-before(Unknown_Data[66],' ['))" />
              </adminsstate>
              <adminspolicy>
                <xsl:value-of select="Unknown_Data[43]" />
              </adminspolicy>
              <subscribername>
                <xsl:value-of select="Unknown_Data[46]" />
              </subscribername>
              <adminszip>
                <xsl:value-of select="Unknown_Data[67]" />
              </adminszip>
              <adminsPaCode />
              <absPatientUnit />
              <admInsName>
                <xsl:value-of select="Unknown_Data[40]" />
              </admInsName>
              <admAcctNum />
              <adminsinsuredrel>
                <xsl:value-of select="substring-before(substring-after(Unknown_Data[41],'['),']')" />
              </adminsinsuredrel>
              <adminsstreet>
                <xsl:value-of select="Unknown_Data[64]" />
              </adminsstreet>
              <adminsgroup />
              <adminscity>
                <xsl:value-of select="Unknown_Data[65]" />
              </adminscity>
              <adminsmne>
                <xsl:value-of select="substring-before(substring-after(Unknown_Data[40],'['),']')" />
              </adminsmne>
              <adminsinsuredname>
                <xsl:value-of select="Unknown_Data[46]" />
              </adminsinsuredname>
              <admInsPhone>
                <xsl:value-of select="Unknown_Data[68]" />
              </admInsPhone>
            </Insurance1>
            <Insurance2>
              <adminsstate>
                <xsl:value-of select="Unknown_Data[85]" />
              </adminsstate>
              <adminspolicy>
                <xsl:value-of select="Unknown_Data[71]" />
              </adminspolicy>
              <subscribername />
              <adminszip>
                <xsl:value-of select="Unknown_Data[86]" />
              </adminszip>
              <adminsPaCode />
              <absPatientUnit />
              <admInsName>
                <xsl:value-of select="Unknown_Data[90]" />
              </admInsName>
              <admAcctNum />
              <adminsinsuredrel />
              <adminsstreet>
                <xsl:value-of select="Unknown_Data[83]" />
              </adminsstreet>
              <adminsgroup />
              <adminscity>
                <xsl:value-of select="Unknown_Data[84]" />
              </adminscity>
              <adminsmne>
                <xsl:value-of select="Unknown_Data[70]" />
              </adminsmne>
              <adminsinsuredname>
                <xsl:value-of select="Unknown_Data[46]" />
              </adminsinsuredname>
              <admInsPhone>
                <xsl:value-of select="Unknown_Data[87]" />
              </admInsPhone>
            </Insurance2>
            <Insurance3>
              <admAcctNum />
              <absPatientUnit />
            </Insurance3>
          </Group>
        </xsl:if>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <xsl:function name="pf:formatDate">
    <xsl:param name="date" />
    <xsl:param name="inputFormat" />
    <xsl:param name="outputFormat" />
    <xsl:choose>
      <xsl:when test="$inputFormat = 'MM/dd/yyyy' and $outputFormat = 'yyyyMMdd'">
        <xsl:variable name="parts" select="tokenize($date, '/')" />
        <xsl:if test="count($parts) = 3">
          <xsl:value-of select="concat($parts[3], format-number(number($parts[1]), '00'), format-number(number($parts[2]), '00'))" />
        </xsl:if>
      </xsl:when>
      <xsl:when test="$inputFormat = 'MMddyyyy' and $outputFormat = 'yyyyMMdd'">
        <xsl:if test="string-length($date) = 8">
          <xsl:value-of select="concat(substring($date, 5, 4), substring($date, 1, 2), substring($date, 3, 2))" />
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$date" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="pf:GetStateAbbreviation">
    <xsl:param name="StateName" />
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
      <xsl:when test="$StateName = 'Louisiana'">
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
        <xsl:value-of select="'NA'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>

