<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="ta td" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attr" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="/">
    <ns1:SQLXML>
      <!-- Update Transactions -->
      <xsl:variable name="updateType" select="ta:getAttribute($attr, 'com.pilotfish.crl.statustype')" />
      <xsl:variable name="stagedBatchName" select="ta:getAttribute($attr, 'com.pilotfish.crl.stagedBatchName')" />
      <xsl:variable name="zipBatchName" select="ta:getAttribute($attr, 'zip.filename')" />
      <xsl:variable name="sourceClient" select="ta:getAttribute($attr, 'sourceClient')" />
      <xsl:variable name="excludeSourceClientFromBatchUpdate" select="ta:getAttribute($attr, 'excludeSourceClientFromBatchUpdate')" />
      <xsl:choose>
        <xsl:when test="$updateType = 'awaitingAttachments'">
          <!-- wait for manual attachments -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.AWAITING_ATTACHMENTS='Y', T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ?</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'status' and string-length($stagedBatchName) = 0">
          <!-- Case 1: Recently modified -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.LAST_STATUS_DELIVERED_DATE = cast(to_timestamp(?, 'YYYY-MM-DD HH24:MI:SS.FF3') AS DATE), T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ? AND T.LAST_MODIFIED_DATE &gt; cast(to_timestamp(?, 'YYYY-MM-DD HH24:MI:SS.FF3') AS DATE)</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.lastmodifiedate')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.lastmodifiedate')" />
            </ns1:Params>
          </ns1:Execute>
          <!-- Case 2: Not recently modified -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.LAST_STATUS_DELIVERED_DATE = SYSDATE, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ? AND T.LAST_MODIFIED_DATE &lt;= cast(to_timestamp(?, 'YYYY-MM-DD HH24:MI:SS.FF3') AS DATE)</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.lastmodifiedate')" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'status' and string-length($stagedBatchName) &gt; 0">
          <!-- status is just staged -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.LAST_STATUS_DELIVERED_DATE = SYSDATE, T.PF_BATCH_NAME = ?, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ?</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="$stagedBatchName" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'result' and string-length($stagedBatchName) = 0">
          <!-- final result delivered -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.FINAL_RESULT_DELIVERED_DATE = SYSDATE, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ?</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'result' and string-length($stagedBatchName) &gt; 0">
          <!-- result is just staged -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.FINAL_RESULT_STAGED_DATE = SYSDATE, T.PF_BATCH_NAME = ?, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ?</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="$stagedBatchName" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'batch' and string-length($stagedBatchName) &gt; 0 and $excludeSourceClientFromBatchUpdate = 'true'">
          <!-- staged batch has been sent: update interim status -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.LAST_STATUS_DELIVERED_DATE = SYSDATE, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null, T.PF_BATCH_NAME = ? WHERE T.PF_BATCH_NAME = ? and T.FINAL_RESULT_STAGED_DATE IS NULL</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$zipBatchName" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$stagedBatchName" />
            </ns1:Params>
          </ns1:Execute>
          <!-- staged batch has been sent: update final results -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.FINAL_RESULT_DELIVERED_DATE = SYSDATE, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null, T.PF_BATCH_NAME = ? WHERE T.PF_BATCH_NAME = ? and T.FINAL_RESULT_STAGED_DATE IS NOT NULL</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$zipBatchName" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$stagedBatchName" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'batch' and string-length($stagedBatchName) &gt; 0 and (not($excludeSourceClientFromBatchUpdate) or $excludeSourceClientFromBatchUpdate != 'true')">
          <!-- staged batch has been sent: update interim status -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.LAST_STATUS_DELIVERED_DATE = SYSDATE, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null, T.PF_BATCH_NAME = ? WHERE (T.PF_SOURCE_CLIENT=? OR T.TELEDEX_REMOTE_ID=?) AND T.PF_BATCH_NAME = ? and T.FINAL_RESULT_STAGED_DATE IS NULL</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$zipBatchName" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$sourceClient" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$sourceClient" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$stagedBatchName" />
            </ns1:Params>
          </ns1:Execute>
          <!-- staged batch has been sent: update final results -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.FINAL_RESULT_DELIVERED_DATE = SYSDATE, T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null, T.PF_BATCH_NAME = ? WHERE (T.PF_SOURCE_CLIENT=? OR T.TELEDEX_REMOTE_ID=?) AND T.PF_BATCH_NAME = ? and T.FINAL_RESULT_STAGED_DATE IS NOT NULL</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$zipBatchName" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$sourceClient" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$sourceClient" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="$stagedBatchName" />
            </ns1:Params>
          </ns1:Execute>
          <!-- staged batch has been sent: increment batch ID -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE BATCH B SET B.PF_BATCH_ID = (B.PF_BATCH_ID + 1) WHERE B.PF_SOURCE_CLIENT=?</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="$sourceClient" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:when test="$updateType = 'electronicorder'">
          <!-- The Electronic Order has been requested -->
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE STATUS S SET S.MESSAGE_SENT_DATE=SYSDATE WHERE S.MESSAGE_SENT_DATE IS NULL AND S.REQ_INFO_ID IN (SELECT R.REQ_INFO_ID FROM REQ_INFO R, POLICY P WHERE R.POLICY_ID=P.POLICY_ID AND R.REQ_CODE_TC=535 AND P.TRANSACTION_ID=?)</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
          </ns1:Execute>
          <ns1:Execute>
            <ns1:SQL>
              <xsl:text>UPDATE CRLTRANSACTION T SET T.LAST_MODIFIED_DATE = SYSDATE, T.LAST_MODIFIED_BY = ?, T.PF_PROCESSING_KEY = null WHERE T.TRANSACTION_ID = ?</xsl:text>
            </ns1:SQL>
            <ns1:Params>
              <xsl:value-of select="'pilotfish'" />
            </ns1:Params>
            <ns1:Params>
              <xsl:value-of select="ta:getAttribute($attr, 'com.pilotfish.crl.ordertransactionid')" />
            </ns1:Params>
          </ns1:Execute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>
            <xsl:value-of select="concat('Unexpected update type: ', $updateType)" />
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates />
    </ns1:SQLXML>
  </xsl:template>
  <xsl:template match="TRANSACTIONSTATUSES">
    <xsl:apply-templates />
  </xsl:template>
  <xsl:template match="STATUS">
    <!-- Update Status -->
    <ns1:Execute>
      <ns1:SQL>
        <xsl:text>update STATUS set message_sent_date = SYSDATE where status_id = ? and (message_sent_date is null or (message_sent_date &lt; status_event_date))</xsl:text>
      </ns1:SQL>
      <ns1:Params>
        <xsl:value-of select="STATUSID" />
      </ns1:Params>
    </ns1:Execute>
  </xsl:template>
</xsl:stylesheet>

