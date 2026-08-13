<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ns1="http://pilotfish.sqlxml">
  <!-- Dialect A uses UPPERCASE header tags (e.g. PATIENTID). -->
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <ns1:SQLXML>
      <xsl:for-each select="//*[local-name()='XCSRecord']">
        <ns1:Insert>
          <CsvPatients>
            <PatientId><xsl:value-of select="(*[local-name()='PATIENTID'])[1]"/></PatientId>
            <FirstName><xsl:value-of select="(*[local-name()='FIRSTNAME'])[1]"/></FirstName>
            <LastName><xsl:value-of select="(*[local-name()='LASTNAME'])[1]"/></LastName>
            <DateOfBirth><xsl:value-of select="(*[local-name()='DATEOFBIRTH'])[1]"/></DateOfBirth>
            <City><xsl:value-of select="(*[local-name()='CITY'])[1]"/></City>
            <StateCode><xsl:value-of select="(*[local-name()='STATE'])[1]"/></StateCode>
            <SourceFile/>
          </CsvPatients>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>
