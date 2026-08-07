<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:tem="http://tempuri.org/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="converter datetime dtFormatter ta td ns2 xsl xsi xsd" extension-element-prefixes="converter" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/ns2:TXLife">
    <!--
		<soap:Envelope>
			<soap:Header />
			<soap:Body>
				<tem:HandleRequest>
					<tem:PLServicesAccountID>
						<xsl:value-of select="ta:getAttribute($attributes, 'PLServicesAccountID')" />
					</tem:PLServicesAccountID>
					<tem:PLServiceAccountPwd>
						<xsl:value-of select="ta:getAttribute($attributes, 'PLServiceAccountPwd')" />
					</tem:PLServiceAccountPwd>
					<tem:TXLifePayLoad>
		-->
    <TXLife>
      <xsl:apply-templates select="node()|@*" />
    </TXLife>
    <!--
					</tem:TXLifePayLoad>
				</tem:HandleRequest>
			</soap:Body>
		</soap:Envelope>
		-->
  </xsl:template>
  <xsl:template match="node()">
    <!-- strip out empty elements that have no attributes -->
    <xsl:choose>
      <xsl:when test="string-length(name()) &gt; 1">
        <xsl:if test="normalize-space(string(.)) != '' or count(*) &gt; 0 or @*[string-length(.) &gt; 0]">
          <xsl:element name="{name()}" namespace="{namespace-uri()}">
            <xsl:apply-templates select="node()|@*[.!='']" />
          </xsl:element>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="node()|@*[.!='']" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@*">
    <!-- strip out empty elements that have no attributes -->
    <xsl:if test="normalize-space(string(.)) != '' or count(*) &gt; 0 or @*[string-length(.) &gt; 0]">
      <xsl:copy>
        <xsl:apply-templates select="node()|@*[.!='']" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <!-- remove attachments from their previous location -->
  <xsl:template match="ns2:Attachment" />
  <!-- remove the fields that PacLife does not want -->
  <xsl:template match="ns2:TransMode" />
  <xsl:template match="ns2:TestIndicator" />
  <xsl:template match="@*[parent::ns2:Policy]" />
  <xsl:template match="ns2:CarrierCode" />
  <xsl:template match="ns2:Coverage" />
  <xsl:template match="ns2:Gender" />
  <xsl:template match="ns2:Address" />
  <xsl:template match="ns2:Phone" />
  <xsl:template match="ns2:OriginatingObjectType" />
  <xsl:template match="ns2:RelatedObjectType" />
  <xsl:template match="ns2:Party[not(ns2:Person)]" />
  <!-- change the value of the TransRefGUID to a new unique ID -->
  <xsl:template match="ns2:Holding">
    <Holding>
      <xsl:apply-templates select="node()|@*[.!='']" />
      <!-- move the attachments to the end of the Holding element and reformat -->
      <xsl:for-each select="//ns2:Attachment[string-length(ns2:AttachmentData) &gt; 5]">
        <Attachment>
          <xsl:apply-templates mode="copy" select="ns2:AttachmentBasicType" />
          <xsl:choose>
            <xsl:when test="not(ns2:AttachmentData)" />
            <xsl:when test="string-length(ns2:AttachmentData) &gt; 20">
              <!-- use inline image data -->
              <Description>
                <xsl:value-of select="ns2:FileName" />
              </Description>
              <xsl:apply-templates mode="copy" select="ns2:AttachmentData" />
            </xsl:when>
            <xsl:otherwise>
              <!-- for large image attachments, the AttachmentData is in an attribute -->
              <Description>
                <!--<xsl:value-of select="concat(substring-before(substring-after(substring-after(ns2:FileName, '-'), '-'), '.'), '.tif')" />-->
                <xsl:value-of select="substring-after(substring-after(ns2:FileName, '-'), '-')" />
              </Description>
              <AttachmentData>
                <xsl:value-of select="ta:getAttribute($attributes, string(ns2:AttachmentData))" />
                <xsl:variable name="throwaway" select="ta:removeAttribute($attributes, string(ns2:AttachmentData))" />
              </AttachmentData>
            </xsl:otherwise>
          </xsl:choose>
          <MimeTypeTC tc="17">application/pdf</MimeTypeTC>
          <TransferEncodingTypeString>base64</TransferEncodingTypeString>
          <AttachmentLocation tc="1">Inline</AttachmentLocation>
        </Attachment>
      </xsl:for-each>
    </Holding>
  </xsl:template>
  <xsl:template match="ns2:TransRefGUID">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <xsl:comment>
      <xsl:value-of select="' New GUID generated for each status transmittal '" />
    </xsl:comment>
    <TransRefGUID>
      <xsl:value-of select="converter:getGUIDString()" />
    </TransRefGUID>
  </xsl:template>
  <!--
	<xsl:template match="ns2:SourceInfo">
		<SourceInfo>
			<SourceInfoName>Branch : 999 BASKING RIDGE</SourceInfoName>
			<SourceInfoDescription>Email : HELPDESK@HOOPERHOLMES.COM</SourceInfoDescription>
			<SourceInfoComment>Phone : 8008226318</SourceInfoComment>
		</SourceInfo>
	</xsl:template>
	-->
  <xsl:template match="ns2:FaceAmt[contains(.,'.')]">
    <!-- strip decimal portion from the FaceAmt value -->
    <FactAmt>
      <xsl:value-of select="substring-before(.,'.')" />
    </FactAmt>
  </xsl:template>
  <xsl:template match="ns2:Party[ns2:Person]">
    <Party>
      <xsl:attribute name="id">
        <xsl:choose>
          <xsl:when test="@id = ../ns2:Holding[1]/ns2:Policy[1]/ns2:RequirementInfo[1]/@AppliesToPartyID">
            <xsl:value-of select="'Party_1'" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@id" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <FullName>
        <xsl:choose>
          <xsl:when test="string-length(normalize-space(ns2:FullName)) &gt; 0">
            <xsl:value-of select="ns2:FullName" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(ns2:Person/ns2:FirstName,' ',ns2:Person/ns2:LastName)" />
          </xsl:otherwise>
        </xsl:choose>
      </FullName>
      <xsl:apply-templates mode="copy" select="ns2:GovtID" />
      <ResidenceState>
        <xsl:apply-templates select="ns2:Address/ns2:AddressStateTC/@*" />
        <xsl:call-template name="TabularMapping_ReplaceStates">
          <xsl:with-param name="value" select="ns2:Address/ns2:AddressStateTC/@*" />
        </xsl:call-template>
      </ResidenceState>
      <ResidenceCountry>
        <xsl:choose>
          <xsl:when test="string-length(normalize-space(ns2:Address/ns2:AddressCountryTC/@tc)) &gt; 0">
            <xsl:apply-templates select="ns2:Address/ns2:AddressCountryTC/@*" />
            <xsl:apply-templates select="ns2:Address/ns2:AddressCountryTC/*" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="tc">1</xsl:attribute>
            <xsl:text>United States of America</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </ResidenceCountry>
      <xsl:apply-templates select="ns2:Person" />
    </Party>
  </xsl:template>
  <xsl:template match="ns2:BirthDate[string-length(normalize-space(.)) &gt; 0]">
    <xsl:apply-templates mode="copy" select="." />
    <Age>
      <xsl:variable name="birthYear" select="substring-before(., '-')" />
      <xsl:variable name="currentYear" select="datetime:format-date(datetime:date-time(),'yyyy')" />
      <xsl:value-of select="($currentYear - $birthYear)" />
    </Age>
  </xsl:template>
  <xsl:template match="ns2:RequirementInfo">
    <!-- Only use the original (first) RequirementInfo -->
    <xsl:if test="not(preceding-sibling::ns2:RequirementInfo)">
      <RequirementInfo>
        <xsl:attribute name="id">
          <!--<xsl:value-of select="concat('Requirement_1_',position())" />-->
          <xsl:value-of select="concat('Requirement_1_','1')" />
        </xsl:attribute>
        <xsl:attribute name="AppliesToPartyID">
          <xsl:choose>
            <xsl:when test="@AppliesToPartyID = ../../../ns2:Holding[1]/ns2:Policy[1]/ns2:RequirementInfo[1]/@AppliesToPartyID">
              <xsl:value-of select="'Party_1'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="@AppliesToPartyID" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:attribute name="RequesterPartyID">
          <xsl:value-of select="'Party_Requester_1'" />
        </xsl:attribute>
        <xsl:attribute name="FulfillerPartyID">
          <xsl:value-of select="'Party_Fulfiller_1'" />
        </xsl:attribute>
        <!-- apply templates for children of this first RequirementInfo and the StatusEvents of all RequirementInfo elements -->
        <xsl:apply-templates select="node() | ../ns2:RequirementInfo[preceding-sibling::ns2:RequirementInfo]/ns2:StatusEvent" />
      </RequirementInfo>
    </xsl:if>
  </xsl:template>
  <xsl:template match="ns2:ReqStatus">
    <xsl:variable name="lastReqStatus" select="../../ns2:RequirementInfo[last()]/ns2:ReqStatus" />
    <ReqStatus>
      <!--<xsl:choose>
				<xsl:when test="../../ns2:RequirementInfo[last()]/ns2:StatusEvent/ns2:ProviderEventCode[.='S78' or .='333' or .='258' or .='334' or .='S76']">
					<xsl:attribute name="tc">11</xsl:attribute>
					<xsl:text>Completed</xsl:text>
				</xsl:when>
				<xsl:otherwise>
			-->
      <xsl:apply-templates select="$lastReqStatus/node() | $lastReqStatus/@*[.!='']" />
      <!--
				</xsl:otherwise>
			</xsl:choose>
			-->
    </ReqStatus>
  </xsl:template>
  <xsl:template match="ns2:Relation[not(preceding-sibling::ns2:Relation)]">
    <Party id="Party_Requester_1">
      <PartyTypeCode tc="2">Company</PartyTypeCode>
      <FullName>LADDER LIFE TEST PROD</FullName>
      <Organization>
        <DBA>LADDER LIFE TEST PROD</DBA>
      </Organization>
    </Party>
    <!--    ====  Old Hooper Holmes ====  -->
    <!--
		<Party id="Party_Fulfiller_1">
			<PartyTypeCode tc="2">Company</PartyTypeCode>
			<FullName>Hooper Holmes</FullName>
			<Organization>
				<DBA>Hooper Holmes</DBA>
			</Organization>
		</Party>
		-->
    <!--    ====  New CRL Plus ====  -->
    <Party id="Party_Fulfiller_1">
      <PartyTypeCode tc="2">Company</PartyTypeCode>
      <FullName>CRL-Plus</FullName>
      <Organization>
        <DBA>CRL-Plus</DBA>
      </Organization>
    </Party>
    <xsl:call-template name="processRelationInsured">
      <xsl:with-param name="value" select="." />
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="ns2:Relation">
    <xsl:call-template name="processRelationInsured">
      <xsl:with-param name="value" select="." />
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="ns2:Relation[not(following-sibling::ns2:Relation)]">
    <xsl:call-template name="processRelationInsured">
      <xsl:with-param name="value" select="." />
    </xsl:call-template>
    <Relation OriginatingObjectID="Party_1" RelatedObjectID="Party_Requester_1" id="Relation_Requester_1">
      <RelationRoleCode tc="97">Requestor</RelationRoleCode>
    </Relation>
    <Relation OriginatingObjectID="Party_1" RelatedObjectID="Party_Fulfiller_1" id="Relation_Fulfiller_1">
      <RelationRoleCode tc="99">Fulfills</RelationRoleCode>
    </Relation>
  </xsl:template>
  <xsl:template name="processRelationInsured">
    <xsl:param name="value" />
    <xsl:if test="$value/ns2:RelationRoleCode/@tc='32'">
      <Relation>
        <xsl:apply-templates select="$value/@*[name() != 'RelatedObjectID']" />
        <xsl:attribute name="RelatedObjectID">
          <xsl:choose>
            <xsl:when test="$value/@RelatedObjectID = $value/../ns2:Holding[1]/ns2:Policy[1]/ns2:RequirementInfo[1]/@AppliesToPartyID">
              <xsl:value-of select="'Party_1'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$value/@RelatedObjectID" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <RelationRoleCode tc="32">Insured</RelationRoleCode>
      </Relation>
    </xsl:if>
  </xsl:template>
  <xsl:template match="ns2:TransExeDate">
    <TransExeDate>
      <xsl:call-template name="current-date" />
    </TransExeDate>
  </xsl:template>
  <xsl:template match="ns2:TransExeTime">
    <TransExeTime>
      <xsl:call-template name="current-time" />
    </TransExeTime>
  </xsl:template>
  <xsl:template match="ns2:ReqCode">
    <!-- strip out the content of ReqCode and just include the tc attribute -->
    <ReqCode tc="{@tc}" />
  </xsl:template>
  <xsl:template match="ns2:RequestedDate">
    <xsl:if test="not(../ns2:RequirementDetails[string-length(normalize-space(.)) &gt; 0]) and ../ns2:ReqCode[string-length(normalize-space(.)) &gt; 0]">
      <RequirementDetails>
        <xsl:value-of select="../ns2:ReqCode" />
      </RequirementDetails>
    </xsl:if>
    <RequestedDate>
      <xsl:call-template name="format-date">
        <xsl:with-param name="date" select="." />
      </xsl:call-template>
    </RequestedDate>
    <xsl:if test="not(../ns2:FulfilledDate) and ../../ns2:RequirementInfo[last()]/ns2:StatusEvent[ns2:StatusEventCode/@tc='185']/ns2:StatusEventDate">
      <FulfilledDate>
        <xsl:value-of select="../../ns2:RequirementInfo[last()]/ns2:StatusEvent[ns2:StatusEventCode/@tc='185']/ns2:StatusEventDate" />
      </FulfilledDate>
    </xsl:if>
    <xsl:if test="not(../ns2:ReceivedAtLocationDate)">
      <ReceivedAtLocationDate>
        <xsl:call-template name="format-date">
          <xsl:with-param name="date" select="../ns2:OrderReceivedDate" />
        </xsl:call-template>
      </ReceivedAtLocationDate>
    </xsl:if>
  </xsl:template>
  <xsl:template match="ns2:FulfilledDate">
    <FulfilledDate>
      <xsl:call-template name="format-date">
        <xsl:with-param name="date" select="../../ns2:RequirementInfo[last()]/ns2:FulfilledDate" />
      </xsl:call-template>
    </FulfilledDate>
  </xsl:template>
  <xsl:template match="ns2:ReceivedAtLocationDate">
    <ReceivedAtLocationDate>
      <xsl:call-template name="format-date">
        <xsl:with-param name="date" select="." />
      </xsl:call-template>
    </ReceivedAtLocationDate>
  </xsl:template>
  <xsl:template match="ns2:StatusDate">
    <xsl:if test="string-length(normalize-space(.)) &gt; 0">
      <StatusDate>
        <xsl:call-template name="format-date">
          <xsl:with-param name="date">
            <xsl:choose>
              <xsl:when test="string-length(../../ns2:RequirementInfo[last()]/ns2:StatusDate) &gt; 0">
                <xsl:value-of select="../../ns2:RequirementInfo[last()]/ns2:StatusDate" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="../../ns2:RequirementInfo[last()]/ns2:StatusEvent[last()]/ns2:StatusEventDate" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </StatusDate>
    </xsl:if>
  </xsl:template>
  <xsl:template match="ns2:UserAuthRequest">
    <UserAuthRequest>
      <UserLoginName />
      <UserPswd>
        <CryptType>NONE</CryptType>
        <Pswd />
      </UserPswd>
      <VendorApp>
        <!--<VendorName VendorCode="84">Portamedic</VendorName>-->
        <VendorName VendorCode="118">CRL-Plus</VendorName>
        <AppName>XMLPROC</AppName>
        <AppVer>1.0.0</AppVer>
      </VendorApp>
    </UserAuthRequest>
  </xsl:template>
  <xsl:template match="ns2:StatusEvent[not(preceding-sibling::ns2:StatusEvent) and not(../../ns2:RequirementInfo[1]/ns2:StatusDate)]">
    <StatusDate>
      <xsl:value-of select="../ns2:StatusEvent[last()]/ns2:StatusEventDate" />
    </StatusDate>
    <StatusEvent>
      <xsl:apply-templates select="node()|@*" />
    </StatusEvent>
  </xsl:template>
  <xsl:template match="ns2:StatusDate[string-length(normalize-space(.))=0 and string-length(normalize-space(../../ns2:RequirementInfo[last()]/ns2:StatusEvent[last()]/ns2:StatusEventDate)) &gt; 0]">
    <StatusDate>
      <xsl:value-of select="../../ns2:RequirementInfo[last()]/ns2:StatusEvent[last()]/ns2:StatusEventDate" />
    </StatusDate>
  </xsl:template>
  <xsl:template match="ns2:StatusEventCode">
    <StatusEventCode tc="2147483647">Others</StatusEventCode>
  </xsl:template>
  <xsl:template name="format-time">
    <xsl:param name="time" />
    <xsl:variable name="timezone" select="datetime:format-date(datetime:date-time(),'Z')" />
    <xsl:if test="string-length(normalize-space($time))&gt;0">
      <xsl:value-of select="concat(normalize-space($time), substring($timezone,1,3), ':', substring($timezone,4,5))" />
    </xsl:if>
  </xsl:template>
  <xsl:template name="current-time">
    <xsl:value-of select="datetime:time()" />
  </xsl:template>
  <xsl:template name="format-date">
    <xsl:param name="date" />
    <xsl:choose>
      <xsl:when test="string-length($date) &gt; 8 and contains($date,' ')">
        <xsl:value-of select="substring-before(normalize-space($date),' ')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$date" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="current-date">
    <xsl:value-of select="datetime:format-date(datetime:date-time(),'yyyy-MM-dd')" />
  </xsl:template>
  <xsl:template name="TabularMapping_ReplaceStates">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>Alabama</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>Alaska</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3'">
        <xsl:text>American Samoa</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>Arizona</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>Arkansas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='60'">
        <xsl:text>Armed Forces Americas (except Canada)</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='61'">
        <xsl:text>"Armed Forces Canada, Africa, Europe, Middle East"</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='6'">
        <xsl:text>California</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='7'">
        <xsl:text>Colorado</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='8'">
        <xsl:text>Connecticut</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='9'">
        <xsl:text>Delaware</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='10'">
        <xsl:text>District of Columbia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='11'">
        <xsl:text>Federated States of Micronesia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>Florida</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>Georgia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='14'">
        <xsl:text>Guam</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='80'">
        <xsl:text>Guantanamo Bay (US Naval Base) Cuba</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='15'">
        <xsl:text>Hawaii</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='16'">
        <xsl:text>Idaho</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='17'">
        <xsl:text>Illinois</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='18'">
        <xsl:text>Indiana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='19'">
        <xsl:text>Iowa</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='20'">
        <xsl:text>Kansas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='21'">
        <xsl:text>Kentucky</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='22'">
        <xsl:text>Louisiana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='23'">
        <xsl:text>Maine</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='24'">
        <xsl:text>Marshall Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='25'">
        <xsl:text>Maryland</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='26'">
        <xsl:text>Massachusetts</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='27'">
        <xsl:text>Michigan</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='28'">
        <xsl:text>Minnesota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='29'">
        <xsl:text>Mississippi</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='30'">
        <xsl:text>Missouri</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='31'">
        <xsl:text>Montana</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='32'">
        <xsl:text>Nebraska</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='33'">
        <xsl:text>Nevada</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='34'">
        <xsl:text>New Hampshire</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='35'">
        <xsl:text>New Jersey</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='36'">
        <xsl:text>New Mexico</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='37'">
        <xsl:text>New York</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='38'">
        <xsl:text>North Carolina</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='39'">
        <xsl:text>North Dakota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='40'">
        <xsl:text>Northern Mariana Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='41'">
        <xsl:text>Ohio</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='42'">
        <xsl:text>Oklahoma</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='43'">
        <xsl:text>Oregon</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='44'">
        <xsl:text>Palau Island</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='45'">
        <xsl:text>Pennsylvania</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='46'">
        <xsl:text>Puerto Rico</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='47'">
        <xsl:text>Rhode Island</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='48'">
        <xsl:text>South Carolina</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='49'">
        <xsl:text>South Dakota</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='50'">
        <xsl:text>Tennessee</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='51'">
        <xsl:text>Texas</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='62'">
        <xsl:text>US Armed Forces Pacific</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='52'">
        <xsl:text>Utah</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='53'">
        <xsl:text>Vermont</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='55'">
        <xsl:text>Virginia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='54'">
        <xsl:text>Virgin Islands</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='56'">
        <xsl:text>Washington</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='57'">
        <xsl:text>West Virginia</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='58'">
        <xsl:text>Wisconsin</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='59'">
        <xsl:text>Wyoming</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="*" mode="copy">
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates select="@*|node()" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*|text()|comment()" mode="copy">
    <xsl:copy />
  </xsl:template>
</xsl:stylesheet>

