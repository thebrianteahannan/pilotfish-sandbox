<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="PHISORDER">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <TXLife xmlns="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.16.01.XSD">
      <UserAuthRequest>
        <UserPswd>
          <CryptType>NONE</CryptType>
        </UserPswd>
        <VendorApp>
          <VendorName VendorCode="118">CRL</VendorName>
          <AppName>LabResultsTransmittal</AppName>
        </VendorApp>
      </UserAuthRequest>
      <TXLifeRequest>
        <xsl:attribute name="id">
          <xsl:value-of select="concat('crl_', converter:getGUIDString())" />
        </xsl:attribute>
        <TransRefGUID />
        <TransType tc="1122">General Requirements Result Transmittal</TransType>
        <TransExeDate>
          <xsl:value-of select="datetime:date()" />
        </TransExeDate>
        <TransExeTime>
          <xsl:value-of select="datetime:time()" />
        </TransExeTime>
        <TransMode tc="2" />
        <OLifE Version="2.16.01">
          <SourceInfo>
            <SourceInfoName>CRL</SourceInfoName>
          </SourceInfo>
          <Holding id="crl_holding">
            <HoldingForm tc="1">Individual</HoldingForm>
            <Policy CarrierPartyID="Carrier" id="{concat('crl_', converter:getGUIDString())}">
              <PolNumber>
                <xsl:value-of select="ORDER_INFO/POLICY/POLICY_NO" />
              </PolNumber>
              <LineOfBusiness tc="1">Life</LineOfBusiness>
              <CarrierCode>70025</CarrierCode>
              <ApplicationInfo>
                <TrackingID>
                  <xsl:value-of select="converter:getGUIDString()" />
                </TrackingID>
              </ApplicationInfo>
              <xsl:for-each select="ORDER_INFO/SERVICE/*[substring(local-name(), 1, 8) = 'SRV_CODE']">
                <xsl:variable name="pos" select="position()" />
                <RequirementInfo AppliesToPartyID="Party_4" id="{concat('crl_', converter:getGUIDString())}">
                  <ReqCode tc="{.}">
                    <xsl:value-of select="." />
                  </ReqCode>
                  <RequirementDetails>
                    <xsl:value-of select="../../REMARKS/*[substring(local-name(), 1, 8) = 'REM_DESC' and substring(local-name(), 9, 1) = $pos]" />
                  </RequirementDetails>
                  <RequirementAcctNum>
                    <xsl:value-of select="../../REMOTE_NO" />
                  </RequirementAcctNum>
                </RequirementInfo>
              </xsl:for-each>
            </Policy>
          </Holding>
          <Party id="Party_1">
            <PartyTypeCode tc="1">Person</PartyTypeCode>
            <FullName>
              <xsl:value-of select="ORDER_INFO/AGENT" />
            </FullName>
            <Phone>
              <PhoneTypeCode tc="2">Business</PhoneTypeCode>
              <AreaCode>
                <xsl:value-of select="substring(translate(ORDER_INFO/AGENCY_PH, '-', ''), 1, 3)" />
              </AreaCode>
              <DialNumber>
                <xsl:value-of select="substring(translate(ORDER_INFO/AGENCY_PH, '-', ''), 4, 7)" />
              </DialNumber>
            </Phone>
          </Party>
          <Party id="Party_2">
            <PartyTypeCode tc="1">Person</PartyTypeCode>
            <FullName>
              <xsl:value-of select="concat(ORDER_INFO/APPLICANT/FIRST_NAME, ' ', ORDER_INFO/APPLICANT/LAST_NAME)" />
            </FullName>
            <GovtID>
              <xsl:value-of select="ORDER_INFO/APPLICANT/APP_SOC" />
            </GovtID>
            <GovtIDTC tc="0">Unknown</GovtIDTC>
            <Person>
              <FirstName>
                <xsl:value-of select="ORDER_INFO/APPLICANT/FIRST_NAME" />
              </FirstName>
              <LastName>
                <xsl:value-of select="ORDER_INFO/APPLICANT/LAST_NAME" />
              </LastName>
              <Gender tc="{APP_GENDER}">
                <xsl:value-of select="ORDER_INFO/APPLICANT/APP_GENDER" />
              </Gender>
            </Person>
            <Address id="crl_28f10c56-0119-1000-008b-00123f850994">
              <AddressTypeCode tc="0">Unknown</AddressTypeCode>
              <Line1>
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_ADDRESS_1" />
              </Line1>
              <Line2>
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_ADDRESS_2" />
              </Line2>
              <City>
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_CITY" />
              </City>
              <AddressState>
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_STATE" />
              </AddressState>
              <AddressStateTC tc="{ORDER_INFO/APPLICANT/EXM_STATE}">
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_STATE" />
              </AddressStateTC>
              <Zip>
                <xsl:value-of select="ORDER_INFO/APPLICANT/EXM_ZIP" />
              </Zip>
            </Address>
            <Phone>
              <PhoneTypeCode tc="1">Home</PhoneTypeCode>
              <AreaCode>
                <xsl:value-of select="concat(translate(ORDER_INFO/APPLICANT/EXM_PHONE, '-', ''), 1, 3)" />
              </AreaCode>
              <DialNumber>
                <xsl:value-of select="concat(translate(ORDER_INFO/APPLICANT/EXM_PHONE, '-', ''), 4, 7)" />
              </DialNumber>
            </Phone>
          </Party>
          <Relation OriginatingObjectID="crl_holding" RelatedObjectID="Party_2" id="Relation_N10007">
            <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
            <RelatedObjectType tc="6">Party</RelatedObjectType>
            <RelationRoleCode tc="32">Insured</RelationRoleCode>
          </Relation>
          <Relation OriginatingObjectID="crl_holding" RelatedObjectID="Party_1" id="Relation_N101E3">
            <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
            <RelatedObjectType tc="6">Party</RelatedObjectType>
            <RelationRoleCode tc="37">Primary Writing Agent</RelationRoleCode>
          </Relation>
          <xsl:for-each select="ORDER_INFO/*[substring(local-name(), 1, 10) = 'ATTACHMENT']">
            <FormInstance id="{ATT_FILENAME}">
              <FormName>
                <xsl:value-of select="ATT_FILENAME" />
              </FormName>
              <OriginalInputMode tc="1">Input Electronically</OriginalInputMode>
              <Attachment>
                <AttachmentBasicType tc="{ATT_FILETYPE}">
                  <xsl:value-of select="ATT_FILETYPE" />
                </AttachmentBasicType>
                <AttachmentData>
                  <xsl:value-of select="ATT_DATA" />
                </AttachmentData>
                <MimeTypeTC tc="{ATT_FILETYPE}">
                  <xsl:value-of select="ATT_FILETYPE" />
                </MimeTypeTC>
                <TransferEncodingTypeTC tc="4">base64</TransferEncodingTypeTC>
                <ImageType tc="{ATT_FILETYPE}">
                  <xsl:value-of select="ATT_FILETYPE" />
                </ImageType>
                <AttachmentLocation tc="1">Inline</AttachmentLocation>
              </Attachment>
            </FormInstance>
          </xsl:for-each>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
</xsl:stylesheet>

