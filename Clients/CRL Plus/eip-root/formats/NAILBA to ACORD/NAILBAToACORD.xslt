<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="converter dtFormatter datetime xsi" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/XCSData">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:TXLife schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
      <ns1:UserAuthRequest>
        <ns1:UserLoginName>
          <xsl:value-of select="NAILBA800/Header/SenderName" />
        </ns1:UserLoginName>
        <ns1:UserPswd>
          <ns1:CryptType />
          <ns1:CryptPswd />
        </ns1:UserPswd>
        <ns1:UserDate>
          <xsl:value-of select="dtFormatter:format(NAILBA800/Header/DateSent,'yyMMdd','yyyy-MM-dd')" />
        </ns1:UserDate>
        <ns1:UserTime>
          <xsl:value-of select="dtFormatter:format(NAILBA800/Header/TimeSent,'HHmmss','HH:mm:ss')" />
        </ns1:UserTime>
        <ns1:VendorApp>
          <ns1:AppName />
          <ns1:AppVer />
        </ns1:VendorApp>
      </ns1:UserAuthRequest>
      <xsl:for-each select="NAILBA800/Request | NAILBA850/Request">
        <ns1:TXLifeRequest PrimaryObjectID="Holding">
          <ns1:TransRefGUID>
            <xsl:value-of select="converter:getGUIDString()" />
          </ns1:TransRefGUID>
          <ns1:TransType>
            <xsl:attribute name="tc">
              <xsl:choose>
                <xsl:when test="../../NAILBA800">121</xsl:when>
                <xsl:otherwise>1122</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="../../NAILBA800">General Requirement Order Request</xsl:when>
              <xsl:otherwise>General Requirement Status/Results Transmittal</xsl:otherwise>
            </xsl:choose>
          </ns1:TransType>
          <ns1:TransExeDate>
            <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
          </ns1:TransExeDate>
          <ns1:TransExeTime>
            <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ss')" />
          </ns1:TransExeTime>
          <xsl:choose>
            <xsl:when test="ReportOrderInsuranceContractInformationRecord/OrderType = 'I'">
              <ns1:TransMode tc="2">Original</ns1:TransMode>
            </xsl:when>
            <xsl:when test="ReportOrderInsuranceContractInformationRecord/OrderType = 'C'">
              <ns1:TransMode tc="6">Cancel</ns1:TransMode>
            </xsl:when>
            <xsl:when test="ReportOrderInsuranceContractInformationRecord/OrderType = 'G'">
              <ns1:TransMode tc="5">Update</ns1:TransMode>
            </xsl:when>
            <xsl:when test="ReportOrderInsuranceContractInformationRecord/OrderType = 'R'">
              <ns1:TransMode tc="4">Replace</ns1:TransMode>
            </xsl:when>
            <xsl:otherwise>
              <!-- unknown order type; treat as new order -->
              <ns1:TransMode tc="2">Original</ns1:TransMode>
            </xsl:otherwise>
          </xsl:choose>
          <ns1:OLifE>
            <ns1:Holding id="Holding">
              <ns1:HoldingTypeCode tc="2">Policy</ns1:HoldingTypeCode>
              <ns1:Policy CarrierPartyID="Carrier" id="Policy_1">
                <ns1:PolNumber>
                  <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/OrderOriginatorQuotebackNumber" />
                </ns1:PolNumber>
                <ns1:CarrierCode>
                  <xsl:value-of select="ReportOrderBillingSegment/ServiceProviderVendorID" />
                </ns1:CarrierCode>
                <ns1:ProductType tc="">
                  <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/InsuranceProductAppliedFor" />
                </ns1:ProductType>
                <ns1:Life>
                  <ns1:FaceAmt>
                    <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/InsuranceAmountOfCoverageAppliedFor" />
                  </ns1:FaceAmt>
                  <ns1:Coverage id="">
                    <ns1:CurrentAmt>
                      <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/InsuranceAmountOfCoverageAppliedFor" />
                    </ns1:CurrentAmt>
                  </ns1:Coverage>
                </ns1:Life>
                <ns1:ApplicationInfo>
                  <ns1:TrackingID>
                    <xsl:value-of select="converter:getGUIDString()" />
                  </ns1:TrackingID>
                </ns1:ApplicationInfo>
                <xsl:for-each select="ReportOrderServiceRequests/ReportOrderServiceRequest">
                  <xsl:if test="not(preceding-sibling::ReportOrderServiceRequest[RecordType=current()/RecordType])">
                    <ns1:RequirementInfo AppliesToPartyID="Patient" FulfillerPartyID="" RequesterPartyID="" id="{concat('Req_', position())}">
                      <xsl:variable name="reqCode">
                        <xsl:choose>
                          <xsl:when test="ServiceRequested = 'APS'">
                            <xsl:value-of select="11" />
                          </xsl:when>
                          <xsl:when test="ServiceRequested = 'PARA'">
                            <xsl:value-of select="10" />
                          </xsl:when>
                          <xsl:when test="ServiceRequested = 'MVR'">
                            <xsl:value-of select="259" />
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="11" />
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <ns1:ReqCode tc="{$reqCode}">
                        <xsl:call-template name="TabularMapping_ReqCode">
                          <xsl:with-param name="value" select="$reqCode" />
                        </xsl:call-template>
                      </ns1:ReqCode>
                      <ns1:CarrierOrderNum>
                        <!--<xsl:value-of select="../../ReportOrderInsuranceContractInformationRecord/ProposedInsuredCarrierCaseReferenceID" />-->
                        <xsl:value-of select="../../ReportOrderInsuranceContractInformationRecord/OrderOriginatorQuotebackNumber" />
                      </ns1:CarrierOrderNum>
                      <ns1:RequirementInfoKey>
                        <xsl:value-of select="Unknown3" />
                      </ns1:RequirementInfoKey>
                      <ns1:RequirementInfoUniqueID>
                        <xsl:value-of select="converter:getGUIDString()" />
                      </ns1:RequirementInfoUniqueID>
                      <ns1:RequestedDate>
                        <xsl:if test="string-length(../../ReportOrderInsuranceContractInformationRecord/OrderRequestDate)=8">
                          <xsl:value-of select="dtFormatter:format(../../ReportOrderInsuranceContractInformationRecord/OrderRequestDate,'yyyyMMdd','yyyy-MM-dd')" />
                        </xsl:if>
                      </ns1:RequestedDate>
                      <ns1:ReleasePartyOrgCode />
                      <ns1:RequirementAcctNum>
                        <xsl:value-of select="../../ReportOrderBillingSegment/BillToVendorAccountNumber" />
                      </ns1:RequirementAcctNum>
                      <ns1:RequirementDetails>
                        <xsl:for-each select="SpecialInstructionsToProvider | following-sibling::ReportOrderServiceRequest[RecordType=current()/RecordType]/SpecialInstructionsToProvider">
                          <xsl:value-of select="." />
                        </xsl:for-each>
                      </ns1:RequirementDetails>
                    </ns1:RequirementInfo>
                  </xsl:if>
                </xsl:for-each>
              </ns1:Policy>
            </ns1:Holding>
            <ns1:Party id="Patient">
              <ns1:PartyTypeCode tc="1">Person</ns1:PartyTypeCode>
              <ns1:FullName>
                <xsl:value-of select="concat(ProposedInsureds/ProposedInsured/FirstName, ' ', ProposedInsureds/ProposedInsured/LastName)" />
              </ns1:FullName>
              <ns1:Address>
                <ns1:Line1>
                  <xsl:value-of select="ReportOrderProposedInsuredResidenceHistory/AddressLine1" />
                </ns1:Line1>
                <ns1:Line2>
                  <xsl:value-of select="ReportOrderProposedInsuredResidenceHistory/AddressLine2" />
                </ns1:Line2>
                <ns1:City>
                  <xsl:value-of select="ReportOrderProposedInsuredResidenceHistory/City" />
                </ns1:City>
                <ns1:AddressCountry>
                  <xsl:value-of select="ReportOrderProposedInsuredResidenceHistory/Country" />
                </ns1:AddressCountry>
                <xsl:variable name="StateToTC">
                  <xsl:call-template name="StateToTCMapping">
                    <xsl:with-param name="valuePreTransform" select="ReportOrderProposedInsuredResidenceHistory/State" />
                  </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="TCToState">
                  <xsl:call-template name="TCToStateMapping">
                    <xsl:with-param name="value" select="$StateToTC" />
                    <xsl:with-param name="default" select="ReportOrderProposedInsuredResidenceHistory/State" />
                  </xsl:call-template>
                </xsl:variable>
                <ns1:AddressStateTC tc="{$StateToTC}">
                  <xsl:value-of select="$TCToState" />
                </ns1:AddressStateTC>
                <ns1:AddressState>
                  <xsl:value-of select="$TCToState" />
                </ns1:AddressState>
                <ns1:Zip>
                  <xsl:value-of select="ReportOrderProposedInsuredResidenceHistory/PostalCode" />
                </ns1:Zip>
                <ns1:AddressCountryTC tc="{ReportOrderProposedInsuredResidenceHistory/Country}">
                  <xsl:value-of select="ReportOrderProposedInsuredResidenceHistory/Country" />
                </ns1:AddressCountryTC>
              </ns1:Address>
              <ns1:Phone>
                <ns1:CountryCode />
                <ns1:AreaCode>
                  <xsl:value-of select="substring(ProposedInsureds/ProposedInsured/HomePhoneNumber,1,3)" />
                </ns1:AreaCode>
                <ns1:DialNumber>
                  <xsl:value-of select="substring(ProposedInsureds/ProposedInsured/HomePhoneNumber,4,7)" />
                </ns1:DialNumber>
                <ns1:PhoneTypeCode tc="1">Home</ns1:PhoneTypeCode>
                <ns1:PrefPhone tc="" />
              </ns1:Phone>
              <xsl:if test="ProposedInsureds/ProposedInsured/WorkPhoneNumber">
                <ns1:Phone>
                  <ns1:CountryCode />
                  <ns1:AreaCode>
                    <xsl:value-of select="substring(ProposedInsureds/ProposedInsured/WorkPhoneNumber,1,3)" />
                  </ns1:AreaCode>
                  <ns1:DialNumber>
                    <xsl:value-of select="substring(ProposedInsureds/ProposedInsured/WorkPhoneNumber,4,7)" />
                  </ns1:DialNumber>
                  <ns1:Ext>
                    <xsl:value-of select="ProposedInsureds/ProposedInsured/WorkPhoneExtension" />
                  </ns1:Ext>
                  <ns1:PhoneTypeCode tc="2">Business</ns1:PhoneTypeCode>
                  <ns1:PrefPhone tc="" />
                </ns1:Phone>
              </xsl:if>
              <xsl:if test="ApplicicantOtherContactInfo/CellPhone1">
                <ns1:Phone>
                  <ns1:CountryCode />
                  <ns1:AreaCode>
                    <xsl:value-of select="substring(ApplicicantOtherContactInfo/CellPhone1,1,3)" />
                  </ns1:AreaCode>
                  <ns1:DialNumber>
                    <xsl:value-of select="substring(ApplicicantOtherContactInfo/CellPhone1,4,7)" />
                  </ns1:DialNumber>
                  <ns1:PhoneTypeCode tc="12">Mobile</ns1:PhoneTypeCode>
                  <ns1:PrefPhone tc="" />
                </ns1:Phone>
              </xsl:if>
              <xsl:if test="ApplicicantOtherContactInfo/CellPhone2">
                <ns1:Phone>
                  <ns1:CountryCode />
                  <ns1:AreaCode>
                    <xsl:value-of select="substring(ApplicicantOtherContactInfo/CellPhone2,1,3)" />
                  </ns1:AreaCode>
                  <ns1:DialNumber>
                    <xsl:value-of select="substring(ApplicicantOtherContactInfo/CellPhone2,4,7)" />
                  </ns1:DialNumber>
                  <ns1:PhoneTypeCode tc="12">Mobile</ns1:PhoneTypeCode>
                  <ns1:PrefPhone tc="" />
                </ns1:Phone>
              </xsl:if>
              <xsl:if test="ReportOrderServiceRequests/ReportOrderServiceRequest/BestTimeToCall">
                <ns1:BestTimeToCallFrom>
                  <xsl:value-of select="ReportOrderServiceRequests/ReportOrderServiceRequest/BestTimeToCall" />
                </ns1:BestTimeToCallFrom>
              </xsl:if>
              <xsl:if test="ApplicicantOtherContactInfo/EmailAddress">
                <ns1:EMailAddress>
                  <ns1:AddrLine>
                    <xsl:value-of select="ApplicicantOtherContactInfo/EmailAddress" />
                  </ns1:AddrLine>
                </ns1:EMailAddress>
              </xsl:if>
              <ns1:GovtID>
                <xsl:value-of select="ProposedInsureds/ProposedInsured/GovernmentID" />
              </ns1:GovtID>
              <xsl:element name="ns1:GovtIDTC">
                <xsl:choose>
                  <xsl:when test="ProposedInsureds/ProposedInsured/GovernmentIDType = 'S' or ProposedInsureds/ProposedInsured/GovernmentIDType = '2'">
                    <xsl:attribute name="tc">
                      <xsl:text>1</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Social Security Number US</xsl:text>
                  </xsl:when>
                  <xsl:when test="ProposedInsureds/ProposedInsured/GovernmentIDType = 'T' or ProposedInsureds/ProposedInsured/GovernmentIDType = '1'">
                    <xsl:attribute name="tc">
                      <xsl:text>9</xsl:text>
                    </xsl:attribute>
                    <xsl:text>Tax ID for US non-resident alien</xsl:text>
                  </xsl:when>
                </xsl:choose>
              </xsl:element>
              <ns1:Person id="">
                <ns1:FirstName>
                  <xsl:value-of select="ProposedInsureds/ProposedInsured/FirstName" />
                </ns1:FirstName>
                <ns1:LastName>
                  <xsl:value-of select="ProposedInsureds/ProposedInsured/LastName" />
                </ns1:LastName>
                <xsl:choose>
                  <xsl:when test="ProposedInsureds/ProposedInsured/Gender = 'F'">
                    <ns1:Gender tc="2">
                      <xsl:text>Female</xsl:text>
                    </ns1:Gender>
                  </xsl:when>
                  <xsl:when test="ProposedInsureds/ProposedInsured/Gender = 'M'">
                    <ns1:Gender tc="1">
                      <xsl:text>Male</xsl:text>
                    </ns1:Gender>
                  </xsl:when>
                </xsl:choose>
                <xsl:element name="ns1:MarStat">
                  <xsl:choose>
                    <xsl:when test="ProposedInsureds/ProposedInsured/MaritalStatus = 'S'">
                      <xsl:attribute name="tc">
                        <xsl:text>2</xsl:text>
                      </xsl:attribute>
                      <xsl:text>Single</xsl:text>
                    </xsl:when>
                    <xsl:when test="ProposedInsureds/ProposedInsured/MaritalStatus = 'M'">
                      <xsl:attribute name="tc">
                        <xsl:text>1</xsl:text>
                      </xsl:attribute>
                      <xsl:text>Married</xsl:text>
                    </xsl:when>
                    <xsl:when test="ProposedInsureds/ProposedInsured/MaritalStatus = 'W'">
                      <xsl:attribute name="tc">
                        <xsl:text>4</xsl:text>
                      </xsl:attribute>
                      <xsl:text>Widowed</xsl:text>
                    </xsl:when>
                    <xsl:when test="ProposedInsureds/ProposedInsured/MaritalStatus = 'D'">
                      <xsl:attribute name="tc">
                        <xsl:text>3</xsl:text>
                      </xsl:attribute>
                      <xsl:text>Divorced</xsl:text>
                    </xsl:when>
                  </xsl:choose>
                </xsl:element>
                <ns1:BirthDate>
                  <xsl:value-of select="dtFormatter:format(ProposedInsureds/ProposedInsured/DateOfBirth,'yyyyMMdd','yyyy-MM-dd')" />
                </ns1:BirthDate>
              </ns1:Person>
              <ns1:Risk>
                <ns1:MedicalExam>
                  <ns1:LabSlipTicketNum />
                </ns1:MedicalExam>
              </ns1:Risk>
              <ns1:Client>
                <ns1:ClientKey>
                  <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/ProposedInsuredCarrierCaseReferenceID" />
                </ns1:ClientKey>
              </ns1:Client>
            </ns1:Party>
            <ns1:Party id="Carrier">
              <ns1:PartyTypeCode tc="2">Organization</ns1:PartyTypeCode>
              <ns1:FullName>
                <xsl:choose>
                  <xsl:when test="ReportOrderBillingSegment/ManagingGeneralAgencyName">
                    <xsl:value-of select="ReportOrderBillingSegment/ManagingGeneralAgencyName" />
                  </xsl:when>
                  <xsl:when test="ReportOrderBillingSegment/InsuranceCarrierNameForReportDelivery">
                    <xsl:value-of select="ReportOrderBillingSegment/InsuranceCarrierNameForReportDelivery" />
                  </xsl:when>
                </xsl:choose>
              </ns1:FullName>
              <ns1:Organization>
                <ns1:AbbrName>
                  <xsl:choose>
                    <xsl:when test="ReportOrderBillingSegment/ServiceProviderVendorID">
                      <xsl:value-of select="ReportOrderBillingSegment/ServiceProviderVendorID" />
                    </xsl:when>
                    <xsl:when test="ReportOrderBillingSegment/ManagingGeneralAgencyName">
                      <xsl:value-of select="ReportOrderBillingSegment/ManagingGeneralAgencyName" />
                    </xsl:when>
                  </xsl:choose>
                </ns1:AbbrName>
              </ns1:Organization>
              <ns1:Phone>
                <ns1:CountryCode />
                <ns1:AreaCode>
                  <xsl:value-of select="substring(ReportOrderBillingSegment/OrderOriginatorContactVoicePhone,1,3)" />
                </ns1:AreaCode>
                <ns1:DialNumber>
                  <xsl:value-of select="substring(ReportOrderBillingSegment/OrderOriginatorContactVoicePhone,4,7)" />
                </ns1:DialNumber>
                <ns1:PhoneTypeCode tc="2">Business</ns1:PhoneTypeCode>
                <ns1:PrefPhone tc="1">True</ns1:PrefPhone>
              </ns1:Phone>
              <ns1:EMailAddress />
              <!--<ns1:GovtID />-->
            </ns1:Party>
            <ns1:Party id="Facility">
              <ns1:PartyTypeCode tc="2">Organization</ns1:PartyTypeCode>
              <ns1:FullName>
                <xsl:value-of select="ReportOrderMedicalHistoryInformation/PhysicianName" />
              </ns1:FullName>
              <ns1:Organization>
                <ns1:AbbrName />
              </ns1:Organization>
              <ns1:Address>
                <ns1:Line1>
                  <xsl:value-of select="ReportOrderMedicalHistoryInformation/PhysicianAddressLine1" />
                </ns1:Line1>
                <ns1:Line2>
                  <xsl:value-of select="ReportOrderMedicalHistoryInformation/PhysicianAddressLine2" />
                </ns1:Line2>
                <ns1:City>
                  <xsl:value-of select="ReportOrderMedicalHistoryInformation/PhysicianCity" />
                </ns1:City>
                <ns1:AddressCountry />
                <xsl:variable name="StateToTC">
                  <xsl:call-template name="StateToTCMapping">
                    <xsl:with-param name="valuePreTransform" select="ReportOrderMedicalHistoryInformation/PhysicianState" />
                  </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="TCToState">
                  <xsl:call-template name="TCToStateMapping">
                    <xsl:with-param name="value" select="$StateToTC" />
                    <xsl:with-param name="default" select="ReportOrderMedicalHistoryInformation/PhysicianState" />
                  </xsl:call-template>
                </xsl:variable>
                <ns1:AddressStateTC tc="{$StateToTC}">
                  <xsl:value-of select="$TCToState" />
                </ns1:AddressStateTC>
                <ns1:AddressState>
                  <xsl:value-of select="$TCToState" />
                </ns1:AddressState>
                <ns1:Zip>
                  <xsl:value-of select="ReportOrderMedicalHistoryInformation/PhysicianPostalCode" />
                </ns1:Zip>
                <ns1:AddressCountryTC tc="" />
              </ns1:Address>
              <ns1:Phone>
                <ns1:CountryCode />
                <ns1:AreaCode>
                  <xsl:value-of select="substring(ReportOrderMedicalHistoryInformation/PhysicianPhoneNumber,1,3)" />
                </ns1:AreaCode>
                <ns1:DialNumber>
                  <xsl:value-of select="substring(ReportOrderMedicalHistoryInformation/PhysicianPhoneNumber,4,7)" />
                </ns1:DialNumber>
                <ns1:PhoneTypeCode tc="2">Business</ns1:PhoneTypeCode>
                <ns1:PrefPhone tc="1">True</ns1:PrefPhone>
              </ns1:Phone>
            </ns1:Party>
            <xsl:if test="string-length(normalize-space(ReportOrderInsuranceContractInformationRecord/WritingAgentLastName)) &gt; 0">
              <ns1:Party id="WritingAgent">
                <ns1:PartyTypeCode tc="1">Person</ns1:PartyTypeCode>
                <ns1:FullName>
                  <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/WritingAgentFirstName" />
                  <xsl:value-of select="' '" />
                  <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/WritingAgentLastName" />
                </ns1:FullName>
                <ns1:Person id="">
                  <ns1:FirstName>
                    <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/WritingAgentFirstName" />
                  </ns1:FirstName>
                  <ns1:LastName>
                    <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/WritingAgentLastName" />
                  </ns1:LastName>
                </ns1:Person>
                <ns1:GovtID>
                  <xsl:value-of select="ReportOrderInsuranceContractInformationRecord/WritingAgentGovernmentID" />
                </ns1:GovtID>
                <xsl:element name="ns1:GovtIDTC">
                  <xsl:choose>
                    <xsl:when test="ReportOrderInsuranceContractInformationRecord/WritingAgentGovernmentIDType = 'S' or ReportOrderInsuranceContractInformationRecord/WritingAgentGovernmentIDType = '2'">
                      <xsl:attribute name="tc">
                        <xsl:text>1</xsl:text>
                      </xsl:attribute>
                      <xsl:text>Social Security Number US</xsl:text>
                    </xsl:when>
                    <xsl:when test="ReportOrderInsuranceContractInformationRecord/WritingAgentGovernmentIDType = 'T' or ReportOrderInsuranceContractInformationRecord/WritingAgentGovernmentIDType = '1'">
                      <xsl:attribute name="tc">
                        <xsl:text>9</xsl:text>
                      </xsl:attribute>
                      <xsl:text>Tax ID for US non-resident alien</xsl:text>
                    </xsl:when>
                  </xsl:choose>
                </xsl:element>
              </ns1:Party>
              <ns1:Relation OriginatingObjectID="Holding" RelatedObjectID="WritingAgent" id="HoldingWritingAgentRelation">
                <ns1:OriginatingObjectType tc="4">Holding</ns1:OriginatingObjectType>
                <ns1:RelatedObjectType tc="6">Party</ns1:RelatedObjectType>
                <ns1:RelationRoleCode tc="37">Primary Writing Agent</ns1:RelationRoleCode>
              </ns1:Relation>
            </xsl:if>
            <ns1:Relation OriginatingObjectID="Holding" RelatedObjectID="Patient" id="HoldingPatientRelation">
              <ns1:OriginatingObjectType tc="4">Holding</ns1:OriginatingObjectType>
              <ns1:RelatedObjectType tc="6">Party</ns1:RelatedObjectType>
              <ns1:RelationRoleCode tc="32">Insured</ns1:RelationRoleCode>
            </ns1:Relation>
            <ns1:Relation OriginatingObjectID="Holding" RelatedObjectID="Carrier" id="HoldingCarrierRelation">
              <ns1:OriginatingObjectType tc="4">Holding</ns1:OriginatingObjectType>
              <ns1:RelatedObjectType tc="36">Carrier</ns1:RelatedObjectType>
              <ns1:RelationRoleCode tc="87">Carrier</ns1:RelationRoleCode>
            </ns1:Relation>
            <ns1:Relation OriginatingObjectID="Holding" RelatedObjectID="Facility" id="HoldingFacilityRelation">
              <ns1:OriginatingObjectType tc="4">Holding</ns1:OriginatingObjectType>
              <ns1:RelatedObjectType tc="169">Physician</ns1:RelatedObjectType>
              <ns1:RelationRoleCode tc="41">Physician</ns1:RelationRoleCode>
            </ns1:Relation>
          </ns1:OLifE>
        </ns1:TXLifeRequest>
      </xsl:for-each>
    </ns1:TXLife>
  </xsl:template>
  <xsl:template name="StateToTCMapping">
    <xsl:param name="valuePreTransform" />
    <xsl:variable name="value" select="translate($valuePreTransform, 'qwertyuioplkjhgfdsazxcvbnm', 'QWERTYUIOPLKJHGFDSAZXCVBNM')" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='UNKNOW'">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AL'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALA'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALAB'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALABAM'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALB'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALBAM'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALBMA'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALABAMA'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AK'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALASK'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALASKA'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Alaska'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARIZ'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARIZON'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARZ'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AZ'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARIZONA'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AR'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARK'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARKAN'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARKANS'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARKNS'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ARKANSAS'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CA'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CAL'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CALIF'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CALIFO'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CALIFORNIA'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CLRADO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CLRDO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='COL'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='COLO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='COLORA'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='COLORADO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CONN'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CONNEC'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CONNET'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CT'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CONNECTICUT'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DE'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DEL'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DELA'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DELAW'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DELAWA'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DELAWARE'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='D C'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='D COL'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DC'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DCOL'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DCOLUM'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DISTCO'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DISTRI'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DISTRICT OF COLUMBIA'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YAP'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YAP'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FL'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FLA'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FLO'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FLOR'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FLRDA'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FLORIDA'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GA'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GEO'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GEOR'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GEORG'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GEORGI'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GRGIA'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GEORGIA'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HAW'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HAWAI'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HAWAII'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HI'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HT'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HW'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HAWAII TERRITORY'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ID'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IDA'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IDAH'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IDAHO'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IL'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ILL'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ILLINO'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ILLN'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ILLNOS'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ILLINOIS'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IN'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IND'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='INDANA'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='INDIAN'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='INDIANA'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IA'">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IOWA'">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KAN'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KANS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KANSAS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KNS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KNSAS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KEN'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KENT'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KENTUC'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KNTKY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KTY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KENTUCKY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LA'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LOUIS'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LOUISI'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LOUISIANA'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAINE'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ME'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MNE'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MRS IS'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MRSIS'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARSHALL ISLANDS'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARYLA'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MD'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MRYLND'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARYLAND'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MA'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAS'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MASS'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MASSAC'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MASSACHUSETTS'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MCHGAN'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MCHGN'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MI'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MICH'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MICHIG'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MICHIGAN'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MINN'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MINNES'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MINSOT'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MN'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MNSOTA'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MINNESOTA'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISS'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISSIP'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISSIS'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MS'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISSISSIPPI'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISSOU'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISSRI'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MO'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MSURI'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MISSOURI'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MNTANA'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MNTN'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MNTNA'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MONT'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MONTA'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MONTAN'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MT'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MONTANA'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NE'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEB'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEBR'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEBRA'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEBRAS'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEBRASKA'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEV'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEVAD'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEVADA'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NV'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NVADA'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NVDA'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEVADA'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N H'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N HAM'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N HAMP'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWHAM'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NH'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NHAM'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NHAMP'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NHAMPS'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEW HAMPSHIRE'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N J'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N JER'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N JERS'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWJER'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJ'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJER'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJERS'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJERSE'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEW JERSEY'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N M'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N MEX'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWMEX'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NM'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NMEX'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NMEXIC'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NMXCO'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEW MEXICO'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N Y'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N YORK'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWYOR'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NY'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NYORK'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEW YORK'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N C'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N CAR'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NC'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NCAR'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NCAROL'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NCRLIN'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NO CAR'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NORTHC'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NORTH CAROLINA'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N D'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N DAK'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ND'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NDAK'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NDAKOT'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NO DAK'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NORTHD'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NORTH DAKOTA'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAR IS'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARIS'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARIANA ISLANDS'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OH'">
        <xsl:text>41</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OHI'">
        <xsl:text>41</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OHIO'">
        <xsl:text>41</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OK'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OKL'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OKLA'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OKLAHO'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OKLAMA'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OKLAHOMA'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OR'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ORE'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OREG'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OREGON'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ORG'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ORGEN'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ORGN'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ORGON'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PALAU'">
        <xsl:text>44</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PEN'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENN'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENNA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENNSA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENNSY'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENSA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENSY'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PENNSYLVANIA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PR'">
        <xsl:text>46</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PUERTO RICO'">
        <xsl:text>46</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='R I'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RD IS'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RDIS'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RH IS '">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RH ISL'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RHIS'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RHISL'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RI'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RHODE ISLAND'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='S C'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='S CAR'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SC'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SCAR'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SCAROL'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SCRLNA'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SO CAR'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SOUTHC'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SOUTH CAROLINA'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='S D'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='S DAK'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SD'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SDAK'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SDAKA'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SDAKOT'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SOUTHD'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SOUTH DAKOTA'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TENESE'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TENN'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TENNES'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TN'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TENNESSEE'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TEX'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TEXAS'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TX'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TXAS'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TXS'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UT'">
        <xsl:text>52</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UTA'">
        <xsl:text>52</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UTAH'">
        <xsl:text>52</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VERM'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VERMON'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VRMNT'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VT'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VERMONT'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VI'">
        <xsl:text>54</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VIRGIN ISLANDS'">
        <xsl:text>54</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VIRG'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VIRGIN'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VRGNA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VRGNIA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VIRGINIA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WA'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WASH'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WASHIN'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WASHTN'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WASHINGTON'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='W VA'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='W VIRG'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WEST V'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WESTV'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WESTVA'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WV'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WVA'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WVIRG'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WVRGNA'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WVRGNI'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WEST VIRGINIA'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WI'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WIS'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WISC'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WISCON'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WISCONSIN'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WY'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYM'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYMG'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYMNG'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYO'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYOM'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYOMIN'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WYOMING'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AB'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALBER'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALBERT'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALBRT'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALTA'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ALBERTA'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='B C'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BC'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BR COL'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BRCOL'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BRCOLU'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BRITISH COLUMBIA'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAN'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MANIT'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MANITO'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MB'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MANITOBA'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N B'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NB'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NBRUN'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NBRUNS'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWBRU'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEW BRUNSWICK'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWFOU'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NF'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NFLD'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NFLND'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NWFLD'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NEWFOUNDLAND'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NT'">
        <xsl:text>106</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NWT'">
        <xsl:text>106</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NWTERR'">
        <xsl:text>106</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NORTHWEST TERRITORIES'">
        <xsl:text>106</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CB'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='N S'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NOVASC'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NS'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CAPE BRETON'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NOVA SCOTIA'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ON'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ONT'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ONTAR'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ONTARI'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ONTARIO'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='P E I'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PE'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PEI'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PEIS'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PEISL'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PREDIS'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PRINCE EDWARD ISLAND'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAGD I'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAGDI'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PQ'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PQUE'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PQUEB'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QC'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QUE'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QUEB'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QUEBEC'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MAGDALENE ISLANDS'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PROVINCE OF QUEBEC'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QUEBEC'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SASK'">
        <xsl:text>111</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SASKAT'">
        <xsl:text>111</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SK'">
        <xsl:text>111</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SASKATCHEWAN'">
        <xsl:text>111</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YKN'">
        <xsl:text>112</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YT'">
        <xsl:text>112</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YUKON'">
        <xsl:text>112</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NU'">
        <xsl:text>113</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NUNAVUT'">
        <xsl:text>113</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AS'">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FM'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GU'">
        <xsl:text>14</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MH'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MP'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PR'">
        <xsl:text>46</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PW'">
        <xsl:text>44</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VI'">
        <xsl:text>54</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AA'">
        <xsl:text>60</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AE'">
        <xsl:text>61</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AP'">
        <xsl:text>62</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>0</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TCToStateMapping">
    <xsl:param name="value" />
    <xsl:param name="default" />
    <xsl:choose>
      <xsl:when test="string-length(normalize-space($default))=2">
        <xsl:value-of select="$default" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>AL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>AK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>AZ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>AR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>CA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>CO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>CT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9'">
        <xsl:text>DE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>DC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>FS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>FL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>GA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>HI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='16'">
        <xsl:text>ID</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>IL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='18'">
        <xsl:text>IN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>IA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>KS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>KY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>LA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>ME</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='24'">
        <xsl:text>MH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>MD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='26'">
        <xsl:text>MA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='27'">
        <xsl:text>MI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='28'">
        <xsl:text>MN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='29'">
        <xsl:text>MS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='30'">
        <xsl:text>MO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>MT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='32'">
        <xsl:text>NE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='33'">
        <xsl:text>NV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='34'">
        <xsl:text>NH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='35'">
        <xsl:text>NJ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='36'">
        <xsl:text>NM</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='37'">
        <xsl:text>NY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='38'">
        <xsl:text>NC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='39'">
        <xsl:text>ND</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='40'">
        <xsl:text>MP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='41'">
        <xsl:text>OH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='42'">
        <xsl:text>OK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='43'">
        <xsl:text>OR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='44'">
        <xsl:text>PW</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='45'">
        <xsl:text>PA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='46'">
        <xsl:text>PR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='47'">
        <xsl:text>RI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='48'">
        <xsl:text>SC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='49'">
        <xsl:text>SD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='50'">
        <xsl:text>TN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='51'">
        <xsl:text>TX</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='52'">
        <xsl:text>UT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='53'">
        <xsl:text>VT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='54'">
        <xsl:text>VI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='55'">
        <xsl:text>VA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='56'">
        <xsl:text>WA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='57'">
        <xsl:text>WV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='58'">
        <xsl:text>WI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='59'">
        <xsl:text>WY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='101'">
        <xsl:text>AB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='102'">
        <xsl:text>BC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='103'">
        <xsl:text>MB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='104'">
        <xsl:text>NB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='105'">
        <xsl:text>NF</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='106'">
        <xsl:text>NT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='107'">
        <xsl:text>NS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='108'">
        <xsl:text>ON</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='109'">
        <xsl:text>PE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='110'">
        <xsl:text>QC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='111'">
        <xsl:text>SK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='112'">
        <xsl:text>YT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='113'">
        <xsl:text>NU</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="string-length(normalize-space($default)) &gt; 0">
            <xsl:value-of select="$default" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>UN</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_ReqCode">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='134'">
        <xsl:text>1035 Exchange Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='706'">
        <xsl:text>1035 Funds Amount Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='801'">
        <xsl:text>2 App Packets Required</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='53'">
        <xsl:text>2 Urine Specimens Voided on Different Days</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='94'">
        <xsl:text>2 View Chest X-Ray; PA &amp; Lateral</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='156'">
        <xsl:text>Absolute Assign of Policy Ownership</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='170'">
        <xsl:text>Accelerated Death Benefit Disclosure</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='654'">
        <xsl:text>Accident Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='839'">
        <xsl:text>Add'l Medical Info Needed from Attending Physician</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='815'">
        <xsl:text>Additional Chest X-Ray</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='814'">
        <xsl:text>Additional ECG</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='902'">
        <xsl:text>Additional Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='167'">
        <xsl:text>Additional Information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='905'">
        <xsl:text>Additional Information from personal physician</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='517'">
        <xsl:text>Additional Regulatory Jurisdiction Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='536'">
        <xsl:text>Adoption Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='837'">
        <xsl:text>Agent's Covering Letter</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='900'">
        <xsl:text>Agent Address</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='152'">
        <xsl:text>Agent Statement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='126'">
        <xsl:text>Amendment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='502'">
        <xsl:text>Analyze Additional Blood Sample</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='503'">
        <xsl:text>Analyze Additional Urine Specimen (HOS)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='498'">
        <xsl:text>Analyze Blood Sample</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='501'">
        <xsl:text>Analyze Blood Sample- Mark for CBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='504'">
        <xsl:text>Analyze Dried Blood Spot</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='507'">
        <xsl:text>Analyze Glucose Tolerance Test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='506'">
        <xsl:text>Analyze Hair Sample</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='505'">
        <xsl:text>Analyze Oral Fluid (Saliva)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='500'">
        <xsl:text>Analyze Urine HIV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='499'">
        <xsl:text>Analyze Urine Specimen (HOS)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='701'">
        <xsl:text>Anti Money-Laundering Training Certification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='157'">
        <xsl:text>Application Clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='633'">
        <xsl:text>Application Delivery Service</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='600'">
        <xsl:text>Application Packet Fulfillment Service</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='635'">
        <xsl:text>Application Packet Pickup Service</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='634'">
        <xsl:text>Application Quality Control Service</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='862'">
        <xsl:text>Application Signed Date</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='315'">
        <xsl:text>Application Supplement (other)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='534'">
        <xsl:text>Appointment - Renewal Fee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='151'">
        <xsl:text>Approval from Reinsurance company</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='181'">
        <xsl:text>APS # 2 Order</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='182'">
        <xsl:text>APS # 3 Order</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='183'">
        <xsl:text>APS # 4 Order</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='184'">
        <xsl:text>APS # 5 Order</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='190'">
        <xsl:text>APS Reimbursement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='662'">
        <xsl:text>Articles of Incorporation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='527'">
        <xsl:text>Assignment of Commission Forms</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='142'">
        <xsl:text>Authorization - Credit Check</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='140'">
        <xsl:text>Authorization - Electronic Funds Transfer</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='143'">
        <xsl:text>Authorization - Other</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='141'">
        <xsl:text>Authorization - Payroll Deduction</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='859'">
        <xsl:text>Authorization to Share Information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='642'">
        <xsl:text>Auto Rebalancing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='514'">
        <xsl:text>Background Check Authorization Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='515'">
        <xsl:text>Background Check Results</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='220'">
        <xsl:text>Bank Draft Authorization Card (Bank information)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='221'">
        <xsl:text>Beneficiary - Change of</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='222'">
        <xsl:text>Beneficiary Clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='693'">
        <xsl:text>Beneficiary Form for Early Death Benefit</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='314'">
        <xsl:text>Billing Control Number</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='542'">
        <xsl:text>Blood A/G Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='572'">
        <xsl:text>Blood AFP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='621'">
        <xsl:text>Blood Albumin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='592'">
        <xsl:text>Blood Alcohol</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='627'">
        <xsl:text>Blood Alkaline Phosphatase</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='594'">
        <xsl:text>Blood Amphetamine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='823'">
        <xsl:text>Blood Analysis - Amylase</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='32'">
        <xsl:text>Blood Analysis - CBC w/ Hemoglobin &amp; Hematocrit</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='33'">
        <xsl:text>Blood Analysis - CBC with Differential</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='824'">
        <xsl:text>Blood Analysis - CK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='36'">
        <xsl:text>Blood Analysis - Fasting Blood Sugar</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='37'">
        <xsl:text>Blood Analysis - Fingerstick Microtainer</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='34'">
        <xsl:text>Blood Analysis - for Cholesterol</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='35'">
        <xsl:text>Blood Analysis - for Creatinine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='38'">
        <xsl:text>Blood Analysis - for GGTP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='39'">
        <xsl:text>Blood Analysis - for Hematocrit</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='40'">
        <xsl:text>Blood Analysis - for Hemoglobin Count</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='41'">
        <xsl:text>Blood Analysis - for Hepatitis Screens</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='42'">
        <xsl:text>Blood Analysis - for Serum Creatinine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='43'">
        <xsl:text>Blood Analysis - for SGOT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='44'">
        <xsl:text>Blood Analysis - for SGPT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='45'">
        <xsl:text>Blood Analysis - SMA 12 Blood Profile</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='46'">
        <xsl:text>Blood Analysis - SMA 24 Blood Profile</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='48'">
        <xsl:text>Blood Analysis - Thyroid Profile Test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='47'">
        <xsl:text>Blood Analysis - Triglycerides</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='825'">
        <xsl:text>Blood Analysis - Vitamin B12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='567'">
        <xsl:text>Blood Anti-HVC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='709'">
        <xsl:text>Blood Apolipoprotein A1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='710'">
        <xsl:text>Blood Apolipoprotein B</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='711'">
        <xsl:text>Blood Apolipoprotein Ratio A1/B</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='611'">
        <xsl:text>Blood Barbituates</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='565'">
        <xsl:text>Blood Basophils %</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='538'">
        <xsl:text>Blood Basophils ABS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='571'">
        <xsl:text>Blood BCGT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='582'">
        <xsl:text>Blood Benzodiazepines</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='557'">
        <xsl:text>Blood Beta-2 Microglobulin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='544'">
        <xsl:text>Blood BUN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='540'">
        <xsl:text>Blood Calcium</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='766'">
        <xsl:text>Blood Cardiac Relative Risk</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='566'">
        <xsl:text>Blood CBC Bands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='546'">
        <xsl:text>Blood CDT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='741'">
        <xsl:text>Blood CDT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='789'">
        <xsl:text>Blood CDT - Quantitative</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='586'">
        <xsl:text>Blood CEA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='715'">
        <xsl:text>Blood Cholesterol/HDL Cholesterol</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='550'">
        <xsl:text>Blood Cocaine Metabolites</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='549'">
        <xsl:text>Blood Cotinine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='618'">
        <xsl:text>Blood cPSA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='765'">
        <xsl:text>Blood CRP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='717'">
        <xsl:text>Blood Differential - Atypical Lymph</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='718'">
        <xsl:text>Blood Differential - Blast</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='719'">
        <xsl:text>Blood Differential - Metamyelocyte</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='720'">
        <xsl:text>Blood Differential - Monocyte</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='721'">
        <xsl:text>Blood Differential - Myelocyte</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='722'">
        <xsl:text>Blood Differential - Promyelocyte</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='612'">
        <xsl:text>Blood Direct Bilirubin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='356'">
        <xsl:text>Blood Draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='640'">
        <xsl:text>Blood Eosinophils %</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='551'">
        <xsl:text>Blood Eosinophils ABS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='545'">
        <xsl:text>Blood Ferritin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='570'">
        <xsl:text>Blood Free PSA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='569'">
        <xsl:text>Blood Free PSA Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='748'">
        <xsl:text>Blood Free T3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='750'">
        <xsl:text>Blood Free Thyroxine Index</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='558'">
        <xsl:text>Blood Fructosamine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='744'">
        <xsl:text>Blood FT4 - Free Thyroxine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='636'">
        <xsl:text>Blood GGT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='714'">
        <xsl:text>Blood Globulin - (Total Protein minus Albumin)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='713'">
        <xsl:text>Blood Glucose</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='553'">
        <xsl:text>Blood Glucose - 1/2 Hour</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='552'">
        <xsl:text>Blood Glucose - 2 Hour</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='589'">
        <xsl:text>Blood Glycated Protein</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='723'">
        <xsl:text>Blood GTT - 1.0 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='724'">
        <xsl:text>Blood GTT - 1.5 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='725'">
        <xsl:text>Blood GTT - 2.5 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='726'">
        <xsl:text>Blood GTT - 3.0 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='740'">
        <xsl:text>Blood HAA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='638'">
        <xsl:text>Blood HBeAb</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='539'">
        <xsl:text>Blood HBeAg</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='568'">
        <xsl:text>Blood HBsAg</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='543'">
        <xsl:text>Blood HDL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='756'">
        <xsl:text>Blood Hepatitis 5-1-1p/c100p Band</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='754'">
        <xsl:text>Blood Hepatitis A</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='755'">
        <xsl:text>Blood Hepatitis A IgM</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='752'">
        <xsl:text>Blood Hepatitis B Core Antibody</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='751'">
        <xsl:text>Blood Hepatitis B Surface Antibody</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='761'">
        <xsl:text>Blood Hepatitis c22p Band</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='757'">
        <xsl:text>Blood Hepatitis c33c Band</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='753'">
        <xsl:text>Blood Hepatitis Core IgM</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='763'">
        <xsl:text>Blood Hepatitis hSOD Band</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='762'">
        <xsl:text>Blood Hepatitis NS5 Band</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='590'">
        <xsl:text>Blood Homocysteine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='624'">
        <xsl:text>Blood Indirect Bilirubin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='541'">
        <xsl:text>Blood Iron</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='620'">
        <xsl:text>Blood LDH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='548'">
        <xsl:text>Blood LDL/HDL Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='716'">
        <xsl:text>Blood LDL Cholesterol</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='554'">
        <xsl:text>Blood Lymphocytes %</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='555'">
        <xsl:text>Blood Lymphocytes ABS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='597'">
        <xsl:text>Blood Marijuana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='625'">
        <xsl:text>Blood MCH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='588'">
        <xsl:text>Blood MCHC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='581'">
        <xsl:text>Blood Methadone</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='580'">
        <xsl:text>Blood Methaqualone</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='616'">
        <xsl:text>Blood Monocytes ABS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='575'">
        <xsl:text>Blood MVC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='613'">
        <xsl:text>Blood Neutrophils %</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='596'">
        <xsl:text>Blood Opiates</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='595'">
        <xsl:text>Blood PCP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='573'">
        <xsl:text>Blood Phosphorus</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='560'">
        <xsl:text>Blood Platelets</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>Blood Pressure Reading</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='826'">
        <xsl:text>Blood Pressure Reading 2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='827'">
        <xsl:text>Blood Pressure Reading 3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='712'">
        <xsl:text>Blood Pro-BNP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3'">
        <xsl:text>Blood Profile (for HIV)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>Blood Profile (Glycohemoblogin) - for testing diabetes</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>Blood Profile &amp; Urine Specimen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='329'">
        <xsl:text>Blood Profile recheck</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='322'">
        <xsl:text>Blood Profile with CDT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='323'">
        <xsl:text>Blood Profile with Drug Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='321'">
        <xsl:text>Blood profile with Hepatitis B Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='324'">
        <xsl:text>Blood Profile with PSA screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='593'">
        <xsl:text>Blood Propoxyphene</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='739'">
        <xsl:text>Blood PSA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='614'">
        <xsl:text>Blood RBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='559'">
        <xsl:text>Blood Segmented Neutrophils</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='609'">
        <xsl:text>Blood Serum Fibronogen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='608'">
        <xsl:text>Blood Serum Hemolysis</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='742'">
        <xsl:text>Blood Serum HIV IFA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='731'">
        <xsl:text>Blood Serum HIV Interpretation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='637'">
        <xsl:text>Blood Serum Index</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='610'">
        <xsl:text>Blood Serum Lipemia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='745'">
        <xsl:text>Blood T-3 Total</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='747'">
        <xsl:text>Blood T-3 Uptake</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='749'">
        <xsl:text>Blood T4 - Thyroxine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='732'">
        <xsl:text>Blood T-Cell: %T-4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='733'">
        <xsl:text>Blood T-Cell: %T-8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='735'">
        <xsl:text>Blood T-Cell: Absolute Lymph T4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='736'">
        <xsl:text>Blood T-Cell: Absolute Lymph T8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='738'">
        <xsl:text>Blood T-Cell: I-3 Positive Suppressors (T8)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='737'">
        <xsl:text>Blood T-Cell: T-4/T-8 Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='734'">
        <xsl:text>Blood T-Cell: Total WBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='626'">
        <xsl:text>Blood Total Bilirubin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='622'">
        <xsl:text>Blood Total Protein</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='746'">
        <xsl:text>Blood TSH - Thyroid Stimulating Hormone</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='628'">
        <xsl:text>Blood Uric Acid</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='743'">
        <xsl:text>Blood Very Low Denstiy Lipid (VLDL)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='556'">
        <xsl:text>Blood WBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='828'">
        <xsl:text>Body Temperature</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='345'">
        <xsl:text>Business Clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='223'">
        <xsl:text>Business Submission Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='224'">
        <xsl:text>Buy-Sell Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='531'">
        <xsl:text>Carrier Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='510'">
        <xsl:text>Carrier-specific supplemental info form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='708'">
        <xsl:text>Carrier-specific Tax Withholding Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='632'">
        <xsl:text>Case Level Requirements Determination</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='225'">
        <xsl:text>Cash With Application Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='86'">
        <xsl:text>Catherization Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='131'">
        <xsl:text>Certified Copy of Trust Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='901'">
        <xsl:text>Change of Name Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='818'">
        <xsl:text>Child Rider Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='659'">
        <xsl:text>Claimant Interview</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='650'">
        <xsl:text>Claim Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='631'">
        <xsl:text>Cognitive Evaluation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='228'">
        <xsl:text>Collateral Assignment Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='49'">
        <xsl:text>Collect Additional Blood Sample</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='50'">
        <xsl:text>Collect Additional Urine Specimen (HOS)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>Collect Blood Sample</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>Collect Blood Sample- Mark for CBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='24'">
        <xsl:text>Collect Dried Blood Spot</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='91'">
        <xsl:text>Collect Glucose Tolerance Test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='629'">
        <xsl:text>Collect Hair Sample</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>Collect Oral Fluid (Saliva)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='327'">
        <xsl:text>Collect Urine HIV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>Collect Urine Specimen (HOS)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='158'">
        <xsl:text>Comparison Statement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='835'">
        <xsl:text>Compensation Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='497'">
        <xsl:text>Complete Questionnaire</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='137'">
        <xsl:text>Conduct Tele-Interview</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='895'">
        <xsl:text>Consumer Disclosure Guide</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='529'">
        <xsl:text>Continuing Education Certification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='516'">
        <xsl:text>Copy of E&amp;O Declaration Page</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='512'">
        <xsl:text>Copy of regulatory jurisdiction license - Non-Resident</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='511'">
        <xsl:text>Copy of regulatory jurisdiction license - Resident</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='230'">
        <xsl:text>Corporate Disclaimer</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='231'">
        <xsl:text>Corporate Financial Statement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='232'">
        <xsl:text>Corporate Resolution</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='806'">
        <xsl:text>Corporation Search</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='159'">
        <xsl:text>Cost Basis Information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='702'">
        <xsl:text>Credit/Debit Card Authorization</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='330'">
        <xsl:text>Criminal Records Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='331'">
        <xsl:text>Criminal Records Report Max coverage</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='667'">
        <xsl:text>Daily Care Notes</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='564'">
        <xsl:text>Data Verification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='233'">
        <xsl:text>Date of Birth</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='784'">
        <xsl:text>DBS - A1c</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='584'">
        <xsl:text>DBS Cholesterol</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='782'">
        <xsl:text>DBS - Cholesterol/HDL Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='617'">
        <xsl:text>DBS Cocaine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='802'">
        <xsl:text>DBS - Cocaine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='619'">
        <xsl:text>DBS Cotinine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='583'">
        <xsl:text>DBS GGT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='783'">
        <xsl:text>DBS - Glucose</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='780'">
        <xsl:text>DBS - HDL Cholesterol</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='615'">
        <xsl:text>DBS HIV Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='781'">
        <xsl:text>DBS - Triglycerides</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='811'">
        <xsl:text>Declaration Release Form for non-res applicants</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='705'">
        <xsl:text>Definition of Life Insurance Selection</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='841'">
        <xsl:text>Details related to other pending applications</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='234'">
        <xsl:text>Details to questions</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='535'">
        <xsl:text>Diagnose</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='519'">
        <xsl:text>Digital signature</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='532'">
        <xsl:text>Direct Deposit Authorization</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='235'">
        <xsl:text>Doctor's Name and Address</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='236'">
        <xsl:text>Doctor's Phone Number</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='666'">
        <xsl:text>Doctor's Plan of Treatment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='707'">
        <xsl:text>Dollar Cost Averaging Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='237'">
        <xsl:text>Drivers License Number</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='319'">
        <xsl:text>Drug Urine Test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='238'">
        <xsl:text>E &amp; O Insurance</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='88'">
        <xsl:text>Echocardiogram - Repeat</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='679'">
        <xsl:text>EKG / ECG - Stress or Treadmill - with Thallium</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='819'">
        <xsl:text>Electronically display/present document</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='810'">
        <xsl:text>Electronically Sign Documents</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='877'">
        <xsl:text>Employee Benefit Review</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='658'">
        <xsl:text>Employer's Statement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='239'">
        <xsl:text>Enrollment Cards</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='240'">
        <xsl:text>Evidence of Age</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='241'">
        <xsl:text>Evidence of Insurability</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='906'">
        <xsl:text>Examiner's Name and Address</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='242'">
        <xsl:text>Exchange Delivery Receipt</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='879'">
        <xsl:text>Exclusion</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='878'">
        <xsl:text>Expensecomp Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='149'">
        <xsl:text>Experience Letter to another company (used in cases of 'churning'; etc. as a notification).</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='661'">
        <xsl:text>Extended Care Facility Statement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='335'">
        <xsl:text>FAA Records Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='243'">
        <xsl:text>Face Amount Requested</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='495'">
        <xsl:text>Face to Face Assessment for Long Term Care</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='795'">
        <xsl:text>Face to Face Cognitive Assessment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='913'">
        <xsl:text>Face to Face Cognitive Assessment Recheck</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='912'">
        <xsl:text>Face to Face Frailty Assessment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='915'">
        <xsl:text>Face to Face Frailty Assessment Recheck</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='350'">
        <xsl:text>Face to Face Inspection plus Credit &amp; Financial Report (billed hourly) - 10 year history</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='911'">
        <xsl:text>Face to Face Mobility Assessment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='914'">
        <xsl:text>Face to Face Mobility Assessment Recheck</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='880'">
        <xsl:text>Farmer's Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='898'">
        <xsl:text>Fees to be paid</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='334'">
        <xsl:text>Financial / Credit Check</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='145'">
        <xsl:text>Financial Report - Audited Business (accountant statements)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='144'">
        <xsl:text>Financial Report - Personal</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='146'">
        <xsl:text>Financial Report - Unaudited Business (profit and loss statements)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='525'">
        <xsl:text>Fingerprint card</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='261'">
        <xsl:text>FINRA Registration Required</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='520'">
        <xsl:text>FINRA U4 (Reg Prods Only) App for Sec Reg</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='521'">
        <xsl:text>FINRA U4 Sts Rpt (from CRD rpt) Sts curr Sec Reg</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='522'">
        <xsl:text>FINRA U5 (Reg Prods Only) Term of prior Sec Reg</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='89'">
        <xsl:text>Forced Expiratory Volume Test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='90'">
        <xsl:text>Forced Expiry Volume Test - Repeat</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='652'">
        <xsl:text>Foreign Death Affidavit</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='244'">
        <xsl:text>Formal Papers</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='903'">
        <xsl:text>Form Clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='808'">
        <xsl:text>Gas chromatography-mass spectrometry (GC/MS)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='813'">
        <xsl:text>Glomerular Filtration Rate (GFR)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='160'">
        <xsl:text>Government Allotment Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='665'">
        <xsl:text>Government Issued Certificate of good standing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='697'">
        <xsl:text>Government Registration Papers</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='245'">
        <xsl:text>Group Census</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='867'">
        <xsl:text>Guarantor Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='809'">
        <xsl:text>HCV PCR (polymerase chain reaction)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='96'">
        <xsl:text>Height</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='764'">
        <xsl:text>Hepatitis RIBA-3 Interpretation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='526'">
        <xsl:text>High School Diploma</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='822'">
        <xsl:text>HIPAA Authorization</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>HIV Consent</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='850'">
        <xsl:text>Identify Applicable Product Page</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='851'">
        <xsl:text>Identify Attending Physician</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='849'">
        <xsl:text>Identify Underwriter</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='683'">
        <xsl:text>Identity Verification Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='246'">
        <xsl:text>Illustration Certificate signed (waiving illustration)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='247'">
        <xsl:text>Illustration - Inforce Illustration</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='248'">
        <xsl:text>Illustration - Revised</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='647'">
        <xsl:text>Important Notice about Information Practices</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='860'">
        <xsl:text>Income Verification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='868'">
        <xsl:text>Independent Legal Opinion (Borrower)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='641'">
        <xsl:text>Indeterminate Premium Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='812'">
        <xsl:text>Indexed Product Acknowledgement Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='892'">
        <xsl:text>Info Request - affiliates outside issuing country</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='249'">
        <xsl:text>Informal Quote</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='875'">
        <xsl:text>Information from confidential source</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='672'">
        <xsl:text>Initial Nursing Home Assessment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='847'">
        <xsl:text>Initial Underwriting Review</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='138'">
        <xsl:text>Inspection Report - Business Beneficiary</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='229'">
        <xsl:text>Insurance Company Contract</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='250'">
        <xsl:text>Insurance History Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='121'">
        <xsl:text>Insurance Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='863'">
        <xsl:text>Insured/Owner Address</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='864'">
        <xsl:text>Insured/Owner Telephone Number</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='821'">
        <xsl:text>Interpret ECG</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='196'">
        <xsl:text>Interview coworkers</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='197'">
        <xsl:text>Interview neighbors</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='251'">
        <xsl:text>IRA Disclosure Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='907'">
        <xsl:text>IRS Request for Individual Tax Return Transcript</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='671'">
        <xsl:text>Itemized Hospital Bill</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='673'">
        <xsl:text>Itemized Nursing Home Bill</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='313'">
        <xsl:text>Juvenile Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='833'">
        <xsl:text>Lab Slip Document</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='252'">
        <xsl:text>Lab slip missing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='899'">
        <xsl:text>Letter Of Authority</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='888'">
        <xsl:text>Letter of Consent</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='150'">
        <xsl:text>Letter to Doctor (used for explanation of findings during application process).</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='669'">
        <xsl:text>License of Agency</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='668'">
        <xsl:text>License of Facility</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='670'">
        <xsl:text>License of Provider of Care</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='253'">
        <xsl:text>Licensing - Agent Multiple Contracting</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='623'">
        <xsl:text>Licensing - Agent Requirement Form (ARF comment)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='254'">
        <xsl:text>Licensing - Agents Current State License (State License Form)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='255'">
        <xsl:text>Licensing - Agents Personal Data Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='836'">
        <xsl:text>Licensing - License Renewal</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='256'">
        <xsl:text>Licensing - Licensing Fee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='257'">
        <xsl:text>Licensing - Producer Info &amp; Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='258'">
        <xsl:text>Licensing - State Appointment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='663'">
        <xsl:text>LLC Operating Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='676'">
        <xsl:text>Loan Carry-Forward Information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='861'">
        <xsl:text>Location application was signed</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='123'">
        <xsl:text>Lost Policy Form Request</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='797'">
        <xsl:text>LTC Older Age Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='884'">
        <xsl:text>Marketing Center Reply</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='530'">
        <xsl:text>Maryland Acknowledgement Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='682'">
        <xsl:text>Medallion Signature Guarantee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='649'">
        <xsl:text>Medical Details Release Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='72'">
        <xsl:text>Medical Exam by Cardiologist</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='74'">
        <xsl:text>Medical Exam by Internist</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='75'">
        <xsl:text>Medical Exam By Pediatrician (Juvenile Medical)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9'">
        <xsl:text>Medical Examination by Senior Doctor</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='73'">
        <xsl:text>Medical Exam with Cardiovascular section</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='876'">
        <xsl:text>Medical records</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='894'">
        <xsl:text>Medical section of application</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='18'">
        <xsl:text>Medical Test - Other</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>MIB Authorization</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>MIB Inquiry</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='340'">
        <xsl:text>MIB Prenotice</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>MIB Request for Details</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='648'">
        <xsl:text>MIB Update</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='695'">
        <xsl:text>Mini Mental State Exam Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='817'">
        <xsl:text>Modified Data Verification report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='840'">
        <xsl:text>Motor Vehicle Authorization Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='259'">
        <xsl:text>Motor Vehicle Report - General Agent ordered</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='853'">
        <xsl:text>Motor Vehicle Report Recheck</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='260'">
        <xsl:text>NAIC Disclosure</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='891'">
        <xsl:text>New Front Page to medical examination</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='136'">
        <xsl:text>Non English Speaking Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='262'">
        <xsl:text>Non-Medical - Details of Answers</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='264'">
        <xsl:text>Non-Medical - Part I</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='265'">
        <xsl:text>Non-Medical - Part II</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='266'">
        <xsl:text>Non-Medical - Signature Required</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='263'">
        <xsl:text>Non-Medical - Unanswered Question</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='674'">
        <xsl:text>Notarized Signature</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='704'">
        <xsl:text>Notice Regarding MECs Required</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='854'">
        <xsl:text>Notify agent of activity</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>Obtain Attending Physician Statement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='848'">
        <xsl:text>Obtain Company Producer Identifier</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='804'">
        <xsl:text>Obtain Information on File</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='803'">
        <xsl:text>Obtain Medical Evidence from other company</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='147'">
        <xsl:text>Obtain Motor Vehicle Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='852'">
        <xsl:text>Obtain Referral</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='130'">
        <xsl:text>Obtain Required Signature</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='805'">
        <xsl:text>Obtain Social Insurance Number</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='681'">
        <xsl:text>Obtain the opinion of the reinsurer</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='785'">
        <xsl:text>Oral Fluid Antibody Screen Interpretation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='787'">
        <xsl:text>Oral Fluid Antibody Screen Interpretation (U.S.)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='786'">
        <xsl:text>Oral Fluid Confirmation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='788'">
        <xsl:text>Oral Fluid Hepatitis B Surface Interpretation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='790'">
        <xsl:text>Oral HGA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='124'">
        <xsl:text>Original Policy or Old Policy Request</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='678'">
        <xsl:text>OSJ Compliance Approval</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2147483647'">
        <xsl:text>Other</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='168'">
        <xsl:text>Other Administrative Requirement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='268'">
        <xsl:text>Other Company's Papers</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='169'">
        <xsl:text>Other Delivery Requirement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='508'">
        <xsl:text>Outsourced Underwriting</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='523'">
        <xsl:text>Outstanding Licensing Fee Money (non resident)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='820'">
        <xsl:text>Outstanding Loan Balance</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='269'">
        <xsl:text>Owner - Change of Ownership</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='344'">
        <xsl:text>Owner Clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='664'">
        <xsl:text>Partnership Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='270'">
        <xsl:text>Passport</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>Pathology Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='807'">
        <xsl:text>Payment Source</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='271'">
        <xsl:text>Pension Plan Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='16'">
        <xsl:text>Perform 1 View X-Ray (Frontal)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='92'">
        <xsl:text>Perform 2 View X-Ray (Frontal &amp; Lateral) OR Hair Analysis</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='97'">
        <xsl:text>Perform Blood Pressure Readings - Different Days</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='71'">
        <xsl:text>Perform Blood Pressure Recheck - Single Visit</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='85'">
        <xsl:text>Perform CAT Scan</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='87'">
        <xsl:text>Perform Echocardiogram</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='796'">
        <xsl:text>Perform Echocardiogram - Regular Stress</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>Perform EKG / ECG (Electrocardiograph)- Resting</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='14'">
        <xsl:text>Perform EKG / ECG -Stress or Treadmill</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>Perform Examination By MD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>Perform Examination By Paramed</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>Perform Examination By Specialist</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='342'">
        <xsl:text>Perform Heart Chart Exam</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='680'">
        <xsl:text>Perform Persantine Stress test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='496'">
        <xsl:text>Perform Physical Measurements</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>Perform Pulmonary Function Test (TVC)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='26'">
        <xsl:text>Perform Short Form Exam By Paramed</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='272'">
        <xsl:text>Personal History Interview</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='318'">
        <xsl:text>Pharmaceutical Profile Consent Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='348'">
        <xsl:text>Pharmaceutical Profile Request</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='798'">
        <xsl:text>Physical Measurements Re-check</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='904'">
        <xsl:text>Place of Birth</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='273'">
        <xsl:text>Plan of Insurance</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='533'">
        <xsl:text>Pledge of Professionalism</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='653'">
        <xsl:text>Police Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='282'">
        <xsl:text>Policy Change Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='816'">
        <xsl:text>Policy Change Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='887'">
        <xsl:text>Policy Declaration</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='343'">
        <xsl:text>Policy Delivery Extension</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='885'">
        <xsl:text>Policy Delivery Instructions</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='132'">
        <xsl:text>Policy Delivery Receipt</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='337'">
        <xsl:text>Policy Issue Date Change (Endorsement)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='845'">
        <xsl:text>Policy Re-issue Request</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='283'">
        <xsl:text>Policy Returned Not Taken</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='699'">
        <xsl:text>Policy Summary</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='842'">
        <xsl:text>Politically Exposed Foreign Person Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='865'">
        <xsl:text>Postal Zipcode Required</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='675'">
        <xsl:text>Power of Attorney</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='643'">
        <xsl:text>Preliminary Statement of Policy Cost</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='844'">
        <xsl:text>Premium Allocation Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='889'">
        <xsl:text>Premium Discrepancy</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='125'">
        <xsl:text>Premium Due Carrier</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='161'">
        <xsl:text>Premium Refund</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='284'">
        <xsl:text>Premium - Verify Mode</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='139'">
        <xsl:text>Prepare Inspection Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='509'">
        <xsl:text>Producer Appointment Data Sheet</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='873'">
        <xsl:text>Provide Best Time to Call</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='834'">
        <xsl:text>Provide Death Certificate</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='332'">
        <xsl:text>Public Records Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='333'">
        <xsl:text>Public Records Report Max Coverage</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='93'">
        <xsl:text>Pulmonary Function Test</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='999'">
        <xsl:text>PVT CSC Used in an inquiry to request all</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='362'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='363'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='364'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='365'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='366'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='367'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='368'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='369'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='370'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='371'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='372'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='373'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='374'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='375'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='376'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='377'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='378'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='379'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='380'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='381'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='382'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='383'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='384'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='385'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='386'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='387'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='388'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='389'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='390'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='391'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='392'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='393'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='394'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='395'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='396'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='397'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='398'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='399'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='400'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='401'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='402'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='403'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='404'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='405'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='406'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='407'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='408'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='409'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='410'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='411'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='412'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='413'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='414'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='415'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='416'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='417'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='418'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='419'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='420'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='421'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='422'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='423'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='424'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='425'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='426'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='427'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='428'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='429'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='430'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='431'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='432'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='433'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='434'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='435'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='436'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='437'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='438'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='439'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='440'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='441'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='442'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='443'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='444'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='445'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='446'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='447'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='448'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='449'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='450'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='451'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='452'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='453'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='454'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='455'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='456'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='457'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='458'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='459'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='460'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='461'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='462'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='463'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='464'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='465'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='466'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='467'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='468'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='469'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='470'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='471'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='472'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='473'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='474'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='475'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='476'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='477'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='478'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='479'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='480'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='481'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='482'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='483'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='484'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='485'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='486'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='487'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='488'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='489'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='490'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='491'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='492'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='493'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='494'">
        <xsl:text>PVT ING</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='171'">
        <xsl:text>PVT Met Initial information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='114'">
        <xsl:text>Questionnaire - Alcohol Usage</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='107'">
        <xsl:text>Questionnaire - Asthma</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='102'">
        <xsl:text>Questionnaire - Aviation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='103'">
        <xsl:text>Questionnaire - Avocation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='692'">
        <xsl:text>Questionnaire - Avocation/Hobby/Aviation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='108'">
        <xsl:text>Questionnaire - Back or Neck Disorder</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='909'">
        <xsl:text>Questionnaire - Ballooning</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='361'">
        <xsl:text>Questionnaire - Blood or Lymph Gland Disorder</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='856'">
        <xsl:text>Questionnaire - Blood Pressure</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='360'">
        <xsl:text>Questionnaire - Bone or Joint Disorder</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='209'">
        <xsl:text>Questionnaire - Business Insurance</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='109'">
        <xsl:text>Questionnaire - Chest Pain</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='203'">
        <xsl:text>Questionnaire - Colitis</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='119'">
        <xsl:text>Questionnaire - Confidential Personal History</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='204'">
        <xsl:text>Questionnaire - Convulsion</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='153'">
        <xsl:text>Questionnaire - Coronary Artery Disease</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='871'">
        <xsl:text>Questionnaire - Critical Illness</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='111'">
        <xsl:text>Questionnaire - Diabetic</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='686'">
        <xsl:text>Questionnaire - Digestive</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='104'">
        <xsl:text>Questionnaire - Diving</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='855'">
        <xsl:text>Questionnaire - Driving History</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='115'">
        <xsl:text>Questionnaire - Drug Usage</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='110'">
        <xsl:text>Questionnaire - Epilepsy</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='687'">
        <xsl:text>Questionnaire - Fainting or Loss Of Consciousness</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='689'">
        <xsl:text>Questionnaire - Family History</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='117'">
        <xsl:text>Questionnaire - Financial Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='883'">
        <xsl:text>Questionnaire - Fishing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='688'">
        <xsl:text>Questionnaire - Foreign Residence/Travel</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='210'">
        <xsl:text>Questionnaire- Foreign Travel</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='205'">
        <xsl:text>Questionnaire - Gastric Disease</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='881'">
        <xsl:text>Questionnaire - Hang Gliding</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='101'">
        <xsl:text>Questionnaire - Hazardous Activities</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='113'">
        <xsl:text>Questionnaire - HIV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='112'">
        <xsl:text>Questionnaire - Indigestion / Ulcer</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='874'">
        <xsl:text>Questionnaire - Key Person Supplement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='869'">
        <xsl:text>Questionnaire - Liver Disorder</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='698'">
        <xsl:text>Questionnaire - Mature Age Focus</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='106'">
        <xsl:text>Questionnaire - Medical</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='118'">
        <xsl:text>Questionnaire - Military</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='910'">
        <xsl:text>Questionnaire - Motor Boat Racing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='200'">
        <xsl:text>Questionnaire - Motor Sports</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='690'">
        <xsl:text>Questionnaire - Mountain Climbing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='206'">
        <xsl:text>Questionnaire - Nervous Disease</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='870'">
        <xsl:text>Questionnaire - Neurological</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='201'">
        <xsl:text>Questionnaire - Occupational Duties</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='120'">
        <xsl:text>Questionnaire - Other</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='843'">
        <xsl:text>Questionnaire - Politically Exposed Foreign Person</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='691'">
        <xsl:text>Questionnaire - Preferred Risk</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='207'">
        <xsl:text>Questionnaire- Psychiatric</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='211'">
        <xsl:text>Questionnaire - Resident Alien</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='886'">
        <xsl:text>Questionnaire - Risk Classification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='882'">
        <xsl:text>Questionnaire - Seasonal</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='208'">
        <xsl:text>Questionnaire - Seizure</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='202'">
        <xsl:text>Questionnaire - Sky Diving</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='872'">
        <xsl:text>Questionnaire - Suicide And Incontestability</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='116'">
        <xsl:text>Questionnaire - Tobacco Usage</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='105'">
        <xsl:text>Questionnaire - Truck Drivers</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='154'">
        <xsl:text>Questionnaire - Universal Life</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='359'">
        <xsl:text>Questionnaire - Urinary or Kidney Disorder</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='358'">
        <xsl:text>Questionnaire - Violation</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='285'">
        <xsl:text>Rate Reduction</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='286'">
        <xsl:text>Refer to Home Office</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='288'">
        <xsl:text>Reinsurance - Automatic</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='287'">
        <xsl:text>Reinsurance - Facultative</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='685'">
        <xsl:text>Release of Assignee's Interest Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='684'">
        <xsl:text>Release of Bankruptcy Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='294'">
        <xsl:text>Release of Liability Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='655'">
        <xsl:text>Replaced Policy Funds</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='694'">
        <xsl:text>Replacement Consent Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='127'">
        <xsl:text>Replacement Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='893'">
        <xsl:text>Replacement form clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='128'">
        <xsl:text>Replacement Letter</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='703'">
        <xsl:text>Reply To an Offer on a Modified Application</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='155'">
        <xsl:text>Reply to memo</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='267'">
        <xsl:text>Reply to Tentative Offer</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='336'">
        <xsl:text>Report from Motor Vehicle records Max Coverage</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>Request for 'Consent for General Blood Testing' Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='162'">
        <xsl:text>Return Alternate Policy</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='163'">
        <xsl:text>Return Conditional Receipt</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='164'">
        <xsl:text>Returned check - (agent must deal with client's bounced check).</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='598'">
        <xsl:text>Review by Carrier's Medical Director or CMO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='838'">
        <xsl:text>Review of cases combined for administration</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='295'">
        <xsl:text>Rollover Amount Due</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='644'">
        <xsl:text>Sales Material Checklist</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='585'">
        <xsl:text>Saliva Cocaine Metabolites</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='591'">
        <xsl:text>Saliva Hepatitis C Ab</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='547'">
        <xsl:text>Saliva Nicotine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='328'">
        <xsl:text>Saliva test with HIV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='897'">
        <xsl:text>Scheduled Date for Appointment</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='70'">
        <xsl:text>Second Medical Examination</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='791'">
        <xsl:text>Serum Appearance</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='696'">
        <xsl:text>Short Portable Mental Status Questionnaire</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='890'">
        <xsl:text>Side Account Transfer Needed</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='677'">
        <xsl:text>Signature Guarantee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='316'">
        <xsl:text>Signature On Agent's Report</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='165'">
        <xsl:text>Signed Application - (applicants signature)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='133'">
        <xsl:text>Signed Illustration</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='296'">
        <xsl:text>Single Case Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='297'">
        <xsl:text>Special Class Letter</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='300'">
        <xsl:text>Special Requirement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='513'">
        <xsl:text>Specific Carrier Contract</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='301'">
        <xsl:text>Split Dollar Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='148'">
        <xsl:text>State Disclosure</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>Statement / Documentation of Good Health</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='227'">
        <xsl:text>Statement from Client</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='135'">
        <xsl:text>Superannuation - application for membership</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='866'">
        <xsl:text>Supplementary Application</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='832'">
        <xsl:text>Support Document to Follow</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='700'">
        <xsl:text>Surrender Charge Acknowledgement Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='645'">
        <xsl:text>Surrender Comparison Index Certification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='651'">
        <xsl:text>Surrendered Policy Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='302'">
        <xsl:text>Surrender Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='320'">
        <xsl:text>Swab Test Oral Fluid Specimen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='129'">
        <xsl:text>Tax Identification Number Request</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='303'">
        <xsl:text>Tax Return - Copy</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='304'">
        <xsl:text>Tax Return - Schedule A</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='351'">
        <xsl:text>Tele-Inspection report - 1 year history</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='354'">
        <xsl:text>Tele-Inspection report plus Credit &amp; Financial Report (billed hourly) - 10 year history</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='353'">
        <xsl:text>Tele-Inspection report plus Credit &amp; Financial report - 5 year history</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='352'">
        <xsl:text>Tele-Inspection report plus Credit report - 3 year history</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='122'">
        <xsl:text>Temporary Insurance Agreement</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='896'">
        <xsl:text>Tenants in Common Ownership Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='846'">
        <xsl:text>Third Party Financial Information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='908'">
        <xsl:text>Third Party Sources of Financial Information</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='51'">
        <xsl:text>Third Urine Specimen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='355'">
        <xsl:text>Transaction Analysis ( overall analysis of each requirement).</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='310'">
        <xsl:text>Trust Agreement Tax ID #</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='311'">
        <xsl:text>Trust Certification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='309'">
        <xsl:text>Trust - Date Of</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='346'">
        <xsl:text>Trustee Clarification</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='312'">
        <xsl:text>Trustee Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='341'">
        <xsl:text>Underwriters Worksheet</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='0'">
        <xsl:text>Unknown</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='357'">
        <xsl:text>Urinalysis</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='829'">
        <xsl:text>Urine Adulterant</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='773'">
        <xsl:text>Urine Amphetamine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='768'">
        <xsl:text>Urine BAB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='758'">
        <xsl:text>Urine Benzodiazepine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='606'">
        <xsl:text>Urine Blood Content</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='769'">
        <xsl:text>Urine Cocaine Metabolite</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='774'">
        <xsl:text>Urine Codeine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='561'">
        <xsl:text>Urine Cotinine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='607'">
        <xsl:text>Urine Creatinine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='767'">
        <xsl:text>Urine DIU</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='604'">
        <xsl:text>Urine Fasting Glucose</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='601'">
        <xsl:text>Urine Glucose</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='603'">
        <xsl:text>Urine Glucose - 1/2 Hour</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='602'">
        <xsl:text>Urine Glucose - 2 Hour</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='574'">
        <xsl:text>Urine Granular Casts</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='727'">
        <xsl:text>Urine GTT - 1.0 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='728'">
        <xsl:text>Urine GTT - 1.5 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='729'">
        <xsl:text>Urine GTT - 2.5 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='730'">
        <xsl:text>Urine GTT - 3.0 hour draw</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='771'">
        <xsl:text>Urine HCG</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='562'">
        <xsl:text>Urine Hyaline Casts</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='563'">
        <xsl:text>Urine Leukocyte Esterase</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='770'">
        <xsl:text>Urine Marijuana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='605'">
        <xsl:text>Urine MC Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='792'">
        <xsl:text>Urine Meperidine Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='760'">
        <xsl:text>Urine Methadone Qualitative CLS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='793'">
        <xsl:text>Urine Methadone Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='779'">
        <xsl:text>Urine Methamphetamine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='776'">
        <xsl:text>Urine Methaqualone</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='772'">
        <xsl:text>Urine Microalbumin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='775'">
        <xsl:text>Urine Morphine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='794'">
        <xsl:text>Urine Oxycodone Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='599'">
        <xsl:text>Urine PC Ratio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='578'">
        <xsl:text>Urine PH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='777'">
        <xsl:text>Urine Phencyclidine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='778'">
        <xsl:text>Urine Propoxyphene</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='830'">
        <xsl:text>Urine Random Opiates</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='576'">
        <xsl:text>Urine RBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='579'">
        <xsl:text>Urine Specific Gravity</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='52'">
        <xsl:text>Urine Specimen (for Prostate Specific Antigen)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='587'">
        <xsl:text>Urine Total Protein</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='759'">
        <xsl:text>Urine Toxicology - Barbiturate</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='577'">
        <xsl:text>Urine WBC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='326'">
        <xsl:text>Urine with Full Drug Screen</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='325'">
        <xsl:text>Urine with Microalbumin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='528'">
        <xsl:text>Verification Form of Govt Tax ID for businesses</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='799'">
        <xsl:text>Vitals: BP Readings / Pulse Only</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='831'">
        <xsl:text>Vitals: BP Readings / Pulse Only 2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='800'">
        <xsl:text>Vitals: Height and Weight Only</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='349'">
        <xsl:text>Vitals / Physical Measurements</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='166'">
        <xsl:text>Void Check - (need voided check from client).</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='305'">
        <xsl:text>W-2 Copy</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='306'">
        <xsl:text>W-4P Withholding Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='646'">
        <xsl:text>W-8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='307'">
        <xsl:text>W-9 Taxpayer Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='308'">
        <xsl:text>WD Tax Form - Permanent Insurance</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='95'">
        <xsl:text>Weight</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='518'">
        <xsl:text>Wet signature</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='858'">
        <xsl:text>Witness Declaration Form</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='857'">
        <xsl:text>Witness Signature on application</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='524'">
        <xsl:text>Work History</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

