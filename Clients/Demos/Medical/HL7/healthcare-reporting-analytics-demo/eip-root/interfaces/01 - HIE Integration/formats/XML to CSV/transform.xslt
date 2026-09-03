<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/patients">
    <XCSData>
      <xsl:for-each select="patient">
        <XCSRecord>
          <mrn>
            <xsl:value-of select="mrn" />
          </mrn>
          <last>
            <xsl:value-of select="lastName" />
          </last>
          <first>
            <xsl:value-of select="firstName" />
          </first>
          <dob>
            <xsl:value-of select="dob" />
          </dob>
          <address>
            <xsl:value-of select="address" />
          </address>
          <city>
            <xsl:value-of select="city" />
          </city>
          <state>
            <xsl:value-of select="state" />
          </state>
          <zip>
            <xsl:value-of select="postalCode" />
          </zip>
        </XCSRecord>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

