<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" exclude-result-prefixes="converter ns1 ta td datetime dtFormatter" extension-element-prefixes="converter" version="1.0">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:Holding">
    <converter:register class="com.pilotfish.eip.transform.converters.EchoConverter" name="EchoConverter" params="EchoField">
      <Mode>Echo</Mode>
    </converter:register>
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
    <xsl:variable name="ID">
      <xsl:value-of select="converter:getGUIDString()" />
    </xsl:variable>
    <Attachment xmlns="http://ACORD.org/Standards/Life/2" id="{concat('crl_', $ID)}">
      <AttachmentBasicType tc="2">Image - This attachment contains only an image</AttachmentBasicType>
      <Description>Lab Results - Misc</Description>
      <AttachmentData>
        <xsl:value-of select="ta:getAttribute($attributes, 'com.crl.paclife.mergedTiff')" />
      </AttachmentData>
      <AttachmentType tc="1">Document</AttachmentType>
      <MimeType>image/tiff</MimeType>
      <MimeTypeTC tc="11">image/tiff</MimeTypeTC>
      <TransferEncodingTypeString>Base64</TransferEncodingTypeString>
      <TransferEncodingTypeTC tc="4">Base64</TransferEncodingTypeTC>
      <AttachmentLocation tc="1">Inline Data</AttachmentLocation>
      <LastUpdate>2015-07-16</LastUpdate>
    </Attachment>
  </xsl:template>
  <xsl:template match="ns1:Risk" />
  <xsl:template match="ns1:RequirementInfo" />
  <xsl:template match="ns1:Attachment" />
</xsl:stylesheet>

