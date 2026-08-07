<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/XCSData">
    <XCSData>
      <xsl:for-each select="ProcessComponent">
        <File encoding="{File/@encoding}" name="{File/@name}" path="{File/@path}">
          <xsl:value-of select="File" />
        </File>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

