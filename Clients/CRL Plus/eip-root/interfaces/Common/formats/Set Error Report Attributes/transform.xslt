<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="err td ta datetime" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="/err:errorReport">
    <err:errorReport>
      <xsl:apply-templates />
    </err:errorReport>
    <xsl:variable name="path">
      <xsl:text>pf.</xsl:text>
      <xsl:value-of select="ta:getAttribute($attributes, 'CustomerName')" />
      <xsl:text>.</xsl:text>
      <xsl:value-of select="datetime:format-date(datetime:date-time(),'YYYYMMdd-HHmmss.SSS')" />
      <xsl:text>.</xsl:text>
      <!-- ErrorListener is set to either 'incoming' or 'outgoing' -->
      <xsl:value-of select="ta:getAttribute($attributes, 'ErrorListener')" />
      <xsl:text>.</xsl:text>
      <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.eip.OriginatingTransactionID')" />
    </xsl:variable>
    <xsl:variable name="errorSubDir">
      <xsl:value-of select="$path" />
    </xsl:variable>
    <xsl:comment>
      <xsl:value-of select="$errorSubDir" />
    </xsl:comment>
    <xsl:variable name="temp">
      <xsl:value-of select="ta:setAttribute($attributes, 'error.subdir', $errorSubDir)" />
    </xsl:variable>
  </xsl:template>
</xsl:stylesheet>

