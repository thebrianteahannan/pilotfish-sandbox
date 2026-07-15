<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <XCSData>
      <xsl:copy-of select="query_results" />
      <Import>
        <xsl:for-each select="xml/Import/PatientDemographics[@stripped = 'false']">
          <xsl:variable name="groupingKey" select="admAcctNum" />
          <Group>
            <xsl:copy-of select="/XCSData/xml/Import/*[admAcctNum = $groupingKey or radAcctNum = $groupingKey]" />
          </Group>
        </xsl:for-each>
      </Import>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

