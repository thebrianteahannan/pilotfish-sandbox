<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ns2="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns3="http://crlcorp.com/schema/DocumentRequest" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="/ns1:Attachment">
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
    <ns2:Envelope>
      <ns2:Header />
      <ns2:Body>
        <ns3:StoreDocumentRequest>
          <ns3:UserId>
            <xsl:text>CRL_PLUS_INSIGHT</xsl:text>
          </ns3:UserId>
          <ns3:DrawerName>
            <xsl:text>CRL_PLUS</xsl:text>
          </ns3:DrawerName>
          <ns3:DocumentType>
            <xsl:text>APPLICATION</xsl:text>
          </ns3:DocumentType>
          <ns3:Pages>
            <ns3:PageSequence>
              <xsl:text>1</xsl:text>
            </ns3:PageSequence>
            <ns3:Images>
              <ns3:MimeType>
                <xsl:variable name="lowercaseDescr" select="translate(ns1:Description, $uppercase, $lowercase)" />
                <xsl:choose>
                  <xsl:when test="substring-after($lowercaseDescr,'.') = 'tif' or substring-after($lowercaseDescr,'.') = 'tiff'">
                    <xsl:text>image/tiff</xsl:text>
                  </xsl:when>
                  <xsl:when test="substring-after($lowercaseDescr,'.') = 'gif'">
                    <xsl:text>image/gif</xsl:text>
                  </xsl:when>
                  <xsl:when test="substring-after($lowercaseDescr,'.') = 'png'">
                    <xsl:text>image/png</xsl:text>
                  </xsl:when>
                  <xsl:when test="substring-after($lowercaseDescr,'.') = 'jpg' or substring-after($lowercaseDescr, '.') = 'jpeg'">
                    <xsl:text>image/jpg</xsl:text>
                  </xsl:when>
                  <xsl:when test="substring-after($lowercaseDescr,'.') = 'pdf'">
                    <xsl:text>application/pdf</xsl:text>
                  </xsl:when>
                </xsl:choose>
              </ns3:MimeType>
              <ns3:ImageSequence>
                <xsl:text>1</xsl:text>
              </ns3:ImageSequence>
              <ns3:DataBuffer>
                <xsl:value-of select="ns1:AttachmentData" />
              </ns3:DataBuffer>
            </ns3:Images>
          </ns3:Pages>
        </ns3:StoreDocumentRequest>
      </ns2:Body>
    </ns2:Envelope>
  </xsl:template>
</xsl:stylesheet>

