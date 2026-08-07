<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" version="1.0">
  <xsl:template match="/PHISORDER">
    <ns1:TXLife>
      <ns1:UserAuthRequest>
        <ns1:UserPswd>
          <ns1:CryptType>
            <xsl:text>NONE</xsl:text>
          </ns1:CryptType>
        </ns1:UserPswd>
        <ns1:VendorApp>
          <ns1:VendorName VendorCode="118">
            <xsl:text>CRL</xsl:text>
          </ns1:VendorName>
          <ns1:AppName>
            <xsl:text>LabResultsTransmittal</xsl:text>
          </ns1:AppName>
        </ns1:VendorApp>
      </ns1:UserAuthRequest>
      <ns1:TXLifeRequest>
        <xsl:attribute name="id" />
        <ns1:TransRefGUID />
        <ns1:TransType tc="1122">
          <xsl:text>General Requirements Result Transmittal</xsl:text>
        </ns1:TransType>
        <ns1:TransExeDate>
          <xsl:value-of select="ORDER_INFO/ORDER_DATE" />
        </ns1:TransExeDate>
        <ns1:OLifE>
          <xsl:attribute name="Version">2.16.01</xsl:attribute>
          <ns1:SourceInfo>
            <ns1:SourceInfoName>
              <xsl:text>CRL</xsl:text>
            </ns1:SourceInfoName>
          </ns1:SourceInfo>
          <ns1:Holding id="crl_holding">
            <xsl:element name="HoldingForm">
              <xsl:attribute name="tc" />
              <xsl:text>Individual</xsl:text>
            </xsl:element>
            <ns1:Policy>
              <xsl:attribute name="id" />
              <xsl:attribute name="CarrierPartyID">
                <xsl:text>Carrier</xsl:text>
              </xsl:attribute>
              <ns1:PolNumber>
                <xsl:value-of select="ORDER_INFO/POLICY/POLICY_NO" />
              </ns1:PolNumber>
              <xsl:element name="LineOfBusiness">
                <xsl:attribute name="tc">
                  <xsl:text>1</xsl:text>
                </xsl:attribute>
                <xsl:text>Life</xsl:text>
              </xsl:element>
              <xsl:element name="CarrierCode">
                <xsl:text>70025</xsl:text>
              </xsl:element>
              <ns1:ApplicationInfo>
                <ns1:TrackingID />
              </ns1:ApplicationInfo>
              <xsl:for-each select="ORDER_INFO/SERVICE/*[substring(local-name(), 1, 8) = 'SRV_CODE']">
                <ns1:RequirementInfo AppliesToPartyID="Party_4" id="">
                  <ns1:ReqCode tc="{.}">
                    <xsl:value-of select="." />
                  </ns1:ReqCode>
                  <ns1:RequirementDetails>
                    <xsl:value-of select="../../REMARKS/*[substring(local-name(), 1, 8) = 'REM_DESC' and substring(local-name(), 9, 1) = string(position())]" />
                  </ns1:RequirementDetails>
                  <ns1:RequirementAcctNum>
                    <xsl:value-of select="../../REMOTE_NO" />
                  </ns1:RequirementAcctNum>
                </ns1:RequirementInfo>
              </xsl:for-each>
            </ns1:Policy>
          </ns1:Holding>
          <ns1:Party id="Party_1">
            <ns1:FullName>
              <xsl:value-of select="ORDER_INFO/AGENT" />
            </ns1:FullName>
            <ns1:PartyTypeCode tc="1">
              <xsl:text>Person</xsl:text>
            </ns1:PartyTypeCode>
            <xsl:element name="Phone">
              <xsl:element name="PhoneTypeCode">
                <xsl:attribute name="tc">
                  <xsl:text>2</xsl:text>
                </xsl:attribute>
                <xsl:text>Business</xsl:text>
              </xsl:element>
              <xsl:element name="AreaCode">
                <xsl:value-of select="substring(translate(ORDER_INFO/AGENCY_PH, '-', ''), 1, 3)" />
              </xsl:element>
              <xsl:element name="DialNumber">
                <xsl:value-of select="substring(translate(ORDER_INFO/AGENCY_PH, '-', ''), 4, 7)" />
              </xsl:element>
            </xsl:element>
          </ns1:Party>
          <ns1:Party id="Party_2">
            <ns1:FullName>
              <xsl:value-of select="concat(ORDER_INFO/APPLICANT/FIRST_NAME, ' ', ORDER_INFO/APPLICANT/LAST_NAME)" />
            </ns1:FullName>
            <ns1:GovtID>
              <xsl:value-of select="ORDER_INFO/APPLICANT/APP_SOC" />
            </ns1:GovtID>
            <ns1:Person>
              <ns1:FirstName>
                <xsl:value-of select="ORDER_INFO/APPLICANT/FIRST_NAME" />
              </ns1:FirstName>
              <ns1:LastName>
                <xsl:value-of select="ORDER_INFO/APPLICANT/LAST_NAME" />
              </ns1:LastName>
              <ns1:BirthDate>
                <xsl:value-of select="ORDER_INFO/APPLICANT/APP_DOB" />
              </ns1:BirthDate>
              <ns1:Age>
                <xsl:value-of select="ORDER_INFO/APPLICANT/APP_AGE" />
              </ns1:Age>
              <xsl:element name="Gender">
                <xsl:attribute name="tc">
                  <xsl:value-of select="ORDER_INFO/APPLICANT/APP_GENDER" />
                </xsl:attribute>
                <xsl:value-of select="ORDER_INFO/APPLICANT/APP_GENDER" />
              </xsl:element>
            </ns1:Person>
            <ns1:PartyTypeCode tc="1">
              <xsl:text>Person</xsl:text>
            </ns1:PartyTypeCode>
            <xsl:element name="GovtIDTC">
              <xsl:attribute name="tc">
                <xsl:text>0</xsl:text>
              </xsl:attribute>
              <xsl:text>Unknown</xsl:text>
            </xsl:element>
            <xsl:element name="Address">
              <xsl:element name="AddressTypeCode">
                <xsl:attribute name="tc">
                  <xsl:text>0</xsl:text>
                </xsl:attribute>
                <xsl:text>Unknown</xsl:text>
              </xsl:element>
              <xsl:element name="Line1">
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_ADDRESS_1" />
              </xsl:element>
              <xsl:element name="Line2">
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_ADDRESS_2" />
              </xsl:element>
              <xsl:element name="City">
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_CITY" />
              </xsl:element>
              <xsl:element name="AddressState">
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_STATE" />
              </xsl:element>
              <xsl:element name="AddressStateTC">
                <xsl:attribute name="tc">
                  <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_STATE" />
                </xsl:attribute>
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_STATE" />
              </xsl:element>
              <xsl:element name="Zip">
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_ZIP" />
              </xsl:element>
              <xsl:element name="Phone">
                <xsl:element name="PhoneTypeCode">
                  <xsl:attribute name="tc">
                    <xsl:text>1</xsl:text>
                  </xsl:attribute>
                  <xsl:text>Home</xsl:text>
                </xsl:element>
                <xsl:element name="AreaCode">
                  <xsl:value-of select="substring(translate(ORDER_INFO/APPLICANT/EXM_PHONE, '-',''), 1, 3)" />
                </xsl:element>
                <xsl:element name="DialNumber">
                  <xsl:value-of select="substring(translate(ORDER_INFO/APPLICANT/EXM_PHONE, '-',''), 4, 7)" />
                </xsl:element>
              </xsl:element>
            </xsl:element>
          </ns1:Party>
          <ns1:Relation>
            <xsl:attribute name="ns1:RelatedObjectID">
              <xsl:text>Party_2</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="ns1:id">
              <xsl:text>Relation_N10007</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="ns1:OriginatingObjectID">
              <xsl:text>crl_holding</xsl:text>
            </xsl:attribute>
            <xsl:element name="OriginatingObjectType">
              <xsl:attribute name="tc">
                <xsl:text>4</xsl:text>
              </xsl:attribute>
              <xsl:text>Holding</xsl:text>
            </xsl:element>
            <xsl:element name="RelatedObjectType">
              <xsl:attribute name="tc">
                <xsl:text>6</xsl:text>
              </xsl:attribute>
              <xsl:text>Party</xsl:text>
            </xsl:element>
            <xsl:element name="ns1:RelationRoleCode">
              <xsl:attribute name="tc">
                <xsl:text>32</xsl:text>
              </xsl:attribute>
              <xsl:text>Insured</xsl:text>
            </xsl:element>
          </ns1:Relation>
          <ns1:Relation>
            <xsl:attribute name="ns1:RelatedObjectID">
              <xsl:text>Party_1</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="id">
              <xsl:text>Relation_N101E3</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="ns1:OriginatingObjectID">
              <xsl:text>crl_holding</xsl:text>
            </xsl:attribute>
            <xsl:element name="OriginatingObjectType">
              <xsl:attribute name="tc">
                <xsl:text>4</xsl:text>
              </xsl:attribute>
              <xsl:text>Holding</xsl:text>
            </xsl:element>
            <xsl:element name="RelatedObjectType">
              <xsl:attribute name="tc">
                <xsl:text>6</xsl:text>
              </xsl:attribute>
              <xsl:text>Party</xsl:text>
            </xsl:element>
            <xsl:element name="ns1:RelationRoleCode">
              <xsl:attribute name="tc">
                <xsl:text>37</xsl:text>
              </xsl:attribute>
              <xsl:text>PrimaryWritingAgent</xsl:text>
            </xsl:element>
          </ns1:Relation>
          <xsl:for-each select="ORDER_INFO/*[substring(local-name(),1,10) = 'ATTACHMENT']">
            <xsl:element name="FormInstance">
              <xsl:attribute name="id">
                <xsl:value-of select="ATT_FILENAME" />
              </xsl:attribute>
              <xsl:element name="FormName">
                <xsl:value-of select="ATT_FILENAME" />
              </xsl:element>
              <xsl:element name="OriginalInputMode">
                <xsl:attribute name="tc">
                  <xsl:text>1</xsl:text>
                </xsl:attribute>
                <xsl:text>Input Electronically</xsl:text>
              </xsl:element>
              <xsl:element name="Attachment">
                <xsl:element name="AttachmentBasicType">
                  <xsl:attribute name="tc">
                    <xsl:value-of select="ATT_FILETYPE" />
                  </xsl:attribute>
                  <xsl:value-of select="ATT_FILETYPE" />
                </xsl:element>
                <xsl:element name="AttachmentData">
                  <xsl:value-of select="ATT_DATA" />
                </xsl:element>
                <xsl:element name="MimeTypeTC">
                  <xsl:attribute name="tc">
                    <xsl:value-of select="ATT_FILETYPE" />
                  </xsl:attribute>
                  <xsl:value-of select="ATT_FILETYPE" />
                </xsl:element>
                <xsl:element name="TransferEncodingTypeTC">
                  <xsl:attribute name="tc">
                    <xsl:text>4</xsl:text>
                  </xsl:attribute>
                  <xsl:text>base64</xsl:text>
                </xsl:element>
                <xsl:element name="ImageType">
                  <xsl:attribute name="tc">
                    <xsl:value-of select="ATT_FILETYPE" />
                  </xsl:attribute>
                  <xsl:value-of select="ATT_FILETYPE" />
                </xsl:element>
                <xsl:element name="AttachmentLocation">
                  <xsl:attribute name="tc">
                    <xsl:text>1</xsl:text>
                  </xsl:attribute>
                  <xsl:text>Inline</xsl:text>
                </xsl:element>
              </xsl:element>
            </xsl:element>
          </xsl:for-each>
        </ns1:OLifE>
      </ns1:TXLifeRequest>
    </ns1:TXLife>
  </xsl:template>
</xsl:stylesheet>

