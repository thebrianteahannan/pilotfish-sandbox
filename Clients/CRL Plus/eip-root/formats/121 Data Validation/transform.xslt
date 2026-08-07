<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="/">
    <Messages>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransMode) = 0">
        <Message level="error">No TransMode (TXLife/TXLifeRequest/TransMode) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransMode/@tc) = 0">
        <Message level="error">No TransMode tc value (TXLife/TXLifeRequest/TransMode/@tc) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransRefGUID) = 0">
        <Message level="error">No TransRefGUID value (TXLife/TXLifeRequest/TransRefGUID) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransType) = 0">
        <Message level="error">No TransType value (TXLife/TXLifeRequest/TransType) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransType/@tc) = 0">
        <Message level="error">No TransType tc value (TXLife/TXLifeRequest/TransType/@tc) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransExeDate) = 0 or string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransExeTime) = 0">
        <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:CreationDate) = 0 or string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:CreationTime) = 0">
          <Message level="error">No Trans Exe Date/Time combination (TXLife/TXLifeRequest/TransExeDate and TXLife/TXLifeRequest/TransExeTime) nor source info creation Date/Time combination (TXLife/TXLifeRequest/OLifE/SourceInfo/CreationDate and TXLife/TXLifeRequest/OLifE/SourceInfo/CreationTime) provided. You must supply either the TransExeDate and TransExeTime, or CreationDate and CreationTime.</Message>
        </xsl:if>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:UserAuthRequest) = 0">
        <Message level="error">No UserAuthRequest (TXLife/UserAuthRequest) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding) = 0">
        <Message level="error">No OLifE Holding (TXLife/TXLifeRequest/OLifE/Holding) provided</Message>
      </xsl:if>
      <!-- FOREACH HOLDING -->
      <xsl:for-each select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Holding">
        <xsl:if test="string-length(@id) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Holding ID attribute (TXLife/TXLifeRequest/OLifE/Holding[', position(), ']/@id) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:HoldingTypeCode/@tc) = 0">
          <Message level="error">No HoldingTypeCode tc value (TXLife/TXLifeRequest/OLifE/Holding/HoldingTypeCode/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:HoldingTypeCode) = 0">
          <Message level="error">No HoldingTypeCode (TXLife/TXLifeRequest/OLifE/Holding/HoldingTypeCode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:PolNumber) = 0">
          <Message level="error">No Policy Number (TXLife/TXLifeRequest/OLifE/Holding/Policy/PolNumber) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:LineOfBusiness/@tc) = 0">
          <Message level="error">No Policy Line of Business tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/LineOfBussiness/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:LineOfBusiness) = 0">
          <Message level="error">No Policy Line of Business (TXLife/TXLifeRequest/OLifE/Holding/Policy/LineOfBusiness) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ProductType/@tc) = 0">
          <Message level="error">No Policy Product Type tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/ProductType/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ProductType) = 0">
          <Message level="error">No Policy Type (TXLife/TXLifeRequest/OLifE/Holding/Policy/ProductType) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ProductCode) = 0">
          <Message level="error">No Policy Product Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/ProductCode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:CarrierCode) = 0">
          <Message level="error">No Policy Carrier Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/CarrierCode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:PaymentMode/@tc) = 0">
          <Message level="error">No Policy Payment Mode tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/PaymentMode/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:PaymentMode) = 0">
          <Message level="error">No Policy Payment Mode (TXLife/TXLifeRequest/OLifE/Holding/Policy/PaymentMode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:PaymentMethod/@tc) = 0">
          <Message level="error">No Policy Payment Method tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/PaymentMethod/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:PaymentMethod) = 0">
          <Message level="error">No Policy Payment Method (TXLife/TXLifeRequest/OLifE/Holding/Policy/PaymentMethod) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:InitialPremAmt) = 0">
          <Message level="error">No Policy Life Initial Premium Amount (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/InitialPremAmt) provided</Message>
        </xsl:if>
        <!-- FACE AMOUNT OR TOTAL RISK AMOUNT -->
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:FaceAmt) = 0">
          <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:TotalRiskAmt) = 0">
            <Message level="error">No Policy Life Face Amount or Total Risk Amount (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/FaceAmt and/or TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/TotalRiskAmt) provided</Message>
          </xsl:if>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:PlanName) = 0">
          <Message level="error">No Policy Plan Name (TXLife/TXLifeRequest/OLifE/Holding/Policy/PlanName) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:ShortName) = 0">
          <Message level="error">No Policy Life Coverage Short Name (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/ShortName) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovStatus/@tc) = 0">
          <Message level="error">No Policy Life Coverage LifeCovStatus tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeCovStatus/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovStatus) = 0">
          <Message level="error">No Policy Life Coverage LifeCovStatus (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeCovStatus) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovTypeCode/@tc) = 0">
          <Message level="error">No Policy Life Coverage Type Code tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeCovTypeCode/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeCovTypeCode) = 0">
          <Message level="error">No Policy Life Coverage Type Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeCovTypeCode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:IndicatorCode/@tc) = 0">
          <Message level="error">No Policy Life Coverage Indicator Code tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/IndicatorCode/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:IndicatorCode) = 0">
          <Message level="error">No Policy Life Coverage Indicator Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/IndicatorCode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:CurrentAmt) = 0">
          <Message level="error">No Policy Life Coverage Current Amount (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/CurrentAmt) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/@PartyID) = 0">
          <Message level="error">No Policy Life Coverage Participant @PartyID (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/@PartyID) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/@id) = 0">
          <xsl:if test="string-length(../ns1:Relation[ns1:RelatedObjectType/@tc=6 and ns1:RelationRoleCode/@tc=32]/@RelatedObjectID) = 0">
            <Message level="error">No Policy Life Coverage Participant @id (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/@id and/or Relation[RelatedObjectType/@tc=6 and RelationRoleCode/@tc=32]/@RelationObjectID) provided</Message>
          </xsl:if>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/ns1:LifeParticipantRoleCode/@tc) = 0">
          <Message level="error">No Policy Life Coverage Participant Role Code tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/LifeParticipantRoleCode/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant/ns1:LifeParticipantRoleCode) = 0">
          <Message level="error">No Policy Life Coverage Participant Role Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/Coverage/LifeParticipant/LifeParticipantRoleCode) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID) = 0">
          <Message level="error">No Policy Application Info Tracking ID (TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/TrackingID) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction/@tc) = 0">
          <Message level="error">No Policy Application Info Jurisdiction tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/ApplicationJurisdiction/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction) = 0">
          <Message level="error">No Policy Application Info Jurisdiction (TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/ApplicationJurisdiction) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ApplicationInfo/ns1:SignedDate) = 0">
          <Message level="error">No Policy Application Info Signed Date (TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/SignedDate) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ApplicationInfo/ns1:PrefLanguage/@tc) = 0">
          <Message level="error">No Policy Application Info Preferred Language tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/PrefLanguage/@tc) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:ApplicationInfo/ns1:PrefLanguage) = 0">
          <Message level="error">No Policy Application Info Preferred Language (TXLife/TXLifeRequest/OLifE/Holding/Policy/ApplicationInfo/PrefLanguage) provided</Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Policy/ns1:RequirementInfo) = 0">
          <Message level="error">No Policy Requirement Info (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo) provided</Message>
        </xsl:if>
        <!-- FOREACH REQUIREMENT INFO -->
        <xsl:for-each select="ns1:Policy/ns1:RequirementInfo">
          <xsl:if test="string-length(@AppliesToPartyId) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info @AppliesToPartyId (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/@AppliesToPartyId) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:ReqCode/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info ReqCode tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReqCode/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:ReqCode) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info ReqCode (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReqCode) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequirementInfoUniqueID) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Unique ID (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequirementInfoUniqueID) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequestedDate) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Requested Date (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequestedDate) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequestedScheduleDate) = 0">
            <xsl:if test="string-length(ns1:ScheduledDate) = 0">
              <xsl:if test="string-length(ns1:RequestedDate) = 0">
                <Message level="error">
                  <xsl:value-of select="concat('No Policy Requirement Info Requested Schedule Date, Schedule Date, or Requested Date (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequestedScheduledDate, and/or ScheduledDate, and/or RequestedDate) provided')" />
                </Message>
              </xsl:if>
            </xsl:if>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequestedScheduleTimeStart) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Requested Schedule Time Start (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequestedScheduleTimeStart) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:ReleasePartyOrgCode) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Release Party Organization Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReleasePartyOrgCode) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequirementAcctNum) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Account No (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequirementAcctNum) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:ReqStatus) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Status (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReqStatus) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequirementDetails) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Details (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequirementDetails) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:CarrierOrderNum) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Requirement Info Carrier Order No (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/CarrierOrderNum) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH REQUIREMENT INFO -->
        <!-- FOREACH ATTACHMENT -->
        <xsl:for-each select="ns1:Attachment">
          <xsl:if test="string-length(ns1:AttachmentBasicType/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Basic Type tc value (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/AttachmentBasicType/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AttachmentBasicType) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Basic Type (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/AttachmentBasicType) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:Description) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Description (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/Description) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AttachmentType/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Type tc value (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/AttachmentType/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AttachmentType) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Type (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/AttachmentType) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:MimeType) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment MIME Type (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/MimeType) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:TransferEncodingTypeString) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Transfer Encoding Type String (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/TransferEncodingTypeString) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:TransferEncodingTypeString/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Transfer Encoding Type String tc value (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/TransferEncodingTypeString/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AttachmentLocation/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment Location (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/AttachmentLocation/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:OLifEExtension/ns1:CRL_DOCUMENT_ID) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment OLifEExtension CRL_DOCUMENT_ID (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/OLifEExtension/CRL_DOCUMENT_ID) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:OLifEExtension/ns1:CRL_FOLDER_ID) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment OLifEExtension CRL_FOLDER_ID (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/OLifEExtension/CRL_FOLDER_ID) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:OLifEExtension/ns1:CRL_DRAWER_NAME) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment OLifEExtension CRL_DRAWER_NAME (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/OLifEExtension/CRL_DRAWER_NAME) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:OLifEExtension/ns1:CRL_PAGE_COUNT) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Policy Attachment OLifEExtension CRL_PAGE_COUNT (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/OLifEExtension/CRL_PAGE_COUNT) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH ATTACHMENT -->
      </xsl:for-each>
      <!-- END FOREACH HOLDING -->
      <!-- FOREACH PARTY -->
      <xsl:for-each select="ns1:OLifE/ns1:Party">
        <xsl:if test="string-length(@id) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party @id (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/@id) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:PartyTypeCode/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Type Code tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/PartyTypeCode/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:PartyTypeCode) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Type Code (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/PartyTypeCode) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:GovtID) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Government ID (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/GovtID) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:FirstName) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person First Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/FirstName) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:LastName) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Last Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/LastName) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:MiddleName) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Middle Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/MiddleName) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:Occupation) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Occupation (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/Occupation) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:Gender/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Gender tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/Gender/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:Gender) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Gender (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/Gender) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:BirthDate) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Birth Date (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/BirthDate) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:Citizenship/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Citizenship tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:Citizenship) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Citizenship (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:BirthCountry/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Birth Country tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:BirthCountry) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Birth Country (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:BirthJurisdictionTC/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Birth Jurisdiction tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Person/ns1:Prefix) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Person Prefix (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:FullName) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Full Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/FullName) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Organization/ns1:DBA) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Organization DBA (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Organization/DBA) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:ResidenceState/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Residence State tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/ResidenceState/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:ResidenceState) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Residence State (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/ResidenceState) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:ResidenceCountry/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Residence Country tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/ResidenceCountry/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:ResidenceCountry) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Residence Country (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/ResidenceCountry) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:BestTimeToCallFrom) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Best Time To Call From (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/BestTimeToCallFrom) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:BestTimeToCallTo) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Best Time To Call To (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/BestTimeToCallTo) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:Client/ns1:ClientKey) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No OLifE Party Client Key (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Client/ClientKey) provided')" />
          </Message>
        </xsl:if>
        <!-- FOREACH ADDRESS -->
        <xsl:for-each select="ns1:Address">
          <xsl:if test="string-length(ns1:AddressTypeCode/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address Type Code tc value (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/AddressTypeCode/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AddressTypeCode) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address Type Code (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/AddressTypeCode) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:Line1) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address Line1 (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/Line1) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:Line2) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address Line2 (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/Line2) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:City) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address City (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/City) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AddressStateTC/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party AddressStateTC tc value (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/AddressStateTC/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AddressState) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address State (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/AddressState) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AddressStateTC) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party AddressStateTC (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/AddressStateTC) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:Zip) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address Zip Code (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/Zip) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:PreventOverrideInd/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Address Prevent Override Indicator (TXLife/TXLifeRequest/OLifE/Party/Address[', position(), ']/PreventOverrideInd/@tc) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH ADDRESS -->
        <!-- FOREACH PHONE -->
        <xsl:for-each select="ns1:Phone">
          <xsl:if test="string-length(ns1:PhoneTypeCode/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Phone Type Code tc value (TXLife/TXLifeRequest/OLifE/Party/Phone[', position(), ']/PhoneTypeCode/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:AreaCode) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Phone Area Code (TXLife/TXLifeRequest/OLifE/Party/Phone[', position(), ']/AreaCode) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:DialNumber) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Phone Dial Number (TXLife/TXLifeRequest/OLifE/Party/Phone[', position(), ']/DialNumber) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:BestTimeToCallFrom) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Phone Best Time To Call From (TXLife/TXLifeRequest/OLifE/Party/Phone[', position(), ']/BestTimeToCallFrom) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:BestTimeToCallTo) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Phone Best Time To Call To (TXLife/TXLifeRequest/OLifE/Party/Phone[', position(), ']/BestTimeToCallTo) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:Ext) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Phone Extension (TXLife/TXLifeRequest/OLifE/Party/Phone[', position(), ']/Ext) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH PHONE -->
        <!-- FOREACH EMAIL ADDRESS -->
        <xsl:for-each select="ns1:EMailAddress">
          <xsl:if test="string-length(ns1:AddrLine) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No OLifE Party Email Address (TXLife/TXLifeRequest/OLifE/Party/EMailAddress[', position(), ']/AddrLine) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH EMAIL ADDRESS -->
      </xsl:for-each>
      <!-- END FOR EACH PARTY -->
      <!-- FOREACH RELATION -->
      <xsl:for-each select="ns1:OLifE/ns1:Relation">
        <xsl:if test="string-length(@OriginatingObjectID) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation @OriginatingObjectID value (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/@OriginatingObjectID) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(@RelatedObjectID) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation @RelatedObjectID value (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/@RelatedObjectID) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(@id) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation @id value (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/@id) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:OriginatingObjectType/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation OriginatingObjectType tc value (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/OriginatingObjectType/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:RelatedObjectType/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation RelatedObjectType tc value (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/RelatedObjectType/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:RelationRoleCode/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation Role Code tc value (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/RelationRoleCode/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:RelationRoleCode) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation Role Code (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/RelationRoleCode) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:RelationDescription) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Relation Description (TXLife/TXLifeRequest/OLifE/Relation[', position(), ']/RelationDescription) provided')" />
          </Message>
        </xsl:if>
      </xsl:for-each>
      <!-- END FOREACH RELATION -->
    </Messages>
  </xsl:template>
</xsl:stylesheet>

