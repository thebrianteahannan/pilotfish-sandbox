<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XCSExcelBook>
      <XCSExcelSheet name="Demos No Charges Warnings">
        <XCSExcelRow>
          <CDM>CDM</CDM>
          <Quantity>Quantity</Quantity>
          <CollectionDate>CollectionDate</CollectionDate>
          <PatientName>PatientName</PatientName>
          <PatientAccount>PatientAccount</PatientAccount>
          <ProcedureName>ProcedureName</ProcedureName>
          <ProcedureCodeCPT>ProcedureCodeCPT</ProcedureCodeCPT>
        </XCSExcelRow>
        <xsl:for-each select="//XCSData/Charges[@no-matching-demo-warning='true']/XCSRecord">
          <XCSExcelRow>
            <CDM>
              <xsl:value-of select="CDM | CDM_CODE" />
            </CDM>
            <Quantity>
              <xsl:value-of select="QUANTITY" />
            </Quantity>
            <CollectionDate>
              <xsl:value-of select="SPECIMENCOLLECTIONDATE | SERVICEDATE" />
            </CollectionDate>
            <PatientName>
              <xsl:value-of select="PATIENTNAME" />
            </PatientName>
            <PatientAccount>
              <xsl:value-of select="PATIENTACCOUNT | CSN" />
            </PatientAccount>
            <ProcedureName>
              <xsl:value-of select="PROCEDUREDESCRIPTION" />
            </ProcedureName>
            <ProcedureCodeCPT>
              <xsl:value-of select="PROCEDURECODECPT | CPTCODE" />
            </ProcedureCodeCPT>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

