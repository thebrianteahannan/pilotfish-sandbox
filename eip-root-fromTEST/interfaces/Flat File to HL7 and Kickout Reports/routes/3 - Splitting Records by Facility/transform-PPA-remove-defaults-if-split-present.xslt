<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output indent="yes" method="xml" />
  <!-- Find the default split code from PARTITION_CLIENT_FACILITY_INFO for PPA partition -->
  <xsl:variable name="defaultSplitCode" select="//PARTITION_CLIENT_FACILITY_INFO[PARTITION='PPA' and IS_DEFAULT='1']/FACILITY" />
  <!-- Identity transform template -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!-- Remove Client elements that match on client_code and Group/@key where SplitCode is default -->
  <xsl:template match="Client[SplitCode=$defaultSplitCode]">
    <xsl:variable name="clientCode" select="@client_code" />
    <xsl:variable name="groupKey" select="../@key" />
    <xsl:if test="not(//Client[@client_code=$clientCode and ../@key=$groupKey and SplitCode!=$defaultSplitCode])">
      <!-- Skip this Client element -->
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>

