<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:tmCall="xalan://com.pilotfish.eip.gui.mapper.util.TabDelimitedFileUtil" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="ns2:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <xsl:variable name="sourceClient" select="converter:getAttributeString('sourceClient')" />
    <ns2:TXLife Version="{@Version}">
      <ns2:UserAuthRequest>
        <ns2:UserLoginName>
          <xsl:value-of select="ns2:UserAuthRequest/ns2:UserLoginName" />
        </ns2:UserLoginName>
        <ns2:UserPswd>
          <ns2:CryptPswd>
            <xsl:value-of select="ns2:UserAuthRequest/ns2:UserPswd/ns2:CryptPswd" />
          </ns2:CryptPswd>
          <ns2:CryptType>
            <xsl:value-of select="ns2:UserAuthRequest/ns2:UserPswd/ns2:CryptType" />
          </ns2:CryptType>
          <ns2:Pswd>
            <xsl:value-of select="ns2:UserAuthRequest/ns2:UserPswd/ns2:Pswd" />
          </ns2:Pswd>
        </ns2:UserPswd>
        <ns2:UserDate>
          <xsl:value-of select="ns2:UserAuthRequest/ns2:UserDate" />
        </ns2:UserDate>
        <ns2:UserTime>
          <xsl:value-of select="ns2:UserAuthRequest/ns2:UserTime" />
        </ns2:UserTime>
        <ns2:VendorApp>
          <ns2:VendorName VendorCode="{ns2:UserAuthRequest/ns2:VendorApp/ns2:VendorName/@VendorCode}">
            <xsl:value-of select="ns2:UserAuthRequest/ns2:VendorApp/ns2:VendorName" />
          </ns2:VendorName>
          <ns2:AppName>
            <xsl:value-of select="ns2:UserAuthRequest/ns2:VendorApp/ns2:AppName" />
          </ns2:AppName>
          <ns2:AppVer>
            <xsl:value-of select="ns2:UserAuthRequest/ns2:VendorApp/ns2:AppVer" />
          </ns2:AppVer>
        </ns2:VendorApp>
      </ns2:UserAuthRequest>
      <xsl:for-each select="ns2:TXLifeRequest">
        <ns2:TXLifeRequest>
          <xsl:attribute name="PrimaryObj">
            <xsl:choose>
              <xsl:when test="@PrimaryObjectID">
                <xsl:value-of select="@PrimaryObjectID" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="ns2:OLifE/ns2:Holding/@id" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <ns2:TransRefGUID>
            <xsl:value-of select="ns2:TransRefGUID" />
          </ns2:TransRefGUID>
          <ns2:TransType tc="{ns2:TransType/@tc}">
            <xsl:value-of select="ns2:TransType" />
          </ns2:TransType>
          <ns2:TransExeDate>
            <xsl:value-of select="ns2:TransExeDate" />
          </ns2:TransExeDate>
          <ns2:TransExeTime>
            <xsl:value-of select="ns2:TransExeTime" />
          </ns2:TransExeTime>
          <xsl:choose>
            <xsl:when test="ns2:TransMode/@tc = 6 or ns2:TransSubType/@tc=12101">
              <ns2:TransMode tc="6">Cancel</ns2:TransMode>
            </xsl:when>
            <xsl:when test="ns2:TransMode/@tc = 2 or string-length(ns2:TransMode/@tc)=0">
              <ns2:TransMode tc="2">Original</ns2:TransMode>
            </xsl:when>
            <xsl:otherwise>
              <ns2:TransMode tc="{ns2:TransMode/@tc}">
                <xsl:value-of select="ns2:TransMode" />
              </ns2:TransMode>
            </xsl:otherwise>
          </xsl:choose>
          <ns2:TestIndicator tc="{ns2:TestIndicator/@tc}">
            <xsl:value-of select="ns2:TestIndicator" />
          </ns2:TestIndicator>
          <xsl:if test="ns2:ProcessingInstruction">
            <!-- Prudential uses this element to indicate that the order is a priority order -->
            <ns2:ProcessingInstruction>
              <ns2:ProcessingInstructionType tc="{ns2:ProcessingInstruction/ns2:ProcessingInstructionType/@tc}" />
              <ns2:ProcessingInstructionDesc>
                <xsl:value-of select="ns2:ProcessingInstruction/ns2:ProcessingInstructionDesc" />
              </ns2:ProcessingInstructionDesc>
            </ns2:ProcessingInstruction>
          </xsl:if>
          <ns2:OLifE>
            <ns2:SourceInfo>
              <ns2:CreationDate>
                <xsl:value-of select="ns2:OLifE/ns2:SourceInfo/ns2:CreationDate" />
              </ns2:CreationDate>
              <ns2:CreationTime>
                <xsl:value-of select="ns2:OLifE/ns2:SourceInfo/ns2:CreationTime" />
              </ns2:CreationTime>
              <ns2:SourceInfoName>
                <xsl:value-of select="ns2:OLifE/ns2:SourceInfo/ns2:SourceInfoName" />
              </ns2:SourceInfoName>
              <ns2:SourceInfoDescription>
                <xsl:value-of select="ns2:OLifE/ns2:SourceInfo/ns2:SourceInfoDescription" />
              </ns2:SourceInfoDescription>
            </ns2:SourceInfo>
            <xsl:for-each select="ns2:OLifE/ns2:Holding">
              <ns2:Holding id="{@id}">
                <ns2:HoldingTypeCode tc="{ns2:HoldingTypeCode/@tc}">
                  <xsl:value-of select="ns2:HoldingTypeCode" />
                </ns2:HoldingTypeCode>
                <ns2:Policy>
                  <xsl:if test="ns2:Policy/@CarrierPartyID">
                    <xsl:attribute name="CarrierPartyID">
                      <xsl:value-of select="ns2:Policy/@CarrierPartyID" />
                    </xsl:attribute>
                  </xsl:if>
                  <xsl:if test="ns2:Policy/@id">
                    <xsl:attribute name="id">
                      <xsl:value-of select="ns2:Policy/@id" />
                    </xsl:attribute>
                  </xsl:if>
                  <ns2:PolNumber>
                    <xsl:value-of select="ns2:Policy/ns2:PolNumber" />
                  </ns2:PolNumber>
                  <xsl:choose>
                    <xsl:when test="ns2:Policy/ns2:LineOfBusiness">
                      <ns2:LineOfBusiness tc="{ns2:Policy/ns2:LineOfBusiness/@tc}">
                        <xsl:value-of select="ns2:Policy/ns2:LineOfBusiness" />
                      </ns2:LineOfBusiness>
                    </xsl:when>
                    <xsl:when test="ns2:Policy/ns2:Life">
                      <ns2:LineOfBusiness tc="1">
                        <xsl:value-of select="'Life'" />
                      </ns2:LineOfBusiness>
                    </xsl:when>
                    <xsl:when test="ns2:Policy/ns2:Annuity">
                      <ns2:LineOfBusiness tc="2">
                        <xsl:value-of select="'Annuity'" />
                      </ns2:LineOfBusiness>
                    </xsl:when>
                    <xsl:when test="ns2:Policy/ns2:DisabilityHealth">
                      <ns2:LineOfBusiness tc="4">
                        <xsl:value-of select="'Health'" />
                      </ns2:LineOfBusiness>
                    </xsl:when>
                    <xsl:when test="ns2:Policy/ns2:PropertyandCasualty">
                      <ns2:LineOfBusiness tc="8">
                        <xsl:value-of select="'Property and Casualty'" />
                      </ns2:LineOfBusiness>
                    </xsl:when>
                    <xsl:otherwise>
                      <ns2:LineOfBusiness tc="{ns2:Policy/ns2:LineOfBusiness/@tc}">
                        <xsl:value-of select="ns2:Policy/ns2:LineOfBusiness" />
                      </ns2:LineOfBusiness>
                    </xsl:otherwise>
                  </xsl:choose>
                  <ns2:ProductType tc="{ns2:Policy/ns2:ProductType/@tc}">
                    <xsl:value-of select="ns2:Policy/ns2:ProductType" />
                  </ns2:ProductType>
                  <ns2:ProductCode>
                    <xsl:choose>
                      <xsl:when test="ns2:Policy/ns2:ProductCode">
                        <xsl:value-of select="ns2:Policy/ns2:ProductCode" />
                      </xsl:when>
                      <xsl:when test="ns2:Policy/ns2:Life/ns2:Coverage/ns2:ProductCode">
                        <xsl:value-of select="ns2:Policy/ns2:Life/ns2:Coverage/ns2:ProductCode" />
                      </xsl:when>
                      <xsl:otherwise />
                    </xsl:choose>
                  </ns2:ProductCode>
                  <ns2:CarrierCode>
                    <xsl:value-of select="ns2:Policy/ns2:CarrierCode" />
                  </ns2:CarrierCode>
                  <ns2:PlanName>
                    <xsl:value-of select="ns2:Policy/ns2:PlanName" />
                  </ns2:PlanName>
                  <xsl:if test="string-length(ns2:Policy/ns2:Jurisdiction) &gt; 0">
                    <ns2:Jurisdiction tc="{ns2:Policy/ns2:Jurisdiction/@tc}">
                      <xsl:value-of select="ns2:Policy/ns2:Jurisdiction" />
                    </ns2:Jurisdiction>
                  </xsl:if>
                  <ns2:PolicyStatus tc="{ns2:Policy/ns2:PolicyStatus/@tc}">
                    <xsl:value-of select="ns2:Policy/ns2:PolicyStatus" />
                  </ns2:PolicyStatus>
                  <xsl:if test="string-length(ns2:Policy/ns2:PolicyValue) &gt; 0">
                    <ns2:PolicyValue>
                      <xsl:call-template name="normalizeAmount">
                        <xsl:with-param name="inputVal">
                          <xsl:value-of select="ns2:Policy/ns2:PolicyValue" />
                        </xsl:with-param>
                      </xsl:call-template>
                    </ns2:PolicyValue>
                  </xsl:if>
                  <ns2:PaymentMode tc="{ns2:Policy/ns2:PaymentMode/@tc}">
                    <xsl:value-of select="ns2:Policy/ns2:PaymentMode" />
                  </ns2:PaymentMode>
                  <ns2:PaymentMethod tc="{ns2:Policy/ns2:PaymentMethod/@tc}">
                    <xsl:value-of select="ns2:Policy/ns2:PaymentMethod" />
                  </ns2:PaymentMethod>
                  <xsl:if test="ns2:Policy/ns2:Life">
                    <ns2:Life>
                      <xsl:if test="string-length(ns2:Policy/ns2:Life/ns2:InitialPremAmt) &gt; 0">
                        <ns2:InitialPremAmt>
                          <xsl:call-template name="normalizeAmount">
                            <xsl:with-param name="inputVal">
                              <xsl:value-of select="ns2:Policy/ns2:Life/ns2:InitialPremAmt" />
                            </xsl:with-param>
                          </xsl:call-template>
                        </ns2:InitialPremAmt>
                      </xsl:if>
                      <ns2:FaceAmt>
                        <xsl:call-template name="normalizeAmount">
                          <xsl:with-param name="inputVal">
                            <xsl:value-of select="ns2:Policy/ns2:Life/ns2:FaceAmt" />
                          </xsl:with-param>
                        </xsl:call-template>
                      </ns2:FaceAmt>
                      <xsl:if test="ns2:Policy/ns2:Life/ns2:TotalRiskAmt">
                        <ns2:TotalRiskAmt>
                          <xsl:call-template name="normalizeAmount">
                            <xsl:with-param name="inputVal">
                              <xsl:value-of select="ns2:Policy/ns2:Life/ns2:TotalRiskAmt" />
                            </xsl:with-param>
                          </xsl:call-template>
                        </ns2:TotalRiskAmt>
                      </xsl:if>
                      <xsl:for-each select="ns2:Policy/ns2:Life/ns2:Coverage">
                        <ns2:Coverage id="{@id}">
                          <ns2:PlanName>
                            <xsl:value-of select="ns2:PlanName" />
                          </ns2:PlanName>
                          <ns2:ShortName>
                            <xsl:value-of select="ns2:ShortName" />
                          </ns2:ShortName>
                          <ns2:LifeCovStatus tc="{ns2:LifeCovStatus/@tc}">
                            <xsl:value-of select="ns2:LifeCovStatus" />
                          </ns2:LifeCovStatus>
                          <ns2:LifeCovTypeCode tc="{ns2:LifeCovTypeCode/@tc}">
                            <xsl:value-of select="ns2:LifeCovTypeCode" />
                          </ns2:LifeCovTypeCode>
                          <ns2:IndicatorCode tc="{ns2:IndicatorCode/@tc}">
                            <xsl:value-of select="ns2:IndicatorCode" />
                          </ns2:IndicatorCode>
                          <xsl:if test="string-length(ns2:DeathBenefitOptType) &gt; 0 or string-length(ns2:DeathBenefitOptType/@tc) &gt; 0">
                            <DeathBenefitOptType tc="{ns2:DeathBenefitOptType/@tc}">
                              <xsl:value-of select="ns2:DeathBenefitOptType" />
                            </DeathBenefitOptType>
                          </xsl:if>
                          <ns2:CurrentAmt>
                            <xsl:call-template name="normalizeAmount">
                              <xsl:with-param name="inputVal">
                                <xsl:value-of select="ns2:CurrentAmt" />
                              </xsl:with-param>
                            </xsl:call-template>
                          </ns2:CurrentAmt>
                          <ns2:LifeParticipant PartyID="{ns2:LifeParticipant/@PartyID}" id="{ns2:LifeParticipant/@id}">
                            <ns2:LifeParticipantRoleCode tc="{ns2:LifeParticipant/ns2:LifeParticipantRoleCode/@tc}">
                              <xsl:value-of select="ns2:LifeParticipant/ns2:LifeParticipantRoleCode" />
                            </ns2:LifeParticipantRoleCode>
                          </ns2:LifeParticipant>
                        </ns2:Coverage>
                      </xsl:for-each>
                    </ns2:Life>
                  </xsl:if>
                  <ns2:ApplicationInfo>
                    <ns2:TrackingID>
                      <xsl:value-of select="ns2:Policy/ns2:ApplicationInfo/ns2:TrackingID" />
                    </ns2:TrackingID>
                    <ns2:ApplicationJurisdiction tc="{ns2:Policy/ns2:ApplicationInfo/ns2:ApplicationJurisdiction/@tc}">
                      <xsl:value-of select="ns2:Policy/ns2:ApplicationInfo/ns2:ApplicationJurisdiction" />
                    </ns2:ApplicationJurisdiction>
                    <xsl:if test="string-length(ns2:Policy/ns2:ApplicationInfo/ns2:SignedDate) &gt; 0">
                      <ns2:SignedDate>
                        <xsl:value-of select="ns2:Policy/ns2:ApplicationInfo/ns2:SignedDate" />
                      </ns2:SignedDate>
                    </xsl:if>
                    <ns2:PrefLanguage tc="{ns2:Policy/ns2:ApplicationInfo/ns2:PrefLanguage/@tc}">
                      <xsl:value-of select="ns2:Policy/ns2:ApplicationInfo/ns2:PrefLanguage" />
                    </ns2:PrefLanguage>
                  </ns2:ApplicationInfo>
                  <xsl:for-each select="ns2:Policy/ns2:RequirementInfo">
                    <ns2:RequirementInfo AppliesToPartyID="{@AppliesToPartyID}">
                      <xsl:if test="@FulfillerPartyID">
                        <xsl:attribute name="FulfillerPartyID">
                          <xsl:value-of select="@FulfillerPartyID" />
                        </xsl:attribute>
                      </xsl:if>
                      <xsl:if test="@RequesterPartyID">
                        <xsl:attribute name="RequesterPartyID">
                          <xsl:value-of select="@RequesterPartyID" />
                        </xsl:attribute>
                      </xsl:if>
                      <xsl:if test="@id">
                        <xsl:attribute name="id">
                          <xsl:value-of select="@id" />
                        </xsl:attribute>
                      </xsl:if>
                      <xsl:choose>
                        <xsl:when test="number(ns2:ReqCode/@tc) &gt; 361 and number(ns2:ReqCode/@tc) &lt;495">
                          <ns2:ReqCode tc="459">
                            <xsl:value-of select="'PVT ING'" />
                          </ns2:ReqCode>
                        </xsl:when>
                        <xsl:otherwise>
                          <ns2:ReqCode tc="{ns2:ReqCode/@tc}">
                            <xsl:choose>
                              <xsl:when test="string-length(ns2:ReqCode) &gt; 0">
                                <xsl:value-of select="ns2:ReqCode" />
                              </xsl:when>
                              <xsl:when test="ns2:ReqCode/@tc = '11'">
                                <xsl:text>Obtain Attending Physician Statement</xsl:text>
                              </xsl:when>
                              <xsl:when test="ns2:ReqCode/@tc = '137'">
                                <xsl:text>Conduct Tele-Interview</xsl:text>
                              </xsl:when>
                              <xsl:when test="ns2:ReqCode/@tc = '138'">
                                <xsl:text>Inspection Report - Business Beneficiary</xsl:text>
                              </xsl:when>
                              <xsl:when test="ns2:ReqCode/@tc = '139'">
                                <xsl:text>Prepare Inspection Report</xsl:text>
                              </xsl:when>
                              <xsl:when test="ns2:ReqCode/@tc = '334'">
                                <xsl:text>Financial / Credit Check</xsl:text>
                              </xsl:when>
                              <xsl:otherwise />
                            </xsl:choose>
                          </ns2:ReqCode>
                        </xsl:otherwise>
                      </xsl:choose>
                      <!-- START SOURCE CLIENT AIE SPECIFIC STUFF -->
                      <xsl:if test="$sourceClient='AIE'">
                        <ns2:RequirementInfoKey>
                          <xsl:value-of select="ns2:RequirementInfoKey" />
                        </ns2:RequirementInfoKey>
                      </xsl:if>
                      <!-- END SOURCE CLIENT AIE SPECIFIC STUFF -->
                      <ns2:RequirementInfoUniqueID>
                        <xsl:value-of select="ns2:RequirementInfoUniqueID" />
                      </ns2:RequirementInfoUniqueID>
                      <ns2:RequestedDate>
                        <xsl:value-of select="ns2:RequestedDate" />
                      </ns2:RequestedDate>
                      <ns2:RequestedScheduleDate>
                        <xsl:value-of select="ns2:RequestedScheduleDate" />
                      </ns2:RequestedScheduleDate>
                      <xsl:if test="string-length(ns2:ScheduledDate) &gt; 0">
                        <ns2:ScheduledDate>
                          <xsl:value-of select="ns2:ScheduledDate" />
                        </ns2:ScheduledDate>
                      </xsl:if>
                      <xsl:if test="string-length(ns2:RequestedScheduleTimeStart) &gt; 0">
                        <ns2:RequestedScheduleTimeStart>
                          <xsl:value-of select="ns2:RequestedScheduleTimeStart" />
                        </ns2:RequestedScheduleTimeStart>
                      </xsl:if>
                      <xsl:if test="string-length(ns2:RequestedScheduleTimeEnd) &gt; 0">
                        <ns2:RequestedScheduleTimeEnd>
                          <xsl:value-of select="ns2:RequestedScheduleTimeEnd" />
                        </ns2:RequestedScheduleTimeEnd>
                      </xsl:if>
                      <ns2:ReleasePartyOrgCode>
                        <xsl:value-of select="ns2:ReleasePartyOrgCode" />
                      </ns2:ReleasePartyOrgCode>
                      <ns2:RequirementAcctNum>
                        <xsl:value-of select="ns2:RequirementAcctNum" />
                      </ns2:RequirementAcctNum>
                      <ns2:CarrierOrderNum>
                        <xsl:value-of select="ns2:CarrierOrderNum" />
                      </ns2:CarrierOrderNum>
                      <!-- START SOURCE CLIENT NON-AIE SPECIFIC STUFF -->
                      <xsl:if test="$sourceClient!='AIE'">
                        <ns2:RequirementInfoKey>
                          <xsl:value-of select="ns2:RequirementInfoKey" />
                        </ns2:RequirementInfoKey>
                      </xsl:if>
                      <!-- END SOURCE CLIENT NON-AIE SPECIFIC STUFF -->
                      <xsl:if test="string-length(ns2:RequirementDetails) &gt; 0">
                        <ns2:RequirementDetails>
                          <xsl:value-of select="ns2:RequirementDetails" />
                        </ns2:RequirementDetails>
                      </xsl:if>
                      <xsl:if test="ns2:LanguageInterpreterNeeded">
                        <ns2:LanguageInterpreterNeeded tc="{ns2:LanguageInterpreterNeeded/@tc}">
                          <xsl:value-of select="ns2:LanguageInterpreterNeeded" />
                        </ns2:LanguageInterpreterNeeded>
                      </xsl:if>
                      <xsl:if test="ns2:InterpretedLanguage">
                        <ns2:InterpretedLanguage tc="{ns2:InterpretedLanguage/@tc}">
                          <xsl:value-of select="ns2:InterpretedLanguage" />
                        </ns2:InterpretedLanguage>
                      </xsl:if>
                      <!--
											<xsl:for-each select="../../ns2:Attachment[contains(ns2:AttachmentData,'PTR_SPECIAL_NEEDS -')]">
												<ns2:OLifEExtension VendorCode="118">
													<xsl:value-of select="normalize-space(substring-after(ns2:AttachmentData,'PTR_SPECIAL_NEEDS -'))" />
												</ns2:OLifEExtension>
											</xsl:for-each>
											-->
                      <xsl:choose>
                        <xsl:when test="ns2:OLifEExtension[@VendorCode='118']">
                          <xsl:for-each select="ns2:OLifEExtension[@VendorCode='118']">
                            <ns2:OLifEExtension VendorCode="118">
                              <xsl:value-of select="." />
                            </ns2:OLifEExtension>
                          </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:for-each select="../../ns2:Attachment[contains(ns2:AttachmentData,'PTR_SPECIAL_NEEDS -')]">
                            <ns2:OLifEExtension VendorCode="118">
                              <xsl:value-of select="normalize-space(substring-after(ns2:AttachmentData,'PTR_SPECIAL_NEEDS -'))" />
                            </ns2:OLifEExtension>
                          </xsl:for-each>
                        </xsl:otherwise>
                      </xsl:choose>
                    </ns2:RequirementInfo>
                  </xsl:for-each>
                </ns2:Policy>
                <xsl:for-each select="ns2:Attachment">
                  <ns2:Attachment>
                    <ns2:AttachmentBasicType tc="{ns2:AttachmentBasicType/@tc}">
                      <xsl:value-of select="ns2:AttachmentBasicType" />
                    </ns2:AttachmentBasicType>
                    <ns2:Description>
                      <xsl:choose>
                        <xsl:when test="string-length(ns2:Description) &gt; 0">
                          <xsl:value-of select="ns2:Description" />
                        </xsl:when>
                        <xsl:when test="(ns2:AttachmentType/@tc = '2' or ns2:AttachmentType/@tc = '14') and string-length(ns2:AttachmentData) &gt; 0">
                          <!-- for AXA the content of a "comment" attachment is in the AttachmentData element -->
                          <xsl:value-of select="ns2:AttachmentData" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="ns2:Description" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </ns2:Description>
                    <xsl:if test="string-length(ns2:AttachmentData) &gt; 0 and ns2:AttachmentType/@tc != '2' and ns2:AttachmentType/@tc != '14'">
                      <ns2:AttachmentData>
                        <xsl:value-of select="ns2:AttachmentData" />
                      </ns2:AttachmentData>
                    </xsl:if>
                    <ns2:AttachmentType tc="{ns2:AttachmentType/@tc}">
                      <xsl:choose>
                        <xsl:when test="string-length(normalize-space(ns2:AttachmentType)) &gt; 0">
                          <xsl:value-of select="ns2:AttachmentType" />
                        </xsl:when>
                        <xsl:when test="ns2:AttachmentType/@tc = 1">
                          <xsl:text>Document</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:AttachmentType/@tc = 2">
                          <xsl:text>Comment/Remark</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:AttachmentType/@tc = 14">
                          <xsl:text>General Note</xsl:text>
                        </xsl:when>
                        <xsl:otherwise />
                      </xsl:choose>
                    </ns2:AttachmentType>
                    <ns2:MimeType>
                      <xsl:choose>
                        <xsl:when test="ns2:ImageType">
                          <xsl:choose>
                            <xsl:when test="ns2:ImageType/@tc=1 or ns2:ImageType='JPEG' or ns2:ImageType='JPG'">
                              <ns2:MimeType>image/jpeg</ns2:MimeType>
                            </xsl:when>
                            <xsl:when test="ns2:ImageType/@tc=2 or ns2:ImageType='GIF'">
                              <ns2:MimeType>image/gif</ns2:MimeType>
                            </xsl:when>
                            <xsl:when test="ns2:ImageType/@tc=3 or ns2:ImageType='TIFF' or ns2:ImageType='TIF'">
                              <ns2:MimeType>image/tiff</ns2:MimeType>
                            </xsl:when>
                            <xsl:when test="ns2:ImageType/@tc=4 or ns2:ImageType='PDF'">
                              <ns2:MimeType>application/pdf</ns2:MimeType>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="ns2:ImageType" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:when>
                        <xsl:when test="ns2:MimeTypeTC">
                          <xsl:choose>
                            <xsl:when test="ns2:MimeTypeTC/@tc=11 or ns2:MimeTypeTC='TIFF' or ns2:MimeTypeTC='TIF' or ns2:MimeTypeTC='tiff' or ns2:MimeTypeTC='tif'">
                              <ns2:MimeType>image/tiff</ns2:MimeType>
                            </xsl:when>
                            <xsl:when test="ns2:MimeTypeTC/@tc=17 or ns2:MimeTypeTC='PDF' or ns2:MimeTypeTC='pdf'">
                              <ns2:MimeType>application/pdf</ns2:MimeType>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="ns2:MimeTypeTC" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="ns2:MimeType" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </ns2:MimeType>
                    <ns2:TransferEncodingTypeString>
                      <xsl:value-of select="ns2:TransferEncodingTypeString" />
                    </ns2:TransferEncodingTypeString>
                    <ns2:TransferEncodingTypeTC tc="{ns2:TransferEncodingTypeTC/@tc}">
                      <xsl:value-of select="ns2:TransferEncodingTypeTC" />
                    </ns2:TransferEncodingTypeTC>
                    <ns2:AttachmentLocation tc="{ns2:AttachmentLocation/@tc}">
                      <xsl:value-of select="ns2:AttachmentLocation" />
                    </ns2:AttachmentLocation>
                  </ns2:Attachment>
                </xsl:for-each>
              </ns2:Holding>
            </xsl:for-each>
            <xsl:for-each select="ns2:OLifE/ns2:Party">
              <ns2:Party id="{@id}">
                <xsl:variable name="PartyID" select="@id" />
                <ns2:PartyTypeCode tc="{ns2:PartyTypeCode/@tc}">
                  <xsl:choose>
                    <xsl:when test="ns2:PartyTypeCode">
                      <xsl:value-of select="ns2:PartyTypeCode" />
                    </xsl:when>
                    <xsl:when test="ns2:Person">
                      <xsl:text>Person</xsl:text>
                    </xsl:when>
                    <xsl:when test="ns2:Organization">
                      <xsl:text>Organization</xsl:text>
                    </xsl:when>
                  </xsl:choose>
                </ns2:PartyTypeCode>
                <ns2:FullName>
                  <xsl:value-of select="ns2:FullName" />
                </ns2:FullName>
                <ns2:GovtID>
                  <xsl:choose>
                    <xsl:when test="string-length(ns2:Producer/ns2:CarrierAppointment/ns2:CompanyProducerID) &gt; 0">
                      <xsl:value-of select="ns2:Producer/ns2:CarrierAppointment/ns2:CompanyProducerID" />
                    </xsl:when>
                    <xsl:when test="string-length(ns2:Producer/ns2:CarrierAppointment/ns2:AppointmentCategory) &gt; 0">
                      <xsl:value-of select="ns2:Organization/ns2:OrgCode" />
                      <xsl:value-of select="' '" />
                      <xsl:value-of select="ns2:Producer/ns2:CarrierAppointment/ns2:AppointmentCategory" />
                    </xsl:when>
                    <xsl:when test="not(ns2:GovtID) and ../ns2:Relation[@RelatedObjectID=$PartyID]/ns2:RelationRoleCode/@tc='37' and ../ns2:Party[@id = ../ns2:Relation[ns2:RelationRoleCode/@tc='182']/@RelatedObjectID]/ns2:Producer/ns2:CarrierAppointment/ns2:AppointmentCategory">
                      <xsl:value-of select="../ns2:Party[@id = ../ns2:Relation[ns2:RelationRoleCode/@tc='182']/@RelatedObjectID]/ns2:Organization/ns2:OrgCode" />
                      <xsl:value-of select="' '" />
                      <xsl:value-of select="../ns2:Party[@id = ../ns2:Relation[ns2:RelationRoleCode/@tc='182']/@RelatedObjectID]/ns2:Producer/ns2:CarrierAppointment/ns2:AppointmentCategory" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="ns2:GovtID" />
                    </xsl:otherwise>
                  </xsl:choose>
                </ns2:GovtID>
                <xsl:if test="ns2:Person">
                  <ns2:Person>
                    <ns2:FirstName>
                      <xsl:value-of select="ns2:Person/ns2:FirstName" />
                    </ns2:FirstName>
                    <ns2:MiddleName>
                      <xsl:value-of select="ns2:Person/ns2:MiddleName" />
                    </ns2:MiddleName>
                    <ns2:LastName>
                      <xsl:value-of select="ns2:Person/ns2:LastName" />
                    </ns2:LastName>
                    <ns2:Occupation>
                      <xsl:value-of select="ns2:Person/ns2:Occupation" />
                    </ns2:Occupation>
                    <ns2:Gender tc="{ns2:Person/ns2:Gender/@tc}">
                      <xsl:choose>
                        <xsl:when test="ns2:Person/ns2:Gender/@tc = '0'">
                          <xsl:text>Unknown</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:Person/ns2:Gender/@tc = '1'">
                          <xsl:text>Male</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:Person/ns2:Gender/@tc = '2'">
                          <xsl:text>Female</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:Person/ns2:Gender/@tc = '3'">
                          <xsl:text>Unisex</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:Person/ns2:Gender/@tc = '4'">
                          <xsl:text>Combined</xsl:text>
                        </xsl:when>
                        <xsl:when test="ns2:Person/ns2:Gender/@tc = '2147483647'">
                          <xsl:text>Other</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="ns2:Person/ns2:Gender" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </ns2:Gender>
                    <xsl:if test="string-length(ns2:Person/ns2:BirthDate) &gt; 0">
                      <ns2:BirthDate>
                        <xsl:value-of select="ns2:Person/ns2:BirthDate" />
                      </ns2:BirthDate>
                    </xsl:if>
                    <ns2:Citizenship tc="{ns2:Person/ns2:Citizenship/@tc}">
                      <xsl:value-of select="ns2:Person/ns2:Citizenship" />
                    </ns2:Citizenship>
                    <ns2:BirthCountry tc="{ns2:Person/ns2:BirthCountry/@tc}">
                      <xsl:value-of select="ns2:Person/ns2:BirthCountry" />
                    </ns2:BirthCountry>
                    <ns2:BirthJurisdictionTC tc="{ns2:Person/ns2:BirthJurisdictionTC/@tc}">
                      <xsl:value-of select="ns2:Person/ns2:BirthJurisdictionTC" />
                    </ns2:BirthJurisdictionTC>
                    <xsl:if test="string-length(ns2:Person/ns2:Prefix) &gt; 0">
                      <ns2:Prefix>
                        <xsl:value-of select="ns2:Person/ns2:Prefix" />
                      </ns2:Prefix>
                    </xsl:if>
                  </ns2:Person>
                </xsl:if>
                <xsl:if test="ns2:Organization">
                  <ns2:Organization>
                    <ns2:AbbrName>
                      <xsl:value-of select="ns2:Organization/ns2:AbbrName" />
                    </ns2:AbbrName>
                  </ns2:Organization>
                </xsl:if>
                <xsl:if test="ns2:Client/ns2:ClientKey">
                  <ns2:Client>
                    <ns2:ClientKey>
                      <xsl:value-of select="ns2:Client/ns2:ClientKey" />
                    </ns2:ClientKey>
                  </ns2:Client>
                </xsl:if>
                <xsl:if test="ns2:BestTimeToCallFrom">
                  <ns2:BestTimeToCallFrom>
                    <xsl:call-template name="normalizeBestTimeToCall">
                      <xsl:with-param name="value" select="ns2:BestTimeToCallFrom" />
                    </xsl:call-template>
                  </ns2:BestTimeToCallFrom>
                </xsl:if>
                <xsl:if test="ns2:BestTimeToCallTo">
                  <ns2:BestTimeToCallTo>
                    <xsl:call-template name="normalizeBestTimeToCall">
                      <xsl:with-param name="value" select="ns2:BestTimeToCallTo" />
                    </xsl:call-template>
                  </ns2:BestTimeToCallTo>
                </xsl:if>
                <xsl:for-each select="ns2:Address">
                  <ns2:Address>
                    <xsl:choose>
                      <xsl:when test="string-length(ns2:AddressTypeCode/@tc) &gt; 0">
                        <ns2:AddressTypeCode tc="{ns2:AddressTypeCode/@tc}">
                          <xsl:choose>
                            <xsl:when test="string-length(ns2:AddressTypeCode) &gt; 0">
                              <xsl:value-of select="ns2:AddressTypeCode" />
                            </xsl:when>
                            <xsl:when test="ns2:AddressTypeCode/@tc = 0">
                              <xsl:text>Unknown</xsl:text>
                            </xsl:when>
                            <xsl:when test="ns2:AddressTypeCode/@tc = 1">
                              <xsl:text>Residence</xsl:text>
                            </xsl:when>
                            <xsl:when test="ns2:AddressTypeCode/@tc = 2">
                              <xsl:text>Business</xsl:text>
                            </xsl:when>
                            <xsl:when test="ns2:AddressTypeCode/@tc = 3">
                              <xsl:text>Vacation</xsl:text>
                            </xsl:when>
                            <xsl:when test="ns2:AddressTypeCode/@tc = 17">
                              <xsl:text>Mailing</xsl:text>
                            </xsl:when>
                            <xsl:when test="ns2:AddressTypeCode/@tc = 26">
                              <xsl:text>Billing Mailing</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="ns2:AddressTypeCode" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </ns2:AddressTypeCode>
                      </xsl:when>
                      <xsl:when test="../ns2:Person">
                        <ns2:AddressTypeCode tc="1">
                          <xsl:value-of select="'Residence'" />
                        </ns2:AddressTypeCode>
                      </xsl:when>
                      <xsl:when test="../ns2:Organization">
                        <ns2:AddressTypeCode tc="2">
                          <xsl:value-of select="'Business'" />
                        </ns2:AddressTypeCode>
                      </xsl:when>
                      <xsl:otherwise>
                        <ns2:AddressTypeCode tc="0">
                          <xsl:value-of select="'Unknown'" />
                        </ns2:AddressTypeCode>
                      </xsl:otherwise>
                    </xsl:choose>
                    <ns2:Line1>
                      <xsl:value-of select="ns2:Line1" />
                    </ns2:Line1>
                    <ns2:Line2>
                      <xsl:value-of select="ns2:Line2" />
                    </ns2:Line2>
                    <ns2:City>
                      <xsl:value-of select="ns2:City" />
                    </ns2:City>
                    <xsl:variable name="AddressState">
                      <xsl:choose>
                        <xsl:when test="string-length(normalize-space(ns2:AddressStateTC/@tc)) &gt; 0 and number(normalize-space(ns2:AddressStateTC/@tc)) &gt; 100">
                          <xsl:value-of select="'UN'" />
                        </xsl:when>
                        <xsl:when test="string-length(normalize-space(ns2:AddressState)) &gt; 0 ">
                          <xsl:value-of select="ns2:AddressState" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:call-template name="TCToStateMapping">
                            <xsl:with-param name="value" select="ns2:AddressStateTC/@tc" />
                          </xsl:call-template>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="AddressStateTC">
                      <xsl:choose>
                        <xsl:when test="string-length(normalize-space(ns2:AddressStateTC/@tc)) &gt; 0 and number(normalize-space(ns2:AddressStateTC/@tc)) &gt; 100">
                          <xsl:value-of select="'0'" />
                        </xsl:when>
                        <xsl:when test="string-length(normalize-space(ns2:AddressStateTC/@tc)) &gt; 0">
                          <xsl:value-of select="ns2:AddressStateTC/@tc" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:call-template name="StateToTCMapping">
                            <xsl:with-param name="value" select="$AddressState" />
                          </xsl:call-template>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <ns2:AddressState>
                      <xsl:value-of select="$AddressState" />
                    </ns2:AddressState>
                    <ns2:AddressStateTC tc="{$AddressStateTC}">
                      <xsl:value-of select="$AddressState" />
                    </ns2:AddressStateTC>
                    <ns2:Zip>
                      <xsl:value-of select="ns2:Zip" />
                    </ns2:Zip>
                    <ns2:PreventOverrideInd tc="{ns2:PreventOverrideInd/@tc}">
                      <xsl:value-of select="ns2:PreventOverrideInd" />
                    </ns2:PreventOverrideInd>
                  </ns2:Address>
                </xsl:for-each>
                <xsl:for-each select="ns2:Phone">
                  <ns2:Phone>
                    <xsl:choose>
                      <xsl:when test="(ns2:PhoneTypeCode/@tc = '1') and (count(preceding-sibling::ns2:Phone[ns2:PhoneTypeCode/@tc = '1']) &gt;= 2)">
                        <ns2:PhoneTypeCode tc="12">
                          <xsl:value-of select="ns2:PhoneTypeCode" />
                        </ns2:PhoneTypeCode>
                      </xsl:when>
                      <xsl:when test="(ns2:PhoneTypeCode/@tc = '1') and (count(preceding-sibling::ns2:Phone[ns2:PhoneTypeCode/@tc = '1']) = 1)">
                        <ns2:PhoneTypeCode tc="2">
                          <xsl:value-of select="ns2:PhoneTypeCode" />
                        </ns2:PhoneTypeCode>
                      </xsl:when>
                      <xsl:otherwise>
                        <ns2:PhoneTypeCode tc="{ns2:PhoneTypeCode/@tc}">
                          <xsl:value-of select="ns2:PhoneTypeCode" />
                        </ns2:PhoneTypeCode>
                      </xsl:otherwise>
                    </xsl:choose>
                    <ns2:AreaCode>
                      <xsl:value-of select="ns2:AreaCode" />
                    </ns2:AreaCode>
                    <ns2:DialNumber>
                      <xsl:value-of select="ns2:DialNumber" />
                    </ns2:DialNumber>
                    <ns2:Ext>
                      <xsl:value-of select="ns2:Ext" />
                    </ns2:Ext>
                    <xsl:choose>
                      <xsl:when test="string-length(ns2:PrefPhone/@tc) &gt; 0">
                        <xsl:choose>
                          <xsl:when test="ns2:PrefPhone/@tc = '0'">
                            <ns2:PrefPhone tc="0">False</ns2:PrefPhone>
                          </xsl:when>
                          <xsl:when test="ns2:PrefPhone/@tc = '1'">
                            <ns2:PrefPhone tc="1">True</ns2:PrefPhone>
                          </xsl:when>
                        </xsl:choose>
                      </xsl:when>
                      <xsl:when test="string-length(ns2:PrefPhone) &gt; 0">
                        <xsl:choose>
                          <xsl:when test="ns2:PrefPhone = 'False' or ns2:PrefPhone = 'false' or ns2:PrefPhone = 'FALSE' or ns2:PrefPhone = 'No' or ns2:PrefPhone = 'no' or ns2:PrefPhone = 'NO' or ns2:PrefPhone = '0'">
                            <ns2:PrefPhone tc="0">False</ns2:PrefPhone>
                          </xsl:when>
                          <xsl:when test="ns2:PrefPhone = 'True' or ns2:PrefPhone = 'true' or ns2:PrefPhone = 'TRUE' or ns2:PrefPhone = 'Yes' or ns2:PrefPhone = 'yes' or ns2:PrefPhone = 'YES' or ns2:PrefPhone = '1'">
                            <ns2:PrefPhone tc="1">True</ns2:PrefPhone>
                          </xsl:when>
                        </xsl:choose>
                      </xsl:when>
                    </xsl:choose>
                    <xsl:if test="ns2:BestTimeToCallFrom">
                      <ns2:BestTimeToCallFrom>
                        <xsl:call-template name="normalizeBestTimeToCall">
                          <xsl:with-param name="value" select="ns2:BestTimeToCallFrom" />
                        </xsl:call-template>
                      </ns2:BestTimeToCallFrom>
                    </xsl:if>
                    <xsl:if test="ns2:BestTimeToCallTo">
                      <ns2:BestTimeToCallTo>
                        <xsl:call-template name="normalizeBestTimeToCall">
                          <xsl:with-param name="value" select="ns2:BestTimeToCallTo" />
                        </xsl:call-template>
                      </ns2:BestTimeToCallTo>
                    </xsl:if>
                  </ns2:Phone>
                </xsl:for-each>
                <!-- strip out empty email addresses -->
                <xsl:for-each select="ns2:EMailAddress[string-length(ns2:AddrLine) &gt; 0]">
                  <ns2:EMailAddress>
                    <ns2:AddrLine>
                      <xsl:value-of select="ns2:AddrLine" />
                    </ns2:AddrLine>
                  </ns2:EMailAddress>
                </xsl:for-each>
                <xsl:if test="string-length(concat(ns2:ResidenceState/@tc, ns2:ResidenceState)) &gt; 0">
                  <ns2:ResidenceState tc="{ns2:ResidenceState/@tc}">
                    <xsl:value-of select="ns2:ResidenceState" />
                  </ns2:ResidenceState>
                </xsl:if>
                <xsl:if test="string-length(concat(ns2:ResidenceCountry/@tc, ns2:ResidenceCountry)) &gt; 0">
                  <ns2:ResidenceCountry tc="{ns2:ResidenceCountry/@tc}">
                    <xsl:value-of select="ns2:ResidenceCountry" />
                  </ns2:ResidenceCountry>
                </xsl:if>
              </ns2:Party>
            </xsl:for-each>
            <xsl:for-each select="ns2:OLifE/ns2:Relation">
              <ns2:Relation OriginatingObjectID="{@OriginatingObjectID}" RelatedObjectID="{@RelatedObjectID}" id="{@id}">
                <ns2:OriginatingObjectType tc="{ns2:OriginatingObjectType/@tc}">
                  <xsl:value-of select="ns2:OriginatingObjectType" />
                </ns2:OriginatingObjectType>
                <ns2:RelatedObjectType tc="{ns2:RelatedObjectType/@tc}">
                  <xsl:value-of select="ns2:RelatedObjectType" />
                </ns2:RelatedObjectType>
                <!-- SOMETIMES CLIENTS SEND IN 121 FILES WITH MISSING RELATIONROLECODE VALUES BUT TC VALUES ARE POPULATED -->
                <!-- SO WE ARE GOING TO USE A TABULAR MAPPING TO POPULATE THE RELATIONROLECODE VALUES BASED ON THE TC VALUE THAT IS PROVIDED -->
                <ns2:RelationRoleCode tc="{ns2:RelationRoleCode/@tc}">
                  <!-- FIRST GET THE FULL PATH TO THE EXTERNAL TABULAR MAPPINGS TAB DELIMITED TEXT FILE FROM TRANS ATTR THAT WAS POPULATED FROM ENVIRONMENT PROPERTIES -->
                  <xsl:variable name="RelationRoleCodeTabularMappingsFilePath" select="converter:getAttributeString('RelationRoleCodeTabularMappingsFilePath')" />
                  <!-- MAKE THE EXTERNAL JAVA CALL TO GET THE VALUE FROM THE EXTERNAL MAPPING FILE -->
                  <xsl:value-of select="tmCall:getTargetValueFromFile($RelationRoleCodeTabularMappingsFilePath, ns2:RelationRoleCode/@tc)" />
                </ns2:RelationRoleCode>
              </ns2:Relation>
            </xsl:for-each>
          </ns2:OLifE>
        </ns2:TXLifeRequest>
      </xsl:for-each>
    </ns2:TXLife>
  </xsl:template>
  <xsl:template name="TCToStateMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='0'">
        <xsl:text>UN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>AL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>AK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>AZ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>AR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>CA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>CO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>CT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9'">
        <xsl:text>DE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>DC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>YAP</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>FL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>GA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>HI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='16'">
        <xsl:text>ID</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>IL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='18'">
        <xsl:text>IN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>IA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>KS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>KY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>LA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>ME</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='24'">
        <xsl:text>MRSIS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>MD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='26'">
        <xsl:text>MA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='27'">
        <xsl:text>MI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='28'">
        <xsl:text>MN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='29'">
        <xsl:text>MS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='30'">
        <xsl:text>MO</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>MT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='32'">
        <xsl:text>NE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='33'">
        <xsl:text>NV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='34'">
        <xsl:text>NH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='35'">
        <xsl:text>NJ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='36'">
        <xsl:text>NM</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='37'">
        <xsl:text>NY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='38'">
        <xsl:text>NC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='39'">
        <xsl:text>ND</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='40'">
        <xsl:text>MARIS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='41'">
        <xsl:text>OH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='42'">
        <xsl:text>OK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='43'">
        <xsl:text>OR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='44'">
        <xsl:text>PALAU</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='45'">
        <xsl:text>PA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='46'">
        <xsl:text>PR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='47'">
        <xsl:text>RI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='48'">
        <xsl:text>SC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='49'">
        <xsl:text>SD</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='50'">
        <xsl:text>TN</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='51'">
        <xsl:text>TX</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='52'">
        <xsl:text>UT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='53'">
        <xsl:text>VT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='54'">
        <xsl:text>VI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='55'">
        <xsl:text>VA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='56'">
        <xsl:text>WA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='57'">
        <xsl:text>WV</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='58'">
        <xsl:text>WI</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='59'">
        <xsl:text>WY</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='101'">
        <xsl:text>AB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='102'">
        <xsl:text>BC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='103'">
        <xsl:text>MB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='104'">
        <xsl:text>NB</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='105'">
        <xsl:text>NF</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='106'">
        <xsl:text>NT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='107'">
        <xsl:text>NS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='108'">
        <xsl:text>ON</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='109'">
        <xsl:text>PE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='110'">
        <xsl:text>QC</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='111'">
        <xsl:text>SK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='112'">
        <xsl:text>YT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='113'">
        <xsl:text>NU</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UN</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="StateToTCMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='UN'">
        <xsl:text>0</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AL'">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AK'">
        <xsl:text>2</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AZ'">
        <xsl:text>4</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AR'">
        <xsl:text>5</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CA'">
        <xsl:text>6</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CO'">
        <xsl:text>7</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='CT'">
        <xsl:text>8</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DE'">
        <xsl:text>9</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='DC'">
        <xsl:text>10</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YAP'">
        <xsl:text>11</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='FL'">
        <xsl:text>12</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='GA'">
        <xsl:text>13</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='HI'">
        <xsl:text>15</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ID'">
        <xsl:text>16</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IL'">
        <xsl:text>17</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IN'">
        <xsl:text>18</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='IA'">
        <xsl:text>19</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KS'">
        <xsl:text>20</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='KY'">
        <xsl:text>21</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='LA'">
        <xsl:text>22</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ME'">
        <xsl:text>23</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>ME</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>MNE</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MRSIS'">
        <xsl:text>24</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MD'">
        <xsl:text>25</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MA'">
        <xsl:text>26</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MI'">
        <xsl:text>27</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MN'">
        <xsl:text>28</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MS'">
        <xsl:text>29</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MO'">
        <xsl:text>30</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MT'">
        <xsl:text>31</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NE'">
        <xsl:text>32</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NV'">
        <xsl:text>33</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NH'">
        <xsl:text>34</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NJ'">
        <xsl:text>35</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NM'">
        <xsl:text>36</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NY'">
        <xsl:text>37</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NC'">
        <xsl:text>38</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ND'">
        <xsl:text>39</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MARIS'">
        <xsl:text>40</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OH'">
        <xsl:text>41</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OK'">
        <xsl:text>42</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='OR'">
        <xsl:text>43</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PALAU'">
        <xsl:text>44</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PA'">
        <xsl:text>45</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PR'">
        <xsl:text>46</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='RI'">
        <xsl:text>47</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SC'">
        <xsl:text>48</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SD'">
        <xsl:text>49</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TN'">
        <xsl:text>50</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='TX'">
        <xsl:text>51</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='UT'">
        <xsl:text>52</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VT'">
        <xsl:text>53</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VI'">
        <xsl:text>54</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='VA'">
        <xsl:text>55</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WA'">
        <xsl:text>56</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WV'">
        <xsl:text>57</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WI'">
        <xsl:text>58</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='WY'">
        <xsl:text>59</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='AB'">
        <xsl:text>101</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='BC'">
        <xsl:text>102</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='MB'">
        <xsl:text>103</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NB'">
        <xsl:text>104</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NF'">
        <xsl:text>105</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NT'">
        <xsl:text>106</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NS'">
        <xsl:text>107</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='ON'">
        <xsl:text>108</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='PE'">
        <xsl:text>109</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='QC'">
        <xsl:text>110</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='SK'">
        <xsl:text>111</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='YT'">
        <xsl:text>112</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='NU'">
        <xsl:text>113</xsl:text>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="normalizeBestTimeToCall">
    <xsl:param name="value" />
    <xsl:variable name="valueUppercase">
      <xsl:value-of select="translate($value,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$valueUppercase = 'MORNING'">
        <xsl:text>09:00:00</xsl:text>
      </xsl:when>
      <xsl:when test="$valueUppercase = 'AFTERNOON'">
        <xsl:text>13:00:00</xsl:text>
      </xsl:when>
      <xsl:when test="$valueUppercase = 'EVENING'">
        <xsl:text>18:00:00</xsl:text>
      </xsl:when>
      <xsl:when test="string-length($value) = 8 and translate($value,'0123456789','')='::' and substring($value,3,1)=':' and substring($value,6,1)=':'">
        <xsl:value-of select="$value" />
      </xsl:when>
      <xsl:when test="string-length($value) = 5 and translate($value,'0123456789','')=':' and substring($value,3,1)=':'">
        <xsl:value-of select="concat($value,':00')" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="normalizeAmount">
    <xsl:param name="inputVal" />
    <xsl:variable name="valStripped">
      <xsl:value-of select="translate($inputVal,'+$,','')" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string(number($valStripped)) = 'NaN'">
        <xsl:value-of select="''" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="string(number($valStripped))" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

