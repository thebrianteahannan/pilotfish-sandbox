<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="/">
    <Messages>
      <!--
			<xsl:if test="/ns1:TXLife/ns1:UserAuthRequest">
				<xsl:if test="/ns1:TXLife/ns1:UserAuthRequest/ns1:UserPswd">
					<xsl:if test="string-length(/ns1:TXLife/ns1:UserAuthRequest/ns1:UserPswd/ns1:CryptType) = 0">
						<Message level="error">No Crypt Type (TXLife/UserAuthRequest/UserPswd/CryptType) provided</Message>
					</xsl:if>
					<xsl:if test="string-length(/ns1:TXLife/ns1:UserAuthRequest/ns1:UserPswd/ns1:Pswd) = 0">
						<Message level="error">No User Password (TXLife/UserAuthRequest/UserPswd/Pswd) provided</Message>
					</xsl:if>
				</xsl:if>
				<xsl:if test="string-length(/ns1:TXLife/ns1:UserAuthRequest/ns1:UserDate) = 0">
					<Message level="error">No User Date (TXLife/UserAuthRequest/UserDate) provided</Message>
				</xsl:if>
				<xsl:if test="string-length(/ns1:TXLife/ns1:UserAuthRequest/ns1:UserTime) = 0">
					<Message level="error">No User Time (TXLife/UserAuthRequest/UserTime) provided</Message>
				</xsl:if>
				<xsl:if test="/ns1:TXLife/ns1:UserAuthRequest/ns1:VendorApp">
					<xsl:if test="string-length(/ns1:TXLife/ns1:UserAuthRequest/ns1:VendorApp/ns1:VendorName) = 0">
						<Message level="error">No Vendor Name (TXLife/UserAuthRequest/VendorApp/VendorName) provided</Message>
					</xsl:if>
				</xsl:if>
			</xsl:if>
			-->
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransRefGUID) = 0">
        <Message level="error">No TransRefGUID value (TXLife/TXLifeRequest/TransRefGUID) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransType/@tc) = 0">
        <Message level="error">No TransType tc value (TXLife/TXLifeRequest/TransType/@tc) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransExeDate) = 0">
        <Message level="error">No TransExeDate value (TXLife/TXLifeRequest/TransExeDate) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransExeTime) = 0">
        <Message level="error">No TransExeTime value (TXLife/TXLifeRequest/TransExeTime) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransMode) = 0">
        <Message level="error">No TransMode (TXLife/TXLifeRequest/TransMode) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TransMode/@tc) = 0">
        <Message level="error">No TransMode tc value (TXLife/TXLifeRequest/TransMode/@tc) provided</Message>
      </xsl:if>
      <xsl:if test="string-length(/ns1:TXLife/ns1:TXLifeRequest/ns1:TestIndicator) = 0">
        <Message level="error">No TestIndicator (TXLife/TXLifeRequest/TestIndicator) provided</Message>
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
        <!--
				<xsl:if test="string-length(ns1:Policy/ns1:ProductType/@tc) = 0">
					<Message level="error">No Policy Product Type tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/ProductType/@tc) provided</Message>
				</xsl:if>
				-->
        <!-- FACE AMOUNT OR TOTAL RISK AMOUNT on main policy -->
        <!--
				<xsl:if test="position()=1 and string-length(ns1:Policy/ns1:Life/ns1:FaceAmt) = 0 and string-length(ns1:Policy/ns1:Life/ns1:TotalRiskAmt) = 0">
					<Message level="error">No Policy Life Face Amount or Total Risk Amount (TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/FaceAmt and/or TXLife/TXLifeRequest/OLifE/Holding/Policy/Life/TotalRiskAmt) provided</Message>
				</xsl:if>
				-->
        <xsl:if test="position()=1 and string-length(ns1:Policy/ns1:RequirementInfo) = 0">
          <Message level="error">No Policy Requirement Info (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo) provided</Message>
        </xsl:if>
        <!-- FOREACH REQUIREMENT INFO -->
        <xsl:for-each select="ns1:Policy/ns1:RequirementInfo">
          <xsl:if test="string-length(ns1:ReqCode/@tc) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Requirement Info ReqCode tc value (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReqCode/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:ReqCode) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Requirement Info ReqCode (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReqCode) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequestedDate) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Requirement Info Requested Date (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequestedDate) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:ReleasePartyOrgCode) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Requirement Info Release Party Organization Code (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/ReleasePartyOrgCode) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:RequirementAcctNum) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Requirement Info Account No (TXLife/TXLifeRequest/OLifE/Holding/Policy/RequirementInfo[', position(), ']/RequirementAcctNum) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH REQUIREMENT INFO -->
        <!-- FOREACH ATTACHMENT -->
        <xsl:for-each select="ns1:Attachment">
          <!--
					-->
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
          <xsl:choose>
            <xsl:when test="ns1:AttachmentType/@tc = 2">
              <!-- Required for Underwriter Notes -->
              <!-- not included for language interpreter notes
							<xsl:if test="string-length(ns1:Description) = 0">
								<Message level="error">
									<xsl:value-of select="concat('No Requirement Attachment Description (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/Description) provided')" />
								</Message>
							</xsl:if>
							-->
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="string-length(ns1:AttachmentData) = 0">
                <Message level="error">
                  <xsl:value-of select="concat('No Policy Attachment Data (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/AttachmentData) provided')" />
                </Message>
              </xsl:if>
              <!--
							<xsl:if test="string-length(ns1:TransferEncodingTypeString) = 0">
								<Message level="error">
									<xsl:value-of select="concat('No Policy Attachment Transfer Encoding Type String (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/TransferEncodingTypeString) provided')" />
								</Message>
							</xsl:if>
							-->
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
              <!--
							<xsl:if test="string-length(ns1:MimeType) = 0">
								<Message level="error">
									<xsl:value-of select="concat('No Policy Attachment MIME Type (TXLife/TXLifeRequest/OLifE/Holding/Attachment[', position(), ']/MimeType) provided')" />
								</Message>
							</xsl:if>
							-->
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <!-- END FOREACH ATTACHMENT -->
      </xsl:for-each>
      <!-- END FOREACH HOLDING -->
      <!-- FOREACH PARTY -->
      <xsl:for-each select="/ns1:TXLife/ns1:TXLifeRequest/ns1:OLifE/ns1:Party">
        <xsl:variable name="partyIndex" select="position()" />
        <xsl:if test="string-length(@id) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Party @id (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/@id) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:PartyTypeCode/@tc) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Party Type Code tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/PartyTypeCode/@tc) provided')" />
          </Message>
        </xsl:if>
        <xsl:if test="string-length(ns1:PartyTypeCode) = 0">
          <Message level="error">
            <xsl:value-of select="concat('No Party Type Code (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/PartyTypeCode) provided')" />
          </Message>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="ns1:PartyTypeCode/@tc = 2">
            <!-- Organization Party -->
            <xsl:if test="string-length(ns1:FullName) = 0 and string-length(ns1:Organization/ns1:OrgCode) = 0">
              <Message level="error">
                <xsl:value-of select="concat('No Organization Party Full Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/FullName) provided')" />
              </Message>
            </xsl:if>
          </xsl:when>
          <xsl:when test="ns1:PartyTypeCode/@tc = 1">
            <!-- Person Party -->
            <xsl:if test="@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=32]/@RelatedObjectID">
              <xsl:if test="string-length(ns1:Person/ns1:FirstName) = 0">
                <Message level="error">
                  <xsl:value-of select="concat('No Person Party First Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/FirstName) provided')" />
                </Message>
              </xsl:if>
              <xsl:if test="string-length(ns1:Person/ns1:LastName) = 0">
                <Message level="error">
                  <xsl:value-of select="concat('No Person Party Last Name (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/LastName) provided')" />
                </Message>
              </xsl:if>
              <!-- Gender is required for insured -->
              <!--
							<xsl:if test="string-length(ns1:Person/ns1:Gender/@tc) = 0">
								<Message level="error">
									<xsl:value-of select="concat('No Party Person Gender tc value (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/Gender/@tc) provided')" />
								</Message>
							</xsl:if>
							<xsl:if test="string-length(ns1:Person/ns1:Gender) = 0">
								<Message level="error">
									<xsl:value-of select="concat('No Party Person Gender (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/Gender) provided')" />
								</Message>
							</xsl:if>
							-->
              <!-- birthdate is required for insured -->
              <xsl:if test="string-length(ns1:Person/ns1:BirthDate) = 0">
                <Message level="error">
                  <xsl:value-of select="concat('No Party Person Birth Date (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Person/BirthDate) provided')" />
                </Message>
              </xsl:if>
              <!-- address is required for insured -->
              <xsl:if test="string-length(ns1:Address) = 0">
                <Message level="error">
                  <xsl:value-of select="concat('No Party Address (TXLife/TXLifeRequest/OLifE/Party[', position(), ']/Address) provided')" />
                </Message>
              </xsl:if>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
        <!-- FOREACH PHONE -->
        <xsl:for-each select="ns1:Phone">
          <xsl:if test="string-length(ns1:PhoneTypeCode/@tc) = 0 and ../ns1:PartyTypeCode/@tc=1">
            <Message level="error">
              <xsl:value-of select="concat('No Party Phone Type Code tc value (TXLife/TXLifeRequest/OLifE/Party[',$partyIndex,']/Phone[', position(), ']/PhoneTypeCode/@tc) provided')" />
            </Message>
          </xsl:if>
          <xsl:if test="string-length(ns1:DialNumber) = 0">
            <Message level="error">
              <xsl:value-of select="concat('No Party Phone Dial Number (TXLife/TXLifeRequest/OLifE/Party[',$partyIndex,']/Phone[', position(), ']/DialNumber) provided')" />
            </Message>
          </xsl:if>
        </xsl:for-each>
        <!-- END FOREACH PHONE -->
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

