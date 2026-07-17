<?xml version="1.0" encoding="UTF-8"?>
<!--
  XSLT replacement for PilotFish AttributeConcatenationProcessor.

  Combines two sources into XCSData:
    1. Import  - transaction data stream (large XML working payload)
    2. Tag1    - wrapper element for a transaction attribute (small)

  XSLT Parameters (Advanced):
    Name      Value
    Tag1      query_results
    Source1   feed_info_query_results

  If Source1 is omitted, it defaults to Tag1.

  Do NOT store the large Import XML to an attribute; keep it on the data stream.
  Use Saxon engine.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:access="xalan://com.pilotfish.utils.AttributeAndPropertyAccessor" xmlns:local="http://local.functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="access xs local" extension-element-prefixes="access" version="3.1">
  <xsl:output encoding="UTF-8" indent="no" method="xml" version="1.0" />
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:param name="pf_accessObj" select="access:new($eiPlatformTransactionData)" />
  <xsl:param as="xs:string" name="Tag1" select="''" />
  <xsl:param as="xs:string" name="Source1" select="''" />
  <xsl:variable as="xs:string" name="attribute-name" select="if (normalize-space($Source1) != '') then $Source1 else $Tag1" />
  <xsl:function as="xs:string" name="local:strip-first-pi">
    <xsl:param as="xs:string" name="value" />
    <xsl:sequence select="    if (matches($value, '&lt;\?[^?]+\?&gt;'))    then replace($value, '(.*?)&lt;\?[^?]+\?&gt;(.*)', '$1$2')    else $value   " />
  </xsl:function>
  <xsl:template name="concat-from-attribute">
    <xsl:param as="xs:string" name="attribute-name" />
    <xsl:variable name="value" select="access:getAttributeString($pf_accessObj, $attribute-name)" />
    <xsl:variable name="content" select="local:strip-first-pi($value)" />
    <xsl:choose>
      <xsl:when test="normalize-space($content) != '' and $content != 'null'">
        <xsl:try>
          <xsl:copy-of select="parse-xml($content)/node()" />
          <xsl:catch>
            <xsl:value-of select="$content" />
          </xsl:catch>
        </xsl:try>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$content" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="/">
    <XCSData>
      <Import>
        <xsl:copy-of select="/*" />
      </Import>
      <xsl:if test="normalize-space($Tag1) != ''">
        <xsl:element name="{$Tag1}">
          <xsl:call-template name="concat-from-attribute">
            <xsl:with-param name="attribute-name" select="$attribute-name" />
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

