<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:ns1="http://pilotfish.sqlxml" xmlns:ns2="http://crlcorp.com/schema/DocumentRequest" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="ns2:StoreDocumentResponse">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <ns1:SQLXML>
      <ns1:Execute into="">
        <ns1:SQL>INSERT INTO ATTACHMENT
				(TRANSACTION_ID,
				DESCR,
				TYPE_TC,
				TYPE_TXT,
				MIMETYPE,
				ENCTYPESTR,
				LOCATION_TC,
				CRL_DOCUMENT_ID,
				CRL_FOLDER_ID,
				CRL_DRAWER_NAME,
				CRL_PAGE_COUNT,
				PLATFORM)
				VALUES
				(nvl((select max(TRANSACTION_ID) from CRLTRANSACTION WHERE TELEDEX_ORDER_NUM=?),0),
				?,
				1,
				'Document',
				'application/pdf',
				'base64',
				1,
				?,
				?,
				?,
				?,
				'F')</ns1:SQL>
        <!--TELEDEX_ORDER_NUM-->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('Incoming103_TeledexOrderNum')" />
        </ns1:Params>
        <!--DESCR-->
        <ns1:Params>
          <xsl:value-of select="converter:getAttributeString('Incoming103_Filename')" />
        </ns1:Params>
        <!--CRL_DOCUMENT_ID-->
        <ns1:Params>
          <xsl:value-of select="ns2:DocumentId" />
        </ns1:Params>
        <!--CRL_FOLDER_ID-->
        <ns1:Params>
          <xsl:value-of select="ns2:FolderId" />
        </ns1:Params>
        <!--CRL_DRAWER_NAME-->
        <ns1:Params>
          <xsl:value-of select="ns2:DrawerName" />
        </ns1:Params>
        <!--CRL_PAGE_COUNT-->
        <ns1:Params>
          <xsl:value-of select="ns2:PageCount" />
        </ns1:Params>
      </ns1:Execute>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

