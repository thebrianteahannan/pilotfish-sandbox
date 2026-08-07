<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td" version="1.0">
  <xsl:output indent="no" method="text" />
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/Image">
    <xsl:variable name="storeFileName" select="ta:setAttribute($attributes, 'filename', string(BASE_FILENAME))" />
    <xsl:variable name="lf" select="'&#xA;'" />
    <xsl:value-of select="'PAGES = '" />
    <xsl:value-of select="PAGES" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'SUBJECT = '" />
    <xsl:value-of select="SUBJECT" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'LNAME = '" />
    <xsl:value-of select="LNAME" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'FNAME = '" />
    <xsl:value-of select="FNAME" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'MI = '" />
    <xsl:value-of select="MI" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'DOB = '" />
    <xsl:value-of select="DOB" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'SSN = '" />
    <xsl:value-of select="SSN" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'BSTATE = '" />
    <xsl:value-of select="BSTATE" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'CASENO = '" />
    <xsl:value-of select="CASENO" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'POLNO = '" />
    <xsl:value-of select="POLNO" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'DOCTOR = '" />
    <xsl:value-of select="DOCTOR" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'PROVIDER = '" />
    <xsl:value-of select="PROVIDER" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'REQUIRE = '" />
    <xsl:value-of select="REQUIRE" />
    <xsl:value-of select="$lf" />
    <xsl:value-of select="'COMPANY = '" />
    <xsl:value-of select="COMPANY" />
    <xsl:value-of select="$lf" />
  </xsl:template>
</xsl:stylesheet>

