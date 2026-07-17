<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="NumCharges" />
  <xsl:param name="NumDemographics" />
  <xsl:template match="/">
    <XCSExcelBook>
      <XCSExcelSheet name="Counts">
        <XCSExcelRow>
          <NumCharges>NumCharges</NumCharges>
          <NumDemographics>NumDemographics</NumDemographics>
        </XCSExcelRow>
        <XCSExcelRow>
          <NumCharges>
            <xsl:value-of select="$NumCharges" />
          </NumCharges>
          <NumDemographics>
            <xsl:value-of select="$NumDemographics" />
          </NumDemographics>
        </XCSExcelRow>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

