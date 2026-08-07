<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:WLSOrderType="http://crlcorp.com/Orders" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:component="http://crlcorp.com/OrderComponents" xmlns:exsl="http://exslt.org/common" xmlns:java="http://xml.apache.org/xalan/java" xmlns:ns3="http://crlcorp.com/ElectronicOrdering" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="datetime dtFormatter java soap" extension-element-prefixes="exsl ns3" version="1.0">
	<xsl:param name="WSS_ReserveCrlSampleIdRequest_URL" />
	<xsl:param name="WSS_GetCrlTestPanelRequest_URL" />
	<xsl:param name="WSS_Username" />
	<xsl:param name="WSS_Password" />
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:template>
	<xsl:template match="soap:Request">
		<xsl:apply-templates select="@*|node()" />
	</xsl:template>
	<xsl:template match="WLSOrderType:order">
		<xsl:variable name="httpCaller" select="java:com.pilotfish.custom.crl.HttpCaller.new(true())" />
		<WLSOrderType:Order Version="1.0.0">
			<WLSOrderType:Account ClientId="LL5" Reference1Id="{WLSOrderType:lcaAccount}" RegionId="WELL" />
			<WLSOrderType:Subject DateOfBirth="{WLSOrderType:dateOfBirth}" Gender="{WLSOrderType:gender}">
				<component:SubjectId AlphaNumericId="{WLSOrderType:altPatientId}" />
				<component:Name First="{WLSOrderType:name/WLSOrderType:first}" Last="{WLSOrderType:name/WLSOrderType:last}" />
				<xsl:choose>
					<xsl:when test="WLSOrderType:fasting = 'Y'">
						<component:YesNoQuestion DidYouFast="YES" />
					</xsl:when>
					<xsl:when test="WLSOrderType:fasting = 'N'">
						<component:YesNoQuestion DidYouFast="NO" />
					</xsl:when>
					<xsl:otherwise>
						<component:YesNoQuestion DidYouFast="N/S" />
					</xsl:otherwise>
				</xsl:choose>
				<component:Physician NPINumber="{WLSOrderType:npiNumber}">
					<component:Name First="{WLSOrderType:physicianName/WLSOrderType:first}" Last="{WLSOrderType:physicianName/WLSOrderType:last}" />
					<component:Type>REFERRING</component:Type>
				</component:Physician>
			</WLSOrderType:Subject>
			<!-- Call GetCrlTestPanelRequest -->
			<xsl:variable name="serviceLookups" select="exsl:node-set(java:callGetCrlTestPanelRequest($httpCaller, $WSS_GetCrlTestPanelRequest_URL, '', $WSS_Username, $WSS_Password, concat(substring(datetime:dateTime(), 1, 19), '.000Z'), 'LL5', 'WELL', WLSOrderType:lcaAccount, WLSOrderType:services/WLSOrderType:serviceCode/text()))" />
			<xsl:call-template name="checkWSResponse">
				<xsl:with-param name="serviceName" select="'getCrlTestPanelRequest'" />
				<xsl:with-param name="node" select="$serviceLookups" />
			</xsl:call-template>
			<xsl:for-each select="$serviceLookups//*[local-name() = 'clientServiceMap']">
				<xsl:variable name="oldServiceCode" select="string(descendant::*[local-name() = 'clientServiceCode'])" />
				<xsl:variable name="newServiceCode" select="string(descendant::*[local-name() = 'serviceCode'])" />
				<WLSOrderType:Service Description="{WLSOrderType:services[WLSOrderType:serviceCode = $oldServiceCode]/WLSOrderType:serviceDescription}" ServiceCode="{$newServiceCode}" />
			</xsl:for-each>
			<xsl:for-each select="WLSOrderType:specimen">
				<!-- Call ReserveCrlSampleIdRequest -->
				<xsl:variable name="response" select="exsl:node-set(java:callReserveCrlSampleIdRequest($httpCaller, $WSS_ReserveCrlSampleIdRequest_URL, '', $WSS_Username, $WSS_Password, concat(substring(datetime:dateTime(), 1, 19), '.000Z'), WLSOrderType:specimenType))" />
				<!-- Check response validity -->
				<xsl:call-template name="checkWSResponse">
					<xsl:with-param name="serviceName" select="'getCrlTestPanelRequest'" />
					<xsl:with-param name="node" select="$serviceLookups" />
				</xsl:call-template>
				<xsl:variable name="sampleId" select="$response//*[local-name() = 'sampleId']" />
				<xsl:variable name="containerId" select="$response//*[local-name() = 'containerId']" />
				<xsl:if test="(string-length($sampleId) = 0) or (string-length($containerId) = 0)">
					<xsl:message>
						<xsl:value-of select="concat('Error with ReserveCrlSampleIdResponse: either sampleId(', $sampleId, ') or containerId(', $containerId, ') is empty')" />
					</xsl:message>
				</xsl:if>
				<WLSOrderType:Container CollectionDate="{WLSOrderType:specimenDate}" Id="{$containerId}" OriginalBarcode="{WLSOrderType:specimenId}" SpecimenType="{WLSOrderType:specimenType}" />
				<WLSOrderType:Encounter EncounterDate="{../WLSOrderType:eventDate}" RequisitionVersion="">
					<component:EncounterId SampleId="{$sampleId}" SlipId="{../WLSOrderType:patientId}">
						<component:SampleIdentifierMap FieldName="PATIENT ID" FieldValue="{../WLSOrderType:patientId}" />
						<component:SampleIdentifierMap FieldName="ALT PATIENT ID" FieldValue="{../WLSOrderType:altPatientId}" />
						<component:SampleIdentifierMap FieldName="LCA ACCOUNT #" FieldValue="{../WLSOrderType:lcaAccount}" />
					</component:EncounterId>
				</WLSOrderType:Encounter>
			</xsl:for-each>
			<!-- Copy SampleContact -->
			<xsl:copy-of select="//WLSOrderType:SampleContact" />
		</WLSOrderType:Order>
	</xsl:template>
	<xsl:template name="checkWSResponse">
		<xsl:param name="serviceName" />
		<xsl:param name="node" />
		<xsl:if test="string-length($node//Error) &gt; 0">
			<xsl:message>
				<xsl:value-of select="concat('Error calling service ', $serviceName, ': ', $node//Error)" />
			</xsl:message>
		</xsl:if>
		<xsl:if test="(string-length($node//*[local-name() = 'RequestStatus']) &gt; 0) and ($node//*[local-name() = 'RequestStatus'] != 'SUCCESS')">
			<xsl:message>
				<xsl:value-of select="concat('Error calling service ', $serviceName, ': ', $node//*[local-name() = 'RequestStatus'])" />
			</xsl:message>
		</xsl:if>
		<xsl:if test="(string-length($node//*[local-name() = 'FaultMessage']) &gt; 0) and ($node//*[local-name() = 'FaultMessage'] != 'SUCCESS')">
			<xsl:message>
				<xsl:value-of select="concat('Error calling service ', $serviceName, ': ', $node//*[local-name() = 'FaultMessage'])" />
			</xsl:message>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>

