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
      <xsl:for-each select="//CreateAccession | //xifin:CreateAccession ">
        <Group key="{translate(xifin:AccessionId | AccessionId,'-A','')}">
          <PatientDemographics>
            <admmaritalstatus>
              <xsl:value-of select="'U'" />
            </admmaritalstatus>
            <admpatstate>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:State | PatientInfo/Address/State" />
            </admpatstate>
            <absAdmitdate>
              <xsl:value-of select="translate(xifin:DateOfService | DateOfService, '-', '')" />
            </absAdmitdate>
            <absdischargedate>
              <xsl:value-of select="translate(xifin:DateOfService | DateOfService, '-', '')" />
            </absdischargedate>
            <admemplname />
            <admzipcode>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:ZIP | PatientInfo/Address/ZIP" />
            </admzipcode>
            <absattendingdocname>
              <xsl:value-of select="xifin:Physicians/xifin:Ordering/xifin:Name | Physicians/Ordering/Name" />
            </absattendingdocname>
            <admemplstreet />
            <admAcctNum>
              <xsl:value-of select="translate(xifin:AccessionId | AccessionId,'-A','')" />
            </admAcctNum>
            <admbirthdate>
              <xsl:value-of select="translate(xifin:PatientInfo/xifin:Person/types:DateOfBirth | PatientInfo/Person/DateOfBirth, '-', '')" />
            </admbirthdate>
            <admLocation>
              <xsl:value-of select="'TO BE FILLED IN LATER'" />
            </admLocation>
            <admpatsex>
              <xsl:value-of select="substring(xifin:PatientInfo/xifin:Person/types:Gender | PatientInfo/Person/Gender, 1, 1)" />
            </admpatsex>
            <admpatphone>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:HomePhone | PatientInfo/Person/HomePhone" />
            </admpatphone>
            <admssn>
              <xsl:choose>
                <xsl:when test="xifin:PatientInfo/xifin:Person/types:SSN | PatientInfo/Person/SSN">
                  <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:SSN | PatientInfo/Person/SSN" />
                </xsl:when>
                <xsl:otherwise>777777777</xsl:otherwise>
              </xsl:choose>
            </admssn>
            <admname>
              <xsl:if test="concat(xifin:PatientInfo/xifin:Person/types:Name/types:LastName | PatientInfo/Person/Name/LastName, ', ',xifin:PatientInfo/xifin:Person/types:Name/types:FirstName | PatientInfo/Person/Name/FirstName) != ', '">
                <xsl:value-of select="concat(xifin:PatientInfo/xifin:Person/types:Name/types:LastName | PatientInfo/Person/Name/LastName, ', ',xifin:PatientInfo/xifin:Person/types:Name/types:FirstName | PatientInfo/Person/Name/FirstName)" />
              </xsl:if>
            </admname>
            <admemplcity />
            <admpatcity>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:City | PatientInfo/Person/Address/City" />
            </admpatcity>
            <admFinClass />
            <AttendDrNPI>
              <xsl:value-of select="xifin:Physicians/xifin:Ordering/xifin:NPI | Physicians/Ordering/NPI" />
            </AttendDrNPI>
            <admpatienttype>
              <xsl:variable name="PatientType" select="xifin:PatientType | PatientType" />
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
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:AddressLine1 | PatientInfo/Person/Address/AddressLine1" />
            </admstreet>
            <admstreet2>
              <xsl:value-of select="xifin:PatientInfo/xifin:Person/types:Address/types:AddressLine2 | PatientInfo/Person/Address/AddressLine2" />
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
              <xsl:value-of select="translate(xifin:AccessionId | AccessionId,'-A','')" />
            </radAcctNum>
            <xsl:variable name="IsClientBill" select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:PayorId = 'C' or InsuranceInfo[PayorPriority='1']/PayorId = 'C'" />
            <xsl:if test="$IsClientBill and (count(xifin:OrderedTests/xifin:DiagnosisCodes) = 0 and count(OrderedTests/DiagnosisCodes) = 0)">
              <xsl:element name="Diag{position()}">
                <xsl:value-of select="'XXX.X'" />
              </xsl:element>
            </xsl:if>
            <xsl:for-each select="xifin:OrderedTests/xifin:DiagnosisCodes/xifin:DiagnosisCode | OrderedTests/DiagnosisCodes/DiagnosisCode">
              <xsl:element name="Diag{position()}">
                <xsl:choose>
                  <xsl:when test="$IsClientBill and string-length(.) = 0">
                    <xsl:value-of select="'XXX.X'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="." />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:element>
            </xsl:for-each>
          </DiagnosisCodes>
          <Insurance1>
            <adminsinsuredrel>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredRelationship | InsuranceInfo[PayorPriority='1']/InsuredRelationship" />
            </adminsinsuredrel>
            <adminsstate>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:State | InsuranceInfo[PayorPriority='1']/Address/State" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:SubscriberId | InsuranceInfo[PayorPriority='1']/SubscriberId" />
            </adminspolicy>
            <subscribername>
              <xsl:if test="concat(xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:LastName | InsuranceInfo[PayorPriority='1']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:FirstName | InsuranceInfo[PayorPriority='1']/InsuredName/FirstName) != ','">
                <xsl:value-of select="concat(xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:LastName | InsuranceInfo[PayorPriority='1']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:FirstName | InsuranceInfo[PayorPriority='1']/InsuredName/FirstName)" />
              </xsl:if>
            </subscribername>
            <adminszip>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:ZIP | InsuranceInfo[PayorPriority='1']/Address/ZIP" />
            </adminszip>
            <admInsName>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:PayorName | InsuranceInfo[PayorPriority='1']/PayorName" />
            </admInsName>
            <admAcctNum>
              <xsl:value-of select="translate(xifin:AccessionId | AccessionId,'-A','')" />
            </admAcctNum>
            <adminsstreet>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:AddressLine1 | InsuranceInfo[xifin:PayorPriority='1']/Address/AddressLine1" />
            </adminsstreet>
            <adminsstreet2>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:AddressLine2 | InsuranceInfo[xifin:PayorPriority='1']/Address/AddressLine2" />
            </adminsstreet2>
            <adminscity>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Address/types:City | InsuranceInfo[xifin:PayorPriority='1']/Address/City" />
            </adminscity>
            <adminsmne>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:PayorId | InsuranceInfo[xifin:PayorPriority='1']/PayorId" />
            </adminsmne>
            <adminsinsuredname>
              <xsl:if test="concat(xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:LastName | InsuranceInfo[xifin:PayorPriority='1']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:FirstName | InsuranceInfo[xifin:PayorPriority='1']/InsuredName/FirstName       ) != ','">
                <xsl:value-of select="concat(xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:LastName | InsuranceInfo[xifin:PayorPriority='1']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:InsuredName/types:FirstName | InsuranceInfo[xifin:PayorPriority='1']/InsuredName/FirstName       )" />
              </xsl:if>
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='1']/xifin:Phone/types:HomePhone | InsuranceInfo[xifin:PayorPriority='1']/Phone/HomePhone" />
            </admInsPhone>
            <adminsgroup />
          </Insurance1>
          <Insurance2>
            <adminsinsuredrel>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredRelationship | InsuranceInfo[PayorPriority='2']/InsuredRelationship" />
            </adminsinsuredrel>
            <adminsstate>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:Address/types:State | InsuranceInfo[PayorPriority='2']/Address/State" />
            </adminsstate>
            <adminspolicy>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:SubscriberId | InsuranceInfo[PayorPriority='2']/SubscriberId" />
            </adminspolicy>
            <subscribername>
              <xsl:if test="concat(xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:LastName | InsuranceInfo[PayorPriority='2']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:FirstName | InsuranceInfo[PayorPriority='2']/InsuredName/FirstName) != ','">
                <xsl:value-of select="concat(xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:LastName | InsuranceInfo[PayorPriority='2']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:FirstName | InsuranceInfo[PayorPriority='2']/InsuredName/FirstName)" />
              </xsl:if>
            </subscribername>
            <adminszip>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:Address/types:ZIP | InsuranceInfo[PayorPriority='2']/Address/ZIP" />
            </adminszip>
            <admInsName>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:PayorName | InsuranceInfo[PayorPriority='2']/PayorName" />
            </admInsName>
            <admAcctNum>
              <xsl:value-of select="translate(xifin:AccessionId | AccessionId,'-A','')" />
            </admAcctNum>
            <adminsstreet>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:Address/types:AddressLine1 | InsuranceInfo[xifin:PayorPriority='2']/Address/AddressLine1" />
            </adminsstreet>
            <adminsstreet2>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:Address/types:AddressLine2 | InsuranceInfo[xifin:PayorPriority='2']/Address/AddressLine2" />
            </adminsstreet2>
            <adminscity>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:Address/types:City | InsuranceInfo[xifin:PayorPriority='2']/Address/City" />
            </adminscity>
            <adminsmne>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:PayorId | InsuranceInfo[xifin:PayorPriority='2']/PayorId" />
            </adminsmne>
            <adminsinsuredname>
              <xsl:if test="concat(xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:LastName | InsuranceInfo[xifin:PayorPriority='2']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:FirstName | InsuranceInfo[xifin:PayorPriority='2']/InsuredName/FirstName       ) != ','">
                <xsl:value-of select="concat(xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:LastName | InsuranceInfo[xifin:PayorPriority='2']/InsuredName/LastName, ',',xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:InsuredName/types:FirstName | InsuranceInfo[xifin:PayorPriority='2']/InsuredName/FirstName       )" />
              </xsl:if>
            </adminsinsuredname>
            <admInsPhone>
              <xsl:value-of select="xifin:InsuranceInfo[xifin:PayorPriority='2']/xifin:Phone/types:HomePhone | InsuranceInfo[xifin:PayorPriority='2']/Phone/HomePhone" />
            </admInsPhone>
            <adminsgroup />
          </Insurance2>
          <!--THEY DON'T HAVE INS3 INFORMATION-->
          <Insurance3 />
          <!--THEY DON'T HAVE GUARANTOR INFORMATION-->
          <Guarantor />
          <xsl:for-each select="xifin:OrderedTests | OrderedTests">
            <Charge>
              <radExamServDate>
                <xsl:value-of select="translate(../xifin:DateOfService | ../DateOfService, '-', '')" />
              </radExamServDate>
              <radPatientName>
                <xsl:if test="concat(../xifin:PatientInfo/xifin:Person/types:Name/types:LastName | ../PatientInfo/Person/Name/LastName, ', ', ../xifin:PatientInfo/xifin:Person/types:Name/types:FirstName | ../PatientInfo/Person/Name/FirstName) != ', '">
                  <xsl:value-of select="concat(../xifin:PatientInfo/xifin:Person/types:Name/types:LastName | ../PatientInfo/Person/Name/LastName, ', ', ../xifin:PatientInfo/xifin:Person/types:Name/types:FirstName | ../PatientInfo/Person/Name/FirstName)" />
                </xsl:if>
              </radPatientName>
              <radExamBillingCode>
                <xsl:value-of select="xifin:TestId | TestId" />
              </radExamBillingCode>
              <radExamCPT>
                <xsl:value-of select="xifin:TestId | TestId" />
              </radExamCPT>
              <radAcctNum>
                <xsl:value-of select="translate(../xifin:AccessionId | ../AccessionId,'-A','')" />
              </radAcctNum>
              <radNumOfTimes>
                <xsl:value-of select="xifin:Units | Units" />
              </radNumOfTimes>
              <PlaceOfService>
                <xsl:variable name="PlaceOfService" select="xifin:PlaceOfService | PlaceOfService" />
                <xsl:choose>
                  <xsl:when test="$PlaceOfService = 'ECP' or $PlaceOfService = 'INSTRIDE'">
                    <xsl:value-of select="'ECPECP'" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$PlaceOfService" />
                  </xsl:otherwise>
                </xsl:choose>
              </PlaceOfService>
              <RenderingPhysicianNPI>
                <xsl:choose>
                  <xsl:when test="string-length(xifin:RenderingPhysician/xifin:NPI) = 0 and string-length(RenderingPhysician/NPI) = 0">
                    <xsl:value-of select="xifin:RenderingPhysician/xifin:Name | RenderingPhysician/Name" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="xifin:RenderingPhysician/xifin:NPI | RenderingPhysician/NPI" />
                  </xsl:otherwise>
                </xsl:choose>
              </RenderingPhysicianNPI>
            </Charge>
          </xsl:for-each>
        </Group>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

