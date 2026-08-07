<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:acord="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="acord:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <acord:TXLife schemaLocation="{@schemaLocation}">
      <xsl:for-each select="acord:UserAuthRequest">
        <acord:UserAuthRequest>
          <acord:UserLoginName>
            <xsl:value-of select="acord:UserLoginName" />
          </acord:UserLoginName>
          <acord:UserPswd>
            <acord:CryptPswd>
              <xsl:value-of select="acord:UserPswd/acord:CryptPswd" />
            </acord:CryptPswd>
          </acord:UserPswd>
          <acord:UserDate>
            <xsl:value-of select="acord:UserDate" />
          </acord:UserDate>
          <acord:UserTime>
            <xsl:value-of select="acord:UserTime" />
          </acord:UserTime>
          <acord:VendorApp>
            <acord:VendorName VendorCode="{acord:VendorApp/acord:VendorName/@VendorCode}">
              <xsl:value-of select="acord:VendorApp/acord:VendorName" />
            </acord:VendorName>
            <acord:AppName>
              <xsl:value-of select="acord:VendorApp/acord:AppName" />
            </acord:AppName>
            <acord:AppVer>
              <xsl:value-of select="acord:VendorApp/acord:AppVer" />
            </acord:AppVer>
          </acord:VendorApp>
        </acord:UserAuthRequest>
      </xsl:for-each>
      <xsl:for-each select="acord:TXLifeRequest">
        <acord:TXLifeRequest>
          <acord:TransRefGUID>
            <xsl:choose>
              <xsl:when test="string-length(acord:TransRefGUID) &gt; 0">
                <xsl:value-of select="acord:TransRefGUID" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="converter:getGUIDString()" />
              </xsl:otherwise>
            </xsl:choose>
          </acord:TransRefGUID>
          <xsl:choose>
            <xsl:when test="string-length(acord:TransType/@tc) &gt; 0">
              <acord:TransType tc="{acord:TransType/@tc}">
                <xsl:value-of select="acord:TransType" />
              </acord:TransType>
            </xsl:when>
            <xsl:otherwise>
              <acord:TransType tc="121">General Requirement Order Request</acord:TransType>
            </xsl:otherwise>
          </xsl:choose>
          <acord:TransExeDate>
            <xsl:value-of select="acord:TransExeDate" />
          </acord:TransExeDate>
          <acord:TransExeTime>
            <xsl:value-of select="acord:TransExeTime" />
          </acord:TransExeTime>
          <acord:TestIndicator tc="{acord:TestIndicator/@tc}">
            <xsl:value-of select="acord:TestIndicator" />
          </acord:TestIndicator>
          <acord:OLifE>
            <acord:Holding id="{acord:OLifE/acord:Holding/@id}">
              <acord:HoldingTypeCode tc="{acord:OLifE/acord:Holding/acord:HoldingTypeCode/@tc}">
                <xsl:value-of select="acord:OLifE/acord:Holding/acord:HoldingTypeCode" />
              </acord:HoldingTypeCode>
              <acord:Policy CarrierPartyID="{acord:OLifE/acord:Holding/acord:Policy/@CarrierPartyID}" id="{acord:OLifE/acord:Holding/acord:Policy/@id}">
                <acord:PolNumber>
                  <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:PolNumber" />
                </acord:PolNumber>
                <acord:CarrierCode>
                  <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:CarrierCode" />
                </acord:CarrierCode>
                <acord:ProductType tc="{acord:OLifE/acord:Holding/acord:Policy/acord:ProductType/@tc}">
                  <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:ProductType" />
                </acord:ProductType>
                <acord:Life>
                  <acord:FaceAmt>
                    <xsl:choose>
                      <xsl:when test="string-length(acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:FaceAmt) &gt; 0">
                        <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:FaceAmt" />
                      </xsl:when>
                      <xsl:when test="string-length(acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:TotalRiskAmt) &gt; 0">
                        <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:TotalRiskAmt" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:CurrentAmt" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </acord:FaceAmt>
                </acord:Life>
                <acord:ApplicationInfo>
                  <acord:TrackingID>
                    <xsl:value-of select="acord:OLifE/acord:Holding/acord:Policy/acord:ApplicationInfo/acord:TrackingID" />
                  </acord:TrackingID>
                </acord:ApplicationInfo>
                <xsl:for-each select="acord:OLifE/acord:Holding/acord:Policy/acord:RequirementInfo">
                  <acord:RequirementInfo>
                    <xsl:attribute name="AppliesToPartyID">
                      <xsl:value-of select="@AppliesToPartyID" />
                    </xsl:attribute>
                    <xsl:attribute name="id">
                      <xsl:value-of select="@id" />
                    </xsl:attribute>
                    <xsl:attribute name="AppliesToParticipantID">
                      <xsl:value-of select="@AppliesToParticipantID" />
                    </xsl:attribute>
                    <xsl:attribute name="FulfillerPartyID">
                      <xsl:value-of select="@FulfillerPartyID" />
                    </xsl:attribute>
                    <xsl:attribute name="RequesterPartyID">
                      <xsl:value-of select="@RequesterPartyID" />
                    </xsl:attribute>
                    <acord:ReqCode tc="{acord:ReqCode/@tc}">
                      <xsl:value-of select="acord:ReqCode" />
                    </acord:ReqCode>
                    <acord:RequestedDate>
                      <xsl:value-of select="acord:RequestedDate" />
                    </acord:RequestedDate>
                    <acord:ReleasePartyOrgCode>
                      <xsl:value-of select="acord:ReleasePartyOrgCode" />
                    </acord:ReleasePartyOrgCode>
                    <acord:RequirementAcctNum>
                      <xsl:value-of select="acord:RequirementAcctNum" />
                    </acord:RequirementAcctNum>
                    <acord:CarrierOrderNum>
                      <xsl:value-of select="acord:CarrierOrderNum" />
                    </acord:CarrierOrderNum>
                  </acord:RequirementInfo>
                </xsl:for-each>
              </acord:Policy>
              <xsl:variable name="TransRefGUID" select="acord:TransRefGUID" />
              <xsl:for-each select="acord:OLifE/acord:Holding/acord:Attachment[acord:AttachmentType/@tc != 2][string-length(acord:AttachmentData) &gt; 0] | ../acord:Request/acord:Form/acord:Attachment[string-length(acord:Data) &gt; 0]">
                <acord:Attachment>
                  <acord:Description>
                    <xsl:value-of select="concat($TransRefGUID, '-', position(), '.', substring-after(acord:Description, '.'))" />
                  </acord:Description>
                  <acord:AttachmentType tc="{acord:AttachmentType/@tc | acord:ImageType/@tc}">
                    <xsl:value-of select="acord:AttachmentType | acord:ImageType" />
                  </acord:AttachmentType>
                  <acord:FileName>
                    <xsl:value-of select="concat($TransRefGUID, '-', position(), '.', substring-after(acord:Description, '.'))" />
                  </acord:FileName>
                </acord:Attachment>
              </xsl:for-each>
              <xsl:for-each select="acord:OLifE/acord:Holding/acord:Attachment[acord:AttachmentType/@tc = 2] | acord:OLifE/acord:Holding/acord:Attachment[string-length(acord:AttachmentData) &lt; 1] | ../acord:Request/acord:Form/acord:Attachment[string-length(acord:Data) &lt; 1]">
                <acord:Attachment>
                  <acord:AttachmentData>
                    <xsl:value-of select="acord:AttachmentData | acord:Data" />
                  </acord:AttachmentData>
                  <acord:Description>
                    <xsl:value-of select="acord:Description | ../acord:Name" />
                  </acord:Description>
                  <acord:AttachmentType tc="{acord:AttachmentType/@tc | acord:ImageType/@tc}">
                    <xsl:value-of select="acord:AttachmentType | acord:ImageType" />
                  </acord:AttachmentType>
                </acord:Attachment>
              </xsl:for-each>
            </acord:Holding>
            <xsl:for-each select="acord:OLifE/acord:Party">
              <acord:Party id="{@id}">
                <acord:PartyTypeCode tc="{acord:PartyTypeCode/@tc}">
                  <xsl:value-of select="acord:PartyTypeCode" />
                </acord:PartyTypeCode>
                <acord:GovtID>
                  <xsl:value-of select="acord:GovtID" />
                </acord:GovtID>
                <acord:GovtIDTC tc="{acord:GovtIDTC/@tc}">
                  <xsl:value-of select="acord:GovtIDTC" />
                </acord:GovtIDTC>
                <xsl:if test="acord:Person">
                  <acord:Person id="{acord:Person/@id}">
                    <acord:FirstName>
                      <xsl:choose>
                        <xsl:when test="string-length(acord:Person/acord:FirstName) &gt; 0">
                          <xsl:value-of select="acord:Person/acord:FirstName" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="substring-before(acord:FullName, ' ')" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </acord:FirstName>
                    <acord:LastName>
                      <xsl:choose>
                        <xsl:when test="string-length(acord:Person/acord:LastName) &gt; 0">
                          <xsl:value-of select="acord:Person/acord:LastName" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="substring-after(acord:FullName, ' ')" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </acord:LastName>
                    <acord:Occupation>
                      <xsl:value-of select="acord:Person/acord:Occupation" />
                    </acord:Occupation>
                    <acord:MarStat tc="{acord:Person/acord:MarStat/@tc}">
                      <xsl:value-of select="acord:Person/acord:MarStat" />
                    </acord:MarStat>
                    <acord:Gender tc="{acord:Person/acord:Gender/@tc}">
                      <xsl:value-of select="acord:Person/acord:Gender" />
                    </acord:Gender>
                    <acord:BirthDate>
                      <xsl:value-of select="acord:Person/acord:BirthDate" />
                    </acord:BirthDate>
                    <acord:DriversLicenseNum>
                      <xsl:value-of select="acord:Person/acord:DriversLicenseNum" />
                    </acord:DriversLicenseNum>
                    <acord:DriversLicenseState tc="{acord:Person/acord:DriversLicenseState/@tc}">
                      <xsl:value-of select="acord:Person/acord:DriversLicenseState" />
                    </acord:DriversLicenseState>
                  </acord:Person>
                </xsl:if>
                <xsl:for-each select="acord:Address">
                  <acord:Address id="{@id}">
                    <acord:AddressTypeCode tc="{acord:AddressTypeCode/@tc}">
                      <xsl:value-of select="acord:AddressTypeCode" />
                    </acord:AddressTypeCode>
                    <acord:Line1>
                      <xsl:value-of select="acord:Line1" />
                    </acord:Line1>
                    <acord:City>
                      <xsl:value-of select="acord:City" />
                    </acord:City>
                    <acord:AddressState tc="{acord:AddressState/@tc | acord:AddressStateTC/@tc}">
                      <xsl:value-of select="acord:AddressState | acord:AddressStateTC" />
                    </acord:AddressState>
                    <acord:AddressStateTC tc="{acord:AddressState/@tc | acord:AddressStateTC/@tc}">
                      <xsl:value-of select="acord:AddressState | acord:AddressStateTC" />
                    </acord:AddressStateTC>
                    <acord:Zip>
                      <xsl:value-of select="acord:Zip" />
                    </acord:Zip>
                    <acord:Line2>
                      <xsl:value-of select="acord:Line2" />
                    </acord:Line2>
                  </acord:Address>
                </xsl:for-each>
                <xsl:for-each select="acord:Phone">
                  <acord:Phone>
                    <acord:AreaCode>
                      <xsl:value-of select="acord:AreaCode" />
                    </acord:AreaCode>
                    <acord:DialNumber>
                      <xsl:value-of select="acord:DialNumber" />
                    </acord:DialNumber>
                    <acord:PhoneTypeCode tc="{acord:PhoneTypeCode/@tc}">
                      <xsl:value-of select="acord:PhoneTypeCode" />
                    </acord:PhoneTypeCode>
                  </acord:Phone>
                </xsl:for-each>
                <acord:FullName>
                  <xsl:choose>
                    <xsl:when test="string-length(acord:FullName) &gt; 0">
                      <xsl:value-of select="acord:FullName" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat(acord:Person/acord:FirstName, ' ', acord:Person/acord:LastName)" />
                    </xsl:otherwise>
                  </xsl:choose>
                </acord:FullName>
                <xsl:if test="acord:Organization">
                  <acord:Organization>
                    <acord:AbbrName>
                      <xsl:value-of select="acord:Organization/acord:AbbrName" />
                    </acord:AbbrName>
                    <acord:OrgCode>
                      <xsl:value-of select="acord:Organization/acord:OrgCode" />
                    </acord:OrgCode>
                  </acord:Organization>
                </xsl:if>
                <xsl:if test="acord:Carrier">
                  <acord:Carrier>
                    <acord:CarrierCode>
                      <xsl:value-of select="acord:Carrier/acord:CarrierCode" />
                    </acord:CarrierCode>
                    <acord:NAICCode>
                      <xsl:value-of select="acord:Carrier/acord:NAICCode" />
                    </acord:NAICCode>
                  </acord:Carrier>
                </xsl:if>
              </acord:Party>
            </xsl:for-each>
            <xsl:for-each select="acord:OLifE/acord:Relation | acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:LifeParticipant">
              <acord:Relation OriginatingObjectID="{@OriginatingObjectID | ../../../../@id}" RelatedObjectID="{@RelatedObjectID | @PartyID}" id="{@id}">
                <acord:OriginatingObjectType tc="{acord:OriginatingObjectType/@tc | '4'}">
                  <xsl:value-of select="acord:OriginatingObjectType | 'Holding'" />
                </acord:OriginatingObjectType>
                <acord:RelatedObjectType tc="{acord:RelatedObjectType/@tc | '6'}">
                  <xsl:value-of select="acord:RelatedObjectType | 'Party'" />
                </acord:RelatedObjectType>
                <acord:RelationRoleCode tc="{acord:RelationRoleCode/@tc | acord:LifeParticipantRole/@tc}">
                  <xsl:value-of select="acord:RelationRoleCode | acord:LifeParticipantRole" />
                </acord:RelationRoleCode>
                <acord:NameFromRelatedObject>
                  <xsl:variable name="id" select="@RelatedObjectID" />
                  <xsl:variable name="party" select="/acord:TXLife/acord:TXLifeRequest/acord:OLifE/acord:Party[@id=$id]" />
                  <xsl:choose>
                    <xsl:when test="string-length(acord:NameFromRelatedObject) &gt; 0">
                      <xsl:value-of select="acord:NameFromRelatedObject" />
                    </xsl:when>
                    <xsl:when test="string-length($party/acord:FullName) &gt; 0">
                      <xsl:value-of select="$party/acord:FullName" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat($party/acord:Person/acord:FirstName, ' ', $party/acord:Person/acord:LastName)" />
                    </xsl:otherwise>
                  </xsl:choose>
                </acord:NameFromRelatedObject>
                <acord:RelationDescription>
                  <xsl:value-of select="acord:RelationDescription" />
                </acord:RelationDescription>
              </acord:Relation>
            </xsl:for-each>
          </acord:OLifE>
        </acord:TXLifeRequest>
      </xsl:for-each>
    </acord:TXLife>
  </xsl:template>
</xsl:stylesheet>

