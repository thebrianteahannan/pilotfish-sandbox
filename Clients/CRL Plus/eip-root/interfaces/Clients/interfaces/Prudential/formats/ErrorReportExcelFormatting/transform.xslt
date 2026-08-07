<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:java="java" exclude-result-prefixes="java datetime" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:key match="ERROR" name="ERRORS" use="POLNUMBER" />
  <xsl:key match="ERROR" name="ERRORSByMessage" use="concat(POLNUMBER, REASONFORERROR)" />
  <xsl:template match="/EIPData">
    <XCSExcelBook>
      <XCSExcelSheet name="ErrorReport">
        <!--  rowCount="{count(ERRORS/ERROR)}" -->
        <Columns count="5">
          <xsl:variable name="throwaway"  select="ta:setAttribute($attributes, 'com.crl.prudential.error.EmailSubject', concat('CRL Prudential Error Report: ', count(ERRORS/ERROR), ' Errors'))" />
          <Column index="1">PolicyNumber</Column>
          <Column index="2">ErrorDate</Column>
          <Column index="3">ReqCodeTC</Column>
          <Column index="4">ReqCodeDescription</Column>
          <Column index="5">ReasonForError</Column>
        </Columns>
        <xsl:for-each select="ERRORS/ERROR[generate-id(.) = generate-id(key('ERRORS', POLNUMBER)[1])][string-length(POLNUMBER) &gt; 0]">
          <XCSExcelRow index="{position()}">
            <PolicyNumber index="1">
              <xsl:value-of select="POLNUMBER" />
            </PolicyNumber>
            <ErrorDate index="2">
              <xsl:for-each select="key('ERRORS', POLNUMBER)">
                <xsl:if test="position() &gt; 1">
                  <xsl:value-of select="'; '" />
                </xsl:if>
                <xsl:value-of select="substring(ERRORDATE,1,19)" />
              </xsl:for-each>
            </ErrorDate>
            <ReqCodeTC index="3">
              <xsl:value-of select="REQCODETC" />
            </ReqCodeTC>
            <ReqCodeDescription index="4">
              <xsl:value-of select="REQCODETXT" />
            </ReqCodeDescription>
            <ReasonForError index="5">
              <xsl:for-each select="key('ERRORS', POLNUMBER)">
                <xsl:if test="generate-id(.) = generate-id(key('ERRORSByMessage', concat(POLNUMBER, REASONFORERROR))[1])">
                  <xsl:value-of select="REASONFORERROR" />
                </xsl:if>
              </xsl:for-each>
            </ReasonForError>
          </XCSExcelRow>
        </xsl:for-each>
        <xsl:variable name="countErrors" select="count(ERRORS/ERROR[generate-id(.) = generate-id(key('ERRORS', POLNUMBER)[1])][string-length(POLNUMBER) &gt; 0])" />
        <xsl:for-each select="ERRORS/ERROR[generate-id(.) = generate-id(key('ERRORSByMessage', concat(POLNUMBER, REASONFORERROR))[1])][string-length(POLNUMBER) = 0]">
          <XCSExcelRow index="{$countErrors + position()}">
            <PolicyNumber index="1">
              <xsl:value-of select="POLNUMBER" />
            </PolicyNumber>
            <ErrorDate index="2">
              <xsl:for-each select="key('ERRORSByMessage', concat(POLNUMBER, REASONFORERROR))">
                <xsl:if test="position() &gt; 1">
                  <xsl:value-of select="'; '" />
                </xsl:if>
                <xsl:value-of select="substring(ERRORDATE,1,19)" />
              </xsl:for-each>
            </ErrorDate>
            <ReqCodeTC index="3">
              <xsl:value-of select="REQCODETC" />
            </ReqCodeTC>
            <ReqCodeDescription index="4">
              <xsl:value-of select="REQCODETXT" />
            </ReqCodeDescription>
            <ReasonForError index="5">
              <xsl:value-of select="REASONFORERROR" />
            </ReasonForError>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

