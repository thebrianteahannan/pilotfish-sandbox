<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/INCOMING103">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <soapenv:Envelope>
      <soapenv:Body>
        <StoreDocumentRequest xmlns="http://crlcorp.com/schema/DocumentRequest">
          <DrawerName>CRL_PLUS</DrawerName>
          <UserId>CRL_PLUS_INSIGHT</UserId>
          <DocumentType>APPLICATION</DocumentType>
          <DocumentIndex>
            <ColumnName>ORDER_NUMBER</ColumnName>
            <ColumnValue>
              <Value>
                <xsl:choose>
                  <xsl:when test="string-length(converter:getAttributeString('Incoming103_FlownetOrderNum'))&gt;0">
                    <xsl:value-of select="converter:getAttributeString('Incoming103_FlownetOrderNum')" />
                  </xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </Value>
              <Type>TEXT</Type>
            </ColumnValue>
          </DocumentIndex>
          <Pages>
            <OriginalFileName>
              <xsl:value-of select="FILENAME" />
            </OriginalFileName>
            <PageSequence>1</PageSequence>
            <Images>
              <MimeType>
                <xsl:value-of select="FILEMIMETYPE" />
              </MimeType>
              <ImageSequence>1</ImageSequence>
              <DataBuffer>
                <xsl:value-of select="FILEDATA" />
              </DataBuffer>
            </Images>
          </Pages>
        </StoreDocumentRequest>
      </soapenv:Body>
    </soapenv:Envelope>
  </xsl:template>
</xsl:stylesheet>

