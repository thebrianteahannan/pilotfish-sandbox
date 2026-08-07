<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="RESULTS">
    <TXLife xmlns="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.16.01.XSD">
      <TXLifeRequest id="crl_d08b8914-014e-4000-0193-dd11b51b987c">
        <TransRefGUID>
          <xsl:value-of select="TRANSREFGUID" />
        </TransRefGUID>
        <TransType tc="1122">General Requirements Result Transmittal</TransType>
        <TransExeDate>
          <xsl:value-of select="EXEDATE" />
        </TransExeDate>
        <TransExeTime />
        <TransMode tc="4">Replacement request.</TransMode>
        <OLifE Version="2.16.01">
          <SourceInfo>
            <SourceInfoName>CRL</SourceInfoName>
          </SourceInfo>
          <Holding id="{TRANSACTIONPOLICY/POLICY/POLICYID}">
            <HoldingTypeCode tc="2">Policy</HoldingTypeCode>
            <HoldingForm tc="1">Individual</HoldingForm>
            <Policy CarrierPartyID="Carrier" id="{TRANSACTIONPOLICY/POLICY/POLICYID}">
              <PolNumber>
                <xsl:value-of select="TRANSACTIONPOLICY/POLICY/POLNUMBER" />
              </PolNumber>
              <LineOfBusiness tc="{TRANSACTIONPOLICY/POLICY/LINEOFBUSINESSTC}">
                <xsl:value-of select="TRANSACTIONPOLICY/POLICY/LINEOFBUSINESSTCTXT" />
              </LineOfBusiness>
              <CarrierCode>
                <xsl:value-of select="TRANSACTIONPOLICY/POLICY/CARRIERCODE" />
              </CarrierCode>
              <Life>
                <FaceAmt>
                  <xsl:value-of select="TRANSACTIONPOLICY/POLICY/FACEAMT" />
                </FaceAmt>
              </Life>
              <ApplicationInfo>
                <TrackingID>
                  <xsl:value-of select="TRANSACTIONPOLICY/POLICY/TRACKINGID" />
                </TrackingID>
              </ApplicationInfo>
              <xsl:for-each select="TRANSACTIONREQINFO/REQINFO">
                <RequirementInfo AppliesToPartyID="Applicant" FulfillerPartyID="Fulfiller" RequesterPartyID="Carrier" id="{REQINFOID}">
                  <ReqCode tc="{REQCODETC}">
                    <xsl:value-of select="REQCODETXT" />
                  </ReqCode>
                  <RequirementInfoUniqueID>
                    <xsl:value-of select="UNIQUEID" />
                  </RequirementInfoUniqueID>
                  <RequirementDetails>
                    <xsl:value-of select="REQDETAILS" />
                  </RequirementDetails>
                  <ReqStatus tc="{REQSTATUS}">
                    <xsl:value-of select="REQSTATUS" />
                  </ReqStatus>
                  <RequestedDate>
                    <xsl:value-of select="REQDATE" />
                  </RequestedDate>
                  <RequirementAcctNum>
                    <xsl:value-of select="REQACCTNUM" />
                  </RequirementAcctNum>
                  <ProviderOrderNum>
                    <xsl:value-of select="CARRIERORDERNUM" />
                  </ProviderOrderNum>
                </RequirementInfo>
              </xsl:for-each>
            </Policy>
            <xsl:for-each select="TRANSACTIONATTACHMENT/ATTACHMENT">
              <Attachment id="KIT_COMMENT_1">
                <AttachmentBasicType tc="{BASICTYPETC}">
                  <xsl:value-of select="BASICTYPETXT" />
                </AttachmentBasicType>
                <Description>
                  <xsl:value-of select="DESCR" />
                </Description>
                <AttachmentData />
                <AttachmentType tc="{TYPETC}">
                  <xsl:value-of select="TYPETXT" />
                </AttachmentType>
                <TransferEncodingTypeTC tc="{ENCTYPETC}">
                  <xsl:value-of select="ENCTYPESTR" />
                </TransferEncodingTypeTC>
                <MimeType>
                  <xsl:value-of select="MIMETYPE" />
                </MimeType>
              </Attachment>
            </xsl:for-each>
          </Holding>
          <xsl:for-each select="TRANSACTIONPARTY/PARTY">
            <xsl:variable name="PARTYID" select="PARTYID" />
            <Party id="Agent">
              <PartyTypeCode tc="1">Person</PartyTypeCode>
              <GovtID>
                <xsl:value-of select="GOVTID" />
              </GovtID>
              <FullName>
                <xsl:value-of select="FULLNAME" />
              </FullName>
              <Person>
                <FirstName>
                  <xsl:value-of select="FIRSTNAME" />
                </FirstName>
                <LastName>
                  <xsl:value-of select="LASTNAME" />
                </LastName>
                <Gender tc="{GENDERTC}">
                  <xsl:value-of select="GENDERTXT" />
                </Gender>
                <BirthDate>
                  <xsl:value-of select="BIRTHDATE" />
                </BirthDate>
              </Person>
              <xsl:for-each select="../../TRANSACTIONADDRESS/ADDRESS[PARTYID=$PARTYID]">
                <Address id="{ADDRESSID}">
                  <AddressTypeCode tc="{ADDRESSTC}">
                    <xsl:value-of select="ADDRESSTCTXT" />
                  </AddressTypeCode>
                  <Line1>
                    <xsl:value-of select="LINE1" />
                  </Line1>
                  <Line2>
                    <xsl:value-of select="LINE2" />
                  </Line2>
                  <Line3>
                    <xsl:value-of select="LINE3" />
                  </Line3>
                  <City>
                    <xsl:value-of select="CITY" />
                  </City>
                  <AddressState>
                    <xsl:value-of select="STATETXT" />
                  </AddressState>
                  <AddressStateTC tc="{STATETC}">
                    <xsl:value-of select="STATETXT" />
                  </AddressStateTC>
                  <Zip>
                    <xsl:value-of select="ZIP" />
                  </Zip>
                </Address>
              </xsl:for-each>
              <xsl:for-each select="../../TRANSACTIONPHONE/PHONE[PARTYID=$PARTYID]">
                <Phone>
                  <PhoneTypeCode tc="{PHONETC}">
                    <xsl:value-of select="PHONETC" />
                  </PhoneTypeCode>
                  <AreaCode>
                    <xsl:value-of select="AREACODE" />
                  </AreaCode>
                  <DialNumber>
                    <xsl:value-of select="DIALNUM" />
                  </DialNumber>
                  <Extension>
                    <xsl:value-of select="EXTENSION" />
                  </Extension>
                </Phone>
              </xsl:for-each>
              <xsl:for-each select="../../TRANSACTIONEMAIL/EMAIL[PARTYID=$PARTYID]">
                <EMailAddress>
                  <AddrLine>
                    <xsl:value-of select="EMAILADDR" />
                  </AddrLine>
                </EMailAddress>
              </xsl:for-each>
            </Party>
          </xsl:for-each>
          <xsl:for-each select="TRANSACTIONPARTYRELATION/RELATION">
            <Relation OriginatingObjectID="{ORIGINATINGPOLICYID}" RelatedObjectID="{RELATEDPARTYID}" id="{RELATIONID}">
              <OriginatingObjectType tc="4">Holding</OriginatingObjectType>
              <RelatedObjectType tc="6">Party</RelatedObjectType>
              <RelationRoleCode tc="{ROLECODETC}">
                <xsl:value-of select="RELATIONROLE" />
              </RelationRoleCode>
            </Relation>
          </xsl:for-each>
        </OLifE>
      </TXLifeRequest>
    </TXLife>
  </xsl:template>
</xsl:stylesheet>

