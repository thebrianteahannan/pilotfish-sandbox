<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://ACORD.org/Standards/Life/2" xmlns:converter="xalan://com.pilotfish.eip.transform.ConverterProxy" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="http://ACORD.org/Standards/Life/2" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ta="xalan://com.pilotfish.eip.TransactionAttributes" xmlns:td="xalan://com.pilotfish.eip.TransactionData" xmlns:tem="http://tempuri.org/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="converter datetime dtFormatter ta td ns2 xsl xsi xsd" extension-element-prefixes="converter" version="1.0" xsi:schemaLocation="http://ACORD.org/Standards/Life/2 TXLife2.20.02.xsd">
  <xsl:param name="eiPlatformTransactionData" />
  <xsl:variable name="attributes" select="td:getAttributes($eiPlatformTransactionData)" />
  <xsl:template match="node()">
    <!-- strip out empty elements that have no attributes -->
    <xsl:choose>
      <xsl:when test="string-length(name()) &gt; 1">
        <xsl:if test="normalize-space(string(.)) != '' or count(*) &gt; 0 or @*[string-length(.) &gt; 0]">
          <xsl:element name="{name()}" namespace="{namespace-uri()}">
            <xsl:apply-templates select="node()|@*[.!='']" />
          </xsl:element>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="node()|@*[.!='']" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="@*">
    <!-- strip out empty elements that have no attributes -->
    <xsl:if test="normalize-space(string(.)) != '' or count(*) &gt; 0 or @*[string-length(.) &gt; 0]">
      <xsl:copy>
        <xsl:apply-templates select="node()|@*[.!='']" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <xsl:template match="ns2:Attachment[not(../preceding-sibling::ns2:RequirementInfo/ns2:Attachment[string-length(ns2:AttachmentData) &gt; 5])][string-length(ns2:AttachmentData) &gt; 5][1]">
    <xsl:choose>
      <xsl:when test="string-length(ns2:AttachmentData) &gt; 20">
        <!-- use inline image data -->
        <xsl:variable name="throwaway" select="ta:setAttribute($attributes, 'acord.tiff.image', string(ns2:AttachmentData))" />
      </xsl:when>
      <xsl:otherwise>
        <!-- for large image attachments, the AttachmentData is in an attribute -->
        <xsl:variable name="image" select="ta:getAttribute($attributes, string(ns2:AttachmentData))" />
        <xsl:variable name="throwaway" select="ta:setAttribute($attributes, 'acord.tiff.image', $image)" />
        <xsl:variable name="throwawayx" select="ta:setAttribute($attributes, string(ns2:AttachmentData), '--merged--')" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="*" mode="copy">
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <xsl:apply-templates select="@*|node()" />
    </xsl:element>
  </xsl:template>
  <xsl:template match="@*|text()|comment()" mode="copy">
    <xsl:copy />
  </xsl:template>
</xsl:stylesheet>

