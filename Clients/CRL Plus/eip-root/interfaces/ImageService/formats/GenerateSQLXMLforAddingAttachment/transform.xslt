<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="1.0">
  <xsl:template match="/attachment">
    <ns1:SQLXML>
      <ns1:Execute as="transrow" into="transaction">
        <ns1:SQL>select p.TRANSACTION_ID from POLICY p inner join REQ_INFO r on r.POLICY_ID=p.POLICY_ID inner join STATUS s on s.REQ_INFO_ID=r.REQ_INFO_ID where s.STATUS_ID = ?</ns1:SQL>
        <ns1:Params>
          <xsl:value-of select="status_id" />
        </ns1:Params>
      </ns1:Execute>
      <ns1:Iterate as="transrow" over="transaction">
        <ns1:Insert>
          <ATTACHMENT>
            <TRANSACTION_ID>ognl:#transrow.getFieldValue('TRANSACTION_ID')</TRANSACTION_ID>
            <STATUS_ID>
              <xsl:value-of select="status_id" />
            </STATUS_ID>
            <BASICTYPE_TC>2</BASICTYPE_TC>
            <BASICTYPE_TXT>Image</BASICTYPE_TXT>
            <DESCR>
              <xsl:value-of select="filename" />
            </DESCR>
            <TYPE_TC>167</TYPE_TC>
            <TYPE_TXT>OLI_ATTACH_APSREPORT</TYPE_TXT>
            <MIMETYPE>application/pdf</MIMETYPE>
            <ENCTYPESTR>OLI_ENCODE_BASE64</ENCTYPESTR>
            <ENCTYPE_TC>4</ENCTYPE_TC>
            <LOCATION_TC>1</LOCATION_TC>
            <CRL_DOCUMENT_ID>
              <xsl:value-of select="status_id" />
            </CRL_DOCUMENT_ID>
            <CRL_DRAWER_NAME>SFTP FOLDER</CRL_DRAWER_NAME>
            <CRL_FILENAME>
              <xsl:value-of select="filename" />
            </CRL_FILENAME>
          </ATTACHMENT>
        </ns1:Insert>
        <ns1:Execute into="">
          <ns1:SQL>update STATUS set MESSAGE_SENT_DATE=null where status_id=?</ns1:SQL>
          <ns1:Params>
            <xsl:value-of select="status_id" />
          </ns1:Params>
        </ns1:Execute>
        <ns1:Execute into="">
          <ns1:SQL>update CRLTRANSACTION set LAST_MODIFIED_BY=?, LAST_MODIFIED_DATE=sysdate where TRANSACTION_ID=?</ns1:SQL>
          <ns1:Params>pilotfish</ns1:Params>
          <ns1:Params>ognl:#transrow.getFieldValue('TRANSACTION_ID')</ns1:Params>
        </ns1:Execute>
      </ns1:Iterate>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

