<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xsl">
  <!--
    AuthDecision XML → PilotFish HL7 XML (ORU^R01).
    HL7TransformationProcessor (XML to HL7 2.X) emits the ER7 wire.
    Do not hardcode MSH|... text here — map structure only.
  -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:variable name="trace" select="normalize-space((//AuthTraceNumber)[1])"/>
  <xsl:variable name="member" select="normalize-space((//MemberId)[1])"/>
  <xsl:variable name="last" select="normalize-space((//PatientLastName)[1])"/>
  <xsl:variable name="first" select="normalize-space((//PatientFirstName)[1])"/>
  <xsl:variable name="proc" select="normalize-space((//ProcedureCode)[1])"/>
  <xsl:variable name="dx" select="normalize-space((//DiagnosisCode)[1])"/>
  <xsl:variable name="bucket" select="upper-case(normalize-space((//DecisionBucket)[1]))"/>
  <xsl:variable name="reason" select="normalize-space((//Reason)[1])"/>
  <xsl:variable name="msgId" select="concat('PAORU', if ($trace != '') then $trace else 'TRACE')"/>
  <xsl:variable name="ts" select="'20260807131500'"/>

  <xsl:template name="obx">
    <xsl:param name="setId"/>
    <xsl:param name="code"/>
    <xsl:param name="name"/>
    <xsl:param name="value"/>
    <OBX>
      <OBX.1><xsl:value-of select="$setId"/></OBX.1>
      <OBX.2>ST</OBX.2>
      <OBX.3>
        <CE.1><xsl:value-of select="$code"/></CE.1>
        <CE.2><xsl:value-of select="$name"/></CE.2>
        <CE.3>L</CE.3>
      </OBX.3>
      <OBX.5><xsl:value-of select="$value"/></OBX.5>
      <OBX.8>N</OBX.8>
      <OBX.11>F</OBX.11>
      <OBX.14><xsl:value-of select="$ts"/></OBX.14>
    </OBX>
  </xsl:template>

  <xsl:template match="/">
    <ORU_R01>
      <MSH>
        <MSH.1>|</MSH.1>
        <MSH.2><xsl:text>^~\&amp;</xsl:text></MSH.2>
        <MSH.3>PILOTFISH_PA</MSH.3>
        <MSH.4>DEMO_PROVIDER</MSH.4>
        <MSH.5>EHR</MSH.5>
        <MSH.6>DEMO_HOSP</MSH.6>
        <MSH.7><xsl:value-of select="$ts"/></MSH.7>
        <MSH.9>
          <MSG.1>ORU</MSG.1>
          <MSG.2>R01</MSG.2>
          <MSG.3>ORU_R01</MSG.3>
        </MSH.9>
        <MSH.10><xsl:value-of select="$msgId"/></MSH.10>
        <MSH.11>P</MSH.11>
        <MSH.12>2.5.1</MSH.12>
      </MSH>
      <PID>
        <PID.1>1</PID.1>
        <PID.3>
          <CX.1><xsl:value-of select="$member"/></CX.1>
          <CX.4>PAYER</CX.4>
          <CX.5>MI</CX.5>
        </PID.3>
        <PID.5>
          <XPN.1><xsl:value-of select="$last"/></XPN.1>
          <XPN.2><xsl:value-of select="$first"/></XPN.2>
        </PID.5>
        <PID.7>19700101</PID.7>
        <PID.8>U</PID.8>
      </PID>
      <OBR>
        <OBR.1>1</OBR.1>
        <OBR.3><xsl:value-of select="$trace"/></OBR.3>
        <OBR.4>
          <CE.1>PA</CE.1>
          <CE.2>Prior Authorization Decision</CE.2>
          <CE.3>L</CE.3>
        </OBR.4>
        <OBR.7><xsl:value-of select="$ts"/></OBR.7>
        <OBR.16>
          <XCN.1>AUTHBOT</XCN.1>
          <XCN.2>Demo Auth Engine</XCN.2>
        </OBR.16>
      </OBR>
      <xsl:call-template name="obx">
        <xsl:with-param name="setId" select="'1'"/>
        <xsl:with-param name="code" select="'AUTH_STATUS'"/>
        <xsl:with-param name="name" select="'Authorization Status'"/>
        <xsl:with-param name="value" select="$bucket"/>
      </xsl:call-template>
      <xsl:call-template name="obx">
        <xsl:with-param name="setId" select="'2'"/>
        <xsl:with-param name="code" select="'AUTH_REASON'"/>
        <xsl:with-param name="name" select="'Authorization Reason'"/>
        <xsl:with-param name="value" select="$reason"/>
      </xsl:call-template>
      <xsl:call-template name="obx">
        <xsl:with-param name="setId" select="'3'"/>
        <xsl:with-param name="code" select="'AUTH_TRACE'"/>
        <xsl:with-param name="name" select="'Auth Trace Number'"/>
        <xsl:with-param name="value" select="$trace"/>
      </xsl:call-template>
      <xsl:call-template name="obx">
        <xsl:with-param name="setId" select="'4'"/>
        <xsl:with-param name="code" select="'AUTH_PROC'"/>
        <xsl:with-param name="name" select="'Requested Procedure'"/>
        <xsl:with-param name="value" select="$proc"/>
      </xsl:call-template>
      <xsl:call-template name="obx">
        <xsl:with-param name="setId" select="'5'"/>
        <xsl:with-param name="code" select="'AUTH_DX'"/>
        <xsl:with-param name="name" select="'Requested Diagnosis'"/>
        <xsl:with-param name="value" select="$dx"/>
      </xsl:call-template>
    </ORU_R01>
  </xsl:template>
</xsl:stylesheet>
