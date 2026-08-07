<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
  <xsl:template match="RESULTS">
    <RESULTS>
      <CREATEDBY>
        <xsl:value-of select="CREATEDBY" />
      </CREATEDBY>
      <TYPETXT>
        <xsl:value-of select="TYPETXT" />
      </TYPETXT>
      <LASTMODIFIEDBY>
        <xsl:value-of select="LASTMODIFIEDBY" />
      </LASTMODIFIEDBY>
      <CREATEDDATE>
        <xsl:value-of select="CREATEDDATE" />
      </CREATEDDATE>
      <TYPETC>
        <xsl:value-of select="TYPETC" />
      </TYPETC>
      <TRANSACTIONID>
        <xsl:value-of select="TRANSACTIONID" />
      </TRANSACTIONID>
      <MODETC>
        <xsl:value-of select="MODETC" />
      </MODETC>
      <TRANSACTIONTEXT>
        <NORMALIZEDTXT>
          <ns1:TXLife schemaLocation="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/@schemaLocation}">
            <ns1:UserAuthRequest>
              <ns1:UserLoginName>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/UserLoginName" />
              </ns1:UserLoginName>
              <ns1:UserPswd>
                <ns1:CryptType>
                  <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/UserPswd/CryptType" />
                </ns1:CryptType>
                <ns1:Pswd>
                  <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/UserPswd/Pswd" />
                </ns1:Pswd>
              </ns1:UserPswd>
              <ns1:UserDate>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/UserDate" />
              </ns1:UserDate>
              <ns1:UserTime>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/UserTime" />
              </ns1:UserTime>
              <ns1:VendorApp>
                <ns1:VendorName>
                  <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/VendorApp/VendorName" />
                </ns1:VendorName>
                <ns1:AppName>
                  <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/VendorApp/AppName" />
                </ns1:AppName>
                <ns1:AppVer>
                  <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/UserAuthRequest/VendorApp/AppVer" />
                </ns1:AppVer>
              </ns1:VendorApp>
            </ns1:UserAuthRequest>
            <ns1:TXLifeRequest>
              <ns1:TransRefGUID>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/TransRefGUID" />
              </ns1:TransRefGUID>
              <ns1:TransType>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/TransType" />
              </ns1:TransType>
              <ns1:TransExeDate>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/TransExeDate" />
              </ns1:TransExeDate>
              <ns1:TransExeTime>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/TransExeTime" />
              </ns1:TransExeTime>
              <ns1:TransMode>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/TransMode" />
              </ns1:TransMode>
              <ns1:TestIndicator>
                <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/TestIndicator" />
              </ns1:TestIndicator>
              <ns1:OLifE>
                <ns1:SourceInfo>
                  <ns1:CreationDate>
                    <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/SourceInfo/CreationDate" />
                  </ns1:CreationDate>
                  <ns1:CreationTime>
                    <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/SourceInfo/CreationTime" />
                  </ns1:CreationTime>
                </ns1:SourceInfo>
                <ns1:Holding id="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/@id}">
                  <ns1:HoldingTypeCode>
                    <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/HoldingTypeCode" />
                  </ns1:HoldingTypeCode>
                  <ns1:Policy id="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/@id}">
                    <ns1:PolNumber>
                      <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/PolNumber" />
                    </ns1:PolNumber>
                    <ns1:LineOfBusiness>
                      <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/LineOfBusiness" />
                    </ns1:LineOfBusiness>
                    <ns1:ProductType>
                      <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/ProductType" />
                    </ns1:ProductType>
                    <ns1:CarrierCode>
                      <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/CarrierCode" />
                    </ns1:CarrierCode>
                    <ns1:Life>
                      <ns1:LoanIntType>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/LoanIntType" />
                      </ns1:LoanIntType>
                      <ns1:DivType>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/DivType" />
                      </ns1:DivType>
                      <ns1:Coverage id="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/@id}">
                        <ns1:ProductCode>
                          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/ProductCode" />
                        </ns1:ProductCode>
                        <ns1:LifeCovStatus>
                          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeCovStatus" />
                        </ns1:LifeCovStatus>
                        <ns1:LifeCovTypeCode>
                          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeCovTypeCode" />
                        </ns1:LifeCovTypeCode>
                        <ns1:IndicatorCode>
                          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/IndicatorCode" />
                        </ns1:IndicatorCode>
                        <ns1:CurrentAmt>
                          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/CurrentAmt" />
                        </ns1:CurrentAmt>
                        <ns1:LifeParticipant DataRep="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/@DataRep}" PartyID="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/@PartyID}" id="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/@id}">
                          <ns1:LifeParticipantRoleCode>
                            <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/LifeParticipantRoleCode" />
                          </ns1:LifeParticipantRoleCode>
                          <ns1:IssueAge>
                            <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/IssueAge" />
                          </ns1:IssueAge>
                          <ns1:IssueGender>
                            <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/IssueGender" />
                          </ns1:IssueGender>
                          <ns1:SmokerStat>
                            <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/SmokerStat" />
                          </ns1:SmokerStat>
                          <ns1:PermTableRating>
                            <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/PermTableRating" />
                          </ns1:PermTableRating>
                        </ns1:LifeParticipant>
                      </ns1:Coverage>
                    </ns1:Life>
                    <ns1:ApplicationInfo>
                      <ns1:TrackingID>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/TrackingID" />
                      </ns1:TrackingID>
                      <ns1:ApplicationJurisdiction>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/ApplicationJurisdiction" />
                      </ns1:ApplicationJurisdiction>
                      <ns1:SignedDate>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/SignedDate" />
                      </ns1:SignedDate>
                    </ns1:ApplicationInfo>
                    <ns1:RequirementInfo AppliesToPartyID="{(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/@AppliesToPartyID}">
                      <ns1:ReqCode>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/ReqCode" />
                      </ns1:ReqCode>
                      <ns1:RequirementInfoUniqueID>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/RequirementInfoUniqueID" />
                      </ns1:RequirementInfoUniqueID>
                      <ns1:ReqStatus>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/ReqStatus" />
                      </ns1:ReqStatus>
                      <ns1:RequestedDate>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/RequestedDate" />
                      </ns1:RequestedDate>
                      <ns1:ReleasePartyOrgCode>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/ReleasePartyOrgCode" />
                      </ns1:ReleasePartyOrgCode>
                      <ns1:RequirementAcctNum>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo/RequirementAcctNum" />
                      </ns1:RequirementAcctNum>
                    </ns1:RequirementInfo>
                    <ns1:KeyedValue>
                      <ns1:KeyName>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/KeyedValue/KeyName" />
                      </ns1:KeyName>
                      <ns1:KeyValue>
                        <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Policy/KeyedValue/KeyValue" />
                      </ns1:KeyValue>
                    </ns1:KeyedValue>
                  </ns1:Policy>
                  <xsl:for-each select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Holding/Attachment">
                    <ns1:Attachment>
                      <ns1:Description>
                        <xsl:value-of select="Description" />
                      </ns1:Description>
                      <ns1:AttachmentType>
                        <xsl:value-of select="AttachmentType" />
                      </ns1:AttachmentType>
                      <ns1:TransferEncodingTypeString>
                        <xsl:value-of select="TransferEncodingTypeString" />
                      </ns1:TransferEncodingTypeString>
                      <ns1:AttachmentLocation>
                        <xsl:value-of select="AttachmentLocation" />
                      </ns1:AttachmentLocation>
                    </ns1:Attachment>
                  </xsl:for-each>
                </ns1:Holding>
                <xsl:for-each select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Party">
                  <ns1:Party id="{@id}">
                    <ns1:PartyTypeCode>
                      <xsl:value-of select="PartyTypeCode" />
                    </ns1:PartyTypeCode>
                    <ns1:FullName>
                      <xsl:value-of select="FullName" />
                    </ns1:FullName>
                    <ns1:GovtID>
                      <xsl:value-of select="GovtID" />
                    </ns1:GovtID>
                    <ns1:GovtIDStat>
                      <xsl:value-of select="GovtIDStat" />
                    </ns1:GovtIDStat>
                    <ns1:GovtIDTC>
                      <xsl:value-of select="GovtIDTC" />
                    </ns1:GovtIDTC>
                    <ns1:ResidenceState>
                      <xsl:value-of select="ResidenceState" />
                    </ns1:ResidenceState>
                    <ns1:ResidenceCountry>
                      <xsl:value-of select="ResidenceCountry" />
                    </ns1:ResidenceCountry>
                    <ns1:Person>
                      <ns1:FirstName>
                        <xsl:value-of select="Person/FirstName" />
                      </ns1:FirstName>
                      <ns1:MiddleName>
                        <xsl:value-of select="Person/MiddleName" />
                      </ns1:MiddleName>
                      <ns1:LastName>
                        <xsl:value-of select="Person/LastName" />
                      </ns1:LastName>
                      <ns1:Occupation>
                        <xsl:value-of select="Person/Occupation" />
                      </ns1:Occupation>
                      <ns1:MarStat>
                        <xsl:value-of select="Person/MarStat" />
                      </ns1:MarStat>
                      <ns1:Gender>
                        <xsl:value-of select="Person/Gender" />
                      </ns1:Gender>
                      <ns1:BirthDate>
                        <xsl:value-of select="Person/BirthDate" />
                      </ns1:BirthDate>
                      <ns1:Citizenship>
                        <xsl:value-of select="Person/Citizenship" />
                      </ns1:Citizenship>
                      <ns1:EstSalary>
                        <xsl:value-of select="Person/EstSalary" />
                      </ns1:EstSalary>
                      <ns1:NetIncomeAmt>
                        <xsl:value-of select="Person/NetIncomeAmt" />
                      </ns1:NetIncomeAmt>
                    </ns1:Person>
                    <ns1:Address id="{Address/@id}">
                      <ns1:AddressTypeCode>
                        <xsl:value-of select="Address/AddressTypeCode" />
                      </ns1:AddressTypeCode>
                      <ns1:Line1>
                        <xsl:value-of select="Address/Line1" />
                      </ns1:Line1>
                      <ns1:City>
                        <xsl:value-of select="Address/City" />
                      </ns1:City>
                      <ns1:AddressState>
                        <xsl:value-of select="Address/AddressState" />
                      </ns1:AddressState>
                      <ns1:AddressStateTC>
                        <xsl:value-of select="Address/AddressStateTC" />
                      </ns1:AddressStateTC>
                      <ns1:Zip>
                        <xsl:value-of select="Address/Zip" />
                      </ns1:Zip>
                      <ns1:AddressCountryTC>
                        <xsl:value-of select="Address/AddressCountryTC" />
                      </ns1:AddressCountryTC>
                      <ns1:StartDate>
                        <xsl:value-of select="Address/StartDate" />
                      </ns1:StartDate>
                      <ns1:PreventOverrideInd>
                        <xsl:value-of select="Address/PreventOverrideInd" />
                      </ns1:PreventOverrideInd>
                    </ns1:Address>
                    <ns1:Phone>
                      <ns1:PhoneTypeCode>
                        <xsl:value-of select="Phone/PhoneTypeCode" />
                      </ns1:PhoneTypeCode>
                      <ns1:AreaCode>
                        <xsl:value-of select="Phone/AreaCode" />
                      </ns1:AreaCode>
                      <ns1:DialNumber>
                        <xsl:value-of select="Phone/DialNumber" />
                      </ns1:DialNumber>
                      <ns1:PrefPhone>
                        <xsl:value-of select="Phone/PrefPhone" />
                      </ns1:PrefPhone>
                      <ns1:BestTimeToCallFrom>
                        <xsl:value-of select="Phone/BestTimeToCallFrom" />
                      </ns1:BestTimeToCallFrom>
                      <ns1:BestTimeToCallTo>
                        <xsl:value-of select="Phone/BestTimeToCallTo" />
                      </ns1:BestTimeToCallTo>
                      <ns1:StartDate>
                        <xsl:value-of select="Phone/StartDate" />
                      </ns1:StartDate>
                    </ns1:Phone>
                    <ns1:EMailAddress DataRep="{EMailAddress/@DataRep}" id="{EMailAddress/@id}">
                      <ns1:EMailType>
                        <xsl:value-of select="EMailAddress/EMailType" />
                      </ns1:EMailType>
                      <ns1:AddrLine>
                        <xsl:value-of select="EMailAddress/AddrLine" />
                      </ns1:AddrLine>
                      <ns1:StartDate>
                        <xsl:value-of select="EMailAddress/StartDate" />
                      </ns1:StartDate>
                    </ns1:EMailAddress>
                  </ns1:Party>
                </xsl:for-each>
                <xsl:for-each select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/NORMALIZEDTXT/TXLife/TXLifeRequest/OLifE/Relation">
                  <ns1:Relation OriginatingObjectID="{@OriginatingObjectID}" RelatedObjectID="{@RelatedObjectID}" id="{@id}">
                    <ns1:OriginatingObjectType>
                      <xsl:value-of select="OriginatingObjectType" />
                    </ns1:OriginatingObjectType>
                    <ns1:RelatedObjectType>
                      <xsl:value-of select="RelatedObjectType" />
                    </ns1:RelatedObjectType>
                    <ns1:RelationRoleCode>
                      <xsl:value-of select="RelationRoleCode" />
                    </ns1:RelationRoleCode>
                  </ns1:Relation>
                </xsl:for-each>
              </ns1:OLifE>
            </ns1:TXLifeRequest>
          </ns1:TXLife>
        </NORMALIZEDTXT>
        <ORIGINALTXT>
          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/ORIGINALTXT" />
        </ORIGINALTXT>
        <ORIGINALTYPE>
          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/ORIGINALTYPE" />
        </ORIGINALTYPE>
        <TRANSACTIONTEXTID>
          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/TRANSACTIONTEXTID" />
        </TRANSACTIONTEXTID>
        <TRANSACTIONID>
          <xsl:value-of select="(TRANSACTIONTEXT|TRANSACTIONTEXT/RECORD)[1]/TRANSACTIONID" />
        </TRANSACTIONID>
      </TRANSACTIONTEXT>
      <LASTMODIFIEDDATE>
        <xsl:value-of select="LASTMODIFIEDDATE" />
      </LASTMODIFIEDDATE>
      <TRANSACTIONATTACHMENT>
        <xsl:for-each select="TRANSACTIONATTACHMENT/ATTACHMENT">
          <ATTACHMENT>
            <TYPETXT>
              <xsl:value-of select="TYPETXT" />
            </TYPETXT>
            <CRLPAGECOUNT>
              <xsl:value-of select="CRLPAGECOUNT" />
            </CRLPAGECOUNT>
            <TYPETC>
              <xsl:value-of select="TYPETC" />
            </TYPETC>
            <LOCATIONTC>
              <xsl:value-of select="LOCATIONTC" />
            </LOCATIONTC>
            <CRLDRAWERNAME>
              <xsl:value-of select="CRLDRAWERNAME" />
            </CRLDRAWERNAME>
            <TRANSACTIONID>
              <xsl:value-of select="TRANSACTIONID" />
            </TRANSACTIONID>
            <CRLFOLDERID>
              <xsl:value-of select="CRLFOLDERID" />
            </CRLFOLDERID>
            <xsl:if test="string-length(CRLDOCUMENTID) &gt; '0'">
              <CRLDOCUMENTID>
                <xsl:value-of select="CRLDOCUMENTID" />
              </CRLDOCUMENTID>
            </xsl:if>
            <BASICTYPETC>
              <xsl:value-of select="BASICTYPETC" />
            </BASICTYPETC>
            <MIMETYPE>
              <xsl:value-of select="MIMETYPE" />
            </MIMETYPE>
            <BASICTYPETXT>
              <xsl:value-of select="BASICTYPETXT" />
            </BASICTYPETXT>
            <ATTACHMENTID>
              <xsl:value-of select="ATTACHMENTID" />
            </ATTACHMENTID>
            <STATUSID>
              <xsl:value-of select="STATUSID" />
            </STATUSID>
            <ENCTYPESTR>
              <xsl:value-of select="ENCTYPESTR" />
            </ENCTYPESTR>
            <ENCTYPETC>
              <xsl:value-of select="ENCTYPETC" />
            </ENCTYPETC>
            <DESCR>
              <xsl:value-of select="DESCR" />
            </DESCR>
          </ATTACHMENT>
        </xsl:for-each>
      </TRANSACTIONATTACHMENT>
      <CREATIONDATETIME>
        <xsl:value-of select="CREATIONDATETIME" />
      </CREATIONDATETIME>
      <TRANSREFGUID>
        <xsl:value-of select="TRANSREFGUID" />
      </TRANSREFGUID>
      <TRANSACTIONREQINFO>
        <REQINFO>
          <REQACCTNUM>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQACCTNUM" />
          </REQACCTNUM>
          <REQCODETC>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQCODETC" />
          </REQCODETC>
          <UNIQUEID>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/UNIQUEID" />
          </UNIQUEID>
          <APPLIESTOPARTYID>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/APPLIESTOPARTYID" />
          </APPLIESTOPARTYID>
          <REQCODETXT>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQCODETXT" />
          </REQCODETXT>
          <REQSCHEDULEDSTARTTIME>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQSCHEDULEDSTARTTIME" />
          </REQSCHEDULEDSTARTTIME>
          <REQSCHEDULEDDATE>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQSCHEDULEDDATE" />
          </REQSCHEDULEDDATE>
          <RELEASEPARTYORGCODE>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/RELEASEPARTYORGCODE" />
          </RELEASEPARTYORGCODE>
          <REQSTATUS>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQSTATUS" />
          </REQSTATUS>
          <POLICYID>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/POLICYID" />
          </POLICYID>
          <REQDATE>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQDATE" />
          </REQDATE>
          <REQINFOID>
            <xsl:value-of select="TRANSACTIONREQINFO/REQINFO/REQINFOID" />
          </REQINFOID>
        </REQINFO>
      </TRANSACTIONREQINFO>
      <TRANSACTIONPOLICY>
        <POLICY>
          <PREFLANGTC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PREFLANGTC" />
          </PREFLANGTC>
          <PAYMENTMETHODTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PAYMENTMETHODTXT" />
          </PAYMENTMETHODTXT>
          <INDICATORCODETXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/INDICATORCODETXT" />
          </INDICATORCODETXT>
          <PRODUCTTYPETCTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PRODUCTTYPETCTXT" />
          </PRODUCTTYPETCTXT>
          <PAYMENTMODETXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PAYMENTMODETXT" />
          </PAYMENTMODETXT>
          <TRANSACTIONID>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/TRANSACTIONID" />
          </TRANSACTIONID>
          <PLANNAME>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PLANNAME" />
          </PLANNAME>
          <HOLDINGTC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/HOLDINGTC" />
          </HOLDINGTC>
          <PRODUCTCODE>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PRODUCTCODE" />
          </PRODUCTCODE>
          <SHORTNAME>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/SHORTNAME" />
          </SHORTNAME>
          <POLNUMBER>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/POLNUMBER" />
          </POLNUMBER>
          <POLICYID>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/POLICYID" />
          </POLICYID>
          <FACEAMT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/FACEAMT" />
          </FACEAMT>
          <APPJURISDICTIONTC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/APPJURISDICTIONTC" />
          </APPJURISDICTIONTC>
          <LIFECOVTYPECODETC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LIFECOVTYPECODETC" />
          </LIFECOVTYPECODETC>
          <TRACKINGID>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/TRACKINGID" />
          </TRACKINGID>
          <PARTICIPANTROLECODETXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PARTICIPANTROLECODETXT" />
          </PARTICIPANTROLECODETXT>
          <PAYMENTMODETC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PAYMENTMODETC" />
          </PAYMENTMODETC>
          <PARTICIPANTID>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PARTICIPANTID" />
          </PARTICIPANTID>
          <LIFECOVTYPECODETXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LIFECOVTYPECODETXT" />
          </LIFECOVTYPECODETXT>
          <LINEOFBUSINESSTC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LINEOFBUSINESSTC" />
          </LINEOFBUSINESSTC>
          <LIFECOVSTATUSTC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LIFECOVSTATUSTC" />
          </LIFECOVSTATUSTC>
          <PARTICIPANTROLECODETC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PARTICIPANTROLECODETC" />
          </PARTICIPANTROLECODETC>
          <INITIALPREMAMT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/INITIALPREMAMT" />
          </INITIALPREMAMT>
          <CURRENTAMT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/CURRENTAMT" />
          </CURRENTAMT>
          <SIGNEDDATE>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/SIGNEDDATE" />
          </SIGNEDDATE>
          <PREFLANGTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PREFLANGTXT" />
          </PREFLANGTXT>
          <HOLDINGID>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/HOLDINGID" />
          </HOLDINGID>
          <HOLDINGTCTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/HOLDINGTCTXT" />
          </HOLDINGTCTXT>
          <LIFECOVSTATUSTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LIFECOVSTATUSTXT" />
          </LIFECOVSTATUSTXT>
          <LINEOFBUSINESSTCTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LINEOFBUSINESSTCTXT" />
          </LINEOFBUSINESSTCTXT>
          <PARTICIPANTPARTYID>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PARTICIPANTPARTYID" />
          </PARTICIPANTPARTYID>
          <APPJURISDICTIONTXT>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/APPJURISDICTIONTXT" />
          </APPJURISDICTIONTXT>
          <PAYMENTMETHODTC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PAYMENTMETHODTC" />
          </PAYMENTMETHODTC>
          <CARRIERCODE>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/CARRIERCODE" />
          </CARRIERCODE>
          <PRODUCTTYPETC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/PRODUCTTYPETC" />
          </PRODUCTTYPETC>
          <INDICATORCODETC>
            <xsl:value-of select="TRANSACTIONPOLICY/POLICY/INDICATORCODETC" />
          </INDICATORCODETC>
        </POLICY>
      </TRANSACTIONPOLICY>
      <EXEDATETIME>
        <xsl:value-of select="EXEDATETIME" />
      </EXEDATETIME>
      <TRANSACTIONSTATUSES>
        <xsl:for-each select="TRANSACTIONSTATUSES/STATUS">
          <STATUS>
            <STATUSEVENTDETAIL>
              <xsl:value-of select="STATUSEVENTDETAIL" />
            </STATUSEVENTDETAIL>
            <PROVIDEREVENTCODE>
              <xsl:value-of select="PROVIDEREVENTCODE" />
            </PROVIDEREVENTCODE>
            <STATUSEVENTDATETIME>
              <xsl:value-of select="STATUSEVENTDATETIME" />
            </STATUSEVENTDATETIME>
            <MESSAGESENT>
              <xsl:value-of select="MESSAGESENT" />
            </MESSAGESENT>
            <STATUSEVENTTYPECODE>
              <xsl:value-of select="STATUSEVENTTYPECODE" />
            </STATUSEVENTTYPECODE>
            <STATUSID>
              <xsl:value-of select="STATUSID" />
            </STATUSID>
            <REQINFOID>
              <xsl:value-of select="REQINFOID" />
            </REQINFOID>
          </STATUS>
        </xsl:for-each>
      </TRANSACTIONSTATUSES>
      <SOURCEINFONAME>
        <xsl:value-of select="SOURCEINFONAME" />
      </SOURCEINFONAME>
      <TESTINDICATOR>
        <xsl:value-of select="TESTINDICATOR" />
      </TESTINDICATOR>
      <MODETXT>
        <xsl:value-of select="MODETXT" />
      </MODETXT>
      <SOURCEINFODESCR>
        <xsl:value-of select="SOURCEINFODESCR" />
      </SOURCEINFODESCR>
    </RESULTS>
  </xsl:template>
</xsl:stylesheet>

