<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:saxon="http://saxon.sf.net/" xmlns:xip="com.pilotfish.xquery.library" extension-element-prefix="saxon" version="3.1">
  <xsl:output cdata-section-elements="Text" method="xml" />
  <xsl:param name="results" />
  <xsl:variable name="results-document" select="fn:parse-xml($results)" />
  <xsl:template match="/">
    <data>
      <xsl:apply-templates select="node()| @*" />
    </data>
  </xsl:template>
  <xsl:template match="node()">
    <xsl:copy>
      <xsl:variable name="curr-path" select="replace(path(.), 'Q\{\}', '')" />
      <xsl:variable name="att-path" select="replace($curr-path, '/@[A-Za-z]+', '')" />
      <xsl:apply-templates select="node() | @*" />
      <xsl:copy-of select="$results-document//Path[replace(., '/@[A-Za-z]+', '')=$att-path]/parent::error" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="@*">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" />
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

