<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!--SET1-->
  <xsl:template match="//EVENT[HL7TYPE = 'A03LOAD']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>1</SEQUENCENO>
      <SUBSEQUENCENO>1</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A01LOAD']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>1</SEQUENCENO>
      <SUBSEQUENCENO>2</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A22TFIDIS']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>1</SEQUENCENO>
      <SUBSEQUENCENO>3</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A02PROG' and string-length(ORIGHL7TYPE) = 0]">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>1</SEQUENCENO>
      <SUBSEQUENCENO>4</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A02OTHER' and ORIGHL7TYPE = 'A21BEDA22TFIA02OTHERA21TFO']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>1</SEQUENCENO>
      <SUBSEQUENCENO>5</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <!--SET2-->
  <xsl:template match="//EVENT[HL7TYPE = 'A03' and string-length(ORIGHL7TYPE) = 0]">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>2</SEQUENCENO>
      <SUBSEQUENCENO>1</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A21' and ORIGHL7TYPE = 'A21A22BED']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>2</SEQUENCENO>
      <SUBSEQUENCENO>2</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A21' and ORIGHL7TYPE = 'A21BEDA22TFIA02OTHERA21TFO']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>2</SEQUENCENO>
      <SUBSEQUENCENO>3</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A03TFIDIS' and ORIGHL7TYPE = 'A22TFIDISA03TFIDIS']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>2</SEQUENCENO>
      <SUBSEQUENCENO>4</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A21TFO']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>2</SEQUENCENO>
      <SUBSEQUENCENO>5</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <!--SET3-->
  <xsl:template match="//EVENT[HL7TYPE = 'A22' and ORIGHL7TYPE = 'A21A22BED']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <!--IF YOU CHANGE THIS YOU NEED TO GO CHANGE THE SORTING ORDER IN THE NEXT XSLT STEP-->
      <SEQUENCENO>3</SEQUENCENO>
      <SUBSEQUENCENO>1</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A01' and string-length(ORIGHL7TYPE) = 0]">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>3</SEQUENCENO>
      <SUBSEQUENCENO>2</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A22' and string-length(ORIGHL7TYPE) = 0]">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>3</SEQUENCENO>
      <SUBSEQUENCENO>3</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A22TFI' and ORIGHL7TYPE = 'A22TFIA01TFI']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>3</SEQUENCENO>
      <SUBSEQUENCENO>4</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A22TFI' and ORIGHL7TYPE = 'A21BEDA22TFIA02OTHERA21TFO']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>3</SEQUENCENO>
      <SUBSEQUENCENO>5</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <!--SET4-->
  <xsl:template match="//EVENT[HL7TYPE = 'A01TFI' and ORIGHL7TYPE = 'A22TFIA01TFI']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>4</SEQUENCENO>
      <SUBSEQUENCENO>1</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
  <!--SET5-->
  <xsl:template match="//EVENT[HL7TYPE = 'A21TFO' and ORIGHL7TYPE = 'A21BEDA22TFIA02OTHERA21TFO']">
    <xsl:copy>
      <xsl:copy-of select="@*|node()" />
      <SEQUENCENO>5</SEQUENCENO>
      <SUBSEQUENCENO>1</SUBSEQUENCENO>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

