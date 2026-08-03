<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ns1="http://pilotfish.sqlxml">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/FhirMessage">
    <ns1:SQLXML>
      <ns1:Insert>
        <FhirResources>
          <SourceCode><xsl:value-of select="SourceCode"/></SourceCode>
          <ResourceType><xsl:value-of select="ResourceType"/></ResourceType>
          <ResourceId><xsl:value-of select="ResourceId"/></ResourceId>
          <PatientId><xsl:value-of select="PatientId"/></PatientId>
          <PatientName><xsl:value-of select="PatientName"/></PatientName>
          <IsBundle><xsl:value-of select="if (IsBundle='true' or IsBundle='1') then 1 else 0"/></IsBundle>
          <ValidationStatus><xsl:value-of select="ValidationAdvanced"/></ValidationStatus>
          <SourceFile><xsl:value-of select="FileName"/></SourceFile>
          <RawFhir><xsl:value-of select="RawFhir"/></RawFhir>
        </FhirResources>
      </ns1:Insert>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>
