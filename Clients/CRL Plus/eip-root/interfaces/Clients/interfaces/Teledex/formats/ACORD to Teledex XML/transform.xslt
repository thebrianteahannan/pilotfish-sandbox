<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:sql="org.apache.xalan.lib.sql.XConnection" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:xdt="http://www.w3.org/2005/02/xpath-datatypes" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="ns1 converter ta td datetime dtFormatter" extension-element-prefixes="converter sql" version="1.0">
  <xsl:output indent="yes" method="xml" omit-xml-declaration="yes" />
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="sourceClient" select="ta:getAttribute($attributes, 'sourceClient')" />
  <xsl:variable name="defaultSourceInfoDescr" select="ta:getAttribute($attributes, 'defaultSourceInfoDescr')" />
  <xsl:template match="/ns1:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <XCSData>
      <xsl:variable name="driver" select="converter:getAttributeString('CLASS')" />
      <xsl:variable name="url">
        <xsl:variable name="url" select="converter:getAttributeString('URL')" />
        <xsl:value-of select="substring-before($url,'@')" />
        <xsl:value-of select="concat(converter:getAttributeString('USER'),'/')" />
        <xsl:value-of select="converter:getAttributeString('PWD')" />
        <xsl:value-of select="concat('@',substring-after($url,'@'))" />
      </xsl:variable>
      <!--
			<xsl:variable name="driver" select="'oracle.jdbc.driver.OracleDriver'" />
			<xsl:variable name="url" select="'jdbc:oracle:thin:crl_insight_to_pfish/test@mycomputer:1521:xe'" /> -->
      <xsl:variable name="sql" select="sql:new($driver,$url)" />
      <!-- Workaround for a bug in Xalan SQL extension? -->
      <!--
			<xsl:variable name="retries">
				<xsl:choose>
					<xsl:when test="string-length(ns1:RETRY_COUNT/text()) &gt; 0">
						<xsl:value-of select="ns1:RETRY_COUNT/text()" />
					</xsl:when>
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			-->
      <xsl:variable name="streaming" select="sql:disableStreamingMode($sql)" />
      <xsl:for-each select="ns1:TXLifeRequest">
        <xsl:variable name="txLifeRequest" select="." />
        <xsl:variable name="insuredParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=32]/@RelatedObjectID  or @id = ../ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc=1]/@PartyID]" />
        <xsl:variable name="agentParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=11 or ns1:RelationRoleCode/@tc=37]/@RelatedObjectID or @id = ../ns1:Holding/ns1:Policy/ns1:Life/ns1:Coverage/ns1:LifeParticipant[ns1:LifeParticipantRoleCode/@tc=15]/@PartyID]" />
        <xsl:variable name="agencyParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=182]/@RelatedObjectID]" />
        <xsl:variable name="benParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=34]/@RelatedObjectID]" />
        <xsl:variable name="physicianParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=41]/@RelatedObjectID]" />
        <xsl:variable name="empParty" select="ns1:OLifE/ns1:Party[@id = ../ns1:Relation[ns1:RelationRoleCode/@tc=7]/@RelatedObjectID]" />
        <xsl:variable name="policy" select="ns1:OLifE/ns1:Holding/ns1:Policy" />
        <xsl:variable name="transMode" select="ns1:TransMode/@tc" />
        <xsl:variable name="reqCode1">
          <xsl:variable name="value" select="$policy/ns1:RequirementInfo[1]/ns1:ReqCode/@tc" />
          <xsl:if test="string-length($value) = 3">0</xsl:if>
          <xsl:if test="string-length($value) = 2">00</xsl:if>
          <xsl:value-of select="$value" />
        </xsl:variable>
        <xsl:variable name="reqCode2">
          <xsl:variable name="value" select="$policy/ns1:RequirementInfo[2]/ns1:ReqCode/@tc" />
          <xsl:if test="string-length($value) = 3">0</xsl:if>
          <xsl:if test="string-length($value) = 2">00</xsl:if>
          <xsl:value-of select="$value" />
        </xsl:variable>
        <xsl:variable name="releasePartyOrgCode" select="$policy/ns1:RequirementInfo/ns1:ReleasePartyOrgCode" />
        <xsl:variable name="remoteID">
          <xsl:choose>
            <xsl:when test="string-length($txLifeRequest/ns1:OLifEExtension[@VendorCode='118' and @ExtensionCode='1000']/ns1:TeledexRemoteID) &gt; 0">
              <xsl:call-template name="uppercase">
                <xsl:with-param name="value">
                  <xsl:value-of select="$txLifeRequest/ns1:OLifEExtension[@VendorCode='118' and @ExtensionCode='1000']/ns1:TeledexRemoteID" />
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="uppercase">
                <xsl:with-param name="value">
                  <xsl:value-of select="$releasePartyOrgCode" />
                </xsl:with-param>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="remoteClient">
          <xsl:choose>
            <xsl:when test="$remoteID='AIGP' or $remoteID='AIGT'">
              <xsl:value-of select="'AIGP'" />
            </xsl:when>
            <xsl:when test="$remoteID='ELFP' or $remoteID='ELFT'">
              <xsl:value-of select="'ELFP'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'PPLN'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <XCSRecord row="{position()}">
          <BRANCH>
            <!-- ReleasePartyOrgCode  -->
            <!--	<xsl:value-of select="$sourceClient" /> -->
            <xsl:value-of select="$remoteID" />
            <!-- Store the remote id in an attribute so that we can also send it to FlowNet -->
            <xsl:variable name="remoteIDAttrName" select="concat('teledex.remoteid.for.transrefguid.',$txLifeRequest/ns1:TransRefGUID)" />
            <xsl:variable name="storeRemoteID" select="ta:setAttribute($attributes, $remoteIDAttrName, string($remoteID))" />
          </BRANCH>
          <ORDERNO>
            <xsl:variable name="orderno">
              <xsl:choose>
                <xsl:when test="string-length($txLifeRequest/ns1:OLifEExtension[@VendorCode='118' and @ExtensionCode='1000']/ns1:TeledexOrderNumber) &gt; 0">
                  <xsl:call-template name="normalizeAmount">
                    <xsl:with-param name="inputVal">
                      <xsl:value-of select="$txLifeRequest/ns1:OLifEExtension[@VendorCode='118' and @ExtensionCode='1000']/ns1:TeledexOrderNumber" />
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="$remoteClient='AIGP'">
                  <xsl:variable name="aigp" select="sql:query($sql, 'select ORDERNUM_AIG_SEQ.NEXTVAL FROM DUAL')" />
                  <xsl:value-of select="$aigp/sql" />
                </xsl:when>
                <xsl:when test="$remoteClient='ELFP'">
                  <xsl:variable name="erie" select="sql:query($sql, 'select ORDERNUM_ERIE_SEQ.NEXTVAL FROM DUAL')" />
                  <xsl:value-of select="$erie/sql" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="ppln" select="sql:query($sql, 'select ORDERNUM_PPLN_SEQ.NEXTVAL FROM DUAL')" />
                  <xsl:value-of select="$ppln/sql" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="string-length($orderno) &gt; 0">
                <xsl:value-of select="$orderno" />
                <!-- Store the order number in an attribute so that we can also send it to FlowNet -->
                <xsl:variable name="attrName" select="concat('teledex.ordernum.for.transrefguid.',$txLifeRequest/ns1:TransRefGUID)" />
                <xsl:variable name="storeOrderNum" select="ta:setAttribute($attributes, $attrName, string($orderno))" />
              </xsl:when>
              <xsl:otherwise>
                <!--
								<xsl:message terminate="yes">
									<xsl:value-of select="concat('ORDERNO is blank','&#xA;')" />
									<xsl:copy-of select="exsl:node-set(sql:getError($sql)/ext-error)" />
								</xsl:message>
	-->
                <xsl:variable name="Retry">
                  <xsl:variable name="retry" select="ta:getAttribute($attributes,'Retry.Count')" />
                  <xsl:choose>
                    <xsl:when test="string-length($retry) &gt; 0">
                      <xsl:value-of select="$retry" />
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:variable name="storeRetryNum" select="ta:setAttribute($attributes, 'Retry.Count', string($Retry))" />
                <xsl:value-of select="concat('ERROR-',$Retry)" />
              </xsl:otherwise>
            </xsl:choose>
          </ORDERNO>
          <xsl:variable name="orderDate">
            <xsl:variable name="reqDate" select="$policy/ns1:RequirementInfo/ns1:RequestedDate" />
            <xsl:choose>
              <xsl:when test="string-length($reqDate) &gt; 0">
                <xsl:call-template name="formatDate">
                  <xsl:with-param name="value" select="$reqDate" />
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="datetime:year()" />
                <xsl:call-template name="makeTwoDigit">
                  <xsl:with-param name="value">
                    <xsl:value-of select="datetime:month-in-year()" />
                  </xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="makeTwoDigit">
                  <xsl:with-param name="value">
                    <xsl:value-of select="datetime:day-in-month()" />
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <ORDER_DATE>
            <!-- RequirementInfo.RequestedDate -->
            <xsl:value-of select="$orderDate" />
          </ORDER_DATE>
          <ORDER_TYPE>
            <!-- Mapping based on Mahesh's Bill Code Mapping notes for Order Type -->
            <xsl:call-template name="orderTypeMapping">
              <xsl:with-param name="value" select="$reqCode1" />
              <xsl:with-param name="value2" select="$reqCode2" />
            </xsl:call-template>
            <!-- Below is order type mapping on last notes that AIG is 'I' and everything else is 'T'
						<xsl:choose>
							<xsl:when test="starts-with($remoteClient,'AIG')">I</xsl:when>
							<xsl:otherwise>T</xsl:otherwise>
						</xsl:choose>
						-->
          </ORDER_TYPE>
          <RUSH>
            <!-- If ORIGINAL, this will be empty
							 If UPDATE, this will be 'Adhoc'
							 IF CANCEL, this will be 'Cancel'
						-->
            <xsl:choose>
              <xsl:when test="$transMode='6'">Cancel</xsl:when>
              <xsl:when test="$transMode='5'">ADHOC</xsl:when>
            </xsl:choose>
          </RUSH>
          <ORIGIN>C</ORIGIN>
          <AGENT>
            <!-- Party(Agent).FullName -->
            <xsl:choose>
              <xsl:when test="string-length($agentParty/ns1:FullName) &gt; 0">
                <xsl:value-of select="$agentParty/ns1:FullName" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="agentPerson" select="$agentParty/ns1:Person" />
                <!--
								<xsl:value-of select="normalize-space(concat($agentPerson/ns1:FirstName,' ',$agentPerson/ns1:MiddleName,' ',$agentPerson/ns1:LastName))" />
								-->
                <xsl:value-of select="$agentPerson/ns1:FirstName" />
              </xsl:otherwise>
            </xsl:choose>
          </AGENT>
          <AGENT_CD>
            <!-- CompanyProducerID -->
            <xsl:value-of select="$agentParty/ns1:Producer/ns1:CarrierAppointment/ns1:CompanyProducerID" />
          </AGENT_CD>
          <AGENCY>
            <!-- Party(Agency).FullName -->
            <xsl:choose>
              <xsl:when test="string-length($agencyParty/ns1:FullName) &gt; 0">
                <xsl:value-of select="$agencyParty/ns1:FullName" />
              </xsl:when>
              <xsl:when test="string-length($agencyParty/ns1:Organization/ns1:AbbrName) &gt; 0">
                <xsl:value-of select="$agencyParty/ns1:Organization/ns1:AbbrName" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="agencyPerson" select="$agencyParty/ns1:Person" />
                <xsl:value-of select="normalize-space(concat($agencyPerson/ns1:FirstName,' ',$agencyPerson/ns1:MiddleName,' ',$agencyPerson/ns1:LastName))" />
              </xsl:otherwise>
            </xsl:choose>
          </AGENCY>
          <AGENCY_CDE>
            <!-- CompanyProducerID -->
            <xsl:value-of select="$agencyParty/ns1:Producer/ns1:CarrierAppointment/ns1:CompanyProducerID" />
          </AGENCY_CDE>
          <AGENCY_PH>
            <!-- Party(Agency).Phone-->
            <xsl:variable name="agencyPhone" select="$agencyParty/ns1:Phone[not(ns1:PhoneTypeCode/@tc='4' or ns1:PhoneTypeCode/@tc='19' or ns1:PhoneTypeCode/@tc='15')][1]" />
            <xsl:call-template name="formatPhone">
              <xsl:with-param name="value" select="concat($agencyPhone/ns1:AreaCode,$agencyPhone/ns1:DialNumber)" />
            </xsl:call-template>
          </AGENCY_PH>
          <AGENCY_FAX>
            <!-- Party(Agency).Phone -->
            <xsl:variable name="agencyFax" select="$agencyParty/ns1:Phone[ns1:PhoneTypeCode/@tc='4' or ns1:PhoneTypeCode/@tc='19' or ns1:PhoneTypeCode/@tc='15'][1]" />
            <xsl:call-template name="formatPhone">
              <xsl:with-param name="value" select="concat($agencyFax/ns1:AreaCode,$agencyFax/ns1:DialNumber)" />
            </xsl:call-template>
          </AGENCY_FAX>
          <!--
					<xsl:variable name="reqAcctNum" select="$policy/ns1:RequirementInfo/ns1:RequirementAcctNum" /> -->
          <xsl:variable name="reqAcctNum">
            <xsl:variable name="reqAcctNumber" select="$policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
            <xsl:call-template name="reqAcctNumMapping">
              <xsl:with-param name="value" select="$reqAcctNumber" />
            </xsl:call-template>
            <!--<xsl:choose>-->
            <!--<xsl:when test="$reqAcctNumber='71438' or $reqAcctNumber='1044'">-->
            <!--<xsl:value-of select="'71437'" />-->
            <!--</xsl:when>-->
            <!--<xsl:otherwise>-->
            <!--<xsl:value-of select="$reqAcctNumber" />-->
            <!--</xsl:otherwise>-->
            <!--</xsl:choose>-->
          </xsl:variable>
          <xsl:variable name="clientName">
            <xsl:call-template name="clientNameMapping">
              <xsl:with-param name="value" select="$reqAcctNum" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="orderType">
            <xsl:call-template name="orderTypeMapping">
              <xsl:with-param name="value" select="$reqCode1" />
              <xsl:with-param name="value2" select="$reqCode2" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$orderType='T'">
              <!-- ## Filled if order type is TeleInterview ** Need to have the trailing dash ** RequirementAcctNum in Acord ## -->
              <P_CLIENT>
                <xsl:value-of select="$clientName" />
              </P_CLIENT>
              <P_ACCOUNT>
                <xsl:value-of select="concat(substring($reqAcctNum,1,5),'-')" />
              </P_ACCOUNT>
              <A_CLIENT />
              <A_ACCOUNT />
              <I_CLIENT />
              <I_ACCOUNT />
            </xsl:when>
            <xsl:when test="$orderType='A'">
              <!-- ## Filled if order type is APS : Attending Physician Statement ** Need to have the trailing dash ** RequirementAcctNum in Acord ## -->
              <P_CLIENT />
              <P_ACCOUNT />
              <A_CLIENT>
                <xsl:value-of select="$clientName" />
              </A_CLIENT>
              <A_ACCOUNT>
                <xsl:value-of select="concat(substring($reqAcctNum,1,5),'-')" />
              </A_ACCOUNT>
              <I_CLIENT />
              <I_ACCOUNT />
            </xsl:when>
            <xsl:when test="$orderType='I'">
              <!-- ## Filled if order type is Inspection ** Need to have the trailing dash ** RequirementAcctNum in Acord ## -->
              <P_CLIENT />
              <P_ACCOUNT />
              <A_CLIENT />
              <A_ACCOUNT />
              <I_CLIENT>
                <xsl:value-of select="$clientName" />
              </I_CLIENT>
              <I_ACCOUNT>
                <xsl:value-of select="concat(substring($reqAcctNum,1,5),'-')" />
              </I_ACCOUNT>
            </xsl:when>
          </xsl:choose>
          <PRO_INS_NO />
          <INSUR_CODE />
          <POL_AMT>
            <xsl:call-template name="normalizeAmount">
              <xsl:with-param name="inputVal">
                <xsl:choose>
                  <xsl:when test="$remoteClient='ELFP' and string-length($policy/ns1:Life/ns1:Coverage/ns1:CurrentAmt) &gt; 0">
                    <xsl:value-of select="$policy/ns1:Life/ns1:Coverage/ns1:CurrentAmt" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="string-length($policy/ns1:Life/ns1:FaceAmt) &gt; 0">
                        <xsl:value-of select="$policy/ns1:Life/ns1:FaceAmt" />
                      </xsl:when>
                      <xsl:when test="string-length($policy/ns1:Life/ns1:Coverage/ns1:CurrentAmt) &gt; 0">
                        <xsl:value-of select="$policy/ns1:Life/ns1:Coverage/ns1:CurrentAmt" />
                      </xsl:when>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
            </xsl:call-template>
          </POL_AMT>
          <USAGE_CDE />
          <APL_SI_DT />
          <POL_TYPE>
            <xsl:choose>
              <xsl:when test="$remoteClient='PPLN'">
                <xsl:value-of select="'L'" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring($policy/ns1:ProductType,1,1)" />
              </xsl:otherwise>
            </xsl:choose>
          </POL_TYPE>
          <SUB_PTYPE />
          <POLICY>
            <xsl:value-of select="$policy/ns1:PolNumber" />
          </POLICY>
          <APP_ORD_ID />
          <APP_PREFIX>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:Prefix" />
          </APP_PREFIX>
          <APP_FNAME>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:FirstName" />
          </APP_FNAME>
          <APP_MNAME>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:MiddleName" />
          </APP_MNAME>
          <APP_LNAME>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:LastName" />
          </APP_LNAME>
          <APP_SUFFIX>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:Suffix" />
          </APP_SUFFIX>
          <APP_FALIAS>
            <xsl:value-of select="$insuredParty/ns1:PriorName/ns1:FirstName" />
          </APP_FALIAS>
          <APP_MALIAS>
            <xsl:value-of select="$insuredParty/ns1:PriorName/ns1:MiddleName" />
          </APP_MALIAS>
          <APP_LALIAS>
            <xsl:value-of select="$insuredParty/ns1:PriorName/ns1:LastName" />
          </APP_LALIAS>
          <APP_GENDER>
            <xsl:variable name="insuredGender" select="$insuredParty/ns1:Person/ns1:Gender" />
            <xsl:choose>
              <xsl:when test="$insuredGender/@tc=1 or starts-with($insuredGender,'M') or starts-with($insuredGender, 'm')">
                <xsl:value-of select="'M'" />
              </xsl:when>
              <xsl:when test="$insuredGender/@tc=2 or starts-with($insuredGender,'F') or starts-with($insuredGender, 'f')">
                <xsl:value-of select="'F'" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="''" />
              </xsl:otherwise>
            </xsl:choose>
          </APP_GENDER>
          <APP_SMOKER>
            <!--
						<xsl:variable name="smoker" select="$insuredParty/ns1:Person/ns1:SmokerStat" />
						<xsl:choose>
							<xsl:when test="$smoker/@tc='1'">
								<xsl:text>N</xsl:text>
							</xsl:when>
							<xsl:when test="$smoker/@tc='3'">
								<xsl:text>Y</xsl:text>
							</xsl:when>
						</xsl:choose>
						-->
          </APP_SMOKER>
          <APP_MAR_ST>
            <xsl:choose>
              <xsl:when test="$remoteClient='PPLN' and $reqAcctNum='71711'">
                <xsl:value-of select="'S'" />
              </xsl:when>
              <xsl:otherwise>
                <!--
								<xsl:call-template name="appMarSt">
									<xsl:with-param name="value" select="substring($insuredParty/ns1:Person/ns1:MarStat,1,1)" />
									<xsl:with-param name="tc" select="$insuredParty/ns1:Person/ns1:MarStat/@tc" />
								</xsl:call-template>
								-->
                <xsl:if test="string-length($insuredParty/ns1:Person/ns1:MarStat) &gt; 0">
                  <xsl:value-of select="translate(substring($insuredParty/ns1:Person/ns1:MarStat,1,1),'dlmsw','DLMSW')" />
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </APP_MAR_ST>
          <APP_SOC>
            <xsl:call-template name="formatSSN">
              <xsl:with-param name="value" select="$insuredParty/ns1:GovtID" />
            </xsl:call-template>
          </APP_SOC>
          <APP_DOB>
            <xsl:variable name="dob" select="normalize-space($insuredParty/ns1:Person/ns1:BirthDate)" />
            <xsl:if test="string-length($dob)=10">
              <xsl:value-of select="dtFormatter:format($dob,'yyyy-MM-dd','yyyyMMdd')" />
            </xsl:if>
          </APP_DOB>
          <APP_AGE>
            <!--
						<xsl:variable name="current-date" select="datetime:date()" />-->
            <xsl:choose>
              <xsl:when test="normalize-space($insuredParty/ns1:Person/ns1:Age)">
                <xsl:call-template name="normalizeAmount">
                  <xsl:with-param name="inputVal">
                    <xsl:value-of select="normalize-space($insuredParty/ns1:Person/ns1:Age)" />
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="dob" select="normalize-space($insuredParty/ns1:Person/ns1:BirthDate)" />
                <xsl:if test="string-length($dob)=10">
                  <xsl:variable name="y1" select="substring($dob, 1, 4)" />
                  <xsl:variable name="y2" select="substring($orderDate, 1, 4)" />
                  <xsl:variable name="m1" select="substring($dob, 6, 2)" />
                  <xsl:variable name="m2" select="substring($orderDate, 5, 2)" />
                  <xsl:variable name="d1" select="substring($dob, 9, 2)" />
                  <xsl:variable name="d2" select="substring($orderDate, 7, 2)" />
                  <xsl:choose>
                    <xsl:when test="$m2 &lt; $m1 or ($m2=$m1 and $d2 &lt; $d1)">
                      <xsl:value-of select="($y2 - $y1 - 1)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="($y2 - $y1)" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </APP_AGE>
          <PLAC_BIRTH>
            <!--
						<xsl:value-of select="$insuredParty/ns1:Person/ns1:BirthJurisdictionTC" /> -->
          </PLAC_BIRTH>
          <CTRY_CITZN>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:Citizenship" />
          </CTRY_CITZN>
          <EXAM_PLAC />
          <CONT_HME_B />
          <CONT_HME_E />
          <xsl:variable name="insuredAddress2" select="$insuredParty/ns1:Address[1]" />
          <xsl:variable name="insuredPhone" select="$insuredParty/ns1:Phone[1]" />
          <xsl:variable name="phone">
            <xsl:variable name="phone">
              <xsl:call-template name="formatPhone">
                <xsl:with-param name="value" select="concat($insuredPhone/ns1:AreaCode,$insuredPhone/ns1:DialNumber)" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="string-length($phone)=9">0</xsl:when>
              <xsl:when test="string-length($phone)=8">00</xsl:when>
            </xsl:choose>
            <xsl:value-of select="$phone" />
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$remoteClient='PPLN' and $reqAcctNum='71711'">
              <ADR1_NAME />
              <ADR1_ADR1>
                <xsl:value-of select="$insuredAddress2/ns1:Line1" />
              </ADR1_ADR1>
              <ADR1_ADR2>
                <xsl:value-of select="$insuredAddress2/ns1:Line2" />
              </ADR1_ADR2>
              <ADR1_CITY>
                <xsl:value-of select="normalize-space($insuredAddress2/ns1:City)" />
              </ADR1_CITY>
              <ADR1_ST>
                <xsl:choose>
                  <xsl:when test="string-length($insuredAddress2/ns1:AddressStateTC/@tc) &gt; 0">
                    <xsl:call-template name="TCToStateMapping">
                      <xsl:with-param name="value" select="$insuredAddress2/ns1:AddressStateTC/@tc" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:when test="string-length($insuredAddress2/ns1:AddressState) &gt; 0">
                    <xsl:value-of select="$insuredAddress2/ns1:AddressState" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$insuredAddress2/ns1:AddressStateTC" />
                  </xsl:otherwise>
                </xsl:choose>
              </ADR1_ST>
              <ADR1_ZIP1>
                <xsl:value-of select="substring($insuredAddress2/ns1:Zip,1,5)" />
              </ADR1_ZIP1>
              <ADR1_ZIP2>
                <!--
								<xsl:value-of select="substring($insuredAddress2/ns1:Zip,7,4)" /> -->
              </ADR1_ZIP2>
              <ADR1_CTRY />
              <ADR1_PH>
                <xsl:value-of select="$phone" />
              </ADR1_PH>
              <ADR1_EXT>
                <xsl:value-of select="$insuredPhone/ns1:Ext" />
              </ADR1_EXT>
            </xsl:when>
            <xsl:otherwise>
              <ADR1_NAME />
              <ADR1_ADR1 />
              <ADR1_ADR2 />
              <ADR1_CITY />
              <ADR1_ST />
              <ADR1_ZIP1 />
              <ADR1_ZIP2 />
              <ADR1_CTRY />
              <ADR1_PH />
              <ADR1_EXT />
            </xsl:otherwise>
          </xsl:choose>
          <RES_BDATE />
          <RES_EDATE />
          <ADR2_PLAC />
          <ADR2_NAME />
          <ADR2_ADR1>
            <xsl:choose>
              <xsl:when test="$reqAcctNum='279833'">
                <xsl:value-of select="substring($insuredAddress2/ns1:Line1,1,20)" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$insuredAddress2/ns1:Line1" />
              </xsl:otherwise>
            </xsl:choose>
          </ADR2_ADR1>
          <ADR2_ADR2>
            <xsl:value-of select="$insuredAddress2/ns1:Line2" />
          </ADR2_ADR2>
          <ADR2_CITY>
            <xsl:value-of select="normalize-space($insuredAddress2/ns1:City)" />
          </ADR2_CITY>
          <ADR2_ST>
            <xsl:choose>
              <xsl:when test="string-length($insuredAddress2/ns1:AddressStateTC/@tc) &gt; 0">
                <xsl:call-template name="TCToStateMapping">
                  <xsl:with-param name="value" select="$insuredAddress2/ns1:AddressStateTC/@tc" />
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="string-length($insuredAddress2/ns1:AddressState) &gt; 0">
                <xsl:value-of select="$insuredAddress2/ns1:AddressState" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$insuredAddress2/ns1:AddressStateTC" />
              </xsl:otherwise>
            </xsl:choose>
          </ADR2_ST>
          <ADR2_ZIP1>
            <xsl:value-of select="substring($insuredAddress2/ns1:Zip,1,5)" />
          </ADR2_ZIP1>
          <ADR2_ZIP2>
            <!--
						<xsl:value-of select="substring($insuredAddress2/ns1:Zip,7,4)" />-->
          </ADR2_ZIP2>
          <ADR2_CTRY>
            <!--
						<xsl:value-of select="$insuredAddress2/ns1:AddressCountryTC" />
						-->
          </ADR2_CTRY>
          <ADR2_PH>
            <xsl:value-of select="translate($phone,'-','')" />
          </ADR2_PH>
          <ADR2_EXT>
            <xsl:value-of select="$insuredPhone/ns1:Ext" />
          </ADR2_EXT>
          <xsl:variable name="remarks">
            <!--
						<xsl:choose>
							<xsl:when test="$remoteClient='PPLN'">
								<xsl:for-each select="ns1:OLifE/ns1:Holding/ns1:Attachment/ns1:AttachmentData">
									<xsl:variable name="int" select="position()" />
									<xsl:if test="$int&gt;1">
										<xsl:value-of select="concat('%',$int,'%')" />
									</xsl:if>
									<xsl:value-of select="." />
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
							-->
            <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Attachment[ns1:AttachmentType/@tc='2']/ns1:Description" />
            <!--
							</xsl:otherwise>
						</xsl:choose>
						-->
          </xsl:variable>
          <xsl:variable name="remarksFix">
            <xsl:variable name="remove-comma-between-zeros">
              <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$remarks" />
                <xsl:with-param name="replace" select="',0'" />
                <xsl:with-param name="by" select="'0'" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="remove-comma-between-zeros2">
              <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$remove-comma-between-zeros" />
                <xsl:with-param name="replace" select="',5'" />
                <xsl:with-param name="by" select="'5'" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="add-another-double-quote">
              <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$remove-comma-between-zeros2" />
                <xsl:with-param name="replace">"</xsl:with-param>
                <xsl:with-param name="by">""</xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="strip-newlines">
              <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$add-another-double-quote" />
                <xsl:with-param name="replace">
                  <xsl:text>#x0A</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="by" select="' '" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$remoteClient='ELFP'">
                <xsl:variable name="removed-commas">
                  <xsl:call-template name="string-replace-all">
                    <xsl:with-param name="text" select="$strip-newlines" />
                    <xsl:with-param name="replace" select="', '" />
                    <xsl:with-param name="by" select="''" />
                  </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="',' = substring($removed-commas,string-length($removed-commas)-string-length(',')+1)">
                    <xsl:value-of select="normalize-space(substring($removed-commas,1,string-length($removed-commas)-string-length(',')))" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space($removed-commas)" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="normalize-space($strip-newlines)" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <REMARKS1>
            <xsl:choose>
              <xsl:when test="$remoteClient='PPLN'">
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Attachment[1]/ns1:AttachmentData" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring($remarksFix, 1, 60)" />
              </xsl:otherwise>
            </xsl:choose>
          </REMARKS1>
          <REMARKS2>
            <xsl:choose>
              <xsl:when test="$remoteClient='PPLN'">
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Attachment[2]/ns1:AttachmentData" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring($remarksFix, 61, 60)" />
              </xsl:otherwise>
            </xsl:choose>
          </REMARKS2>
          <REMARKS3>
            <xsl:choose>
              <xsl:when test="$remoteClient='PPLN'">
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Attachment[3]/ns1:AttachmentData" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring($remarksFix, 121, 60)" />
              </xsl:otherwise>
            </xsl:choose>
          </REMARKS3>
          <REMARKS4>
            <xsl:choose>
              <xsl:when test="$remoteClient='PPLN'">
                <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Attachment[4]/ns1:AttachmentData" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring($remarksFix, 181, 60)" />
              </xsl:otherwise>
            </xsl:choose>
          </REMARKS4>
          <PRC_LST />
          <BILL_ST />
          <!--
						Refer to Bill Code Mapping for BILL_CD1 to BILL_CD9

						"Acord sends ReqCode.  Process translates Req code to Hooper Bill (service) codes.  Eg Erie sends '137'.  Bill code is ""419"".
						Up to 9 can be requested.  " (eg, Erie sends '137' Bill code is '419'). Sample contain 300 and 419 for 1st, 2nd contains 704 and 210
					-->
          <xsl:call-template name="billCodeMapping">
            <xsl:with-param name="value" select="$reqCode1" />
            <xsl:with-param name="value2" select="$reqCode2" />
          </xsl:call-template>
          <LAB />
          <EXAMINER />
          <EXM_SOC />
          <EXAMNR_CDE />
          <APPT_DATE />
          <APPT_TIME />
          <APPT_PM />
          <TO_EXAMNER />
          <SCHD_DATE>
            <xsl:choose>
              <xsl:when test="string-length($policy/ns1:RequirementInfo/ns1:ScheduledDate) = 10">
                <xsl:value-of select="dtFormatter:format($policy/ns1:RequirementInfo/ns1:ScheduledDate,'yyyy-MM-dd','yyyyMMdd')" />
              </xsl:when>
              <xsl:when test="string-length($policy/ns1:RequirementInfo/ns1:RequestedScheduleDate)=10">
                <xsl:value-of select="dtFormatter:format($policy/ns1:RequirementInfo/ns1:RequestedScheduleDate,'yyyy-MM-dd','yyyyMMdd')" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="''" />
              </xsl:otherwise>
            </xsl:choose>
          </SCHD_DATE>
          <STATUS />
          <TRANTONO />
          <SPARE_DATE />
          <SPARE_FLD />
          <FOLLOW_DTE />
          <FOLLOW_FLD />
          <AIM />
          <PHY_FNAME>
            <xsl:choose>
              <xsl:when test="string-length($physicianParty/ns1:Person/ns1:FirstName) &gt; 0">
                <xsl:value-of select="$physicianParty/ns1:Person/ns1:FirstName" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$physicianParty/ns1:FullName" />
              </xsl:otherwise>
            </xsl:choose>
          </PHY_FNAME>
          <PHY_MNAME>
            <xsl:value-of select="$physicianParty/ns1:Person/ns1:MiddleName" />
          </PHY_MNAME>
          <PHY_LNAME>
            <xsl:value-of select="$physicianParty/ns1:Person/ns1:LastName" />
          </PHY_LNAME>
          <xsl:variable name="physicianAddress" select="$physicianParty/ns1:Address[1]" />
          <PHY_ADR1>
            <xsl:value-of select="$physicianAddress/ns1:Line1" />
          </PHY_ADR1>
          <PHY_ADR2>
            <xsl:value-of select="$physicianAddress/ns1:Line2" />
          </PHY_ADR2>
          <PHY_CITY>
            <xsl:value-of select="$physicianAddress/ns1:City" />
          </PHY_CITY>
          <PHY_ST>
            <xsl:choose>
              <xsl:when test="string-length($physicianAddress/ns1:AddressStateTC/@tc) &gt; 0">
                <xsl:call-template name="TCToStateMapping">
                  <xsl:with-param name="value" select="$physicianAddress/ns1:AddressStateTC/@tc" />
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="string-length($physicianAddress/ns1:AddressState) &gt; 0">
                <xsl:value-of select="$physicianAddress/ns1:AddressState" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$physicianAddress/ns1:AddressStateTC" />
              </xsl:otherwise>
            </xsl:choose>
          </PHY_ST>
          <PHY_ZIP1>
            <xsl:value-of select="substring($physicianAddress/ns1:Zip,1,5)" />
          </PHY_ZIP1>
          <PHY_ZIP2>
            <xsl:value-of select="substring($physicianAddress/ns1:Zip,7,4)" />
          </PHY_ZIP2>
          <PHY_CTRY>
            <xsl:value-of select="$physicianAddress/ns1:AddressCountryTC" />
          </PHY_CTRY>
          <PHY_PHONE>
            <xsl:variable name="physicianPhone" select="$physicianParty/ns1:Phone[1]" />
            <xsl:call-template name="formatPhone">
              <xsl:with-param name="value" select="concat($physicianPhone/ns1:AreaCode,$physicianPhone/ns1:DialNumber)" />
            </xsl:call-template>
          </PHY_PHONE>
          <PHY_FAX>
            <xsl:variable name="physicianFax" select="$physicianParty/ns1:Phone[ns1:PhoneTypeCode/@tc='4' or ns1:PhoneTypeCode/@tc='19' or ns1:PhoneTypeCode/@tc='15'][1]" />
            <xsl:call-template name="formatPhone">
              <xsl:with-param name="value" select="concat($physicianFax/ns1:AreaCode,$physicianFax/ns1:DialNumber)" />
            </xsl:call-template>
          </PHY_FAX>
          <APS_DATE />
          <BEN_PREFIX>
            <xsl:value-of select="$benParty/ns1:Person/ns1:Prefix" />
          </BEN_PREFIX>
          <BEN_FNAME>
            <!--
						<xsl:choose>
							<xsl:when test="string-length($benParty/ns1:Person/ns1:FirstName) &gt; 0">
								<xsl:value-of select="$benParty/ns1:Person/ns1:FirstName" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$benParty/ns1:FullName" />
							</xsl:otherwise>
						</xsl:choose>
						-->
            <xsl:variable name="benFirstName">
              <xsl:value-of select="$benParty/ns1:Person/ns1:FirstName" />
              <xsl:value-of select="' '" />
              <xsl:value-of select="$benParty/ns1:Person/ns1:MiddleName" />
              <xsl:value-of select="' '" />
              <xsl:value-of select="$benParty/ns1:Person/ns1:LastName" />
            </xsl:variable>
            <xsl:value-of select="substring($benFirstName,1,15)" />
          </BEN_FNAME>
          <BEN_MNAME>
            <!--
						<xsl:value-of select="$benParty/ns1:Person/ns1:MiddleName" />-->
          </BEN_MNAME>
          <BEN_LNAME>
            <!--
						<xsl:value-of select="$benParty/ns1:Person/ns1:LastName" /> -->
          </BEN_LNAME>
          <BEN_SUFFIX>
            <!--
						<xsl:value-of select="$benParty/ns1:Person/ns1:Suffix" /> -->
          </BEN_SUFFIX>
          <BEN_COMP />
          <BEN_AGE />
          <BEN_TYPE />
          <BEN_RELAT>
            <xsl:value-of select="ns1:OLifE/ns1:Relation[ns1:RelationRoleCode/@tc=34]/ns1:RelationDescription" />
          </BEN_RELAT>
          <EMPLOYER>
            <xsl:choose>
              <xsl:when test="string-length($empParty/ns1:FullName) &gt; 0">
                <xsl:value-of select="$empParty/ns1:FullName" />
              </xsl:when>
              <xsl:when test="string-length($empParty/ns1:Organization/ns1:AbbrName) &gt; 0">
                <xsl:value-of select="$empParty/ns1:Organization/ns1:AbbrName" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="empPerson" select="$empParty/ns1:Person" />
                <xsl:value-of select="normalize-space(concat($empPerson/ns1:FirstName,' ',$empPerson/ns1:MiddleName,' ',$empPerson/ns1:LastName))" />
              </xsl:otherwise>
            </xsl:choose>
          </EMPLOYER>
          <xsl:variable name="empAddress" select="$empParty/ns1:Address[1]" />
          <EMPL_ADR1>
            <xsl:value-of select="$empAddress/ns1:Line1" />
          </EMPL_ADR1>
          <EMPL_ADR2>
            <xsl:value-of select="$empAddress/ns1:Line2" />
          </EMPL_ADR2>
          <EMPL_CITY>
            <xsl:value-of select="$empAddress/ns1:City" />
          </EMPL_CITY>
          <EMPL_ST>
            <xsl:choose>
              <xsl:when test="string-length($empAddress/ns1:AddressStateTC/@tc) &gt; 0">
                <xsl:call-template name="TCToStateMapping">
                  <xsl:with-param name="value" select="$empAddress/ns1:AddressStateTC/@tc" />
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="string-length($empAddress/ns1:AddressState) &gt; 0">
                <xsl:value-of select="$empAddress/ns1:AddressState" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$empAddress/ns1:AddressStateTC" />
              </xsl:otherwise>
            </xsl:choose>
          </EMPL_ST>
          <EMPL_ZIP1>
            <xsl:value-of select="substring($empAddress/ns1:Zip,1,5)" />
          </EMPL_ZIP1>
          <EMPL_ZIP2>
            <xsl:value-of select="substring($empAddress/ns1:Zip,7,4)" />
          </EMPL_ZIP2>
          <EMPL_CTRY>
            <xsl:value-of select="$empAddress/ns1:AddressCountryTC" />
          </EMPL_CTRY>
          <xsl:variable name="empPhone" select="$empParty/ns1:Phone" />
          <EMPL_PH>
            <xsl:variable name="phone">
              <xsl:call-template name="formatPhone">
                <xsl:with-param name="value" select="concat($empPhone/ns1:AreaCode,$empPhone/ns1:DialNumber)" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="string-length($phone)=9">0</xsl:when>
              <xsl:when test="string-length($phone)=8">00</xsl:when>
              <xsl:when test="string-length($phone)=3 and number($phone)=$phone">0000000</xsl:when>
            </xsl:choose>
            <xsl:value-of select="$phone" />
          </EMPL_PH>
          <EMPL_EXT>
            <xsl:value-of select="$empPhone/ns1:Ext" />
          </EMPL_EXT>
          <OCCUPATION>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:Occupation" />
          </OCCUPATION>
          <CONT_EMP_B />
          <CONT_EMP_H />
          <EMPL_BDTE />
          <EMPL_EDTE />
          <INF_DATE />
          <DRV_LIC>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:DriversLicenseNum" />
          </DRV_LIC>
          <ISSUE_ST>
            <xsl:value-of select="$insuredParty/ns1:Person/ns1:DriversLicenseState" />
          </ISSUE_ST>
          <MVR_DATE />
          <ORIG_BR />
          <ORIG_ORDNO />
          <REMOTE_ID />
          <REMOTE_NO />
          <PEP_FIELD />
          <DONE_DATE />
          <xsl:variable name="appHeight" select="$insuredParty/ns1:Person/ns1:Height2/ns1:MeasureValue" />
          <APP_HTFT>
            <!--
						<xsl:if test="string(number($appHeight)) != 'NaN'">
							<xsl:value-of select="($appHeight div 12)" />
						</xsl:if> -->
          </APP_HTFT>
          <APP_HTIN>
            <!--
						<xsl:if test="string(number($appHeight)) != 'NaN'">
							<xsl:value-of select="($appHeight mod 12)" />
						</xsl:if> -->
          </APP_HTIN>
          <xsl:variable name="appWeight" select="$insuredParty/ns1:Person/ns1:Weight2/ns1:MeasureValue" />
          <APP_WT>
            <xsl:value-of select="'0'" />
            <!--
						<xsl:choose>
							<xsl:when test="string(number($appWeight)) != 'NaN'">
								<xsl:value-of select="$appWeight" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'0'" />
							</xsl:otherwise>
						</xsl:choose> -->
          </APP_WT>
          <ATTACHMENT />
          <EFORM_ID />
          <FILE_NAME />
          <CONT_PREF />
          <CONT_NEEDS />
          <CONT_INST />
          <CONT_EXT />
          <CTRL_POL />
          <DELIV_ST>
            <!-- ApplicationJurisdiction -->
            <xsl:if test="$remoteClient!='PPLN'">
              <xsl:value-of select="ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:ApplicationJurisdiction" />
            </xsl:if>
          </DELIV_ST>
          <PRU_TRANS />
          <PBX_IND />
          <PLC_IND>
            <!-- Risk.ReplacementInd : If the value is 'Y' or 'T' then replacement indicator will be Y else N -->
            <!--
						<xsl:variable name="replacementInd" select="$insuredParty/ns1:Risk/ns1:ReplacementInd" />
						<xsl:choose>
							<xsl:when test="$replacementInd='Y' or $replacementInd='T' or $replacementInd='y' or $replacementInd='t'">Y</xsl:when>
							<xsl:otherwise>N</xsl:otherwise>
						</xsl:choose>
						-->
          </PLC_IND>
          <ALT_POL />
          <RELAT_APP />
          <JUV_NAME />
          <JUV_FLAG />
          <AGT_W_CLI />
          <EA_IND />
          <ALT_PH>
            <!-- Party(Insured).Phone[PhoneTypeCode=...]
								'MOBILE', 'BUSINESS', 'OTHER'

						<xsl:variable name="phoneTypeCode" select="$insuredParty/Phone/PhoneTypeCode/@tc" />
						<xsl:choose>
							<xsl:when test="$phoneTypeCode=''">MOBILE</xsl:when>
							<xsl:when test="$phoneTypeCode=''">BUSINESS</xsl:when>
							<xsl:otherwise>OTHER</xsl:otherwise>
						</xsl:choose>
						-->
            <!--
						<xsl:variable name="insuredBusiness" select="$insuredParty/ns1:Phone[ns1:PhoneTypeCode/@tc='2' or ns1:PhoneTypeCode/@tc='12' or ns1:PhoneTypeCode/@tc='2147483647']" />
						<xsl:value-of select="concat($insuredBusiness/ns1:AreaCode,$insuredBusiness/ns1:DialNumber)" /> -->
          </ALT_PH>
          <APP_EMAIL>
            <xsl:value-of select="normalize-space($insuredParty/ns1:EMailAddress/ns1:AddrLine)" />
          </APP_EMAIL>
          <APP_MOBILE>
            <xsl:variable name="insuredMobile" select="$insuredParty/ns1:Phone[ns1:PhoneTypeCode/@tc='12']" />
            <xsl:call-template name="formatPhone">
              <xsl:with-param name="value" select="concat($insuredMobile/ns1:AreaCode,$insuredMobile/ns1:DialNumber)" />
            </xsl:call-template>
          </APP_MOBILE>
          <AGT_PH>
            <xsl:variable name="agentPhone" select="$agentParty/ns1:Phone[1]" />
            <xsl:call-template name="formatPhone">
              <xsl:with-param name="value" select="concat($agentPhone/ns1:AreaCode,$agentPhone/ns1:DialNumber)" />
            </xsl:call-template>
          </AGT_PH>
          <AGT_EMAIL>
            <xsl:value-of select="$agentParty/ns1:EMailAddress/ns1:AddrLine" />
          </AGT_EMAIL>
        </XCSRecord>
      </xsl:for-each>
      <!-- SQL CLOSE -->
      <xsl:value-of select="sql:close($sql)" />
    </XCSData>
  </xsl:template>
  <xsl:template name="clientNameMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="$value='71661'">ERIE FAMILY LIFE</xsl:when>
      <xsl:when test="$value='71711'">AXA IPIPELINE-TELEDEX EXAM</xsl:when>
      <xsl:when test="$value='71437'">AG PHI ONLY</xsl:when>
      <xsl:when test="$value='73176'">AMERICAN GENERAL YOUNGER AGES</xsl:when>
      <xsl:when test="$value='73177'">UNITED STATES LIFE-YOUNGER AGES</xsl:when>
      <xsl:when test="$value='09848'">AMERICAN GENERAL LIFE-HOUSTON</xsl:when>
      <xsl:when test="$value='89916'">AMERICAN GENERAL TRAD.-MILWAU</xsl:when>
      <xsl:when test="$value='89817'">UNITED STATES LIFE-HOUSTON/NY</xsl:when>
      <xsl:when test="$value='89917'">UNITED STATES LIFE-TRAND.-MIL</xsl:when>
      <xsl:when test="$value='73148'">USL PHI ONLY</xsl:when>
      <!--<xsl:when test="$value='71789'">MOTORIST TELEDEX IPIPELINE</xsl:when>-->
      <xsl:when test="$value='70291'">MOTORISTS-TELEDEX-HERITAGE LAB</xsl:when>
    </xsl:choose>
  </xsl:template>
  <!-- Mahesh's Bill Code Mapping to determine the order type -->
  <xsl:template name="orderTypeMapping">
    <xsl:param name="value" />
    <xsl:param name="value2" />
    <xsl:choose>
      <xsl:when test="$value='0137'">T</xsl:when>
      <xsl:when test="$value='0138'">T</xsl:when>
      <xsl:when test="$value='0139'">I</xsl:when>
      <xsl:when test="$value='0139' and $value2='0147'">I</xsl:when>
      <xsl:when test="$value='0106'">T</xsl:when>
      <xsl:when test="$value='0147'">M</xsl:when>
      <xsl:otherwise>T</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--
	<xsl:template name="orderTypeMapping">
		<xsl:param name="value" />
		<xsl:choose>
			<xsl:when test="contains($value,'11')">A</xsl:when>
			<xsl:when test="contains($value,'139') or contains($value,'138')">I</xsl:when>
			<xsl:when test="contains($value,'137')">T</xsl:when>
		</xsl:choose>
	</xsl:template>
	-->
  <xsl:template name="billCodeMapping">
    <xsl:param name="value" />
    <xsl:param name="value2" />
    <xsl:choose>
      <xsl:when test="$value='0137' and $value2=''">
        <BILL_CD1>419</BILL_CD1>
        <BILL_CD2 />
        <BILL_CD3 />
      </xsl:when>
      <xsl:when test="$value='0137' and $value2='0535'">
        <BILL_CD1>419</BILL_CD1>
        <BILL_CD2>210</BILL_CD2>
        <BILL_CD3 />
      </xsl:when>
      <xsl:when test="$value='0138' and $value2=''">
        <BILL_CD1>334</BILL_CD1>
        <BILL_CD2>653</BILL_CD2>
        <BILL_CD3>704</BILL_CD3>
      </xsl:when>
      <xsl:when test="($value='0138' and $value2='0139') or ($value='0139' and $value2='0138')">
        <BILL_CD1>300</BILL_CD1>
        <BILL_CD2>506</BILL_CD2>
        <BILL_CD3 />
      </xsl:when>
      <xsl:when test="$value='0139' and $value2=''">
        <BILL_CD1>300</BILL_CD1>
        <BILL_CD2 />
        <BILL_CD3 />
      </xsl:when>
      <xsl:when test="$value='0139' and $value2='0334'">
        <BILL_CD1>300</BILL_CD1>
        <BILL_CD2>702</BILL_CD2>
        <BILL_CD3 />
      </xsl:when>
      <xsl:when test="$value='0139' and $value2='0330'">
        <BILL_CD1>300</BILL_CD1>
        <BILL_CD2>704</BILL_CD2>
        <BILL_CD3 />
      </xsl:when>
      <xsl:when test="$value='0139' and $value2='0147'">
        <BILL_CD1>300</BILL_CD1>
        <BILL_CD2>700</BILL_CD2>
        <BILL_CD3>735</BILL_CD3>
      </xsl:when>
      <xsl:when test="$value='0106'">
        <BILL_CD1>406</BILL_CD1>
        <BILL_CD2>419</BILL_CD2>
        <BILL_CD3>439</BILL_CD3>
      </xsl:when>
      <xsl:when test="$value='0147'">
        <BILL_CD1>700</BILL_CD1>
        <BILL_CD2>735</BILL_CD2>
        <BILL_CD3 />
      </xsl:when>
      <xsl:otherwise>
        <BILL_CD1 />
        <BILL_CD2 />
        <BILL_CD3 />
      </xsl:otherwise>
    </xsl:choose>
    <BILL_CD4 />
    <BILL_CD5 />
    <BILL_CD6 />
    <BILL_CD7 />
    <BILL_CD8 />
    <BILL_CD9 />
  </xsl:template>
  <xsl:template name="formatDate">
    <xsl:param name="value" />
    <!-- year -->
    <xsl:value-of select="substring-before($value, '-')" />
    <!-- month -->
    <xsl:call-template name="makeTwoDigit">
      <xsl:with-param name="value" select="substring-before(substring-after($value, '-'), '-')" />
    </xsl:call-template>
    <!-- day of month -->
    <xsl:call-template name="makeTwoDigit">
      <xsl:with-param name="value" select="substring-after(substring-after($value, '-'), '-')" />
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="makeTwoDigit">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="string-length($value) &gt;1">
        <xsl:value-of select="$value" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('0',$value)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <!--
	<xsl:template name="appMarSt">
		<xsl:param name="value" />
		<xsl:param name="tc" />
		<xsl:choose>
			<xsl:when test="string-length($tc) &gt; 0 and $tc &gt;= 1 and $tc &lt;= 5">
				<xsl:value-of select="$tc" />
			</xsl:when>
			<xsl:when test="$value='M' or $value='m'">M</xsl:when>
			<xsl:when test="$value='S' or $value='s'">S</xsl:when>
			<xsl:when test="$value='D' or $value='d'">D</xsl:when>
			<xsl:when test="$value='W' or $value='w'">W</xsl:when>
			<xsl:when test="$value='L' or $value='l'">L</xsl:when>
			<xsl:otherwise />
		</xsl:choose>
	</xsl:template>
	-->
  <xsl:template name="string-replace-all">
    <xsl:param name="text" />
    <xsl:param name="replace" />
    <xsl:param name="by" />
    <xsl:choose>
      <xsl:when test="contains($text,$replace)">
        <xsl:value-of select="substring-before($text,$replace)" />
        <xsl:value-of select="$by" />
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)" />
          <xsl:with-param name="replace" select="$replace" />
          <xsl:with-param name="by" select="$by" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="uppercase">
    <xsl:param name="value" />
    <xsl:value-of select="translate($value,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
  </xsl:template>
  <xsl:template name="formatPhone">
    <xsl:param name="value" />
    <xsl:value-of select="translate($value,' ()-','')" />
  </xsl:template>
  <xsl:template name="formatSSN">
    <xsl:param name="value" />
    <xsl:value-of select="translate($value,' ()-','')" />
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
  <xsl:template name="reqAcctNumMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='1044'">
        <xsl:value-of select="'71437'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='71438'">
        <xsl:value-of select="'71437'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1048'">
        <xsl:value-of select="'71437'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1049'">
        <xsl:value-of select="'73176'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1050'">
        <xsl:value-of select="'09848'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1051'">
        <xsl:value-of select="'89916'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1052'">
        <xsl:value-of select="'73148'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1053'">
        <xsl:value-of select="'73177'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1054'">
        <xsl:value-of select="'89817'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1055'">
        <xsl:value-of select="'89917'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1056'">
        <xsl:value-of select="'71437'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1060'">
        <xsl:value-of select="'73148'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1061'">
        <xsl:value-of select="'73177'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1062'">
        <xsl:value-of select="'89817'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1064'">
        <xsl:value-of select="'73176'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1066'">
        <xsl:value-of select="'09848'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1068'">
        <xsl:value-of select="'89916'" />
      </xsl:when>
      <xsl:when test="normalize-space($value)='1070'">
        <xsl:value-of select="'89917'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

