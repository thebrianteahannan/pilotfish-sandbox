<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/ns2:TXLife">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <XCSExcelBook>
      <XCSExcelSheet name="Sheet1">
        <Columns count="86">
          <Column index="1" type="String">REMOTE_ID</Column>
          <Column index="2" type="Numeric">REMOTE_NO</Column>
          <Column index="3" type="Numeric">ORDER_DATE</Column>
          <Column index="4" type="String">ORDER_TYPE</Column>
          <Column index="5" type="String">ACCOUNT</Column>
          <Column index="6" type="Numeric">BR_BRANCH</Column>
          <Column index="7" type="String">ORIGIN</Column>
          <Column index="8" type="String">RUSH</Column>
          <Column index="9" type="String">AGENT</Column>
          <Column index="10" type="String">AGENT_CD</Column>
          <Column index="11" type="Numeric">AGENT_PHONE</Column>
          <Column index="12" type="String">AGENT_EXT</Column>
          <Column index="13" type="String">AGENT_EMAIL</Column>
          <Column index="14" type="Numeric">AGENT_FAX</Column>
          <Column index="15" type="String">AGENCY</Column>
          <Column index="16" type="String">AGENCY_CD</Column>
          <Column index="17" type="String">AGENCY_PHONE</Column>
          <Column index="18" type="String">AGENCY_FAX</Column>
          <Column index="19" type="String">AGENCY_EMAIL</Column>
          <Column index="20" type="String">POLICY</Column>
          <Column index="21" type="Numeric">POLICY_TYPE</Column>
          <Column index="22" type="Numeric">POLICY_AMT</Column>
          <Column index="23" type="String">APP_FNAME</Column>
          <Column index="24" type="String">APP_LNAME</Column>
          <Column index="25" type="String">APP_MNAME</Column>
          <Column index="26" type="String">APP_OCCUP</Column>
          <Column index="27" type="String">APP_ADR1</Column>
          <Column index="28" type="String">APP_ADR2</Column>
          <Column index="29" type="String">APP_CITY</Column>
          <Column index="30" type="String">APP_STATE</Column>
          <Column index="31" type="String">APP_STZIP</Column>
          <Column index="32" type="Blank">APP_PHONE</Column>
          <Column index="33" type="null">APP_MOBILE_PHONE</Column>
          <Column index="34" type="null">APP_FAX</Column>
          <Column index="35" type="null">APP_EMAIL</Column>
          <Column index="36" type="null">APP_GENDER</Column>
          <Column index="37" type="null">APP_SSN</Column>
          <Column index="38" type="null">APP_DOB</Column>
          <Column index="39" type="null">APP_AGE</Column>
          <Column index="40" type="null">APP_BIRTH_PLACE</Column>
          <Column index="41" type="null">APP_SMOKER</Column>
          <Column index="42" type="null">APP_MAR_STATUS</Column>
          <Column index="43" type="null">APP_BENEFICIARY</Column>
          <Column index="44" type="null">APPT_DATE</Column>
          <Column index="45" type="null">APPT_TIME</Column>
          <Column index="46" type="null">REMARKS_1</Column>
          <Column index="47" type="null">REMARKS_2</Column>
          <Column index="48" type="null">REMARKS_3</Column>
          <Column index="49" type="null">REMARKS_4</Column>
          <Column index="50" type="null">SRV_CODE1</Column>
          <Column index="51" type="null">SRV_CODE2</Column>
          <Column index="52" type="null">SRV_CODE3</Column>
          <Column index="53" type="null">SRV_CODE4</Column>
          <Column index="54" type="null">SRV_CODE5</Column>
          <Column index="55" type="null">SRV_CODE6</Column>
          <Column index="56" type="null">SRV_CODE7</Column>
          <Column index="57" type="null">SRV_CODE8</Column>
          <Column index="58" type="null">SRV_CODE9</Column>
          <Column index="59" type="null">DRVIER_LICENCE</Column>
          <Column index="60" type="null">LICENCE_ISSUE_ST</Column>
          <Column index="61" type="null">FAST_ID</Column>
          <Column index="62" type="null">AUTHORIZATION_1</Column>
          <Column index="63" type="null">AUTHORIZATION_2</Column>
          <Column index="64" type="null">AUTHORIZATION_3</Column>
          <Column index="65" type="null">AUTHORIZATION_4</Column>
          <Column index="66" type="null">AUTHORIZATION_5</Column>
          <Column index="67" type="null">BUS_NAME</Column>
          <Column index="68" type="null">BUS_ADR1</Column>
          <Column index="69" type="null">BUS_ADR2</Column>
          <Column index="70" type="null">BUS_CITY</Column>
          <Column index="71" type="null">BUS_ST</Column>
          <Column index="72" type="null">BUS_ZIP</Column>
          <Column index="73" type="null">BUS_PHONE</Column>
          <Column index="74" type="null">BUS_EXT</Column>
          <Column index="75" type="null">PHY_FNAME</Column>
          <Column index="76" type="null">PHY_LNAME</Column>
          <Column index="77" type="null">PHY_ADR1</Column>
          <Column index="78" type="null">PHY_ADR2</Column>
          <Column index="79" type="null">PHY_CITY</Column>
          <Column index="80" type="null">PHY_ST</Column>
          <Column index="81" type="null">PHY_ZIP</Column>
          <Column index="82" type="null">PHY_PHONE</Column>
          <Column index="83" type="null">PHY_EXT</Column>
          <Column index="84" type="null">PHY_FAX</Column>
          <Column index="85" type="null">MISC_INFO</Column>
          <Column index="86" type="null">Undefined_86</Column>
        </Columns>
        <xsl:for-each select="ns2:TXLifeRequest">
          <XCSExcelRow index="{position()}">
            <xsl:variable name="carrier" select="ns2:OLifE/ns2:Party[@id=../ns2:Relation[ns2:RelationRoleCode/@tc=87]/@RelatedObjectID]" />
            <xsl:variable name="physician" select="ns2:OLifE/ns2:Party[@id=../ns2:Relation[ns2:RelationRoleCode/@tc=41]/@RelatedObjectID]" />
            <xsl:variable name="agent" select="ns2:OLifE/ns2:Party[(@id=../ns2:Relation[ns2:RelationRoleCode/@tc=11]/@RelatedObjectID) or (@id=../ns2:Holding//ns2:LifeParticipant[ns2:LifeParticipantRoleCode/@tc=15]/@PartyID)]" />
            <xsl:variable name="applicant" select="ns2:OLifE/ns2:Party[(@id=../ns2:Relation[ns2:RelationRoleCode/@tc=96 or ns2:RelationRoleCode/@tc=32]/@RelatedObjectID) or (@id=../ns2:Holding//ns2:LifeParticipant[ns2:LifeParticipantRoleCode/@tc=1]/@PartyID)]" />
            <xsl:variable name="business" select="ns2:OLifE/ns2:Party[@id=../ns2:Relation[ns2:RelationRoleCode/@tc=156]/@RelatedObjectID]" />
            <REMOTE_ID>
              <xsl:value-of select="../ns2:UserAuthRequest/ns2:UserLoginName" />
            </REMOTE_ID>
            <REMOTE_NO>
              <!--Assigned-->
              <xsl:value-of select="position()" />
            </REMOTE_NO>
            <ORDER_DATE>
              <xsl:if test="(string-length(ns2:OLifE/ns2:SourceInfo/ns2:CreationDate)&gt;0)">
                <xsl:value-of select="dtFormatter:format(ns2:OLifE/ns2:SourceInfo/ns2:CreationDate,'yyyy-MM-dd','MM/dd/yy')" />
              </xsl:if>
            </ORDER_DATE>
            <ORDER_TYPE>
              <xsl:value-of select="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:RequirementInfo/ns2:ReqCode/@tc" />
            </ORDER_TYPE>
            <ACCOUNT>
              <xsl:value-of select="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:RequirementInfo/ns2:RequirementAcctNum" />
            </ACCOUNT>
            <BR_BRANCH>
              <!--Assigned-->
              <xsl:value-of select="position()" />
            </BR_BRANCH>
            <ORIGIN>
              <xsl:value-of select="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:ApplicationInfo/ns2:ApplicationOrigin" />
            </ORIGIN>
            <RUSH>
              <xsl:value-of select="translate(ns2:TransMode,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
            </RUSH>
            <AGENT>
              <xsl:choose>
                <xsl:when test="string-length($agent/ns2:FullName) &gt; 0">
                  <xsl:value-of select="$agent/ns2:FullName" />
                </xsl:when>
                <xsl:when test="string-length($agent/ns2:Person/ns2:FirstName) &gt; 0 or string-length($agent/ns2:Person/ns2:LastName) &gt; 0">
                  <xsl:value-of select="$agent/ns2:Person/ns2:FirstName" />
                  <xsl:value-of select="' '" />
                  <xsl:value-of select="$agent/ns2:Person/ns2:LastName" />
                </xsl:when>
              </xsl:choose>
            </AGENT>
            <AGENT_CD>
              <xsl:value-of select="$agent/ns2:Address/ns2:Line1" />
            </AGENT_CD>
            <AGENT_PHONE>
              <xsl:value-of select="$agent/ns2:Phone/ns2:AreaCode" />
              <xsl:value-of select="$agent/ns2:Phone/ns2:DialNumber" />
            </AGENT_PHONE>
            <AGENT_EXT>
              <xsl:value-of select="$agent/ns2:Phone/ns2:Ext" />
            </AGENT_EXT>
            <AGENT_EMAIL>
              <xsl:value-of select="$agent/ns2:EMailAddress" />
            </AGENT_EMAIL>
            <AGENT_FAX>
              <xsl:value-of select="$agent/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:AreaCode" />
              <xsl:value-of select="$agent/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:DialNumber" />
            </AGENT_FAX>
            <AGENCY>
              <xsl:value-of select="$carrier/ns2:FullName" />
            </AGENCY>
            <AGENCY_CD>
              <xsl:value-of select="$carrier/ns2:Address/ns2:Line1" />
            </AGENCY_CD>
            <AGENCY_PHONE>
              <xsl:value-of select="$carrier/ns2:Phone/ns2:AreaCode" />
              <xsl:value-of select="$carrier/ns2:Phone/ns2:DialNumber" />
            </AGENCY_PHONE>
            <AGENCY_FAX>
              <xsl:value-of select="$carrier/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:AreaCode" />
              <xsl:value-of select="$carrier/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:DialNumber" />
            </AGENCY_FAX>
            <AGENCY_EMAIL>
              <xsl:value-of select="$carrier/ns2:EMailAddress" />
            </AGENCY_EMAIL>
            <POLICY>
              <xsl:value-of select="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:PolNumber" />
            </POLICY>
            <POLICY_TYPE>
              <!--Provided sample only includes Life, need to confirm codes for other policy types-->
              <xsl:choose>
                <xsl:when test="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:Life">
                  <xsl:text>L</xsl:text>
                </xsl:when>
                <xsl:when test="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:Annuity">
                  <xsl:text>A</xsl:text>
                </xsl:when>
                <xsl:when test="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:DisabilityHealth">
                  <xsl:text>D</xsl:text>
                </xsl:when>
                <xsl:when test="ns2:OLifE/ns2:Holding/ns2:Policy/ns2:PropertyandCasualty">
                  <xsl:text>P</xsl:text>
                </xsl:when>
                <xsl:otherwise />
              </xsl:choose>
            </POLICY_TYPE>
            <POLICY_AMT>
              <xsl:value-of select="number(ns2:OLifE/ns2:Holding/ns2:Policy/ns2:Life/ns2:FaceAmt)" />
            </POLICY_AMT>
            <APP_FNAME>
              <xsl:value-of select="$applicant/ns2:Person/ns2:FirstName" />
            </APP_FNAME>
            <APP_LNAME>
              <xsl:value-of select="$applicant/ns2:Person/ns2:LastName" />
            </APP_LNAME>
            <APP_MNAME>
              <xsl:value-of select="$applicant/ns2:Person/ns2:MiddleName" />
            </APP_MNAME>
            <APP_OCCUP>
              <xsl:value-of select="$applicant/ns2:Person/ns2:Occupation" />
            </APP_OCCUP>
            <APP_ADR1>
              <xsl:value-of select="$applicant/ns2:Address/ns2:Line1" />
            </APP_ADR1>
            <APP_ADR2>
              <xsl:value-of select="$applicant/ns2:Address/ns2:Line2" />
            </APP_ADR2>
            <APP_CITY>
              <xsl:value-of select="$applicant/ns2:Address/ns2:City" />
            </APP_CITY>
            <APP_STATE>
              <xsl:call-template name="TabularMapping_StateMapping">
                <xsl:with-param name="value" select="$applicant/ns2:Address/ns2:AddressStateTC/@tc" />
              </xsl:call-template>
            </APP_STATE>
            <APP_STZIP>
              <xsl:value-of select="$applicant/ns2:Address/ns2:Zip" />
            </APP_STZIP>
            <APP_PHONE>
              <xsl:value-of select="$applicant/ns2:Phone/ns2:AreaCode" />
              <xsl:value-of select="$applicant/ns2:Phone/ns2:DialNumber" />
            </APP_PHONE>
            <APP_MOBILE_PHONE>
              <xsl:value-of select="$applicant/ns2:Phone[ns2:PhoneTypeCode/@tc=12]/ns2:AreaCode" />
              <xsl:value-of select="$applicant/ns2:Phone[ns2:PhoneTypeCode/@tc=12]/ns2:DialNumber" />
            </APP_MOBILE_PHONE>
            <APP_FAX>
              <xsl:value-of select="$applicant/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:AreaCode" />
              <xsl:value-of select="$applicant/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:DialNumber" />
            </APP_FAX>
            <APP_EMAIL>
              <xsl:value-of select="$applicant/ns2:EMailAddress" />
            </APP_EMAIL>
            <APP_GENDER>
              <xsl:value-of select="$applicant/ns2:Person/ns2:Gender" />
            </APP_GENDER>
            <APP_SSN>
              <xsl:value-of select="$applicant/ns2:GovtID" />
            </APP_SSN>
            <APP_DOB>
              <xsl:if test="(string-length($applicant/ns2:Person/ns2:BirthDate)&gt;0)">
                <xsl:value-of select="dtFormatter:format($applicant/ns2:Person/ns2:BirthDate,'yyyy-MM-dd','MM/dd/yy')" />
              </xsl:if>
            </APP_DOB>
            <APP_AGE>
              <xsl:value-of select="$applicant/ns2:Person/ns2:Age" />
            </APP_AGE>
            <APP_BIRTH_PLACE>
              <xsl:choose>
                <xsl:when test="$applicant/ns2:Person/ns2:BirthJurisdictionTC[@tc != '0' and @tc != '2147483647']">
                  <xsl:call-template name="TabularMapping_StateMapping">
                    <xsl:with-param name="value" select="$applicant/ns2:Person/ns2:BirthJurisdictionTC/@tc" />
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="string-length($applicant/ns2:Person/ns2:BirthCountry) &gt; 0">
                  <xsl:value-of select="$applicant/ns2:Person/ns2:BirthCountry" />
                </xsl:when>
                <xsl:when test="string-length($applicant/ns2:Person/ns2:BirthJurisdictionTC/@tc) &gt; 0">
                  <xsl:call-template name="TabularMapping_StateMapping">
                    <xsl:with-param name="value" select="$applicant/ns2:Person/ns2:BirthJurisdictionTC/@tc" />
                  </xsl:call-template>
                </xsl:when>
              </xsl:choose>
            </APP_BIRTH_PLACE>
            <APP_SMOKER>
              <xsl:value-of select="$applicant/ns2:Person/ns2:SmokerStat" />
            </APP_SMOKER>
            <APP_MAR_STATUS>
              <xsl:value-of select="$applicant/ns2:Person/ns2:MarStat" />
            </APP_MAR_STATUS>
            <APP_BENEFICIARY />
            <APPT_DATE />
            <APPT_TIME />
            <REMARKS_1 />
            <REMARKS_2 />
            <REMARKS_3 />
            <REMARKS_4 />
            <SRV_CODE1 />
            <SRV_CODE2 />
            <SRV_CODE3 />
            <SRV_CODE4 />
            <SRV_CODE5 />
            <SRV_CODE6 />
            <SRV_CODE7 />
            <SRV_CODE8 />
            <SRV_CODE9 />
            <DRVIER_LICENCE>
              <xsl:value-of select="$applicant/ns2:Person/ns2:DriversLicenseNum" />
            </DRVIER_LICENCE>
            <LICENCE_ISSUE_ST>
              <xsl:call-template name="TabularMapping_StateMapping">
                <xsl:with-param name="value" select="$applicant/ns2:Person/ns2:DriversLicenseState/@tc" />
              </xsl:call-template>
            </LICENCE_ISSUE_ST>
            <FAST_ID />
            <AUTHORIZATION_1>
              <xsl:apply-templates select="//ns2:FormInstance[1]" />
            </AUTHORIZATION_1>
            <AUTHORIZATION_2>
              <xsl:apply-templates select="//ns2:FormInstance[2]" />
            </AUTHORIZATION_2>
            <AUTHORIZATION_3>
              <xsl:apply-templates select="//ns2:FormInstance[3]" />
            </AUTHORIZATION_3>
            <AUTHORIZATION_4>
              <xsl:apply-templates select="//ns2:FormInstance[4]" />
            </AUTHORIZATION_4>
            <AUTHORIZATION_5>
              <xsl:apply-templates select="//ns2:FormInstance[5]" />
            </AUTHORIZATION_5>
            <BUS_NAME>
              <xsl:value-of select="$business/ns2:FullName" />
            </BUS_NAME>
            <BUS_ADR1>
              <xsl:value-of select="$business/ns2:Address/ns2:Line1" />
            </BUS_ADR1>
            <BUS_ADR2>
              <xsl:value-of select="$business/ns2:Address/ns2:Line2" />
            </BUS_ADR2>
            <BUS_CITY>
              <xsl:value-of select="$business/ns2:Address/ns2:City" />
            </BUS_CITY>
            <BUS_ST>
              <xsl:call-template name="TabularMapping_StateMapping">
                <xsl:with-param name="value" select="$business/ns2:Address/ns2:AddressStateTC/@tc" />
              </xsl:call-template>
            </BUS_ST>
            <BUS_ZIP>
              <xsl:value-of select="$business/ns2:Address/ns2:Zip" />
            </BUS_ZIP>
            <BUS_PHONE>
              <xsl:value-of select="$business/ns2:Phone/ns2:AreaCode" />
              <xsl:value-of select="$business/ns2:Phone/ns2:DialNumber" />
            </BUS_PHONE>
            <BUS_EXT>
              <xsl:value-of select="$business/ns2:Phone/ns2:Ext" />
            </BUS_EXT>
            <PHY_FNAME>
              <xsl:value-of select="$physician/ns2:Person/ns2:FirstName" />
            </PHY_FNAME>
            <PHY_LNAME>
              <xsl:value-of select="$physician/ns2:Person/ns2:LastName" />
            </PHY_LNAME>
            <PHY_ADR1>
              <xsl:value-of select="$physician/ns2:Address/ns2:Line1" />
            </PHY_ADR1>
            <PHY_ADR2>
              <xsl:value-of select="$physician/ns2:Address/ns2:Line2" />
            </PHY_ADR2>
            <PHY_CITY>
              <xsl:value-of select="$physician/ns2:Address/ns2:City" />
            </PHY_CITY>
            <PHY_ST>
              <xsl:call-template name="TabularMapping_StateMapping">
                <xsl:with-param name="value" select="$physician/ns2:Address/ns2:AddressStateTC/@tc" />
              </xsl:call-template>
            </PHY_ST>
            <PHY_ZIP>
              <xsl:value-of select="$physician/ns2:Address/ns2:Zip" />
            </PHY_ZIP>
            <PHY_PHONE>
              <xsl:value-of select="$physician/ns2:Phone/ns2:AreaCode" />
              <xsl:value-of select="$physician/ns2:Phone/ns2:DialNumber" />
            </PHY_PHONE>
            <PHY_EXT>
              <xsl:value-of select="$physician/ns2:Phone/ns2:Ext" />
            </PHY_EXT>
            <PHY_FAX>
              <xsl:value-of select="$physician/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:AreaCode" />
              <xsl:value-of select="$physician/ns2:Phone[ns2:PhoneTypeCode/@tc=19]/ns2:DialNumber" />
            </PHY_FAX>
            <MISC_INFO />
            <Undefined_86 />
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
  <xsl:template name="TabularMapping_StateMapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='0'">
        <xsl:text>Unknown</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='1'">
        <xsl:text>AL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='2'">
        <xsl:text>AK</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='3'">
        <xsl:text>AS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='4'">
        <xsl:text>AZ</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='5'">
        <xsl:text>AR</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='60'">
        <xsl:text>AA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='61'">
        <xsl:text>AE</xsl:text>
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
        <xsl:text>FS</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='12'">
        <xsl:text>FL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='13'">
        <xsl:text>GA</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='14'">
        <xsl:text>GU</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='80'">
        <xsl:text>GB</xsl:text>
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
        <xsl:text>MH</xsl:text>
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
        <xsl:text>MP</xsl:text>
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
        <xsl:text>PW</xsl:text>
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
      <xsl:when test="normalize-space($value)='62'">
        <xsl:text>AP</xsl:text>
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
      <xsl:when test="normalize-space($value)='2147483647'">
        <xsl:text>Other</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="ns2:FormInstance">
    <!-- create attachment filename -->
    <xsl:value-of select="@id" />
    <xsl:value-of select="'-'" />
    <xsl:value-of select="ancestor::ns2:TXLifeRequest/ns2:TransRefGUID" />
    <xsl:value-of select="'.'" />
    <xsl:value-of select="ns2:Attachment/ns2:MimeTypeTC" />
  </xsl:template>
</xsl:stylesheet>

