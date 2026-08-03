<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <!--
    NHL CAT Option A: strip clinical charges when PatientDemographics/Filler2 is
    HUGGINSHOS or MONCOMHOS; keep demos; override primary insurance to 868 write-off;
    if ICD-10 is blank, emit XXX.X.
    Runs after strip_data so Groups are not auto-stripped when all charges strip.
  -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Group[PatientDemographics/Filler2 = ('HUGGINSHOS','MONCOMHOS')]">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="node()[not(self::Insurance1 or self::DiagnosisCodes)]" />
      <xsl:choose>
        <xsl:when test="Insurance1">
          <xsl:apply-templates select="Insurance1" />
        </xsl:when>
        <xsl:otherwise>
          <Insurance1>
            <adminsmne tweaked="true" tweaked_reason="NHL CAT Huggins/Monadnock write-off insurance">868</adminsmne>
          </Insurance1>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="DiagnosisCodes/Diag[string-length(normalize-space(.)) &gt; 0]">
          <xsl:apply-templates select="DiagnosisCodes" />
        </xsl:when>
        <xsl:when test="DiagnosisCodes">
          <DiagnosisCodes>
            <xsl:copy-of select="DiagnosisCodes/@*" />
            <xsl:attribute name="tweaked">true</xsl:attribute>
            <xsl:attribute name="tweaked_reason" select="'NHL CAT Huggins/Monadnock blank ICD-10 -&gt; XXX.X'" />
            <Diag>XXX.X</Diag>
          </DiagnosisCodes>
        </xsl:when>
        <xsl:otherwise>
          <DiagnosisCodes tweaked="true" tweaked_reason="NHL CAT Huggins/Monadnock blank ICD-10 -&gt; XXX.X">
            <Diag>XXX.X</Diag>
          </DiagnosisCodes>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="Group[PatientDemographics/Filler2 = ('HUGGINSHOS','MONCOMHOS')]/Charge[not(@stripped = 'true')]">
    <Charge>
      <xsl:attribute name="stripped">true</xsl:attribute>
      <xsl:attribute name="stripped_reason" select="'Strip Charge: NHL CAT Huggins/Monadnock Filler2'" />
      <xsl:attribute name="stripped_huggins_monadnock" select="'true'" />
      <xsl:copy-of select="../PatientDemographics" />
      <xsl:copy-of select="." />
    </Charge>
  </xsl:template>

  <xsl:template match="Group[PatientDemographics/Filler2 = ('HUGGINSHOS','MONCOMHOS')]/PatientDemographics/absadmitdiag[string-length(normalize-space(.)) = 0]">
    <absadmitdiag tweaked="true" tweaked_reason="NHL CAT Huggins/Monadnock blank ICD-10 -&gt; XXX.X">XXX.X</absadmitdiag>
  </xsl:template>

  <xsl:template match="Group[PatientDemographics/Filler2 = ('HUGGINSHOS','MONCOMHOS')]/Insurance1/adminsmne">
    <adminsmne tweaked="true" tweaked_reason="NHL CAT Huggins/Monadnock write-off insurance">868</adminsmne>
  </xsl:template>
</xsl:stylesheet>
