<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://ACORD.org/Standards/Life/2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
  <!-- IdentityTransform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="CRLDOCUMENTID">
    <!-- keep the CRLDOCUMENTID element if it is not empty -->
    <xsl:if test="string-length(.) &gt; '0'">
      <xsl:copy>
        <xsl:apply-templates select="@* | node()" />
      </xsl:copy>
    </xsl:if>
    <!-- keep the CRLDOCUMENTID element if it is empty and is an SFTP attachment from LADDER-->
    <xsl:if test="string-length(.) = '0' and ../CRLDRAWERNAME='SFTP' and ../../../PFSOURCECLIENT='LADDER'">
      <xsl:copy>
        <xsl:apply-templates select="@* | node()" />
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <!-- Promote the elements of the first /RESULTS/TRANSACTION/* to /RESULTS/* -->
  <xsl:template match="TRANSACTION[1]">
    <xsl:apply-templates select="@* | node()" />
  </xsl:template>
</xsl:stylesheet>

