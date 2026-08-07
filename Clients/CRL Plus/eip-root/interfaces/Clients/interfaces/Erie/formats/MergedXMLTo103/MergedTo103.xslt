<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bo="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:str="http://exslt.org/strings" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="converter str datetime dtFormatter ta td" extension-element-prefixes="converter" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/GenerationData_103">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <TXLife xmlns="http://ACORD.org/Standards/Life/2" xmlns:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.23.00.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Version="2.23.00">
      <UserAuthRequest xmlns="">
        <VendorApp>
          <VendorName VendorCode="{Data_1122/bo:TXLife/bo:UserAuthRequest/bo:VendorApp/bo:VendorName/@VendorCode}">
            <xsl:value-of select="Data_1122/bo:TXLife/bo:UserAuthRequest/bo:VendorApp/bo:VendorName" />
          </VendorName>
          <AppName>
            <xsl:value-of select="Data_1122/bo:TXLife/bo:UserAuthRequest/bo:VendorApp/bo:AppName" />
          </AppName>
          <AppVer>
            <xsl:value-of select="Data_1122/bo:TXLife/bo:UserAuthRequest/bo:VendorApp/bo:AppVer" />
          </AppVer>
        </VendorApp>
        <OLifEExtension ExtensionCode="6778" VendorCode="220">
          <DellTransRefGUID>
            <xsl:choose>
              <xsl:when test="string-length(TeledexDBData/RESULTS/POLICYDATA/DELLTRANSREFGUID) &gt; 0">
                <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/DELLTRANSREFGUID" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="Data_103/bo:TXLife/bo:UserAuthRequest/bo:OLifEExtension/bo:DellTransRefGUID" />
              </xsl:otherwise>
            </xsl:choose>
          </DellTransRefGUID>
          <CompanyNumber>
            <xsl:value-of select="converter:getAttributeString('CurrentCRLEnvironmentFlag_Form_103')" />
          </CompanyNumber>
        </OLifEExtension>
      </UserAuthRequest>
      <TXLifeRequest xmlns="" PrimaryObjectID="Holding_Primary">
        <TransRefGUID>
          <!--<xsl:value-of select="converter:getGUIDString()" />-->
          <xsl:choose>
            <xsl:when test="string-length(TeledexDBData/RESULTS/POLICYDATA/TRANSREFGUID) &gt; 0">
              <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/TRANSREFGUID" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="Data_103/bo:TXLife/bo:TXLifeRequest/bo:TransRefGUID" />
            </xsl:otherwise>
          </xsl:choose>
        </TransRefGUID>
        <TransType tc="103">New Business Submission</TransType>
        <TransExeDate>
          <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ssXXX')" />
        </TransExeTime>
        <OLifE>
          <SourceInfo>
            <CreationDate>
              <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
            </CreationDate>
            <CreationTime>
              <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ssXXX')" />
            </CreationTime>
            <SourceInfoName>
              <xsl:value-of select="Data_1122/bo:TXLife/bo:TXLifeRequest/bo:OLifE/bo:SourceInfo/bo:SourceInfoName" />
            </SourceInfoName>
          </SourceInfo>
          <Holding id="Holding_Primary">
            <Policy>
              <PolNumber>
                <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/POLICY" />
              </PolNumber>
              <ProductCode>Term</ProductCode>
              <CarrierCode>5340</CarrierCode>
              <PlanName>
                <xsl:call-template name="TabularMapping_PlanName_Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PLANNAME" />
                </xsl:call-template>
              </PlanName>
              <PolicyStatus tc="56">Reentry Pending</PolicyStatus>
              <xsl:choose>
                <xsl:when test="TeledexDBData/RESULTS/POLICYDATA/REPLACETYPE='Y'">
                  <ReplacementType tc="9">Internal Replacement</ReplacementType>
                </xsl:when>
                <xsl:when test="TeledexDBData/RESULTS/POLICYDATA/REPLACETYPE='N'">
                  <ReplacementType tc="3">External Replacement</ReplacementType>
                </xsl:when>
                <xsl:otherwise>
                  <ReplacementType tc="0">Unknown</ReplacementType>
                </xsl:otherwise>
              </xsl:choose>
              <PaymentMode>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_PaymentMode_TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PAYMENTMODE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_PaymentMode_Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PAYMENTMODE" />
                </xsl:call-template>
              </PaymentMode>
              <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/PAYMENTMETHOD != ''">
                <PaymentMethod>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_PaymentMethod_TC_Mapping">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PAYMENTMETHOD" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_PaymentMethod_Desc_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PAYMENTMETHOD" />
                  </xsl:call-template>
                </PaymentMethod>
              </xsl:if>
              <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/ACCOUNTNUMBER != ''">
                <AccountNumber>
                  <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/ACCOUNTNUMBER" />
                </AccountNumber>
              </xsl:if>
              <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/ROUTINGNUMBER != ''">
                <RoutingNumber>
                  <xsl:value-of select="format-number(TeledexDBData/RESULTS/POLICYDATA/ROUTINGNUMBER,str:padding(9,'0'))" />
                </RoutingNumber>
              </xsl:if>
              <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/CHECKINGACCOUNT != ''">
                <BankAcctType>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_BankAcctType_TC_Mapping">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/CHECKINGACCOUNT" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/CHECKINGACCOUNT" />
                </BankAcctType>
              </xsl:if>
              <Life>
                <QualPlanType tc="1">Non-Qualified</QualPlanType>
                <Coverage>
                  <PlanName>
                    <xsl:call-template name="TabularMapping_PlanName_Desc_Mapping">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PLANNAME" />
                    </xsl:call-template>
                  </PlanName>
                  <IndicatorCode tc="1">Base</IndicatorCode>
                  <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/DEATHBENEFITOPTTYPE != '' and TeledexDBData/RESULTS/POLICYDATA[contains('7,|8,|9,|10,|11,|',DEATHBENEFITOPTTYPE)]">
                    <DeathBenefitOptType>
                      <xsl:attribute name="tc">
                        <xsl:call-template name="TabularMapping_DEATHBENEFIT_TC_Mapping">
                          <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/DEATHBENEFITOPTTYPE" />
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:call-template name="TabularMapping_DEATHBENEFIT_Desc_Mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/DEATHBENEFITOPTTYPE" />
                      </xsl:call-template>
                    </DeathBenefitOptType>
                  </xsl:if>
                  <CurrentAmt>
                    <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/POLAMT" />
                  </CurrentAmt>
                  <xsl:if test="(TeledexDBData/RESULTS/POLICYDATA/PREMIUMPERIOD='1,') or (TeledexDBData/RESULTS/POLICYDATA/PREMIUMPERIOD='2,') or (TeledexDBData/RESULTS/POLICYDATA/PREMIUMPERIOD='3,') or (TeledexDBData/RESULTS/POLICYDATA/PREMIUMPERIOD='4,')">
                    <LevelPremiumPeriod>
                      <xsl:call-template name="TabularMapping_Premium_Period_Desc_Mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/POLICYDATA/PREMIUMPERIOD" />
                      </xsl:call-template>
                    </LevelPremiumPeriod>
                  </xsl:if>
                  <CovOption>
                    <PlanName>Accelerated Death Benefit</PlanName>
                  </CovOption>
                  <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/WP != ''">
                    <CovOption>
                      <PlanName>Waiver of Premium</PlanName>
                    </CovOption>
                  </xsl:if>
                  <LifeParticipant PartyID="Party_PrimaryInsured" id="LifeParticipant_PrimaryInsured">
                    <LifeParticipantRoleCode tc="1">Primary Insured</LifeParticipantRoleCode>
                  </LifeParticipant>
                  <LifeParticipant PartyID="Party_PrimaryAgent" id="LifeParticipant_PrimaryAgent">
                    <LifeParticipantRoleCode tc="15">Primary Agent</LifeParticipantRoleCode>
                  </LifeParticipant>
                  <LifeParticipant PartyID="Party_Owner" id="LifeParticipant_Owner">
                    <LifeParticipantRoleCode tc="18">Owner</LifeParticipantRoleCode>
                  </LifeParticipant>
                  <LifeParticipant PartyID="Party_Payor" id="LifeParticipant_Payor">
                    <LifeParticipantRoleCode tc="12">Payor</LifeParticipantRoleCode>
                  </LifeParticipant>
                  <!-- Primary Beneficiary Life Participant Nodes logic -->
                  <xsl:if test="(TeledexDBData/RESULTS/SINGLEPRIMARYDATA/FOUND='1')">
                    <LifeParticipant DataRep="Partial" PartyID="Party_PrimaryBene_1" id="LifeParticipant_PrimaryBene_1">
                      <LifeParticipantRoleCode tc="7">Beneficiary - Primary</LifeParticipantRoleCode>
                      <BeneficiaryPercentDistribution>
                        <xsl:value-of select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENSHARE" />
                      </BeneficiaryPercentDistribution>
                    </LifeParticipant>
                    <xsl:for-each select="TeledexDBData/RESULTS/MULTIPRIMARYDATA">
                      <LifeParticipant DataRep="Partial" PartyID="Party_PrimaryBene_{ID}" id="LifeParticipant_PrimaryBene_{ID}">
                        <LifeParticipantRoleCode tc="7">Beneficiary - Primary</LifeParticipantRoleCode>
                        <BeneficiaryPercentDistribution>
                          <xsl:value-of select="normalize-space(str:split(PRIBENLOOP,'|')[2])" />
                        </BeneficiaryPercentDistribution>
                      </LifeParticipant>
                    </xsl:for-each>
                  </xsl:if>
                  <!-- Contingent Beneficiary Life Participant Nodes logic -->
                  <xsl:if test="(TeledexDBData/RESULTS/SINGLECONTINGENTDATA/FOUND='1')">
                    <LifeParticipant DataRep="Partial" PartyID="Party_ContingentBene_1" id="LifeParticipant_ContingentBene_1">
                      <LifeParticipantRoleCode tc="9">Beneficiary - Contingent</LifeParticipantRoleCode>
                      <BeneficiaryPercentDistribution>
                        <xsl:value-of select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENSHARE" />
                      </BeneficiaryPercentDistribution>
                    </LifeParticipant>
                    <xsl:for-each select="TeledexDBData/RESULTS/MULTICONTINGENTDATA">
                      <LifeParticipant DataRep="Partial" PartyID="Party_ContingentBene_{ID}" id="LifeParticipant_ContingentBene_{ID}">
                        <LifeParticipantRoleCode tc="9">Beneficiary - Contingent</LifeParticipantRoleCode>
                        <BeneficiaryPercentDistribution>
                          <xsl:value-of select="normalize-space(str:split(CONTBENLOOP,'|')[2])" />
                        </BeneficiaryPercentDistribution>
                      </LifeParticipant>
                    </xsl:for-each>
                  </xsl:if>
                </Coverage>
                <xsl:if test="count(TeledexDBData/RESULTS/OTHERINSUREDDATA/CHILDNUMBERUNITS) &gt; 0">
                  <Coverage>
                    <PlanName>Childrens Term Insurance</PlanName>
                    <IndicatorCode tc="2">Rider</IndicatorCode>
                    <IntialNumberOfUnits>
                      <xsl:value-of select="TeledexDBData/RESULTS/OTHERINSUREDDATA[1]/CHILDNUMBERUNITS" />
                    </IntialNumberOfUnits>
                    <xsl:for-each select="TeledexDBData/RESULTS/OTHERINSUREDDATA">
                      <LifeParticipant PartyID="Party_OtherInsured_CTI_{ID}" id="LifeParticipant_OtherInsured_CTI_{ID}">
                        <LifeParticipantRoleCode tc="2">Other Insured</LifeParticipantRoleCode>
                      </LifeParticipant>
                    </xsl:for-each>
                  </Coverage>
                </xsl:if>
              </Life>
              <ApplicationInfo>
                <TrackingID>
                  <xsl:value-of select="converter:getAttributeString('tracking_id')" />
                </TrackingID>
                <ApplicationJurisdiction>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/SIGNATUREDATA/JURISDICTION" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:value-of select="TeledexDBData/RESULTS/SIGNATUREDATA/JURISDICTION" />
                </ApplicationJurisdiction>
                <SignatureInfo>
                  <SignatureRoleCode tc="1">Primary Insured</SignatureRoleCode>
                  <SignatureDate>
                    <xsl:choose>
                      <xsl:when test="string-length(TeledexDBData/RESULTS/SIGNATUREDATA/BRCOMPDT) &gt; 0">
                        <xsl:value-of select="dtFormatter:format(TeledexDBData/RESULTS/SIGNATUREDATA/BRCOMPDT,'yyyy-MM-dd','yyyy-MM-dd')" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </SignatureDate>
                  <SignatureState>
                    <xsl:attribute name="tc">
                      <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/SIGNATUREDATA/JURISDICTION" />
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:value-of select="TeledexDBData/RESULTS/SIGNATUREDATA/JURISDICTION" />
                  </SignatureState>
                  <SignatureOK tc="1">True</SignatureOK>
                </SignatureInfo>
                <SignatureInfo>
                  <SignatureRoleCode tc="15">Primary Agent</SignatureRoleCode>
                  <SignatureDate>
                    <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
                  </SignatureDate>
                  <SignatureState>
                    <xsl:attribute name="tc">
                      <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/SIGNATUREDATA/JURISDICTION" />
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:value-of select="TeledexDBData/RESULTS/SIGNATUREDATA/JURISDICTION" />
                  </SignatureState>
                  <SignatureOK tc="1">True</SignatureOK>
                </SignatureInfo>
              </ApplicationInfo>
              <RequirementInfo AppliesToPartyID="Party_PrimaryInsured" id="Req1">
                <ReqCode tc="137">Tele-Interview</ReqCode>
                <RequestedDate>
                  <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
                </RequestedDate>
                <ReleasePartyOrgCode>ELFP</ReleasePartyOrgCode>
                <RequirementAcctNum>71661</RequirementAcctNum>
              </RequirementInfo>
            </Policy>
            <xsl:if test="TeledexDBData/RESULTS/POLICYDATA/MULTIPLEPOLICY != ''">
              <Attachment>
                <Description>
                  <xsl:value-of select="TeledexDBData/RESULTS/POLICYDATA/MULTIPLEPOLICY" />
                </Description>
                <AttachmentType tc="2">Comment</AttachmentType>
              </Attachment>
            </xsl:if>
          </Holding>
          <!-- Primary Insured Party Node -->
          <Party id="Party_PrimaryInsured">
            <PartyTypeCode tc="1">Person</PartyTypeCode>
            <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPGOVID != ''">
              <GovtID>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPGOVID" />
              </GovtID>
              <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
            </xsl:if>
            <Person DataRep="Partial">
              <FirstName>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPFNAME" />
              </FirstName>
              <LastName>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPLNAME" />
              </LastName>
              <Gender tc="{TeledexDBData/RESULTS/APPLICANTDATA/APPGENDER}">
                <xsl:call-template name="TabularMapping_Gender_Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPGENDER" />
                </xsl:call-template>
              </Gender>
              <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPDOB != ''">
                <BirthDate>
                  <xsl:call-template name="TeledexDateFormatter">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPDOB" />
                  </xsl:call-template>
                </BirthDate>
              </xsl:if>
              <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPHEIGHT">
                <Height2>
                  <MeasureUnits tc="2">US System Standard</MeasureUnits>
                  <MeasureValue>
                    <xsl:value-of select="number(TeledexDBData/RESULTS/APPLICANTDATA/APPHEIGHT)*12" />
                  </MeasureValue>
                </Height2>
              </xsl:if>
              <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPWEIGHT != ''">
                <Weight2>
                  <MeasureUnits tc="2">US System Standard</MeasureUnits>
                  <MeasureValue>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPWEIGHT" />
                  </MeasureValue>
                </Weight2>
              </xsl:if>
              <BirthJurisdictionTC>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPBIRTHPL" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPBIRTHPL" />
              </BirthJurisdictionTC>
            </Person>
            <Address id="APP_ADDRESS">
              <Line1>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSLINE1" />
              </Line1>
              <City>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSCITY" />
              </City>
              <AddressStateTC>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSST" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSST" />
              </AddressStateTC>
              <Zip>
                <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSZIP" />
              </Zip>
            </Address>
            <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPCPHONE != ''">
              <Phone id="APP_CPhone">
                <PhoneTypeCode tc="12">Mobile</PhoneTypeCode>
                <AreaCode>
                  <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPCPHONEACODE" />
                </AreaCode>
                <DialNumber>
                  <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPCPHONE" />
                </DialNumber>
              </Phone>
            </xsl:if>
            <EMailAddress>
              <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPEMAIL != ''">
                <AddrLine>
                  <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPEMAIL" />
                </AddrLine>
              </xsl:if>
              <OLifEExtension VendorCode="84">
                <xsl:choose>
                  <xsl:when test="TeledexDBData/RESULTS/APPLICANTDATA/APPOPTIN != ''">
                    <eDeliveryOptIn>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPOPTIN" />
                    </eDeliveryOptIn>
                  </xsl:when>
                  <xsl:otherwise>
                    <eDeliveryOptIn>NN</eDeliveryOptIn>
                  </xsl:otherwise>
                </xsl:choose>
              </OLifEExtension>
            </EMailAddress>
          </Party>
          <!-- Primary Other Insured Party Nodes -->
          <xsl:for-each select="TeledexDBData/RESULTS/OTHERINSUREDDATA">
            <Party id="Party_OtherInsured_CTI_{ID}">
              <PartyTypeCode tc="1">Person</PartyTypeCode>
              <GovtID>
                <xsl:value-of select="normalize-space(str:split(CHILDRIDER,'|')[7])" />
              </GovtID>
              <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
              <Person>
                <xsl:if test="substring-before(normalize-space(str:split(CHILDRIDER,'|')[1]),' ')!=''">
                  <FirstName>
                    <xsl:value-of select="substring-before(normalize-space(str:split(CHILDRIDER,'|')[1]),' ')" />
                  </FirstName>
                </xsl:if>
                <xsl:if test="substring-after(normalize-space(str:split(CHILDRIDER,'|')[1]),' ')!=''">
                  <LastName>
                    <xsl:value-of select="substring-after(normalize-space(str:split(CHILDRIDER,'|')[1]),' ')" />
                  </LastName>
                </xsl:if>
                <Gender>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_Gender_Letter__TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[5])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_Gender_Letter__Desc_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[5])" />
                  </xsl:call-template>
                </Gender>
                <xsl:if test="normalize-space(str:split(CHILDRIDER,'|')[4])">
                  <BirthDate>
                    <xsl:call-template name="TeledexDateFormatter">
                      <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[4])" />
                    </xsl:call-template>
                  </BirthDate>
                </xsl:if>
                <Height2>
                  <MeasureUnits tc="2">US System Standard</MeasureUnits>
                  <MeasureValue>
                    <xsl:value-of select="normalize-space(str:split(CHILDRIDER,'|')[8])" />
                  </MeasureValue>
                </Height2>
                <Weight2>
                  <MeasureUnits tc="2">US System Standard</MeasureUnits>
                  <MeasureValue>
                    <xsl:value-of select="normalize-space(str:split(CHILDRIDER,'|')[9])" />
                  </MeasureValue>
                </Weight2>
                <BirthJurisdictionTC>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[6])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_State_Abv2Name_mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[6])" />
                  </xsl:call-template>
                </BirthJurisdictionTC>
              </Person>
            </Party>
          </xsl:for-each>
          <!-- Owner and Payor Party Nodes Logic -->
          <!-- The structure of the party nodes differ in each scenario -->
          <!-- If Owner exists but not Payor - use Owner data -->
          <!-- If neither Owner or Payor exist - use Applicant data -->
          <!-- If Payor exists but not Owner - use Applicant data for Owner only -->
          <xsl:choose>
            <xsl:when test="TeledexDBData/RESULTS/OWNERDATA/OWNER = '1'">
              <Party id="Party_Owner">
                <PartyTypeCode tc="1">Person</PartyTypeCode>
                <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNERSOC!=''">
                  <GovtID>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERSOC" />
                  </GovtID>
                  <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
                </xsl:if>
                <Person DataRep="Partial">
                  <FirstName>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERFNAME" />
                  </FirstName>
                  <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNERMNAME!=''">
                    <MiddleName>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERMNAME" />
                    </MiddleName>
                  </xsl:if>
                  <LastName>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERLNAME" />
                  </LastName>
                  <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNERDOB!=''" />
                  <BirthDate>
                    <xsl:call-template name="TeledexDateFormatter">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERDOB" />
                    </xsl:call-template>
                  </BirthDate>
                </Person>
                <Address>
                  <Line1>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDR" />
                  </Line1>
                  <City>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRCITY" />
                  </City>
                  <AddressStateTC>
                    <xsl:attribute name="tc">
                      <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRST" />
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRST" />
                  </AddressStateTC>
                  <Zip>
                    <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRZIP" />
                  </Zip>
                </Address>
                <EMailAddress>
                  <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNEREMAIL!=''">
                    <AddrLine>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNEREMAIL" />
                    </AddrLine>
                  </xsl:if>
                  <OLifEExtension>
                    <eDeliveryOptIn>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNEROPTIN" />
                    </eDeliveryOptIn>
                  </OLifEExtension>
                </EMailAddress>
              </Party>
              <xsl:if test="string-length(TeledexDBData/RESULTS/PAYORDATA/PAYOR)=0">
                <Party id="Party_Payor">
                  <PartyTypeCode tc="1">Person</PartyTypeCode>
                  <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNERSOC!=''">
                    <GovtID>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERSOC" />
                    </GovtID>
                    <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
                  </xsl:if>
                  <Person DataRep="Partial">
                    <FirstName>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERFNAME" />
                    </FirstName>
                    <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNERMNAME!=''">
                      <MiddleName>
                        <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERMNAME" />
                      </MiddleName>
                    </xsl:if>
                    <LastName>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERLNAME" />
                    </LastName>
                    <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNERDOB!=''" />
                    <BirthDate>
                      <xsl:call-template name="TeledexDateFormatter">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERDOB" />
                      </xsl:call-template>
                    </BirthDate>
                  </Person>
                  <Address>
                    <Line1>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDR" />
                    </Line1>
                    <City>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRCITY" />
                    </City>
                    <AddressStateTC>
                      <xsl:attribute name="tc">
                        <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                          <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRST" />
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRST" />
                    </AddressStateTC>
                    <Zip>
                      <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERADDRZIP" />
                    </Zip>
                  </Address>
                  <EMailAddress>
                    <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNEREMAIL!=''">
                      <AddrLine>
                        <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNEREMAIL" />
                      </AddrLine>
                    </xsl:if>
                    <OLifEExtension>
                      <eDeliveryOptIn>
                        <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNEROPTIN" />
                      </eDeliveryOptIn>
                    </OLifEExtension>
                  </EMailAddress>
                </Party>
              </xsl:if>
            </xsl:when>
            <xsl:when test="TeledexDBData/RESULTS/OWNERDATA/OWNER != '1'">
              <Party id="Party_Owner">
                <PartyTypeCode tc="1">Person</PartyTypeCode>
                <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPGOVID != ''">
                  <GovtID>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPGOVID" />
                  </GovtID>
                  <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
                </xsl:if>
                <Person DataRep="Partial">
                  <FirstName>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPFNAME" />
                  </FirstName>
                  <LastName>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPLNAME" />
                  </LastName>
                  <Gender tc="{TeledexDBData/RESULTS/APPLICANTDATA/APPGENDER}">
                    <xsl:call-template name="TabularMapping_Gender_Desc_Mapping">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPGENDER" />
                    </xsl:call-template>
                  </Gender>
                  <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPDOB != ''">
                    <BirthDate>
                      <xsl:call-template name="TeledexDateFormatter">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPDOB" />
                      </xsl:call-template>
                    </BirthDate>
                  </xsl:if>
                </Person>
                <Address>
                  <Line1>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSLINE1" />
                  </Line1>
                  <City>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSCITY" />
                  </City>
                  <AddressStateTC>
                    <xsl:attribute name="tc">
                      <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSST" />
                      </xsl:call-template>
                    </xsl:attribute>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSST" />
                  </AddressStateTC>
                  <Zip>
                    <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSZIP" />
                  </Zip>
                </Address>
                <EMailAddress>
                  <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPEMAIL != ''">
                    <AddrLine>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPEMAIL" />
                    </AddrLine>
                  </xsl:if>
                  <OLifEExtension VendorCode="84">
                    <xsl:choose>
                      <xsl:when test="TeledexDBData/RESULTS/APPLICANTDATA/APPOPTIN != ''">
                        <eDeliveryOptIn>
                          <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPOPTIN" />
                        </eDeliveryOptIn>
                      </xsl:when>
                      <xsl:otherwise>
                        <eDeliveryOptIn>NN</eDeliveryOptIn>
                      </xsl:otherwise>
                    </xsl:choose>
                  </OLifEExtension>
                </EMailAddress>
              </Party>
              <xsl:if test="string-length(TeledexDBData/RESULTS/PAYORDATA/PAYOR)=0">
                <Party id="Party_Payor">
                  <PartyTypeCode tc="1">Person</PartyTypeCode>
                  <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPGOVID != ''">
                    <GovtID>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPGOVID" />
                    </GovtID>
                    <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
                  </xsl:if>
                  <Person DataRep="Partial">
                    <FirstName>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPFNAME" />
                    </FirstName>
                    <LastName>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPLNAME" />
                    </LastName>
                    <Gender tc="{TeledexDBData/RESULTS/APPLICANTDATA/APPGENDER}">
                      <xsl:call-template name="TabularMapping_Gender_Desc_Mapping">
                        <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPGENDER" />
                      </xsl:call-template>
                    </Gender>
                    <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPDOB != ''">
                      <BirthDate>
                        <xsl:call-template name="TeledexDateFormatter">
                          <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPDOB" />
                        </xsl:call-template>
                      </BirthDate>
                    </xsl:if>
                  </Person>
                  <Address>
                    <Line1>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSLINE1" />
                    </Line1>
                    <City>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSCITY" />
                    </City>
                    <AddressStateTC>
                      <xsl:attribute name="tc">
                        <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                          <xsl:with-param name="value" select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSST" />
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSST" />
                    </AddressStateTC>
                    <Zip>
                      <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPADDRESSZIP" />
                    </Zip>
                  </Address>
                  <EMailAddress>
                    <xsl:if test="TeledexDBData/RESULTS/APPLICANTDATA/APPEMAIL != ''">
                      <AddrLine>
                        <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPEMAIL" />
                      </AddrLine>
                    </xsl:if>
                    <OLifEExtension VendorCode="84">
                      <xsl:choose>
                        <xsl:when test="TeledexDBData/RESULTS/APPLICANTDATA/APPOPTIN != ''">
                          <eDeliveryOptIn>
                            <xsl:value-of select="TeledexDBData/RESULTS/APPLICANTDATA/APPOPTIN" />
                          </eDeliveryOptIn>
                        </xsl:when>
                        <xsl:otherwise>
                          <eDeliveryOptIn>NN</eDeliveryOptIn>
                        </xsl:otherwise>
                      </xsl:choose>
                    </OLifEExtension>
                  </EMailAddress>
                </Party>
              </xsl:if>
            </xsl:when>
          </xsl:choose>
          <xsl:if test="string-length(TeledexDBData/RESULTS/PAYORDATA/PAYOR)&gt;0">
            <Party id="Party_Payor">
              <PartyTypeCode tc="1">Person</PartyTypeCode>
              <xsl:if test="TeledexDBData/RESULTS/PAYORDATA/PAYORSOC != ''">
                <GovtID>
                  <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORSOC" />
                </GovtID>
                <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
              </xsl:if>
              <FullName>
                <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORFULL" />
              </FullName>
              <Person DataRep="Partial">
                <xsl:if test="TeledexDBData/RESULTS/PAYORDATA/PAYORFNAME != ''">
                  <FirstName>
                    <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORFNAME" />
                  </FirstName>
                </xsl:if>
                <xsl:if test="TeledexDBData/RESULTS/PAYORDATA/PAYORMNAME != ''">
                  <MiddleName>
                    <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORMNAME" />
                  </MiddleName>
                </xsl:if>
                <xsl:if test="TeledexDBData/RESULTS/PAYORDATA/PAYORLNAME != ''">
                  <LastName>
                    <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORLNAME" />
                  </LastName>
                </xsl:if>
                <xsl:if test="TeledexDBData/RESULTS/PAYORDATA/PAYORDOB != ''">
                  <BirthDate>
                    <xsl:call-template name="TeledexDateFormatter">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/PAYORDATA/PAYORDOB" />
                    </xsl:call-template>
                  </BirthDate>
                </xsl:if>
              </Person>
              <Address>
                <Line1>
                  <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORADDR" />
                </Line1>
                <City>
                  <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PRTRESCITY" />
                </City>
                <AddressStateTC>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_State_Abv2TC_mapping">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/PAYORDATA/PAYORADDRST" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORADDRST" />
                </AddressStateTC>
                <Zip>
                  <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYORADDRZIP" />
                </Zip>
              </Address>
              <EMailAddress>
                <xsl:if test="TeledexDBData/RESULTS/PAYORDATA/PAYOREMAIL != ''">
                  <AddrLine>
                    <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYOREMAIL" />
                  </AddrLine>
                </xsl:if>
                <OLifEExtension>
                  <eDeliveryOptIn>
                    <xsl:value-of select="TeledexDBData/RESULTS/PAYORDATA/PAYOROPTIN" />
                  </eDeliveryOptIn>
                </OLifEExtension>
              </EMailAddress>
            </Party>
          </xsl:if>
          <!-- Primary Agent Party Node -->
          <Party id="Party_PrimaryAgent">
            <PartyTypeCode tc="1">Person</PartyTypeCode>
            <Person>
              <FirstName>
                <xsl:value-of select="substring-before(TeledexDBData/RESULTS/AGENTDATA/AGENTNAME,' ')" />
              </FirstName>
              <LastName>
                <xsl:value-of select="substring-after(TeledexDBData/RESULTS/AGENTDATA/AGENTNAME,' ')" />
              </LastName>
            </Person>
            <Producer>
              <CarrierAppointment>
                <CompanyProducerID>
                  <xsl:value-of select="TeledexDBData/RESULTS/AGENTDATA/AGENTCD" />
                </CompanyProducerID>
              </CarrierAppointment>
            </Producer>
          </Party>
          <!-- Primary Beneficiary Party Nodes logic -->
          <xsl:if test="(TeledexDBData/RESULTS/SINGLEPRIMARYDATA/FOUND='1')">
            <Party id="Party_PrimaryBene_1">
              <PartyTypeCode>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENTYPE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_TabularMapping_Party_Type_Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENTYPE" />
                </xsl:call-template>
              </PartyTypeCode>
              <GovtID>
                <xsl:value-of select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENSSN" />
              </GovtID>
              <GovtIDTC>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENSSNTYPE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_PRIBEN_SSN_TYPE_DESC_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENSSNTYPE" />
                </xsl:call-template>
              </GovtIDTC>
              <Person>
                <FirstName>
                  <xsl:value-of select="substring-before(TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENNAME,' ')" />
                </FirstName>
                <xsl:if test="str:split(TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENNAME,' ')[2]">
                  <LastName>
                    <xsl:value-of select="str:split(TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENNAME,' ')[2]" />
                  </LastName>
                </xsl:if>
                <xsl:if test="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENDOB != ''">
                  <BirthDate>
                    <xsl:call-template name="TeledexDateFormatter">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENDOB" />
                    </xsl:call-template>
                  </BirthDate>
                </xsl:if>
              </Person>
            </Party>
            <xsl:for-each select="TeledexDBData/RESULTS/MULTIPRIMARYDATA">
              <Party id="Party_PrimaryBene_{ID}">
                <PartyTypeCode>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[6])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_TabularMapping_Party_Type_Desc_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[6])" />
                  </xsl:call-template>
                </PartyTypeCode>
                <GovtID>
                  <xsl:value-of select="normalize-space(str:split(PRIBENLOOP,'|')[4])" />
                </GovtID>
                <GovtIDTC>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[6])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_PRIBEN_SSN_TYPE_DESC_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[6])" />
                  </xsl:call-template>
                </GovtIDTC>
                <Person>
                  <FirstName>
                    <xsl:value-of select="substring-before(normalize-space(str:split(PRIBENLOOP,'|')[1]),' ')" />
                  </FirstName>
                  <xsl:if test="str:split(normalize-space(str:split(PRIBENLOOP,'|')[1]),' ')[2]">
                    <LastName>
                      <xsl:value-of select="str:split(normalize-space(str:split(PRIBENLOOP,'|')[1]),' ')[2]" />
                    </LastName>
                  </xsl:if>
                  <xsl:if test="normalize-space(str:split(PRIBENLOOP,'|')[5]) != ''">
                    <BirthDate>
                      <xsl:call-template name="TeledexDateFormatter">
                        <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[5])" />
                      </xsl:call-template>
                    </BirthDate>
                  </xsl:if>
                </Person>
              </Party>
            </xsl:for-each>
          </xsl:if>
          <!-- Contingent Beneficiary Party Nodes logic -->
          <xsl:if test="(TeledexDBData/RESULTS/SINGLECONTINGENTDATA/FOUND='1')">
            <Party id="Party_ContingentBene_1">
              <PartyTypeCode>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENTYPE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_TabularMapping_Party_Type_Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENTYPE" />
                </xsl:call-template>
              </PartyTypeCode>
              <GovtID>
                <xsl:value-of select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENSSN" />
              </GovtID>
              <GovtIDTC>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENSSNTYPE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_PRIBEN_SSN_TYPE_DESC_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENSSNTYPE" />
                </xsl:call-template>
              </GovtIDTC>
              <Person>
                <FirstName>
                  <xsl:value-of select="substring-before(TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENNAME,' ')" />
                </FirstName>
                <xsl:if test="str:split(TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENNAME,' ')[2]">
                  <LastName>
                    <xsl:value-of select="str:split(TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENNAME,' ')[2]" />
                  </LastName>
                </xsl:if>
                <xsl:if test="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENDOB != ''">
                  <BirthDate>
                    <xsl:call-template name="TeledexDateFormatter">
                      <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENDOB" />
                    </xsl:call-template>
                  </BirthDate>
                </xsl:if>
              </Person>
            </Party>
            <xsl:for-each select="TeledexDBData/RESULTS/MULTICONTINGENTDATA">
              <Party id="Party_ContingentBene_{ID}">
                <PartyTypeCode>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[6])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_TabularMapping_Party_Type_Desc_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[6])" />
                  </xsl:call-template>
                </PartyTypeCode>
                <GovtID>
                  <xsl:value-of select="normalize-space(str:split(CONTBENLOOP,'|')[4])" />
                </GovtID>
                <GovtIDTC>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_Party_Type_TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[6])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_PRIBEN_SSN_TYPE_DESC_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[6])" />
                  </xsl:call-template>
                </GovtIDTC>
                <Person>
                  <FirstName>
                    <xsl:value-of select="substring-before(normalize-space(str:split(CONTBENLOOP,'|')[1]),' ')" />
                  </FirstName>
                  <xsl:if test="str:split(normalize-space(str:split(CONTBENLOOP,'|')[1]),' ')[2]">
                    <LastName>
                      <xsl:value-of select="str:split(normalize-space(str:split(CONTBENLOOP,'|')[1]),' ')[2]" />
                    </LastName>
                  </xsl:if>
                  <xsl:if test="normalize-space(str:split(CONTBENLOOP,'|')[5]) != ''">
                    <BirthDate>
                      <xsl:call-template name="TeledexDateFormatter">
                        <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[5])" />
                      </xsl:call-template>
                    </BirthDate>
                  </xsl:if>
                </Person>
              </Party>
            </xsl:for-each>
          </xsl:if>
          <!-- Relation Nodes: -->
          <!-- Other Insured Relation Nodes -->
          <xsl:if test="count(TeledexDBData/RESULTS/OTHERINSUREDDATA/CHILDNUMBERUNITS) &gt; 0">
            <xsl:for-each select="TeledexDBData/RESULTS/OTHERINSUREDDATA">
              <Relation OriginatingObjectID="Party_PrimaryInsured" RelatedObjectID="Party_OtherInsured_CTI_{ID}" id="Relation_OtherInsuredCTI{ID}ToPrimaryInsured">
                <OriginatingObjectType tc="6">Party</OriginatingObjectType>
                <RelatedObjectType tc="6">Party</RelatedObjectType>
                <RelationRoleCode>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_RelationRoleCode__TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[2])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_RelationRoleCode__Desc_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(CHILDRIDER,'|')[2])" />
                  </xsl:call-template>
                </RelationRoleCode>
              </Relation>
            </xsl:for-each>
          </xsl:if>
          <!-- Holding Relation Node -->
          <Relation OriginatingObjectID="Holding_Primary" RelatedObjectID="Party_Owner" id="Relation_OwnerToHolding">
            <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
            <RelatedObjectType tc="6">Party</RelatedObjectType>
            <RelationRoleCode tc="8">Owner</RelationRoleCode>
          </Relation>
          <!-- Owner Relation Node -->
          <xsl:if test="TeledexDBData/RESULTS/OWNERDATA/OWNER = '1'">
            <Relation OriginatingObjectID="Party_PrimaryInsured" RelatedObjectID="Party_Owner" id="Relation_OwnerToPrimaryInsured">
              <OriginatingObjectType tc="6">Party</OriginatingObjectType>
              <RelatedObjectType tc="6">Party</RelatedObjectType>
              <RelationRoleCode>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_RelationRoleCode__TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERRELAT" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_RelationRoleCode__Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERRELAT" />
                </xsl:call-template>
              </RelationRoleCode>
              <RelationDescription>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_RelationDescription_TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/OWNERDATA/OWNERRELAT" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:value-of select="TeledexDBData/RESULTS/OWNERDATA/OWNERRELAT" />
              </RelationDescription>
            </Relation>
          </xsl:if>
          <!-- Primary Beneficiary Relation Nodes logic -->
          <xsl:if test="(TeledexDBData/RESULTS/SINGLEPRIMARYDATA/FOUND='1')">
            <Relation OriginatingObjectID="Party_PrimaryInsured" RelatedObjectID="Party_PrimaryBene_1" id="Relation_PrimaryBene1ToPrimaryInsured">
              <OriginatingObjectType tc="6">Party</OriginatingObjectType>
              <RelatedObjectType tc="6">Party</RelatedObjectType>
              <RelationRoleCode>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_RelationRoleCode__TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENROLE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_RelationRoleCode__Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLEPRIMARYDATA/PRIBENROLE" />
                </xsl:call-template>
              </RelationRoleCode>
            </Relation>
            <xsl:for-each select="TeledexDBData/RESULTS/MULTIPRIMARYDATA">
              <Relation OriginatingObjectID="Party_PrimaryInsured" RelatedObjectID="Party_PrimaryBene_{ID}" id="Relation_PrimaryBene{ID}ToPrimaryInsured">
                <OriginatingObjectType tc="6">Party</OriginatingObjectType>
                <RelatedObjectType tc="6">Party</RelatedObjectType>
                <RelationRoleCode>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_RelationRoleCode__TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[3])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_RelationRoleCode__Desc_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(PRIBENLOOP,'|')[3])" />
                  </xsl:call-template>
                </RelationRoleCode>
              </Relation>
            </xsl:for-each>
          </xsl:if>
          <!-- Contingent Beneficiary Relation Nodes logic -->
          <xsl:if test="(TeledexDBData/RESULTS/SINGLECONTINGENTDATA/FOUND='1')">
            <Relation OriginatingObjectID="Party_PrimaryInsured" RelatedObjectID="Party_ContingentBene_1" id="Relation_ContingentBene1ToPrimaryInsured">
              <OriginatingObjectType tc="6">Party</OriginatingObjectType>
              <RelatedObjectType tc="6">Party</RelatedObjectType>
              <RelationRoleCode>
                <xsl:attribute name="tc">
                  <xsl:call-template name="TabularMapping_RelationRoleCode__TC_Mapping">
                    <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENROLE" />
                  </xsl:call-template>
                </xsl:attribute>
                <xsl:call-template name="TabularMapping_RelationRoleCode__Desc_Mapping">
                  <xsl:with-param name="value" select="TeledexDBData/RESULTS/SINGLECONTINGENTDATA/CONTBENROLE" />
                </xsl:call-template>
              </RelationRoleCode>
            </Relation>
            <xsl:for-each select="TeledexDBData/RESULTS/MULTICONTINGENTDATA">
              <Relation OriginatingObjectID="Party_PrimaryInsured" RelatedObjectID="Party_ContingentBene_{ID}" id="Relation_ContingentBene{ID}ToPrimaryInsured">
                <OriginatingObjectType tc="6">Party</OriginatingObjectType>
                <RelatedObjectType tc="6">Party</RelatedObjectType>
                <RelationRoleCode>
                  <xsl:attribute name="tc">
                    <xsl:call-template name="TabularMapping_RelationRoleCode__TC_Mapping">
                      <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[3])" />
                    </xsl:call-template>
                  </xsl:attribute>
                  <xsl:call-template name="TabularMapping_RelationRoleCode__Desc_Mapping">
                    <xsl:with-param name="value" select="normalize-space(str:split(CONTBENLOOP,'|')[3])" />
                  </xsl:call-template>
                </RelationRoleCode>
              </Relation>
            </xsl:for-each>
          </xsl:if>
          <!-- Primary Relation Node -->
          <Relation OriginatingObjectID="Holding_Primary" RelatedObjectID="TermAppGen-GV" id="Relation_TermAppGen-GV">
            <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
            <RelatedObjectType tc="101">Form Instance</RelatedObjectType>
            <RelationRoleCode tc="107">Form For</RelationRoleCode>
          </Relation>
          <!-- Form Instance Nodes -->
          <FormInstance id="TermAppGen-GV">
            <FormName>TermAppGen-GV</FormName>
            <FormResponse>
              <QuestionNumber>ChildInsuredCitizenship</QuestionNumber>
              <xsl:choose>
                <xsl:when test="TeledexDBData/RESULTS/RESPONSEDATA/CHILDINSUREDCITIZENSHIP != ''">
                  <ResponseCode>
                    <xsl:choose>
                      <xsl:when test="TeledexDBData/RESULTS/RESPONSEDATA/CHILDINSUREDCITIZENSHIP='Y'">1</xsl:when>
                      <xsl:otherwise>2</xsl:otherwise>
                    </xsl:choose>
                  </ResponseCode>
                </xsl:when>
                <xsl:otherwise>
                  <ResponseCode>2</ResponseCode>
                </xsl:otherwise>
              </xsl:choose>
            </FormResponse>
            <FormResponse>
              <QuestionNumber>PrimaryInsuredCitizenship</QuestionNumber>
              <ResponseCode>1</ResponseCode>
            </FormResponse>
            <Attachment>
              <AttachmentData>
                <xsl:variable name="attachmentData">
                  <xsl:value-of select="Data_1122/bo:TXLife/bo:TXLifeRequest/bo:OLifE/bo:Holding/bo:Policy/bo:RequirementInfo/bo:Attachment/bo:AttachmentData" />
                </xsl:variable>
                <xsl:variable name="mergedData">
                  <xsl:value-of select="ta:getAttribute($attributes, 'com.crl.mergedTiff')" />
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="string-length($mergedData) &gt; 0">
                    <xsl:value-of select="$mergedData" />
                    <xsl:variable name="throwaway" select="ta:removeAttribute($attributes, 'com.crl.mergedTiff')" />
                  </xsl:when>
                  <xsl:when test="string-length($attachmentData) &gt; 20">
                    <xsl:value-of select="$attachmentData" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="ta:getAttribute($attributes, string($attachmentData))" />
                    <xsl:variable name="throwaway" select="ta:removeAttribute($attributes, string($attachmentData))" />
                  </xsl:otherwise>
                </xsl:choose>
              </AttachmentData>
              <ImageType tc="3">TIF</ImageType>
            </Attachment>
          </FormInstance>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
  <!-- Templates Section -->
  <xsl:template name="TeledexDateFormatter">
    <xsl:param name="value" />
    <xsl:variable name="value" select="str:split($value,' ')[1]" />
    <xsl:choose>
      <xsl:when test="(string-length(normalize-space($value))=8 and not(contains($value,'/')))">
        <!-- Correct non-slash date: 06241967 -->
        <xsl:value-of select="dtFormatter:format(normalize-space($value),'MMddyyyy','yyyy-MM-dd')" />
      </xsl:when>
      <xsl:when test="contains($value,'/')">
        <!--
				Correct full date: 06/24/1967
				Missing digit for month: 6/24/1967
				Missing digit for day: 06/8/1967
				Missing both digits: 6/8/1967
				-->
        <xsl:value-of select="dtFormatter:format(normalize-space($value),'MM/dd/yyyy','yyyy-MM-dd')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_State_Abv2Name_mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='AL'">
        <xsl:text>Alabama</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AK'">
        <xsl:text>Alaska</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AS'">
        <xsl:text>American Samoa</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AZ'">
        <xsl:text>Arizona</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AR'">
        <xsl:text>Arkansas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CA'">
        <xsl:text>California</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CO'">
        <xsl:text>Colorado</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CT'">
        <xsl:text>Connecticut</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DE'">
        <xsl:text>Delaware</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DC'">
        <xsl:text>District of Columbia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FS'">
        <xsl:text>Federated States of Micronesia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FL'">
        <xsl:text>Florida</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GA'">
        <xsl:text>Georgia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GU'">
        <xsl:text>Guam</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HI'">
        <xsl:text>Hawaii</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ID'">
        <xsl:text>Idaho</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IL'">
        <xsl:text>Illinois</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IN'">
        <xsl:text>Indiana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IA'">
        <xsl:text>Iowa</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KS'">
        <xsl:text>Kansas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KY'">
        <xsl:text>Kentucky</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LA'">
        <xsl:text>Louisiana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ME'">
        <xsl:text>Maine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MH'">
        <xsl:text>Marshall Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MD'">
        <xsl:text>Maryland</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MA'">
        <xsl:text>Massachusetts</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MI'">
        <xsl:text>Michigan</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MN'">
        <xsl:text>Minnesota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MS'">
        <xsl:text>Mississippi</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MO'">
        <xsl:text>Missouri</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MT'">
        <xsl:text>Montana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NE'">
        <xsl:text>Nebraska</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NV'">
        <xsl:text>Nevada</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NH'">
        <xsl:text>New Hampshire</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJ'">
        <xsl:text>New Jersey</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NM'">
        <xsl:text>New Mexico</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NY'">
        <xsl:text>New York</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NC'">
        <xsl:text>North Carolina</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ND'">
        <xsl:text>North Dakota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MP'">
        <xsl:text>Northern Mariana Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OH'">
        <xsl:text>Ohio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OK'">
        <xsl:text>Oklahoma</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OR'">
        <xsl:text>Oregon</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PW'">
        <xsl:text>Palau Island</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PA'">
        <xsl:text>Pennsylvania</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PR'">
        <xsl:text>Puerto Rico</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RI'">
        <xsl:text>Rhode Island</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SC'">
        <xsl:text>South Carolina</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SD'">
        <xsl:text>South Dakota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TN'">
        <xsl:text>Tennessee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TX'">
        <xsl:text>Texas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UT'">
        <xsl:text>Utah</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VT'">
        <xsl:text>Vermont</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VI'">
        <xsl:text>Virgin Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VA'">
        <xsl:text>Virginia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WA'">
        <xsl:text>Washington</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WV'">
        <xsl:text>West Virginia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WI'">
        <xsl:text>Wisconsin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WY'">
        <xsl:text>Wyoming</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GB'">
        <xsl:text>Guantanamo Bay (US Naval Base) Cuba</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AA'">
        <xsl:text>Armed Forces Americas (except Canada)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AE'">
        <xsl:text>Armed Forces Canada, Africa, Europe, Middle East</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AP'">
        <xsl:text>US Armed Forces Pacific</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>*</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_PaymentMode_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1,'">
        <xsl:text>Annual</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2,'">
        <xsl:text>Semi-Annual</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3,'">
        <xsl:text>Quarterly</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4,'">
        <xsl:text>Monthly</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5,'">
        <xsl:text>Monthly</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6,'">
        <xsl:text>Monthly</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_PaymentMode_TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1,'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2,'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3,'">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4,'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5,'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6,'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_PaymentMethod_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1,'">
        <xsl:text>Regular billing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2,'">
        <xsl:text>Regular billing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3,'">
        <xsl:text>Regular billing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5,'">
        <xsl:text>Irregular Billing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6,'">
        <xsl:text>Irregular Billing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4,'">
        <xsl:text>Electronic Funds Transfer</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>No Billing</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_PaymentMethod_TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1,'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2,'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3,'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5,'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6,'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4,'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>1</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_BankAcctType_TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='Savings'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Checking'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Credit'">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Debit'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Brokerage'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CD'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_DEATHBENEFIT_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='7,'">
        <xsl:text>Level</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8,'">
        <xsl:text>Increasing</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9,'">
        <xsl:text>Level</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10,'">
        <xsl:text>Level</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11,'">
        <xsl:text>Increasing</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_DEATHBENEFIT_TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='7,'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8,'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9,'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10,'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11,'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_PlanName_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1,'">
        <xsl:text>Term</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2,'">
        <xsl:text>Term</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3,'">
        <xsl:text>Term</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4,'">
        <xsl:text>Term</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5,'">
        <xsl:text>ERIEFLEX4 SINGLEPAY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6,'">
        <xsl:text>ERIESECURE LIFE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7,'">
        <xsl:text>ERIEflex3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8,'">
        <xsl:text>ERIEflex3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9,'">
        <xsl:text>ERIEflex4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10,'">
        <xsl:text>ERIESECURE LIFE PLUS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11,'">
        <xsl:text>ERIESECURE LIFE PLUS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12,'">
        <xsl:text>Term</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_Gender_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>Female</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>Male</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_Gender_Letter__Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='M'">
        <xsl:text>Male</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='F'">
        <xsl:text>Female</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_Gender_Letter__TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='M'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='F'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_Party_Type_TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='Person'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Organization'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Trust'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_PRIBEN_SSN_TYPE_DESC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='Person'">
        <xsl:text>Social Security Number US</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Trust'">
        <xsl:text>Taxpayer Identification Number</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Organization'">
        <xsl:text>Taxpayer Identification Number</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_State_Abv2TC_mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='AL'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AK'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AS'">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AZ'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AR'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CA'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CT'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DE'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DC'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FS'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FL'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GA'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GU'">
        <xsl:text>14</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HI'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ID'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IL'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IN'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IA'">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LA'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ME'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MH'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MD'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MA'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MI'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MN'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MS'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MO'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MT'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NE'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NV'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NH'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJ'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NM'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NY'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NC'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ND'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MP'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OH'">
        <xsl:text>41</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OK'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OR'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PW'">
        <xsl:text>44</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PR'">
        <xsl:text>46</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RI'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SC'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SD'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TN'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TX'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UT'">
        <xsl:text>52</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VT'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VI'">
        <xsl:text>54</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WA'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WV'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WI'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WY'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GB'">
        <xsl:text>80</xsl:text>
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
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_TabularMapping_Party_Type_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='Person'">
        <xsl:text>Party</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Organization'">
        <xsl:text>Organization</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Trust'">
        <xsl:text>Organization</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_Premium_Period_Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1,'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2,'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3,'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4,'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_RelationDescription_TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="(normalize-space($value)='Husband') or (normalize-space($value)='HUSBAND')">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Wife') or (normalize-space($value)='WIFE')">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Father') or (normalize-space($value)='FATHER')">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Mother') or (normalize-space($value)='MOTHER')">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandfather') or (normalize-space($value)='GRANDFATHER')">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandmother') or (normalize-space($value)='GRANDMOTHER')">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandson') or (normalize-space($value)='GRANDSON')">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Granddaughter') or (normalize-space($value)='GRANDDAUGHTER')">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Brother') or (normalize-space($value)='BROTHER')">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Sister') or (normalize-space($value)='SISTER')">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Son') or (normalize-space($value)='SON')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Daughter') or (normalize-space($value)='DAUGHTER')">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Uncle') or (normalize-space($value)='UNCLE')">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Aunt') or (normalize-space($value)='AUNT')">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Nephew') or (normalize-space($value)='NEPHEW')">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Niece') or (normalize-space($value)='NIECE')">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Other') or (normalize-space($value)='OTHER')">
        <xsl:text>2147483647</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Brother-In-Law') or (normalize-space($value)='BROTHER-IN-LAW')">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Cousin') or (normalize-space($value)='COUSIN')">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Daughter-In-Law') or (normalize-space($value)='DAUGHTER-IN-LAW')">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Fiance') or (normalize-space($value)='FIANCE')">
        <xsl:text>60</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Father-In-Law') or (normalize-space($value)='FATHER-IN-LAW')">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Great Aunt') or (normalize-space($value)='GREAT AUNT')">
        <xsl:text>63</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Great Granddaughter') or (normalize-space($value)='GREAT GRANDDAUGHTER')">
        <xsl:text>68</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Great Grandfather') or (normalize-space($value)='GREAT GRANDFATHER')">
        <xsl:text>69</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Great Grandmother') or (normalize-space($value)='GREAT GRANDMOTHER')">
        <xsl:text>70</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Great Grandson') or (normalize-space($value)='GREAT GRANDSON')">
        <xsl:text>67</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Great Uncle') or (normalize-space($value)='GREAT UNCLE')">
        <xsl:text>64</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Mother-In-Law') or (normalize-space($value)='MOTHER-IN-LAW')">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Sister-In-Law') or (normalize-space($value)='SISTER-IN-LAW')">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Son-In-Law') or (normalize-space($value)='SON-IN-LAW')">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_RelationRoleCode__Desc_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="(normalize-space($value)='Husband') or (normalize-space($value)='HUSBAND')">
        <xsl:text>Spouse</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Wife') or (normalize-space($value)='WIFE')">
        <xsl:text>Spouse</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Son') or (normalize-space($value)='SON')">
        <xsl:text>Child</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Daughter') or (normalize-space($value)='DAUGHTER')">
        <xsl:text>Child</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Father') or (normalize-space($value)='FATHER')">
        <xsl:text>Parent</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Mother') or (normalize-space($value)='MOTHER')">
        <xsl:text>Parent</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Brother') or (normalize-space($value)='BROTHER')">
        <xsl:text>Sibling</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Sister') or (normalize-space($value)='SISTER')">
        <xsl:text>Sibling</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Half Brother') or (normalize-space($value)='HALF BROTHER')">
        <xsl:text>Sibling</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Half Sister') or (normalize-space($value)='HALF SISTER')">
        <xsl:text>Sibling</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Ex-Husband') or (normalize-space($value)='EX-HUSBAND')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Ex-wife') or (normalize-space($value)='EX-WIFE')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Mother') or (normalize-space($value)='STEP MOTHER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Father') or (normalize-space($value)='STEP FATHER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Son') or (normalize-space($value)='STEP SON')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Daughter') or (normalize-space($value)='STEP DAUGHTER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Brother') or (normalize-space($value)='STEP BROTHER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Sister') or (normalize-space($value)='STEP SISTER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandfather') or (normalize-space($value)='GRANDFATHER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandmother') or (normalize-space($value)='GRANDMOTHER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandson') or (normalize-space($value)='GRANDSON')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Granddaughter') or (normalize-space($value)='GRANDDAUGHTER')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Father-in-law') or (normalize-space($value)='FATHER-IN-LAW')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Mother-in-law') or (normalize-space($value)='MOTHER-IN-LAW')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Son-in-law') or (normalize-space($value)='SON-IN-LAW')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Daughter-in-law') or (normalize-space($value)='DAUGHTER-IN-LAW')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Brother-in-law') or (normalize-space($value)='BROTHER-IN-LAW')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Sister-in-law') or (normalize-space($value)='SISTER-IN-LAW')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Uncle') or (normalize-space($value)='UNCLE')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Cousin') or (normalize-space($value)='COUSIN')">
        <xsl:text>Family</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Other</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="TabularMapping_RelationRoleCode__TC_Mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="(normalize-space($value)='Husband') or (normalize-space($value)='HUSBAND')">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Wife') or (normalize-space($value)='WIFE')">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Son') or (normalize-space($value)='SON')">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Daughter') or (normalize-space($value)='DAUGHTER')">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Father') or (normalize-space($value)='FATHER')">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Mother') or (normalize-space($value)='MOTHER')">
        <xsl:text>3</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Brother') or (normalize-space($value)='BROTHER')">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Sister') or (normalize-space($value)='SISTER')">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Half Brother') or (normalize-space($value)='HALF BROTHER')">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Half Sister') or (normalize-space($value)='HALF SISTER')">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Ex-Husband') or (normalize-space($value)='EX-HUSBAND')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Ex-wife') or (normalize-space($value)='EX-WIFE')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Mother') or (normalize-space($value)='STEP MOTHER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Father') or (normalize-space($value)='STEP FATHER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Son') or (normalize-space($value)='STEP SON')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Daughter') or (normalize-space($value)='STEP DAUGHTER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Brother') or (normalize-space($value)='STEP BROTHER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Step Sister') or (normalize-space($value)='STEP SISTER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandfather') or (normalize-space($value)='GRANDFATHER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandmother') or (normalize-space($value)='GRANDMOTHER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Grandson') or (normalize-space($value)='GRANDSON')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Granddaughter') or (normalize-space($value)='GRANDDAUGHTER')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Father-in-law') or (normalize-space($value)='FATHER-IN-LAW')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Mother-in-law') or (normalize-space($value)='MOTHER-IN-LAW')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Son-in-law') or (normalize-space($value)='SON-IN-LAW')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Daughter-in-law') or (normalize-space($value)='DAUGHTER-IN-LAW')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Brother-in-law') or (normalize-space($value)='BROTHER-IN-LAW')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Sister-in-law') or (normalize-space($value)='SISTER-IN-LAW')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Uncle') or (normalize-space($value)='UNCLE')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="(normalize-space($value)='Cousin') or (normalize-space($value)='COUSIN')">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>2147483647</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

