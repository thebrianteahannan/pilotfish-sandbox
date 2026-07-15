<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <Import>
      <xsl:copy-of select="Group[string-length(@key) != 0]" />
    </Import>
  </xsl:template>
</xsl:stylesheet>

