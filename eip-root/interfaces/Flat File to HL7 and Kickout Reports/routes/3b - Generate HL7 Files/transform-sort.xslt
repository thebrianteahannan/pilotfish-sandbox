<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="FileType" />
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--ORDER THE RECORDS IN THE FILE SO THEY ARE IN A PREDICTIBLE AND REPEATABLE ORDER-->
  <xsl:template match="/XCSData">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="ADT_A01">
        <xsl:sort order="ascending" select="PID/PID.5/XPN.1" />
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="ADT_A01">
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$FileType = 'DFT'">
          <xsl:apply-templates select="@*|node() except FT1" />
          <xsl:apply-templates select="FT1">
            <xsl:sort order="ascending" select="FT1.25" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@*|node()" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

