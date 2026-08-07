<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="1.0">
  <xsl:template match="/RECORD">
    <ns1:SQLXML>
      <ns1:Execute into="">
        <ns1:SQL>update ATTACHMENT set CRL_DOCUMENT_ID=?,CRL_FILENAME=? where ATTACHMENT_ID=?</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="ATTACHMENTID" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="FILENAME" />
        </ns1:Params>
        <ns1:Params>
          <xsl:value-of select="ATTACHMENTID" />
        </ns1:Params>
      </ns1:Execute>
      <ns1:Execute into="">
        <ns1:SQL>update STATUS set MESSAGE_SENT_DATE=null where STATUS_ID in (select STATUS_ID from ATTACHMENT where ATTACHMENT_ID=?)</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="ATTACHMENTID" />
        </ns1:Params>
      </ns1:Execute>
      <ns1:Execute into="">
        <ns1:SQL>update CRLTRANSACTION set LAST_MODIFIED_BY=?, LAST_MODIFIED_DATE=sysdate, AWAITING_ATTACHMENTS='N' where TRANSACTION_ID=?</ns1:SQL>
        <ns1:Params>pilotfish</ns1:Params>
        <ns1:Params>
          <xsl:value-of select="TRANSACTIONID" />
        </ns1:Params>
      </ns1:Execute>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

