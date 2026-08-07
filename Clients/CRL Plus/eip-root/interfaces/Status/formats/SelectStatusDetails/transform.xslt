<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sql="http://pilotfish.sqlxml" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="td ta" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/">
    <sql:SQLXML>
      <xsl:variable name="txid">
        <xsl:value-of select="//TRANSACTIONID" />
      </xsl:variable>
      <xsl:variable name="sourceClient">
        <xsl:value-of select="//PFSOURCECLIENT" />
      </xsl:variable>
      <xsl:variable name="setAttribute" select="ta:setAttribute($attributes, 'com.pilotfish.crl.ordertransactionid', $txid)" />
      <xsl:variable name="setAnother" select="ta:setAttribute($attributes, 'sourceClient', $sourceClient)" />
      <xsl:variable name="onlyStatusesNotPreviouslySent">
        <xsl:choose>
          <xsl:when test="$sourceClient='METL' or $sourceClient='PACT'">
            <xsl:value-of select="'true'" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'false'" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <sql:Select as="transaction" into="results">
        <CRLTRANSACTION>
          <TRANSACTION_ID key="true">
            <xsl:value-of select="$txid" />
          </TRANSACTION_ID>
          <TRANSREFGUID />
          <TYPE_TC />
          <TYPE_TXT />
          <EXE_DATE />
          <MODE_TC />
          <MODE_TXT />
          <TESTINDICATOR />
          <CREATION_DATE />
          <SOURCE_INFO_NAME />
          <SOURCE_INFO_DESCR />
          <PF_SOURCE_CLIENT />
          <ORDER_COMPLETE_DATE />
          <CREATED_BY />
          <CREATED_DATE />
          <LAST_MODIFIED_BY />
          <LAST_MODIFIED_DATE />
          <LAST_STATUS_DELIVERED_DATE />
          <FINAL_RESULT_DELIVERED_DATE />
          <PLATFORM />
          <FLOWNET_ORDER_NUM />
          <AWAITING_ATTACHMENTS />
          <TELEDEX_REMOTE_ID />
          <TELEDEX_ORDER_NUM />
        </CRLTRANSACTION>
      </sql:Select>
      <sql:Iterate as="transaction" over="results">
        <sql:Select into="transaction.text">
          <TRANSACTION_TEXT>
            <TRANSACTION_TEXT_ID />
            <TRANSACTION_ID key="true">
              <xsl:value-of select="$txid" />
            </TRANSACTION_ID>
            <ORIGINAL_TXT />
            <ORIGINAL_TYPE />
            <NORMALIZED_TXT />
          </TRANSACTION_TEXT>
        </sql:Select>
        <sql:Execute as="aie" into="transaction.acord_information_exchange">
          <sql:SQL>select * from ACORD_INFORMATION_EXCHANGE where TRANSACTION_ID=?</sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <sql:Execute as="policy" into="transaction.policy">
          <sql:SQL>select * from POLICY where TRANSACTION_ID=?</sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <sql:Execute as="reqinfo" into="transaction.reqinfo">
          <sql:SQL>select * from REQ_INFO where POLICY_ID in (select POLICY_ID from POLICY where TRANSACTION_ID=?)</sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <xsl:variable name="statusWhereClause">
          <xsl:choose>
            <xsl:when test="$onlyStatusesNotPreviouslySent='true'">
              <xsl:value-of select="' and MESSAGE_SENT_DATE IS NULL '" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="' '" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="statusFromClause" select="concat('from STATUS where REQ_INFO_ID in (select REQ_INFO_ID from REQ_INFO where POLICY_ID in (select POLICY_ID from POLICY where TRANSACTION_ID=?))',$statusWhereClause)" />
        <sql:Execute as="status" into="transaction.statuses">
          <sql:SQL>
            <xsl:value-of select="concat('select * ',$statusFromClause)" />
          </sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <sql:Execute as="attachment" into="transaction.attachment">
          <!--<sql:SQL>select * from ATTACHMENT where STATUS_ID in (select STATUS_ID from STATUS where REQ_INFO_ID in (select REQ_INFO_ID from REQ_INFO where POLICY_ID in (select POLICY_ID from POLICY where TRANSACTION_ID=?)))</sql:SQL>-->
          <sql:SQL>
            <xsl:value-of select="concat('select * from ATTACHMENT where STATUS_ID in (select STATUS_ID ',$statusFromClause,')')" />
          </sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <sql:Execute as="attachmentDescription" into="transaction.attachmentDescription">
          <sql:SQL>
            <xsl:text>select DESCR from ATTACHMENT where TRANSACTION_ID = ? and STATUS_ID is null</xsl:text>
          </sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <sql:Execute as="status" into="transaction.reportedstatus">
          <sql:SQL>
            <xsl:text>select * from STATUS where REQ_INFO_ID in (select REQ_INFO_ID from REQ_INFO where POLICY_ID in (select POLICY_ID from POLICY where TRANSACTION_ID=?)) and PROVIDER_EVENT_CODE='S82'</xsl:text>
          </sql:SQL>
          <sql:Params>
            <xsl:value-of select="$txid" />
          </sql:Params>
        </sql:Execute>
        <sql:Execute as="party" into="transaction.party">
          <sql:SQL>select * from PARTY where TRANSACTION_ID=?</sql:SQL>
          <sql:Params>ognl:#transaction.getFieldValue('TRANSACTION_ID')</sql:Params>
        </sql:Execute>
        <sql:Execute as="address" into="transaction.address">
          <sql:SQL>select * from ADDRESS where PARTY_ID in (select PARTY_ID from PARTY where TRANSACTION_ID=?)</sql:SQL>
          <sql:Params>ognl:#transaction.getFieldValue('TRANSACTION_ID')</sql:Params>
        </sql:Execute>
        <sql:Execute as="phone" into="transaction.phone">
          <sql:SQL>select * from PHONE where PARTY_ID in (select PARTY_ID from PARTY where TRANSACTION_ID=?)</sql:SQL>
          <sql:Params>ognl:#transaction.getFieldValue('TRANSACTION_ID')</sql:Params>
        </sql:Execute>
        <sql:Execute as="email" into="transaction.email">
          <sql:SQL>select * from EMAIL where PARTY_ID in (select PARTY_ID from PARTY where TRANSACTION_ID=?)</sql:SQL>
          <sql:Params>ognl:#transaction.getFieldValue('TRANSACTION_ID')</sql:Params>
        </sql:Execute>
        <sql:Execute as="relation" into="transaction.partyrelation">
          <sql:SQL>select * from RELATION where RELATED_PARTY_ID in (select PARTY_ID from PARTY where TRANSACTION_ID=?)</sql:SQL>
          <sql:Params>ognl:#transaction.getFieldValue('TRANSACTION_ID')</sql:Params>
        </sql:Execute>
        <sql:Execute as="relation" into="transaction.policyrelation">
          <sql:SQL>select * from RELATION where ORIGINATING_PARTY_ID in (select PARTY_ID from PARTY where TRANSACTION_ID=?)</sql:SQL>
          <sql:Params>ognl:#transaction.getFieldValue('TRANSACTION_ID')</sql:Params>
        </sql:Execute>
      </sql:Iterate>
      <XMLOut var="results" />
    </sql:SQLXML>
  </xsl:template>
</xsl:stylesheet>

