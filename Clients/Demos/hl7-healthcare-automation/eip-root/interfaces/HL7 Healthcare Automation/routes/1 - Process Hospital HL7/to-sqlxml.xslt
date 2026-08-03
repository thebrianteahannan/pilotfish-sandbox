<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ns1="http://pilotfish.sqlxml">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/HospitalMessage">
    <ns1:SQLXML>
      <ns1:Insert>
        <Hl7Messages>
          <HospitalCode><xsl:value-of select="HospitalCode"/></HospitalCode>
          <MessageType><xsl:value-of select="MessageType"/></MessageType>
          <TriggerEvent><xsl:value-of select="TriggerEvent"/></TriggerEvent>
          <PatientId><xsl:value-of select="PatientId"/></PatientId>
          <PatientName><xsl:value-of select="PatientName"/></PatientName>
          <ControlId><xsl:value-of select="ControlId"/></ControlId>
          <IsBatch><xsl:value-of select="if (IsBatch='true' or IsBatch='1') then 1 else 0"/></IsBatch>
          <ValidationStatus><xsl:value-of select="ValidationAdvanced"/></ValidationStatus>
          <SourceFile><xsl:value-of select="FileName"/></SourceFile>
          <RawHl7><xsl:value-of select="RawHl7"/></RawHl7>
        </Hl7Messages>
      </ns1:Insert>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>
