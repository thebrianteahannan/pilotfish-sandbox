<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ns1="http://pilotfish.sqlxml">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <ns1:SQLXML>
      <ns1:Insert>
        <Patients>
          <PatientId><xsl:value-of select="(//PatientId)[1]"/></PatientId>
          <LastName><xsl:value-of select="(//LastName)[1]"/></LastName>
          <FirstName><xsl:value-of select="(//FirstName)[1]"/></FirstName>
          <DateOfBirth><xsl:value-of select="(//DateOfBirth)[1]"/></DateOfBirth>
          <MessageControlId><xsl:value-of select="(//MessageControlId)[1]"/></MessageControlId>
        </Patients>
      </ns1:Insert>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>
