<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" exclude-result-prefixes="ns1" version="1.0">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ns1:Attachment" />
  <xsl:template match="ns1:RequirementInfo[ns1:ReqCode/@tc != '14']" />
  <xsl:template match="ns1:Risk" />
</xsl:stylesheet>

