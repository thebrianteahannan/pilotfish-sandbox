<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dtFormatter="xalan://com.pilotfish.eip.gui.mapper.util.DateTimeFormatter" exclude-result-prefixes="dtFormatter" version="3.1">
  <xsl:template match="/XCSData">
    <patients>
      <xsl:for-each select="XCSRecord">
        <patient>
          <mrn>
            <xsl:value-of select="mrn" />
          </mrn>
          <lastName>
            <xsl:value-of select="last" />
          </lastName>
          <firstName>
            <xsl:value-of select="first" />
          </firstName>
          <dob>
            <xsl:value-of select="dtFormatter:format(dob,'MM/dd/yyyy','yyyy-MM-dd')" />
          </dob>
          <address>
            <xsl:value-of select="address" />
          </address>
          <city>
            <xsl:value-of select="city" />
          </city>
          <state>
            <xsl:call-template name="TabularMapping_State_mapping">
              <xsl:with-param name="value" select="state" />
            </xsl:call-template>
          </state>
          <postalCode>
            <xsl:value-of select="zip" />
          </postalCode>
        </patient>
      </xsl:for-each>
    </patients>
  </xsl:template>
  <xsl:template name="TabularMapping_State_mapping">
    <xsl:param name="value" />
    <xsl:choose>
      <xsl:when test="normalize-space($value)='Coonecticut'">
        <xsl:text>CT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Florida'">
        <xsl:text>FL</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='Vermont'">
        <xsl:text>VT</xsl:text>
      </xsl:when>
      <xsl:when test="normalize-space($value)='New Hampshire'">
        <xsl:text>NH</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UK</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

