<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A22TFIDISA03TFIDIS']">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A22TFIDIS</HL7TYPE>
      <ORIGHL7TYPE>A22TFIDISA03TFIDIS</ORIGHL7TYPE>
    </xsl:copy>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A03TFIDIS</HL7TYPE>
      <ORIGHL7TYPE>A22TFIDISA03TFIDIS</ORIGHL7TYPE>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A21A22BED']">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A21</HL7TYPE>
      <ORIGHL7TYPE>A21A22BED</ORIGHL7TYPE>
    </xsl:copy>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A22</HL7TYPE>
      <ORIGHL7TYPE>A21A22BED</ORIGHL7TYPE>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A21BEDA22TFIA02OTHERA21TFO']">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A21</HL7TYPE>
      <ORIGHL7TYPE>A21BEDA22TFIA02OTHERA21TFO</ORIGHL7TYPE>
    </xsl:copy>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A22TFI</HL7TYPE>
      <ORIGHL7TYPE>A21BEDA22TFIA02OTHERA21TFO</ORIGHL7TYPE>
    </xsl:copy>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A02OTHER</HL7TYPE>
      <ORIGHL7TYPE>A21BEDA22TFIA02OTHERA21TFO</ORIGHL7TYPE>
    </xsl:copy>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A21TFO</HL7TYPE>
      <ORIGHL7TYPE>A21BEDA22TFIA02OTHERA21TFO</ORIGHL7TYPE>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="//EVENT[HL7TYPE = 'A22TFIA01TFI']">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A22TFI</HL7TYPE>
      <ORIGHL7TYPE>A22TFIA01TFI</ORIGHL7TYPE>
    </xsl:copy>
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="node()[name() != 'HL7TYPE']" />
      <HL7TYPE>A01TFI</HL7TYPE>
      <ORIGHL7TYPE>A22TFIA01TFI</ORIGHL7TYPE>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>

