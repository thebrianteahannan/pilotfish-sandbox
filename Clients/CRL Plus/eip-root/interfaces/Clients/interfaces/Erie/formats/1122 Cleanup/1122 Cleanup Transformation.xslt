<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:tmCall="xalan://com.pilotfish.eip.gui.mapper.util.TabDelimitedFileUtil" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="converter ns1 datetime dtFormatter ta td tmCall" extension-element-prefixes="converter" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="teledexOrderNumber" select="ta:getAttribute($attributes, 'teledexOrderNumber')" />
  <xsl:template match="ns1:TXLife">
    <xsl:variable name="primaryInsuredId" select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[1]/@AppliesToPartyID | /ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=../ns1:Relation[ns1:RelationRoleCode/@tc=32]/@RelatedObjectID]/@id" />
    <xsl:variable name="fulfillsId" select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=../ns1:Relation[ns1:RelationRoleCode/@tc=99]/@RelatedObjectID]/@id" />
    <xsl:variable name="requestorId" select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=../ns1:Relation[ns1:RelationRoleCode/@tc=97]/@RelatedObjectID]/@id" />
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <TXLife xmlns="http://ACORD.org/Standards/Life/2" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.23.00.xsd">
      <UserAuthRequest>
        <UserLoginName />
        <UserPswd>
          <CryptType>NONE</CryptType>
          <Pswd />
        </UserPswd>
        <VendorApp>
          <VendorName VendorCode="{ns1:UserAuthRequest/ns1:VendorApp/ns1:VendorName/@VendorCode}">
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:VendorName" />
          </VendorName>
          <AppName>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:AppName" />
          </AppName>
          <AppVer>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:AppVer" />
          </AppVer>
        </VendorApp>
      </UserAuthRequest>
      <TXLifeRequest>
        <xsl:comment>New GUID generated for each status transmittal</xsl:comment>
        <TransRefGUID>
          <xsl:value-of select="converter:getGUIDString()" />
        </TransRefGUID>
        <TransType tc="1122">General Requirements Result Transmittal</TransType>
        <TransExeDate>
          <xsl:value-of select="dtFormatter:format(datetime:date(),'yyyy-MM-dd','yyyy-MM-dd')" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="dtFormatter:format(datetime:time(),'HH:mm:ss','HH:mm:ssXXX')" />
        </TransExeTime>
        <OLifE>
          <SourceInfo>
            <SourceInfoName>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoName" />
            </SourceInfoName>
            <SourceInfoDescription>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoDescription" />
            </SourceInfoDescription>
            <SourceInfoComment>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoComment" />
            </SourceInfoComment>
          </SourceInfo>
          <Holding id="Holding_1">
            <HoldingTypeCode tc="2">Policy</HoldingTypeCode>
            <Policy>
              <PolNumber>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
              </PolNumber>
              <Life>
                <FaceAmt>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:Life/ns1:FaceAmt" />
                </FaceAmt>
              </Life>
              <ApplicationInfo>
                <TrackingID>
                  <xsl:value-of select="converter:getAttributeString('tracking_id')" />
                </TrackingID>
              </ApplicationInfo>
              <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo">
                <RequirementInfo AppliesToPartyID="Party_1" FulfillerPartyID="{$fulfillsId}" RequesterPartyID="{$requestorId}">
                  <ReqCode tc="{ns1:ReqCode/@tc}">
                    <xsl:value-of select="ns1:ReqCode" />
                  </ReqCode>
                  <RequirementDetails>
                    <xsl:choose>
                      <xsl:when test="ns1:RequirementDetails/text()">
                        <xsl:value-of select="ns1:RequirementDetails" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="ns1:ReqCode" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </RequirementDetails>
                  <ReqStatus tc="{/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[1]/ns1:ReqStatus/@tc}">
                    <xsl:value-of select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[1]/ns1:ReqStatus" />
                  </ReqStatus>
                  <RequestedDate>
                    <xsl:value-of select="dtFormatter:format(ns1:RequestedDate,'yyyy-MM-dd','yyyy-MM-dd')" />
                  </RequestedDate>
                  <xsl:if test="ns1:FulfilledDate">
                    <FulfilledDate>
                      <xsl:value-of select="ns1:FulfilledDate" />
                    </FulfilledDate>
                  </xsl:if>
                  <ReceivedAtLocationDate>
                    <xsl:value-of select="ns1:OrderReceivedDate" />
                  </ReceivedAtLocationDate>
                  <StatusDate>
                    <xsl:value-of select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[1]/ns1:StatusDate" />
                  </StatusDate>
                  <ReleasePartyOrgCode>
                    <xsl:value-of select="ns1:ReleasePartyOrgCode" />
                  </ReleasePartyOrgCode>
                  <RequirementAcctNum>
                    <xsl:value-of select="ns1:RequirementAcctNum" />
                  </RequirementAcctNum>
                  <ProviderOrderNum>
                    <!--<xsl:value-of select="concat('994',ta:getAttribute($attributes, 'teledexOrderNumber'))" />-->
                    <xsl:value-of select="ns1:ProviderOrderNum" />
                  </ProviderOrderNum>
                  <OrderReceivedDate>
                    <xsl:value-of select="ns1:OrderReceivedDate" />
                  </OrderReceivedDate>
                  <xsl:for-each select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[1]/ns1:StatusEvent">
                    <StatusEvent>
                      <StatusEventCode tc="{ns1:StatusEventCode/@tc}">
                        <xsl:value-of select="ns1:StatusEventCode" />
                      </StatusEventCode>
                      <ProviderEventCode>
                        <xsl:value-of select="ns1:ProviderEventCode" />
                      </ProviderEventCode>
                      <StatusEventDate>
                        <xsl:value-of select="ns1:StatusEventDate" />
                      </StatusEventDate>
                      <StatusEventTime>
                        <xsl:value-of select="ns1:StatusEventTime" />
                      </StatusEventTime>
                      <StatusEventDetail>
                        <xsl:value-of select="ns1:StatusEventDetail" />
                      </StatusEventDetail>
                    </StatusEvent>
                  </xsl:for-each>
                </RequirementInfo>
              </xsl:for-each>
            </Policy>
          </Holding>
          <!-- Copy selected Party nodes (insured, fulfiller, requestor) -->
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=$primaryInsuredId]">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=$requestorId]">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party[@id=$fulfillsId]">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <!-- Copy selected Relation nodes (insured, fulfiller, requestor) -->
          <Relation OriginatingObjectID="Holding_1" RelatedObjectID="Party_1" id="Relation_1">
            <RelationRoleCode tc="32">Insured</RelationRoleCode>
          </Relation>
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Relation[@RelatedObjectID=$requestorId]">
            <xsl:apply-templates select="." />
          </xsl:for-each>
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Relation[@RelatedObjectID=$fulfillsId]">
            <xsl:apply-templates select="." />
          </xsl:for-each>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
  <xsl:template match="*">
    <xsl:if test="node()">
      <xsl:element name="{local-name()}" namespace="http://ACORD.org/Standards/Life/2">
        <xsl:apply-templates select="@*|node()" />
      </xsl:element>
    </xsl:if>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="." />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="@*[local-name()='id'][.=ancestor::ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo[1]/@AppliesToPartyID]">
    <xsl:attribute name="{local-name()}">
      <xsl:value-of select="'Party_1'" />
    </xsl:attribute>
  </xsl:template>
  <xsl:template match="ns1:Party[ns1:Person/ns1:LastName]">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:element name="FullName" namespace="http://ACORD.org/Standards/Life/2">
        <xsl:value-of select="normalize-space(concat(ns1:Person/ns1:FirstName,' ',ns1:Person/ns1:MiddleName,' ',ns1:Person/ns1:LastName))" />
      </xsl:element>
      <xsl:copy-of select="ns1:GovtID" />
      <xsl:if test="ns1:Address/ns1:AddressStateTC/@tc &gt; 0 and ns1:Address/ns1:AddressStateTC/@tc &lt; 100">
        <xsl:element name="ResidenceState" namespace="http://ACORD.org/Standards/Life/2">
          <xsl:apply-templates select="ns1:Address/ns1:AddressStateTC/@*" />
          <xsl:call-template name="TabularMapping_From_file__statetctotxt_tdf">
            <xsl:with-param name="value" select="ns1:Address/ns1:AddressStateTC/@tc" />
          </xsl:call-template>
        </xsl:element>
        <xsl:element name="ResidenceCountry" namespace="http://ACORD.org/Standards/Life/2">
          <xsl:attribute name="tc">1</xsl:attribute>
          <xsl:text>United States of America</xsl:text>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="node()[local-name()!='GovtID']" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:PartyTypeCode">
    <!-- Do nothing with the PartyTypeCode node -->
  </xsl:template>
  <xsl:template match="ns1:Address">
    <!-- Do nothing with the Address node -->
  </xsl:template>
  <xsl:template match="ns1:Phone">
    <!-- Do nothing with the Phone node -->
  </xsl:template>
  <xsl:template match="ns1:EMailAddress">
    <!-- Do nothing with the EMailAddress node -->
  </xsl:template>
  <xsl:template match="ns1:Gender">
    <!-- Do nothing with the Gender node -->
  </xsl:template>
  <xsl:template match="ns1:BirthDate">
    <!-- Add Age -->
    <xsl:copy-of select="." />
    <xsl:variable name="dob" select="normalize-space(.)" />
    <xsl:if test="string-length($dob)=10">
      <xsl:variable name="y1" select="substring($dob, 1, 4)" />
      <xsl:variable name="y2" select="datetime:year()" />
      <xsl:variable name="m1" select="substring($dob, 6, 2)" />
      <xsl:variable name="m2" select="datetime:month-in-year()" />
      <xsl:variable name="d1" select="substring($dob, 9, 2)" />
      <xsl:variable name="d2" select="datetime:day-in-month()" />
      <xsl:element name="Age" namespace="http://ACORD.org/Standards/Life/2">
        <xsl:choose>
          <xsl:when test="$m2 &lt; $m1 or ($m2=$m1 and $d2 &lt; $d1)">
            <xsl:value-of select="($y2 - $y1 - 1)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="($y2 - $y1)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:if>
  </xsl:template>
  <xsl:template name="TabularMapping_From_file__statetctotxt_tdf">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>Alabama</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>Alaska</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3'">
        <xsl:text>American Samoa</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>Arizona</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>Arkansas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>California</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>Colorado</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>Connecticut</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9'">
        <xsl:text>Delaware</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>District of Columbia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>Federated States of Micronesia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>Florida</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>Georgia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='14'">
        <xsl:text>Guam</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>Hawaii</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='16'">
        <xsl:text>Idaho</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>Illinois</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='18'">
        <xsl:text>Indiana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>Iowa</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>Kansas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>Kentucky</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>Louisiana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>Maine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='24'">
        <xsl:text>Marshall Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>Maryland</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='26'">
        <xsl:text>Massachusetts</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='27'">
        <xsl:text>Michigan</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='28'">
        <xsl:text>Minnesota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='29'">
        <xsl:text>Mississippi</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='30'">
        <xsl:text>Missouri</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>Montana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='32'">
        <xsl:text>Nebraska</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='33'">
        <xsl:text>Nevada</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='34'">
        <xsl:text>New Hampshire</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='35'">
        <xsl:text>New Jersey</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='36'">
        <xsl:text>New Mexico</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='37'">
        <xsl:text>New York</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='38'">
        <xsl:text>North Carolina</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='39'">
        <xsl:text>North Dakota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='40'">
        <xsl:text>Northern Mariana Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='41'">
        <xsl:text>Ohio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='42'">
        <xsl:text>Oklahoma</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='43'">
        <xsl:text>Oregon</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='44'">
        <xsl:text>Palau Island</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='45'">
        <xsl:text>Pennsylvania</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='46'">
        <xsl:text>Puerto Rico</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='47'">
        <xsl:text>Rhode Island</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='48'">
        <xsl:text>South Carolina</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='49'">
        <xsl:text>South Dakota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='50'">
        <xsl:text>Tennessee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='51'">
        <xsl:text>Texas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='52'">
        <xsl:text>Utah</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='53'">
        <xsl:text>Vermont</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='54'">
        <xsl:text>Virgin Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='55'">
        <xsl:text>Virginia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='56'">
        <xsl:text>Washington</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='57'">
        <xsl:text>West Virginia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='58'">
        <xsl:text>Wisconsin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='59'">
        <xsl:text>Wyoming</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='60'">
        <xsl:text>Armed Forces Americas (except Canada)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='61'">
        <xsl:text>Armed Forces Canada, Africa, Europe, Middle East</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='62'">
        <xsl:text>US Armed Forces Pacific</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='80'">
        <xsl:text>Guantanamo Bay (US Naval Base) Cuba</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Unknown</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

