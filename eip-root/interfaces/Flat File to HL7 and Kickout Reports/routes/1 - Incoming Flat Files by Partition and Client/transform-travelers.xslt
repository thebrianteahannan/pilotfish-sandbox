<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:types="http://www.xifin.com/schema/types" xmlns:xifin="http://www.xifin.com/schema/accession" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <xsl:template match="/">
    <XCSData>
      <Group key="">
        <Header>
          <FacilityName>Ariana</FacilityName>
        </Header>
      </Group>
      <xsl:for-each select="//AccessionType">
        <Group key="{xifin:AccessionId}">
          <PatientDemographics>
            <admmaritalstatus>
              <xsl:value-of select="'U'" />
            </admmaritalstatus>
            <admpatstate>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:State" />
            </admpatstate>
            <absAdmitdate>
              <xsl:value-of select="translate(xifin:DateOfService, '-', '')" />
            </absAdmitdate>
            <absdischargedate>
              <xsl:value-of select="translate(xifin:DateOfService, '-', '')" />
            </absdischargedate>
            <admemplname />
            <admzipcode>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:ZIP" />
            </admzipcode>
            <absattendingdocname>
              <xsl:value-of select="xifin:Physicians/xifin:Ordering/xifin:Name" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="xifin:AccessionId" />
            </admAcctNum>
            <admbirthdate>
              <xsl:value-of select="translate(xifin:PatientInfo/xifin:Person/types:DateOfBirth, '-', '')" />
            </admbirthdate>
            <admLocation>
              <xsl:value-of select="'TO BE FILLED IN LATER'" />
            </admLocation>
            <admpatsex>
              <xsl:value-of select="substring(xifin:PatientInfo/xifin:Person/types:Gender, 1, 1)" />
            </admpatsex>
            <admpatphone>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:HomePhone" />
            </admpatphone>
            <admssn>
              <xsl:choose>
                <xsl:when test="xifin:PatientInfo/xifin:Person/types:SSN">
                  <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:SSN" />
                </xsl:when>
                <xsl:otherwise>777777777</xsl:otherwise>
              </xsl:choose>
            </admssn>
            <admname>
              <xsl:value-of select="concat(xifin:PatientInfo/xifin:Person/types:Name/types:LastName, ', ', xifin:PatientInfo/xifin:Person/types:Name/types:FirstName)" />
            </admname>
            <admemplcity />
            <admpatcity>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:City" />
            </admpatcity>
            <admFinClass />
            <AttendDrNPI>
              <xsl:value-of select="xifin:Physicians/xifin:Ordering/xifin:NPI" />
            </AttendDrNPI>
            <admpatienttype>
              <xsl:variable name="PatientType" select="xifin:PatientType" />
              <xsl:choose>
                <xsl:when test="string-length($PatientType) = 0">
                  <xsl:value-of select="'81'" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$PatientType" />
                </xsl:otherwise>
              </xsl:choose>
            </admpatienttype>
            <admstreet>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:AddressLine1" />
            </admstreet>
            <admstreet2>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:AddressLine2" />
            </admstreet2>
            <admemplzip />
            <ChiefComplaint />
            <ClientID>
              <xsl:value-of select="xifin:ClientId | ClientId" />
            </ClientID>
          </PatientDemographics>
          <DiagnosisCodes>
            <Diag1CodeSet>ICD10</Diag1CodeSet>
            <radAcctNum>
              <xsl:value-of select="xifin:AccessionId" />
            </radAcctNum>
            <xsl:for-each select="xifin:OrderedTests/xifin:DiagnosisCodes">
              <xsl:element name="Diag{position()}">
                <xsl:value-of select="xifin:DiagnosisCode" />
              </xsl:element>
            </xsl:for-each>
          </DiagnosisCodes>
          <Insurance1>
            <adminsinsuredrel>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredRelationship" />
            </adminsinsuredrel>
            <adminsstate>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:State" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:SubscriberId" />
            </adminspolicy>
            <subscribername>
              <xsl:value-of select="concat(xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:LastName, ',', xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:FirstName)" />
            </subscribername>
            <adminszip>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:ZIP" />
            </adminszip>
            <admInsName>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:PayorName" />
            </admInsName>
            <admAcctNum>
              <xsl:value-of select="xifin:AccessionId" />
            </admAcctNum>
            <adminsstreet>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:AddressLine1" />
            </adminsstreet>
            <adminsstreet2>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:AddressLine2" />
            </adminsstreet2>
            <adminscity>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:City" />
            </adminscity>
            <adminsmne>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:PayorId" />
            </adminsmne>
            <adminsinsuredname>
              <xsl:value-of select="concat(xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:LastName, ',', xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:FirstName)" />
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Phone/types:HomePhone" />
            </admInsPhone>
            <adminsgroup>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:GroupId" />
            </adminsgroup>
          </Insurance1>
          <Insurance2 />
          <Insurance3 />
          <Guarantor />
          <xsl:for-each select="xifin:OrderedTests">
            <Charge>
              <radExamServDate>
                <xsl:value-of select="translate(../xifin:DateOfService, '-', '')" />
              </radExamServDate>
              <radPatientName>
                <xsl:value-of select="concat(../xifin:PatientInfo/xifin:Person/types:Name/types:LastName, ', ', ../xifin:PatientInfo/xifin:Person/types:Name/types:FirstName)" />
              </radPatientName>
              <radExamBillingCode>
                <xsl:value-of select="xifin:TestId" />
              </radExamBillingCode>
              <radExamCPT>
                <xsl:value-of select="xifin:TestId" />
              </radExamCPT>
              <radAcctNum>
                <xsl:value-of select="../xifin:AccessionId" />
              </radAcctNum>
              <radNumOfTimes>
                <xsl:value-of select="xifin:Units" />
              </radNumOfTimes>
              <PlaceOfService>
                <xsl:value-of select="xifin:PlaceOfService" />
              </PlaceOfService>
              <RenderingPhysicianNPI>
                <xsl:value-of select="xifin:RenderingPhysician/xifin:NPI" />
              </RenderingPhysicianNPI>
            </Charge>
          </xsl:for-each>
        </Group>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>
