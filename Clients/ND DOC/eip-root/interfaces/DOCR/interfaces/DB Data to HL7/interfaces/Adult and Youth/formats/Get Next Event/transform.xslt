<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <OldestRecord>
      <xsl:choose>
        <!--SET1-->
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '1']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '1'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '2']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '2'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '3']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '3'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '4']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '4'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '5']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '5'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '6']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '6'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '7']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '7'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '8']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '1' and SUBSEQUENCENO = '8'][1]" />
        </xsl:when>
        <!--SET2-->
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '1']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '1'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '2']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '2'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '3']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '3'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '4']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '4'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '5']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '5'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '6']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '6'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '7']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '7'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '8']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '2' and SUBSEQUENCENO = '8'][1]" />
        </xsl:when>
        <!--SET3-->
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '1']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '1'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '2']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '2'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '3']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '3'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '4']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '4'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '5']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '5'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '6']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '6'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '7']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '7'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '8']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '3' and SUBSEQUENCENO = '8'][1]" />
        </xsl:when>
        <!--SET4-->
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '1']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '1'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '2']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '2'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '3']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '3'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '4']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '4'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '5']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '5'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '6']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '6'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '7']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '7'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '8']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '4' and SUBSEQUENCENO = '8'][1]" />
        </xsl:when>
        <!--SET5-->
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '1']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '1'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '2']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '2'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '3']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '3'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '4']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '4'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '5']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '5'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '6']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '6'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '7']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '7'][1]" />
        </xsl:when>
        <xsl:when test="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '8']">
          <xsl:copy-of select="//EVENT[SEQUENCENO = '5' and SUBSEQUENCENO = '8'][1]" />
        </xsl:when>
      </xsl:choose>
    </OldestRecord>
  </xsl:template>
</xsl:stylesheet>

