<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:acord="http://ACORD.org/Standards/Life/2" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:err="http://www.pilotfishtechnology.com/eip/RouteErrorReport" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="err td ta datetime" version="1.0">
  <xsl:output method="text" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/err:errorReport">
    <xsl:text>Status = Open</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Problem Type = Application Support</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Category = ILS</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Detail = PLUS</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Your Priority = High</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Responsible Team = ILS Team</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>CRL System = Insurance PLUS</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>System Tracking # =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="ta:getAttribute($attributes, 'error.subdir')" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Customer Name =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="ta:getAttribute($attributes, 'CustomerName')" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>IS Work Category = Maintenance</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Server =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.hostname')" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Interface =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="err:errorInterface" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Route =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="err:errorRoute" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Stage =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="err:errorStage" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Component =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="err:errorComponent" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Error directory =</xsl:text>
    <xsl:value-of select="' '" />
    <xsl:value-of select="ta:getAttribute($attributes, 'error.dir')" />
    <xsl:value-of select="'\'" />
    <xsl:value-of select="ta:getAttribute($attributes, 'error.subdir')" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:text>Exception:</xsl:text>
    <xsl:value-of select="'&#xA;'" />
    <err:errorReport>
      <xsl:apply-templates select="err:exceptionTrace" />
    </err:errorReport>
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'&#xA;'" />
  </xsl:template>
</xsl:stylesheet>

