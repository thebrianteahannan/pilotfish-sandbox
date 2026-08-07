<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:acord="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="acord" version="1.0">
  <xsl:template match="/acord:TXLife">
    <acord:TXLife schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
      <acord:UserAuthRequest>
        <acord:UserLoginName>
          <xsl:value-of select="acord:UserAuthRequest/acord:UserLoginName" />
        </acord:UserLoginName>
        <acord:UserPswd>
          <acord:CryptType>
            <xsl:value-of select="acord:UserAuthRequest/acord:UserPswd/acord:CryptType" />
          </acord:CryptType>
          <acord:CryptPswd>
            <xsl:value-of select="acord:UserAuthRequest/acord:UserPswd/acord:CryptPswd" />
          </acord:CryptPswd>
        </acord:UserPswd>
        <acord:VendorApp>
          <acord:AppName>
            <xsl:value-of select="acord:UserAuthRequest/acord:VendorApp/acord:AppName" />
          </acord:AppName>
          <acord:AppVer />
        </acord:VendorApp>
      </acord:UserAuthRequest>
      <acord:TXLifeRequest>
        <acord:TransRefGUID>
          <xsl:value-of select="acord:TXLifeRequest/acord:TransRefGUID" />
        </acord:TransRefGUID>
        <acord:TransType tc="121">
          <xsl:text>General Requirement Order Request</xsl:text>
        </acord:TransType>
        <acord:TransExeDate>
          <xsl:value-of select="acord:TXLifeRequest/acord:TransExeDate" />
        </acord:TransExeDate>
        <acord:TransExeTime>
          <xsl:value-of select="acord:TXLifeRequest/acord:TransExeTime" />
        </acord:TransExeTime>
        <acord:OLifE>
          <acord:SourceInfo>
            <acord:CreationDate>
              <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:SourceInfo/acord:CreationDate" />
            </acord:CreationDate>
            <acord:CreationTime>
              <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:SourceInfo/acord:CreationTime" />
            </acord:CreationTime>
            <acord:SourceInfoName>
              <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:SourceInfo/acord:SourceInfoName" />
            </acord:SourceInfoName>
          </acord:SourceInfo>
          <acord:Holding id="{acord:TXLifeRequest/acord:OLifE/acord:Holding/@id}">
            <acord:Policy id="{acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:ProductCode}">
              <acord:PolNumber>
                <xsl:choose>
                  <xsl:when test="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:PolNumber">
                    <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:PolNumber" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:PlanName" />
                  </xsl:otherwise>
                </xsl:choose>
              </acord:PolNumber>
              <acord:CarrierCode>
                <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:CarrierCode" />
              </acord:CarrierCode>
              <acord:Life>
                <acord:FaceAmt>
                  <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:FaceAmt" />
                </acord:FaceAmt>
                <acord:Coverage id="{acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:IndicatorCode}">
                  <acord:CurrentAmt>
                    <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:Life/acord:Coverage/acord:CurrentAmt" />
                  </acord:CurrentAmt>
                </acord:Coverage>
              </acord:Life>
              <acord:ApplicationInfo>
                <acord:TrackingID>
                  <xsl:value-of select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Policy/acord:ApplicationInfo/acord:TrackingID" />
                </acord:TrackingID>
              </acord:ApplicationInfo>
            </acord:Policy>
            <xsl:for-each select="acord:TXLifeRequest/acord:OLifE/acord:Holding/acord:Attachment">
              <acord:Attachment>
                <acord:Description>
                  <xsl:value-of select="acord:Description" />
                </acord:Description>
                <xsl:choose>
                  <xsl:when test="acord:AttachmentType">
                    <acord:AttachmentType tc="{acord:AttachmentType/@tc}">
                      <xsl:value-of select="acord:AttachmentType" />
                    </acord:AttachmentType>
                  </xsl:when>
                </xsl:choose>
                <xsl:if test="acord:AttachmentData">
                  <acord:AttachmentData>
                    <xsl:value-of select="acord:AttachmentData" />
                  </acord:AttachmentData>
                </xsl:if>
                <xsl:if test="acord:TransferEncodingTypeTC">
                  <acord:TransferEncodingTypeString>
                    <xsl:value-of select="acord:TransferEncodingTypeTC" />
                  </acord:TransferEncodingTypeString>
                </xsl:if>
              </acord:Attachment>
            </xsl:for-each>
            <xsl:for-each select="acord:TXLifeRequest/acord:OLifE/acord:FormInstance">
              <acord:Attachment>
                <acord:Description>
                  <xsl:value-of select="concat(acord:Attachment/acord:Description,concat('.',acord:Attachment/acord:MimeTypeTC))" />
                </acord:Description>
                <acord:AttachmentData>
                  <xsl:choose>
                    <xsl:when test="acord:Attachment/acord:AttachmentData">
                      <xsl:value-of select="acord:Attachment/acord:AttachmentData" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="acord:Attachment/acord:Data" />
                    </xsl:otherwise>
                  </xsl:choose>
                </acord:AttachmentData>
                <xsl:choose>
                  <xsl:when test="acord:Attachment/acord:AttachmentType">
                    <acord:AttachmentType tc="{acord:Attachment/acord:AttachmentType/@tc}">
                      <xsl:value-of select="acord:Attachment/acord:AttachmentType" />
                    </acord:AttachmentType>
                  </xsl:when>
                  <xsl:when test="acord:Attachment/acord:AttachmentBasicType">
                    <acord:AttachmentType>
                      <xsl:attribute name="tc">
                        <xsl:call-template name="AttachmentBasicToAttachmentTypeMapping">
                          <xsl:with-param name="value" select="acord:Attachment/acord:AttachmentBasicType/@tc" />
                        </xsl:call-template>
                      </xsl:attribute>
                      <xsl:value-of select="acord:Attachment/acord:AttachmentBasicType" />
                    </acord:AttachmentType>
                  </xsl:when>
                </xsl:choose>
                <acord:MimeTypeTC tc="{acord:Attachment/acord:MimeTypeTC/@tc}">
                  <xsl:value-of select="acord:Attachment/acord:MimeTypeTC" />
                </acord:MimeTypeTC>
                <acord:TransferEncodingTypeString>
                  <xsl:value-of select="acord:Attachment/acord:TransferEncodingTypeTC" />
                </acord:TransferEncodingTypeString>
                <acord:AttachmentLocation tc="{acord:Attachment/acord:AttachmentLocation/@tc}">
                  <xsl:value-of select="acord:Attachment/acord:AttachmentLocation" />
                </acord:AttachmentLocation>
              </acord:Attachment>
            </xsl:for-each>
          </acord:Holding>
          <xsl:for-each select="acord:TXLifeRequest/acord:OLifE/acord:Party">
            <acord:Party id="{@id}">
              <xsl:choose>
                <xsl:when test="acord:PartyTypeCode">
                  <PartyTypeCode tc="{acord:PartyTypeCode/@tc}">
                    <xsl:value-of select="acord:PartyTypeCode" />
                  </PartyTypeCode>
                </xsl:when>
                <xsl:when test="acord:Person/acord:LastName">
                  <PartyTypeCode tc="1">Person</PartyTypeCode>
                </xsl:when>
                <xsl:when test="acord:Organization">
                  <PartyTypeCode tc="2">Organization</PartyTypeCode>
                </xsl:when>
              </xsl:choose>
              <acord:FullName>
                <xsl:choose>
                  <xsl:when test="string-length(acord:FullName) &gt; 0">
                    <xsl:value-of select="acord:FullName" />
                  </xsl:when>
                  <xsl:when test="acord:Person">
                    <xsl:value-of select="concat(acord:Person/acord:FirstName,concat(' ',acord:Person/acord:LastName))" />
                  </xsl:when>
                  <xsl:when test="acord:Organization">
                    <xsl:value-of select="acord:Organization/acord:AbbrName" />
                  </xsl:when>
                </xsl:choose>
              </acord:FullName>
              <xsl:if test="acord:Organization">
                <acord:Organization>
                  <acord:AbbrName>
                    <xsl:value-of select="acord:Organization/acord:AbbrName" />
                  </acord:AbbrName>
                </acord:Organization>
              </xsl:if>
              <xsl:if test="acord:Address">
                <acord:Address>
                  <acord:Line1>
                    <xsl:value-of select="acord:Address/acord:Line1" />
                  </acord:Line1>
                  <acord:City>
                    <xsl:value-of select="acord:Address/acord:City" />
                  </acord:City>
                  <xsl:choose>
                    <xsl:when test="acord:Address/acord:AddressStateTC">
                      <acord:AddressStateTC tc="{acord:Address/acord:AddressStateTC/@tc}">
                        <xsl:value-of select="acord:Address/acord:AddressStateTC" />
                      </acord:AddressStateTC>
                    </xsl:when>
                    <xsl:when test="acord:Person/acord:DriversLicenseState">
                      <acord:AddressStateTC tc="{acord:Person/acord:DriversLicenseState/@tc}">
                        <xsl:value-of select="acord:Person/acord:DriversLicenseState" />
                      </acord:AddressStateTC>
                    </xsl:when>
                  </xsl:choose>
                  <acord:Zip>
                    <xsl:value-of select="acord:Address/acord:Zip" />
                  </acord:Zip>
                </acord:Address>
              </xsl:if>
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
              <xsl:if test="acord:EMailAddress">
                <acord:EMailAddress>
                  <xsl:value-of select="acord:EMailAddress/acord:AddrLine" />
                </acord:EMailAddress>
              </xsl:if>
              <xsl:choose>
                <xsl:when test="acord:GovtID">
                  <xsl:choose>
                    <xsl:when test="acord:GovtIDTC">
                      <GovtIDTC tc="{acord:GovtIDTC/@tc}">
                        <xsl:value-of select="acord:GovtIDTC" />
                      </GovtIDTC>
                    </xsl:when>
                    <xsl:otherwise>
                      <GovtIDTC tc="1">Social Security Number US</GovtIDTC>
                    </xsl:otherwise>
                  </xsl:choose>
                  <acord:GovtID>
                    <xsl:value-of select="acord:GovtID" />
                  </acord:GovtID>
                </xsl:when>
              </xsl:choose>
              <xsl:if test="acord:Person">
                <acord:Person>
                  <acord:FirstName>
                    <xsl:value-of select="acord:Person/acord:FirstName" />
                  </acord:FirstName>
                  <acord:LastName>
                    <xsl:value-of select="acord:Person/acord:LastName" />
                  </acord:LastName>
                  <xsl:choose>
                    <xsl:when test="acord:Person/acord:Gender">
                      <acord:Gender tc="{acord:Person/acord:Gender/@tc}">
                        <xsl:value-of select="acord:Person/acord:Gender" />
                      </acord:Gender>
                    </xsl:when>
                    <xsl:otherwise>
                      <acord:Gender tc="0">Unknown</acord:Gender>
                    </xsl:otherwise>
                  </xsl:choose>
                  <acord:BirthDate>
                    <xsl:value-of select="acord:Person/acord:BirthDate" />
                  </acord:BirthDate>
                </acord:Person>
              </xsl:if>
            </acord:Party>
          </xsl:for-each>
          <xsl:for-each select="acord:TXLifeRequest/acord:OLifE/acord:Relation">
            <acord:Relation OriginatingObjectID="{@OriginatingObjectID}" RelatedObjectID="{@RelatedObjectID}" id="{@id}">
              <acord:OriginatingObjectType tc="{acord:OriginatingObjectType/@tc}">
                <xsl:value-of select="acord:OriginatingObjectType" />
              </acord:OriginatingObjectType>
              <acord:RelatedObjectType tc="{acord:RelatedObjectType/@tc}">
                <xsl:value-of select="acord:RelatedObjectType" />
              </acord:RelatedObjectType>
              <acord:RelationRoleCode tc="{acord:RelationRoleCode/@tc}">
                <xsl:value-of select="acord:RelationRoleCode" />
              </acord:RelationRoleCode>
            </acord:Relation>
          </xsl:for-each>
        </acord:OLifE>
      </acord:TXLifeRequest>
    </acord:TXLife>
  </xsl:template>
  <xsl:template name="AttachmentBasicToAttachmentTypeMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='1'">2</xsl:when>
      <xsl:when test="$value='2'">0</xsl:when>
      <xsl:when test="$value='3'">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

