<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="Partition" />
  <xsl:param name="Client" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="DiagnosisCodes[@ranked = 'true']">
    <xsl:variable name="doTweak" select="count(/XCSData/query_results/TWEAKING_RULES/TWEAKING_RULES[PARTITION = $Partition and CLIENT = $Client and RULE_NAME = 'Sort diagnosis codes using BVWYZ method'])" />
    <xsl:choose>
      <xsl:when test="$doTweak &gt; 0">
        <DiagnosisCodes>
          <xsl:attribute name="ranked">true</xsl:attribute>
          <xsl:attribute name="sorted">true</xsl:attribute>
          <xsl:attribute name="tweaked">true</xsl:attribute>
          <xsl:attribute name="tweaked_reason" select="'Sort diagnosis codes using BVWYZ method'" />
          <xsl:for-each select="Diag">
            <xsl:sort order="ascending" select="number(@sort_rank)" />
            <xsl:if test="string-length(.) != 0">
              <xsl:copy-of select="." />
            </xsl:if>
          </xsl:for-each>
        </DiagnosisCodes>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy select=".">
          <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

