<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="/ns1:TXLife">
    <TXLife>
      <Request>
        <xsl:for-each select="ns1:TXLifeRequest/ns1:OLifE/ns1:FormInstance">
          <Form>
            <FormNum>
              <xsl:value-of select="ns1:ProviderFormNumber" />
            </FormNum>
            <Name>
              <xsl:value-of select="ns1:FormName" />
            </Name>
            <Attachment>
              <Mime>
                <xsl:value-of select="ns1:Attachment/ns1:MimeTypeTC" />
              </Mime>
              <ImageType>
                <xsl:value-of select="ns1:Attachment/ns1:ImageType" />
              </ImageType>
              <Data>
                <xsl:value-of select="ns1:Attachment/ns1:AttachmentData" />
              </Data>
            </Attachment>
          </Form>
        </xsl:for-each>
      </Request>
    </TXLife>
  </xsl:template>
</xsl:stylesheet>

