<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//Group[PatientDemographics/admpatienttype = ('Out','Eme') and count(Charge) &gt; 1]">
    <!--SPLIT GROUP INTO SEPARATE GROUPS FOR EACH RADEXAMSERVDATE-->
    <xsl:for-each-group group-by="Charge/radExamServDate" select=".">
      <Group>
        <xsl:attribute name="key" select="@key" />
        <xsl:copy-of select="PatientDemographics" />
        <xsl:copy-of select="Guarantor" />
        <xsl:copy-of select="Insurance1" />
        <xsl:copy-of select="Insurance2" />
        <xsl:copy-of select="Insurance3" />
        <xsl:copy-of select="Charge[radExamServDate = current-grouping-key()]" />
        <xsl:copy-of select="DiagnosisCodes" />
      </Group>
    </xsl:for-each-group>
  </xsl:template>
</xsl:stylesheet>

