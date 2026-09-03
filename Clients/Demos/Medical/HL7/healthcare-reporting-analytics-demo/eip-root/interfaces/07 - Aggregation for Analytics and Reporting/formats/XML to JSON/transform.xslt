<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.pilotfishtechnology.com/schemas/json" version="3.1">
  <xsl:template match="/patients">
    <json:JSON>
      <json:OBJECT>
        <patients pf_json_type="array">
          <xsl:for-each select="patient">
            <patient>
              <mrn>
                <xsl:value-of select="mrn" />
              </mrn>
              <lastName>
                <xsl:value-of select="lastName" />
              </lastName>
              <firstName>
                <xsl:value-of select="firstName" />
              </firstName>
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
              <postalCode>
                <xsl:value-of select="postalCode" />
              </postalCode>
            </patient>
          </xsl:for-each>
        </patients>
      </json:OBJECT>
    </json:JSON>
  </xsl:template>
</xsl:stylesheet>

