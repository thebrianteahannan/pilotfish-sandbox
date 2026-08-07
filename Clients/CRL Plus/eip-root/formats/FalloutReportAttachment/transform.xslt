<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:java="java" xmlns:str="http://exslt.org/strings" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="java datetime str" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/EIPData">
    <XCSExcelBook>
      <XCSExcelSheet name="ErrorReport">
        <!--  rowCount="{count(ERRORS/ERROR)}" -->
        <Columns count="5">
          <Column index="1">ErrorDate</Column>
          <Column index="2">SourceClient</Column>
          <Column index="3">AccountNumber</Column>
          <Column index="4">PolicyNumber</Column>
          <Column index="5">TrackingID</Column>
          <Column index="6">RequirementCode</Column>
          <Column index="7">TransRefGUID</Column>
          <Column index="8">ExistingTransactionID</Column>
          <Column index="9">ExistingFlowNetOrderNum</Column>
          <Column index="10">TransactionTextID</Column>
          <Column index="11">ReasonForError</Column>
        </Columns>
        <xsl:for-each select="ERRORS/ERROR">
          <XCSExcelRow index="{position()}">
            <xsl:variable name="reasonForError" select="str:tokenize(REASONFORERROR,'|')" />
            <ErrorDate index="1">
              <xsl:value-of select="substring(ERRORDATE,1,19)" />
            </ErrorDate>
            <SourceClient index="2">
              <xsl:value-of select="substring(PFSOURCECLIENT,4)" />
            </SourceClient>
            <AccountNumber index="3">
              <xsl:value-of select="normalize-space($reasonForError[1])" />
            </AccountNumber>
            <PolicyNumber index="4">
              <xsl:value-of select="POLNUMBER" />
            </PolicyNumber>
            <TrackingID index="5">
              <xsl:value-of select="normalize-space($reasonForError[2])" />
            </TrackingID>
            <RequirementCode index="6">
              <xsl:value-of select="concat(REQCODETC,': ',REQCODETXT)" />
            </RequirementCode>
            <TransRefGUID index="7">
              <xsl:value-of select="normalize-space($reasonForError[3])" />
            </TransRefGUID>
            <ExistingTransactionID index="8">
              <xsl:value-of select="normalize-space($reasonForError[4])" />
            </ExistingTransactionID>
            <ExistingFlowNetOrderNum index="9">
              <xsl:value-of select="normalize-space($reasonForError[5])" />
            </ExistingFlowNetOrderNum>
            <TransactionTextID index="10">
              <xsl:value-of select="TRANSACTIONTEXTID" />
            </TransactionTextID>
            <ReasonForError index="11">
              <xsl:value-of select="normalize-space($reasonForError[6])" />
            </ReasonForError>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

