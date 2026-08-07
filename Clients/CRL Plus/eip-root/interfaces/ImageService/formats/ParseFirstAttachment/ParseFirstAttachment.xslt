<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:doc="http://crlcorp.com/schema/DocumentRequest" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" exclude-result-prefixes="ns2" version="1.0">
  <xsl:template match="/ns2:TXLife">
    <xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
    <soapenv:Envelope>
      <soapenv:Body>
        <doc:StoreDocumentRequest>
          <doc:DrawerName>
            <xsl:text>CRL_PLUS</xsl:text>
          </doc:DrawerName>
          <doc:UserId>
            <xsl:text>CRL_PLUS_INSIGHT</xsl:text>
          </doc:UserId>
          <doc:DocumentType>
            <xsl:text>APPLICATION</xsl:text>
          </doc:DocumentType>
          <doc:DocumentIndex>
            <doc:ColumnName>ORDER_NUMBER</doc:ColumnName>
            <doc:ColumnValue>
              <doc:Value>
                <xsl:value-of select="//ns2:TransRefGUID" />
              </doc:Value>
              <doc:Type>TEXT</doc:Type>
            </doc:ColumnValue>
          </doc:DocumentIndex>
          <doc:Pages>
            <doc:OriginalFileName>
              <xsl:variable name="attachmentElement" select="//ns2:Attachment[string-length(ns2:AttachmentData) &gt; 0][1]" />
              <xsl:choose>
                <!-- workaround for when Pacific Life sends in PDF files that are incorrectly tagged as TIFF files -->
                <xsl:when test="substring($attachmentElement/ns2:AttachmentData,1,5)='JVBER'">
                  <xsl:value-of select="translate(concat($attachmentElement/ns2:Description,'.pdf'), $upper, $lower)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="translate($attachmentElement/ns2:Description, $upper, $lower)" />
                </xsl:otherwise>
              </xsl:choose>
            </doc:OriginalFileName>
            <doc:PageSequence>
              <xsl:text>1</xsl:text>
            </doc:PageSequence>
            <!-- use first non-empty attachment -->
            <xsl:for-each select="//ns2:Attachment[string-length(ns2:AttachmentData) &gt; 0][1]">
              <doc:Images>
                <doc:MimeType>
                  <xsl:variable name="mimeTC" select="ns2:MimeTypeTC/@tc" />
                  <xsl:variable name="descr" select="translate(ns2:Description, $upper, $lower)" />
                  <xsl:variable name="ext" select="substring($descr, string-length($descr) - 2)" />
                  <xsl:choose>
                    <!-- workaround for when Pacific Life sends in PDF files that are incorrectly tagged as TIFF files -->
                    <xsl:when test="substring(ns2:AttachmentData,1,5)='JVBER'">
                      <xsl:text>application/pdf</xsl:text>
                    </xsl:when>
                    <xsl:when test="$mimeTC = 11">
                      <xsl:text>image/tiff</xsl:text>
                    </xsl:when>
                    <xsl:when test="$mimeTC = 4">
                      <xsl:text>image/gif</xsl:text>
                    </xsl:when>
                    <xsl:when test="$mimeTC = 3">
                      <xsl:text>image/jpeg</xsl:text>
                    </xsl:when>
                    <xsl:when test="$mimeTC = 33">
                      <xsl:text>image/png</xsl:text>
                    </xsl:when>
                    <xsl:when test="$mimeTC = 17 or $ext='pdf' or $ext='PDF'">
                      <xsl:text>application/pdf</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'tif' or substring($descr, string-length($descr) - 3) = 'tiff'">
                      <xsl:text>image/tiff</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'gif'">
                      <xsl:text>image/gif</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'bmp'">
                      <xsl:text>image/bmp</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'jpg' or substring($descr, string-length($descr) - 3) = 'jpeg'">
                      <xsl:text>image/jpeg</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'png'">
                      <xsl:text>image/png</xsl:text>
                    </xsl:when>
                    <xsl:when test="$ext = 'pdf'">
                      <xsl:text>application/pdf</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>image/</xsl:text>
                      <xsl:value-of select="$ext" />
                    </xsl:otherwise>
                  </xsl:choose>
                </doc:MimeType>
                <doc:ImageSequence>
                  <xsl:text>1</xsl:text>
                </doc:ImageSequence>
                <doc:DataBuffer>
                  <xsl:value-of select="ns2:AttachmentData" />
                </doc:DataBuffer>
              </doc:Images>
            </xsl:for-each>
          </doc:Pages>
        </doc:StoreDocumentRequest>
      </soapenv:Body>
    </soapenv:Envelope>
  </xsl:template>
</xsl:stylesheet>

