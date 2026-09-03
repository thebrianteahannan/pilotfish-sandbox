<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" xmlns:ns2="urn:hl7-org:v3" exclude-result-prefixes="ns2 dtFormatter" version="1.0">
  <xsl:template match="ns2:ClinicalDocument">
    <patients>
      <patient>
        <mrn>
          <xsl:value-of select="ns2:recordTarget/ns2:patientRole/ns2:id/@extension" />
        </mrn>
        <lastName>
          <xsl:value-of select="ns2:recordTarget/ns2:patientRole/ns2:patient/ns2:name/ns2:family" />
        </lastName>
        <firstName>
          <xsl:value-of select="ns2:recordTarget/ns2:patientRole/ns2:patient/ns2:name/ns2:given" />
        </firstName>
        <dob>
          <xsl:if test="ns2:recordTarget/ns2:patientRole/ns2:patient/ns2:birthTime != ''">
            <xsl:value-of select="dtFormatter:format(ns2:recordTarget/ns2:patientRole/ns2:patient/ns2:birthTime,'yyyyMMdd','yyyy-MM-dd')" />
          </xsl:if>
        </dob>
        <address>
          <xsl:value-of select="ns2:recordTarget/ns2:patientRole/ns2:addr/ns2:streetAddressLine" />
        </address>
        <city>
          <xsl:value-of select="ns2:recordTarget/ns2:patientRole/ns2:addr/ns2:city" />
        </city>
        <state>
          <xsl:call-template name="TabularMapping_State_mapping">
            <xsl:with-param name="value" select="ns2:recordTarget/ns2:patientRole/ns2:addr/ns2:state" />
          </xsl:call-template>
        </state>
        <postalCode>
          <xsl:value-of select="ns2:recordTarget/ns2:patientRole/ns2:addr/ns2:postalCode" />
        </postalCode>
      </patient>
    </patients>
  </xsl:template>
  <xsl:template name="TabularMapping_State_mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='Connecticut'">
        <xsl:text>CT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='New Hampshire'">
        <xsl:text>NH</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Florida'">
        <xsl:text>FL</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Unknown</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

