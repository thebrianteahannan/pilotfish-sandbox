<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--ADD 'A' TO CDMs - FOR SPG ONLY-->
  <xsl:template match="FT1.25">
    <xsl:choose>
      <xsl:when test=". = ('88235','88240','88262','88280','10021','76098','85060','85097','86077','86078','86079','88104','88108','88112','88120','88121','88130','88141','88143','88160','88161','88162','88164','88167','88172','88173','88177','88182','88184','88185','88187','88188','88189','88237','88264','88291','88300','88302','88304','88305','88307','88309','88311','88312','88313','88314','88319','88321','88323','88325','88329','88331','88332','88333','88334','88341','88342','88344','88346','88348','88350','88360','88361','88362','88363','88364','88365','88366','88367','88368','88369','88373','88374','88377','88381','88387','G0124','G0416','87626','87624','87491','87591','87661','G0124','G0476','88175')">
        <FT1.25>
          <xsl:attribute name="cdm-appended-a" select="'yes'" />
          <xsl:attribute name="alternate-account-numbers" select="@alternate-account-numbers" />
          <xsl:value-of select="concat(.,'A')" />
        </FT1.25>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="." />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

