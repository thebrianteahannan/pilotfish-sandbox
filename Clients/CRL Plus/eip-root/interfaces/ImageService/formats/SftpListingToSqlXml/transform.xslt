<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="1.0">
  <xsl:template match="/JSCHFiles">
    <ns1:SQLXML>
      <ns1:Execute into="validAttachments">
        <ns1:SQL>
          <xsl:text>SELECT b.*
FROM ATTACHMENT a, 
(SELECT TO_NUMBER(REGEXP_SUBSTR(COLUMN_VALUE, '^[^-]*')) as TRANSACTION_ID, 
TO_NUMBER(REGEXP_SUBSTR(COLUMN_VALUE, '^[^-]*-([^-]*)',1,1,'',1)) as ATTACHMENT_ID, 
COLUMN_VALUE as FILENAME 
FROM table(sys.odcivarchar2list(</xsl:text>
          <xsl:for-each select="File[number(substring-before(FileName,'-')) &gt; 0 and number(substring-before(substring-after(FileName,'-'),'-')) &gt; 0]">
            <xsl:if test="position() &gt; 1">
              <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>'</xsl:text>
            <xsl:value-of select="FileName" />
            <xsl:text>'</xsl:text>
          </xsl:for-each>
          <xsl:text>))) b
WHERE a.ATTACHMENT_ID=b.ATTACHMENT_ID AND a.TRANSACTION_ID=b.TRANSACTION_ID</xsl:text>
        </ns1:SQL>
      </ns1:Execute>
      <ns1:XMLOut var="validAttachments" />
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

