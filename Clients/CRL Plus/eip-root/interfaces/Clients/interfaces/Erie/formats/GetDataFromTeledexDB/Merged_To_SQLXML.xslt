<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" xmlns:ns2="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/GenerationData_103">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute as="results" into="results">
        <ns1:SQL>SELECT CAST(GETDATE() AS DATE)</ns1:SQL>
      </ns1:Execute>
      <!-- Applicant Data -->
      <ns1:Execute as="ApplicantData" into="ApplicantData">
        <ns1:SQL>select HOM_CITY as APP_Address_City,
						HOM_ADR1 as APP_Address_Line1,
						HOM_STATE as APP_Address_St,
						HOM_STZIP as APP_Address_Zip,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20001' and Q_SUBCODE = 'B' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_BIRTHPL,
						substring (HOM_PHONE,4,7) as APP_CPhone,
						substring (HOM_PHONE,1,3) as APP_CPhone_ACode,
						APP_DOB,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20006' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_EMAIL,
						APP_FNAME,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20005' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_GENDER,
						APP_SOC as APP_GovID,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '10000' and Q_SUBCODE = 'E' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_HEIGHT,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20059' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_INSURED_CITIZENSHIP,
						APP_LNAME,
						(select PRT_EAPP_OPTION from PRT_PARTY_INFO with (nolock) where PRT_TYPE = 'I' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_OPTIN,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20002A' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as APP_WEIGHT
						from WR_ORDERS with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Policy Data -->
      <ns1:Execute as="PolicyData" into="PolicyData">
        <ns1:SQL>select 
						(select Source_TransRefGUID from ACCORD_XML with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?) as DELLTRANSREFGUID,
						(select TRANSREFGUID from ACCORD_XML with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?) as TRANSREFGUID,
						(select tagvalue from PLN_COVERAGE_INFO with (nolock) where TAGNAME = 'AccountNumber' and remote_id = ? and REMOTE_NO = ?) as ACCOUNT_NUMBER,
						(select tagvalue from PLN_COVERAGE_INFO with (nolock) where TAGNAME = 'BankAcctType' and remote_id = ? and REMOTE_NO = ?) as CHECKING_ACCOUNT,
						(select tagvalue from PLN_COVERAGE_INFO with (nolock) where TAGNAME = 'RoutingNumber' and REMOTE_ID = ? and REMOTE_NO = ?) as ROUTING_NUMBER,
						(select POLICY from WR_ORDERS with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?) as POLICY,
						(select REM_DESC from WR_RMKS with (nolock) where REM_DESC LIKE '%Multiple Policy?%' and remote_id = ? and REMOTE_NO = ?) as MULTIPLE_POLICY,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20036' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as DEATH_BENEFIT_OPT_TYPE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20042' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as PAYMENT_METHOD,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20042' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as PAYMENT_MODE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20036' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as PLAN_NAME,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20033' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as POL_AMT,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20036' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as PREMIUM_PERIOD,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20031' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as REPLACE_TYPE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20037C' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as WP</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Signature Data -->
      <ns1:Execute as="SignatureData" into="SignatureData">
        <ns1:SQL>select BR_COMPDT, BR_RECVDT as BR_ORDER_RECEIVED_DATE,
						(select HOM_STATE from WR_ORDERS with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?) as JURISDICTION
						from WR_BRCHORD with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Response Data -->
      <ns1:Execute as="ResponseData" into="ResponseData">
        <ns1:SQL>select ANSWER as CHILD_INSURED_CITIZENSHIP
						from WR_ANSWER with (nolock) where Q_CODE = '20037A' and Q_SUBCODE = 'G' and REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Agent Data -->
      <ns1:Execute as="AgentData" into="AgentData">
        <ns1:SQL>select AGENT_CD, AGENT as AGENT_NAME
						from WR_ORDERS with (nolock) where REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Owner Data -->
      <ns1:Execute as="OwnerData" into="OwnerData">
        <ns1:SQL>select
						case when (ANSWER IS NOT NULL and  cast(ANSWER as varchar(5000)) != '') then '1' else '0' end as OWNER,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021C' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_ADDR,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021C' and Q_SUBCODE = 'B' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_ADDR_CITY,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021C' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_ADDR_ST,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021C' and Q_SUBCODE = 'D' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_ADDR_ZIP,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'D' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_DOB,
						(select PRT_EMAIL from PRT_PARTY_INFO with (nolock) where PRT_TYPE = 'O' and remote_id = ? and REMOTE_NO = ?) as OWNER_EMAIL,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_FNAME,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'B' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_MNAME,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_LNAME,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '10000' and Q_SUBCODE = 'G' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_OPTIN,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'F' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_RELAT,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'F' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_ROLE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'E' and REMOTE_ID = ? and REMOTE_NO = ?) as OWNER_SOC
						from WR_ANSWER with (nolock) where Q_CODE = '20021B' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Payor Data -->
      <ns1:Execute as="PayorData" into="PayorData">
        <ns1:SQL>select 
						case when (PRT_NAME IS NOT NULL and  PRT_NAME != '') then '1' when (PRT_FIRST IS NOT NULL and  PRT_FIRST != '') then '1' else '0' end as PAYOR, 
						PRT_NAME as PAYOR_FULL, 
						PRT_FIRST as PAYOR_FNAME, 
						PRT_MI as PAYOR_MNAME, 
						PRT_LAST as PAYOR_LNAME, 
						PRT_SOC as PAYOR_SOC, 
						PRT_DOB as PAYOR_DOB, 
						rtrim(PRT_RES_ADR1) as PAYOR_ADDR,  
						rtrim(PRT_RES_CITY) as PRT_RES_CITY, 
						PRT_RES_STATE as PAYOR_ADDR_ST, 
						PRT_RES_STZIP as PAYOR_ADDR_ZIP, 
						PRT_EMAIL as PAYOR_EMAIL, 
						PRT_EAPP_OPTION as PAYOR_OPTIN
						FROM PRT_PARTY_INFO with (nolock) where PRT_TYPE = 'P' and remote_id = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Single Primary Data -->
      <ns1:Execute as="SinglePrimaryData" into="SinglePrimaryData">
        <ns1:SQL>select
case when (ANSWER IS NOT NULL and  cast(ANSWER as varchar(5000)) != '') then '1' else '0' end as FOUND,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'E' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_DOB,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_NAME,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_ROLE,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'B' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_SHARE,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'D' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_SSN,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'F' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_SSN_TYPE,
(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'F' and REMOTE_ID = ? and REMOTE_NO = ?) as PRIBEN_TYPE                                                                                                                                                                                                                                                                                                                  
from WR_ANSWER with (nolock) where Q_CODE = '20022B' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Multi Primary Data -->
      <ns1:Execute as="MultiPrimaryData" into="MultiPrimaryData">
        <ns1:SQL>SELECT 1 AS FOUND,
						(SEQNO+1) AS ID, 
						ANSWER AS PRIBEN_LOOP
						FROM WR_ANSWER with (nolock) WHERE RELATION LIKE '20022CC,20022CC' AND FORM_NO = 'TAB' AND REMOTE_ID = ? AND REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Single Contingent Data -->
      <ns1:Execute as="SingleContingentData" into="SingleContingentData">
        <ns1:SQL>select
						case when (ANSWER IS NOT NULL and  cast(ANSWER as varchar(5000)) != '') then '1' else '0' end as FOUND,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'E' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_DOB,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_NAME,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'C' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_ROLE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'B' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_SHARE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'D' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_SSN,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'F' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_SSN_TYPE,
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'F' and REMOTE_ID = ? and REMOTE_NO = ?) as CONTBEN_TYPE                                                                                                                                                                                                                                                                                                                  
						from WR_ANSWER with (nolock) where Q_CODE = '20023B' and Q_SUBCODE = 'A' and REMOTE_ID = ? and REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Multi Contingent Data -->
      <ns1:Execute as="MultiContingentData" into="MultiContingentData">
        <ns1:SQL>SELECT 1 AS FOUND,
						(SEQNO+1) AS ID, 
						ANSWER AS CONTBEN_LOOP
						FROM WR_ANSWER with (nolock) WHERE RELATION LIKE '20023CC,20023CC' AND FORM_NO = 'TAB' AND REMOTE_ID = ? AND REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <!-- Other Insured Data -->
      <ns1:Execute as="OtherInsuredData" into="OtherInsuredData">
        <ns1:SQL>SELECT 1 AS FOUND,
						(SEQNO) AS ID, 
						(select ANSWER from WR_ANSWER with (nolock) where Q_CODE = '20037A' and Q_SUBCODE = 'I' and REMOTE_ID = ? and REMOTE_NO = ?) as CHILD_NUMBER_UNITS,
						ANSWER as CHILD_RIDER
						FROM WR_ANSWER with (nolock) WHERE RELATION LIKE '20037AA,20037AA' AND FORM_NO = 'TAB' AND REMOTE_ID = ? AND REMOTE_NO = ?</ns1:SQL>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
        <!-- @REMOTE_ID -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexRemoteID')" />
        </ns1:Params>
        <!-- @REMOTE_NO -->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('teledexOrderNumber')" />
        </ns1:Params>
      </ns1:Execute>
      <ns1:XMLOut var="results" />
      <ns1:XMLOut appendTo="results" var="ApplicantData" />
      <ns1:XMLOut appendTo="results" var="PolicyData" />
      <ns1:XMLOut appendTo="results" var="SignatureData" />
      <ns1:XMLOut appendTo="results" var="ResponseData" />
      <ns1:XMLOut appendTo="results" var="AgentData" />
      <ns1:XMLOut appendTo="results" var="OwnerData" />
      <ns1:XMLOut appendTo="results" var="PayorData" />
      <ns1:XMLOut appendTo="results" var="SinglePrimaryData" />
      <ns1:XMLOut appendTo="results" var="MultiPrimaryData" />
      <ns1:XMLOut appendTo="results" var="SingleContingentData" />
      <ns1:XMLOut appendTo="results" var="MultiContingentData" />
      <ns1:XMLOut appendTo="results" var="OtherInsuredData" />
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

