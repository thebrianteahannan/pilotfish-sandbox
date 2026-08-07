<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="ns1:TXLife">
    <ns1:TXLife schemaLocation="{@schemaLocation}">
      <ns1:UserAuthRequest>
        <ns1:UserLoginName>
          <xsl:value-of select="ns1:UserAuthRequest/ns1:UserLoginName" />
        </ns1:UserLoginName>
        <ns1:UserPswd>
          <ns1:CryptType>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:UserPswd/ns1:CryptType" />
          </ns1:CryptType>
          <ns1:CryptPswd>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:UserPswd/ns1:CryptPswd" />
          </ns1:CryptPswd>
        </ns1:UserPswd>
        <ns1:UserDate>
          <xsl:value-of select="ns1:UserAuthRequest/ns1:UserDate" />
        </ns1:UserDate>
        <ns1:UserTime>
          <xsl:value-of select="ns1:UserAuthRequest/ns1:UserTime" />
        </ns1:UserTime>
        <ns1:VendorApp>
          <ns1:AppName>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:AppName" />
          </ns1:AppName>
          <ns1:AppVer>
            <xsl:value-of select="ns1:UserAuthRequest/ns1:VendorApp/ns1:AppVer" />
          </ns1:AppVer>
        </ns1:VendorApp>
      </ns1:UserAuthRequest>
      <ns1:TXLifeRequest>
        <ns1:TransRefGUID>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TransRefGUID" />
        </ns1:TransRefGUID>
        <ns1:TransType>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TransType" />
        </ns1:TransType>
        <ns1:TransExeDate>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TransExeDate" />
        </ns1:TransExeDate>
        <ns1:TransExeTime>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TransExeTime" />
        </ns1:TransExeTime>
        <ns1:TransMode>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TransMode" />
        </ns1:TransMode>
        <ns1:TestIndicator>
          <xsl:value-of select="ns1:TXLifeRequest/ns1:TestIndicator" />
        </ns1:TestIndicator>
        <ns1:OLifE>
          <ns1:SourceInfo>
            <ns1:CreationDate>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:CreationDate" />
            </ns1:CreationDate>
            <ns1:CreationTime>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:CreationTime" />
            </ns1:CreationTime>
            <ns1:SourceInfoName>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoName" />
            </ns1:SourceInfoName>
            <ns1:SourceInfoDescription>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:SourceInfoDescription" />
            </ns1:SourceInfoDescription>
          </ns1:SourceInfo>
          <ns1:Holding id="{ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/@id}">
            <ns1:HoldingTypeCode>
              <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:HoldingTypeCode" />
            </ns1:HoldingTypeCode>
            <ns1:Policy CarrierPartyID="PartyType_1" id="PolicyType_1">
              <ns1:PolNumber>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
              </ns1:PolNumber>
              <ns1:CarrierCode>
                <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:CarrierCode" />
              </ns1:CarrierCode>
              <ns1:Life>
                <ns1:FaceAmt>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:Life/ns1:FaceAmt" />
                </ns1:FaceAmt>
                <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage">
                  <ns1:Coverage id="[CoverageType_1, CoverageType_2]">
                    <ns1:CurrentAmt>
                      <xsl:value-of select="ns1:CurrentAmt" />
                    </ns1:CurrentAmt>
                  </ns1:Coverage>
                </xsl:for-each>
              </ns1:Life>
              <ns1:ApplicationInfo>
                <ns1:TrackingID>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
                </ns1:TrackingID>
              </ns1:ApplicationInfo>
              <ns1:RequirementInfo AppliesToPartyID="PartyType_2_life_1" id="RequirementInfoType_1">
                <ns1:ReqCode>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:ReqCode" />
                </ns1:ReqCode>
                <ns1:RequirementInfoKey>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementInfoKey" />
                </ns1:RequirementInfoKey>
                <ns1:RequirementInfoUniqueID>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementInfoUniqueID" />
                </ns1:RequirementInfoUniqueID>
                <ns1:RequestedDate>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequestedDate" />
                </ns1:RequestedDate>
                <ns1:ReleasePartyOrgCode>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:ReleasePartyOrgCode" />
                </ns1:ReleasePartyOrgCode>
                <ns1:RequirementAcctNum>
                  <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
                </ns1:RequirementAcctNum>
              </ns1:RequirementInfo>
            </ns1:Policy>
            <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Attachment | ns1:TXLifeRequest/ns1:OLifE/ns1:FormInstance/ns1:Attachment">
              <ns1:Attachment>
                <ns1:Description>
                  <xsl:value-of select="ns1:Description" />
                </ns1:Description>
                <ns1:AttachmentData>
                  <xsl:value-of select="ns1:AttachmentData" />
                </ns1:AttachmentData>
                <ns1:AttachmentType>
                  <xsl:value-of select="ns1:AttachmentType" />
                </ns1:AttachmentType>
                <ns1:TransferEncodingTypeString>
                  <xsl:value-of select="ns1:TransferEncodingTypeString" />
                </ns1:TransferEncodingTypeString>
                <ns1:AttachmentLocation>
                  <xsl:value-of select="ns1:AttachmentLocation" />
                </ns1:AttachmentLocation>
              </ns1:Attachment>
            </xsl:for-each>
          </ns1:Holding>
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Party">
            <ns1:Party id="{@id}">
              <ns1:PartyTypeCode>
                <xsl:value-of select="ns1:PartyTypeCode" />
              </ns1:PartyTypeCode>
              <ns1:FullName>
                <xsl:value-of select="ns1:FullName" />
              </ns1:FullName>
              <ns1:Organization>
                <ns1:AbbrName>
                  <xsl:value-of select="ns1:Organization/ns1:AbbrName" />
                </ns1:AbbrName>
              </ns1:Organization>
              <ns1:Address>
                <ns1:Line1>
                  <xsl:value-of select="ns1:Address/ns1:Line1" />
                </ns1:Line1>
                <ns1:Line2>
                  <xsl:value-of select="ns1:Address/ns1:Line2" />
                </ns1:Line2>
                <ns1:City>
                  <xsl:value-of select="ns1:Address/ns1:City" />
                </ns1:City>
                <ns1:AddressCountry>
                  <xsl:value-of select="ns1:Address/ns1:AddressCountry" />
                </ns1:AddressCountry>
                <ns1:AddressStateTC>
                  <xsl:value-of select="ns1:Address/ns1:AddressStateTC" />
                </ns1:AddressStateTC>
                <ns1:Zip>
                  <xsl:value-of select="ns1:Address/ns1:Zip" />
                </ns1:Zip>
                <ns1:AddressCountryTC>
                  <xsl:value-of select="ns1:Address/ns1:AddressCountryTC" />
                </ns1:AddressCountryTC>
              </ns1:Address>
              <ns1:Phone>
                <ns1:CountryCode>
                  <xsl:value-of select="ns1:Phone/ns1:CountryCode" />
                </ns1:CountryCode>
                <ns1:AreaCode>
                  <xsl:value-of select="ns1:Phone/ns1:AreaCode" />
                </ns1:AreaCode>
                <ns1:DialNumber>
                  <xsl:value-of select="ns1:Phone/ns1:DialNumber" />
                </ns1:DialNumber>
                <ns1:PhoneTypeCode>
                  <xsl:value-of select="ns1:Phone/ns1:PhoneTypeCode" />
                </ns1:PhoneTypeCode>
                <ns1:PrefPhone>
                  <xsl:value-of select="ns1:Phone/ns1:PrefPhone" />
                </ns1:PrefPhone>
              </ns1:Phone>
              <ns1:EMailAddress>
                <xsl:value-of select="ns1:EMailAddress" />
              </ns1:EMailAddress>
              <ns1:GovtID>
                <xsl:value-of select="ns1:GovtID" />
              </ns1:GovtID>
              <ns1:Person id="PersonType_1">
                <ns1:FirstName>
                  <xsl:value-of select="ns1:Person/ns1:FirstName" />
                </ns1:FirstName>
                <ns1:LastName>
                  <xsl:value-of select="ns1:Person/ns1:LastName" />
                </ns1:LastName>
                <ns1:Gender>
                  <xsl:value-of select="ns1:Person/ns1:Gender" />
                </ns1:Gender>
                <ns1:BirthDate>
                  <xsl:value-of select="ns1:Person/ns1:BirthDate" />
                </ns1:BirthDate>
              </ns1:Person>
              <ns1:Risk>
                <ns1:MedicalExam>
                  <ns1:LabSlipTicketNum>
                    <xsl:value-of select="ns1:Risk/ns1:MedicalExam/ns1:LabSlipTicketNum" />
                  </ns1:LabSlipTicketNum>
                </ns1:MedicalExam>
              </ns1:Risk>
            </ns1:Party>
          </xsl:for-each>
          <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:Relation">
            <ns1:Relation OriginatingObjectID="{@OriginatingObjectID}" RelatedObjectID="{@RelatedObjectID}" id="{@id}">
              <ns1:OriginatingObjectType>
                <xsl:value-of select="ns1:OriginatingObjectType" />
              </ns1:OriginatingObjectType>
              <ns1:RelatedObjectType>
                <xsl:value-of select="ns1:RelatedObjectType" />
              </ns1:RelatedObjectType>
              <ns1:RelationRoleCode>
                <xsl:value-of select="ns1:RelationRoleCode" />
              </ns1:RelationRoleCode>
            </ns1:Relation>
          </xsl:for-each>
        </ns1:OLifE>
      </ns1:TXLifeRequest>
    </ns1:TXLife>
  </xsl:template>
</xsl:stylesheet>

