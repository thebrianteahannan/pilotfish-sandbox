<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="CRLDOCUMENTID[. = ta:getAttribute($attributes, 'CRL_DOCUMENT_ID')]">
    <CRLDOCUMENTID id="{.}">
      <xsl:value-of select="ta:getAttribute($attributes, 'GetDocumentResponse')" />
    </CRLDOCUMENTID>
    <CRLMIMETYPE>
      <xsl:value-of select="ta:getAttribute($attributes, 'GetDocumentMimeType')" />
    </CRLMIMETYPE>
    <CRLORIGINALFILENAME>
      <xsl:value-of select="ta:getAttribute($attributes, 'GetDocumentOriginalFileName')" />
    </CRLORIGINALFILENAME>
  </xsl:template>
</xsl:stylesheet>

