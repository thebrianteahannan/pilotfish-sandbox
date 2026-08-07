<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:java="java" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ns3="http://www.w3.org/1999/xhtml" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ns1" version="1.0">
  <xsl:output method="text" />
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:variable name="sourceClient" select="ta:getAttribute($attributes, 'sourceClient')" />
  <xsl:variable name="crlEnv" select="ta:getAttribute($attributes, 'crl.environment')" />
  <xsl:template match="/ns1:TXLife">
    <xsl:text>Cancellation received, but did not find existing order in PilotFish database</xsl:text>
    <xsl:value-of select="'&#xA;&#xA;'" />
    <xsl:value-of select="'ENVIRONMENT = '" />
    <xsl:value-of select="$crlEnv" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'PF_SOURCE_CLIENT = '" />
    <xsl:value-of select="$sourceClient" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'RECEIVED_DATE = '" />
    <xsl:call-template name="currentDateTime" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'ACCOUNT_NUMBER = '" />
    <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementAcctNum" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'POLNUMBER = '" />
    <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:PolNumber" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'TRACKING_ID = '" />
    <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:ApplicationInfo/ns1:TrackingID" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'REQ_INFO_UNIQUE_ID = '" />
    <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:RequirementInfoUniqueID" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'CARRIER_CODE = '" />
    <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:CarrierCode" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'CARRIER_ORDER_NUM = '" />
    <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:Holding/ns1:Policy/ns1:RequirementInfo/ns1:CarrierOrderNum" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'TRANSACTION_DATE = '" />
    <xsl:choose>
      <xsl:when test="string-length(ns1:TXLifeRequest/ns1:TransExeDate) &gt; 0">
        <xsl:value-of select="ns1:TXLifeRequest/ns1:TransExeDate" />
        <xsl:value-of select="' '" />
        <xsl:value-of select="ns1:TXLifeRequest/ns1:TransExeTime" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:CreationDate" />
        <xsl:value-of select="' '" />
        <xsl:value-of select="ns1:TXLifeRequest/ns1:OLifE/ns1:SourceInfo/ns1:CreationTime" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'&#xA;'" />
    <xsl:value-of select="'PF_SERVER_HOSTNAME = '" />
    <xsl:variable name="localHost" select="java:net.InetAddress.getLocalHost()" />
    <xsl:value-of select="java:getHostName($localHost)" />
    <xsl:value-of select="'&#xA;'" />
  </xsl:template>
  <xsl:template name="currentDateTime">
    <xsl:value-of select="datetime:year()" />
    <xsl:value-of select="'-'" />
    <xsl:value-of select="datetime:month-in-year()" />
    <xsl:value-of select="'-'" />
    <xsl:value-of select="datetime:day-in-month()" />
    <xsl:value-of select="' '" />
    <xsl:value-of select="datetime:hour-in-day()" />
    <xsl:value-of select="':'" />
    <xsl:call-template name="makeTwoDigit">
      <xsl:with-param name="value" select="datetime:minute-in-hour()" />
    </xsl:call-template>
    <xsl:value-of select="':'" />
    <xsl:call-template name="makeTwoDigit">
      <xsl:with-param name="value" select="datetime:second-in-minute()" />
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="makeTwoDigit">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="string-length($value) &gt;1">
        <xsl:value-of select="$value" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('0',$value)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

