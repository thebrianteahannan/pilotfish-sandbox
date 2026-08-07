<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:sql="http://pilotfish.sqlxml" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ns1 datetime ta td dtFormatter" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/">
    <SQLXML xmlns="http://pilotfish.sqlxml">
      <!-- Validate required attributes -->
      <xsl:call-template name="validateRequiredAttributes" />
      <!-- Insert message row -->
      <Execute>
        <SQL>
          <xsl:text>INSERT INTO CRLMESSAGES(TRANSACTION_ID, MESSAGE_DATE, PF_SOURCE_CLIENT, MESSAGE_TYPE, CONTENTS_TYPE, CONTENTS) VALUES(?, SYSDATE, ?, ?, ?, ?)</xsl:text>
        </SQL>
        <Params>
          <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.ordertransactionid')" />
        </Params>
        <Params>
          <xsl:value-of select="ta:getAttribute($attributes, 'sourceClient')" />
        </Params>
        <Params>
          <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.message.type')" />
        </Params>
        <Params>
          <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.contents.type')" />
        </Params>
        <Params>
          <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.insert_message')" />
        </Params>
      </Execute>
      <!-- Fetch inserted row -->
      <Execute as="message" into="messages">
        <SQL>SELECT MAX(MESSAGE_ID) AS MESSAGE_ID FROM CRLMESSAGES WHERE TRANSACTION_ID = ?</SQL>
        <Params>
          <xsl:value-of select="ta:getAttribute($attributes, 'com.pilotfish.crl.ordertransactionid')" />
        </Params>
      </Execute>
      <!-- Insert attributes -->
      <Iterate as="message" over="messages">
        <!-- pickle -->
        <xsl:call-template name="insertAttribute">
          <xsl:with-param name="attributeName" select="'pickle'" />
        </xsl:call-template>
      </Iterate>
    </SQLXML>
  </xsl:template>
  <!-- Inserts an attribute name/value row -->
  <xsl:template name="insertAttribute">
    <xsl:param name="attributeName" />
    <Execute>
      <SQL>INSERT INTO CRLATTRIBUTES(MESSAGE_ID, ATTRIBUTE_NAME, ATTRIBUTE_VALUE) VALUES(?, ?, ?)</SQL>
      <Params>
        <xsl:text>ognl:#message('MESSAGE_ID')</xsl:text>
      </Params>
      <Params>
        <xsl:value-of select="$attributeName" />
      </Params>
      <Params>
        <xsl:value-of select="ta:getAttribute($attributes, $attributeName)" />
      </Params>
    </Execute>
  </xsl:template>
  <!-- Validates attributes that are required -->
  <xsl:template name="validateRequiredAttributes">
    <!-- sourceClient -->
    <xsl:call-template name="validateRequiredAttribute">
      <xsl:with-param name="attributeName" select="'sourceClient'" />
    </xsl:call-template>
    <!-- com.pilotfish.crl.ordertransactionid -->
    <xsl:call-template name="validateRequiredAttribute">
      <xsl:with-param name="attributeName" select="'com.pilotfish.crl.ordertransactionid'" />
    </xsl:call-template>
    <!-- com.pilotfish.crl.message.type -->
    <xsl:call-template name="validateRequiredAttribute">
      <xsl:with-param name="attributeName" select="'com.pilotfish.crl.message.type'" />
    </xsl:call-template>
    <!-- com.pilotfish.crl.contents.type -->
    <xsl:call-template name="validateRequiredAttribute">
      <xsl:with-param name="attributeName" select="'com.pilotfish.crl.contents.type'" />
    </xsl:call-template>
    <!-- com.pilotfish.crl.insert_message -->
    <xsl:call-template name="validateRequiredAttribute">
      <xsl:with-param name="attributeName" select="'com.pilotfish.crl.insert_message'" />
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="validateRequiredAttribute">
    <xsl:param name="attributeName" />
    <!-- Fetch attribute value -->
    <xsl:variable name="attribute" select="ta:getAttribute($attributes, $attributeName)" />
    <!-- Check normalized string length of attribute -->
    <xsl:if test="string-length(normalize-space($attribute)) = 0">
      <!-- If it's empty / blank, report an error -->
      <xsl:message>
        <xsl:value-of select="concat('Expected attribute [', $attributeName, ']')" />
      </xsl:message>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>

