<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:java="http://xml.apache.org/xalan/java" exclude-result-prefixes="java" version="1.0">
  <xsl:template match="/JSCHFiles">
    <xsl:variable name="date" select="java:java.util.Date.new()" />
    <xsl:variable name="now" select="floor(java:getTime($date) div 1000)" />
    <JSCHFiles>
      <xsl:for-each select="File">
        <File>
          <xsl:copy-of select="*" />
          <Now>
            <xsl:value-of select="$now" />
          </Now>
          <DaysOld>
            <xsl:value-of select="floor(($now - number(LastModifiedTime)) div (86400))" />
          </DaysOld>
        </File>
      </xsl:for-each>
    </JSCHFiles>
  </xsl:template>
</xsl:stylesheet>

