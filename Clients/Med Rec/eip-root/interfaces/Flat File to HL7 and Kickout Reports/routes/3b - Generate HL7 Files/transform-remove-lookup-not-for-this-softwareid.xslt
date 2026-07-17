<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="SoftwareID" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/LOCATION[SOFTWARE_ID != $SoftwareID]">
    <!--REMOVE ANYTHING NOT RELATED TO THIS SOFTWARE ID-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/FLAGGED_ACCOUNT[SOFTWARE_ID != $SoftwareID]">
    <!--REMOVE ANYTHING NOT RELATED TO THIS SOFTWARE ID-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/PMA_MOD26_ACCTS[SOFTWARE_ID != $SoftwareID]">
    <!--REMOVE ANYTHING NOT RELATED TO THIS SOFTWARE ID-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/CDMLIST">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/CPTTABLE">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/MEDIPASS_CERT_CODES">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/STRIP_LOCATIONS[SOFTWARE_ID != $SoftwareID]">
    <!--REMOVE ANYTHING NOT RELATED TO THIS SOFTWARE ID-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/PARTITION_CLIENT_FACILITY_INFO[SOFTWAREID != $SoftwareID]">
    <!--REMOVE ANYTHING NOT RELATED TO THIS SOFTWARE ID-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/BAD_GROUP_NUMS">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/BAD_SECONDARY_INSURANCES">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/SECONDARY_INSURANCE_COMPANY_CODES">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/TWEAKING_RULES">
    <!--REMOVE ALL-->
  </xsl:template>
  <xsl:template match="query_results/LOCATIONS/MUE_EDITS[SOFTWARE_ID != $SoftwareID]">
    <!--REMOVE ANYTHING NOT RELATED TO THIS SOFTWARE ID-->
  </xsl:template>
</xsl:stylesheet>

