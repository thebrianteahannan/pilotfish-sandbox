<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xsd" version="3.1">
  <xsl:param name="UniqueControlID" />
  <xsl:param name="CurrentHL7Type" />
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <xsl:strip-space elements="*" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[ETTRANSID = $UniqueControlID and HL7TYPE = $CurrentHL7Type]" />
</xsl:stylesheet>

