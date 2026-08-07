<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:doc="http://crlcorp.com/schema/DocumentRequest" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="converter" extension-element-prefixes="converter" version="1.0">
  <xsl:template match="/RESULTS">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <soapenv:Envelope>
      <soapenv:Header />
      <soapenv:Body>
        <xsl:variable name="crlDocumentID" select="converter:getAttributeString('CRL_DOCUMENT_ID')" />
        <xsl:for-each select="TRANSACTIONATTACHMENT/ATTACHMENT[CRLDOCUMENTID = $crlDocumentID][1]">
          <doc:GetDocumentRequest>
            <doc:DrawerName>
              <xsl:choose>
                <xsl:when test="string-length(CRLDRAWERNAME) &gt; 0">
                  <xsl:value-of select="CRLDRAWERNAME" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>CRL_PLUS</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </doc:DrawerName>
            <doc:UserId>
              <xsl:text>CRL_PLUS_INSIGHT</xsl:text>
            </doc:UserId>
            <doc:SearchCriteria>
              <doc:DocumentId>
                <xsl:value-of select="CRLDOCUMENTID" />
              </doc:DocumentId>
              <doc:OutputType>
                <xsl:choose>
                  <!-- The CRL Imaging Service cannot convert PDF files. -->
                  <xsl:when test="MIMETYPE = 'application/pdf'">
                    <xsl:text>PDF</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>TIFF</xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </doc:OutputType>
            </doc:SearchCriteria>
          </doc:GetDocumentRequest>
        </xsl:for-each>
      </soapenv:Body>
    </soapenv:Envelope>
  </xsl:template>
</xsl:stylesheet>

