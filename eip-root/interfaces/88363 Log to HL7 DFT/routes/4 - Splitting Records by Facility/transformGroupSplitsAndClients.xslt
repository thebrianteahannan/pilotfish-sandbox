<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/*">
    <SplitInfo>
      <xsl:for-each-group group-by="SplitCode" select="//Client">
        <Split account_num_alpha="{AccountNumAlpha}" facility_code="{FacilityCode}" split_code="{current-grouping-key()}">
          <xsl:copy-of select="current-group()" />
        </Split>
      </xsl:for-each-group>
    </SplitInfo>
  </xsl:template>
</xsl:stylesheet>

