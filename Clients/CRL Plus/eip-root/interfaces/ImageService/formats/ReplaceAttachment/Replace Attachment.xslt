<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="td ns2 ta" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="firstAttachmentDataID" select="generate-id(//ns2:Attachment/ns2:AttachmentData[string-length(.) &gt; 0][1])" />
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns2:AttachmentData">
    <!-- just replace the first AttachmentData -->
    <xsl:choose>
      <!--<xsl:when test="not(../preceding-sibling::ns2:Attachment[string-length(ns2:AttachmentData) &gt; 0]) and string-length(.) &gt; 0">-->
      <xsl:when test="generate-id(.) = $firstAttachmentDataID">
        <ns2:OLifEExtension>
          <ns2:CRL_DOCUMENT_ID>
            <xsl:value-of select="ta:getAttribute($attributes, 'CRL_DOCUMENT_ID')" />
          </ns2:CRL_DOCUMENT_ID>
          <ns2:CRL_FOLDER_ID>
            <xsl:value-of select="ta:getAttribute($attributes, 'CRL_FOLDER_ID')" />
          </ns2:CRL_FOLDER_ID>
          <ns2:CRL_DRAWER_NAME>
            <xsl:value-of select="ta:getAttribute($attributes, 'CRL_DRAWER_NAME')" />
          </ns2:CRL_DRAWER_NAME>
          <ns2:CRL_PAGE_COUNT>
            <xsl:value-of select="ta:getAttribute($attributes, 'CRL_PAGE_COUNT')" />
          </ns2:CRL_PAGE_COUNT>
        </ns2:OLifEExtension>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

