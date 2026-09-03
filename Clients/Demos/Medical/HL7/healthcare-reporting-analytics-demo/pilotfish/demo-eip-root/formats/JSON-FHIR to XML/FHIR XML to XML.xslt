<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.pilotfishtechnology.com/schemas/json" xmlns:ns3="http://hl7.org/fhir" exclude-result-prefixes="ns3" version="3.1">
  <xsl:template match="/json:JSON">
    <patients>
      <patient>
        <mrn>
          <xsl:value-of select="json:OBJECT/identifier/json:OBJECT/value" />
        </mrn>
        <lastName>
          <xsl:value-of select="json:OBJECT/name/json:OBJECT/family" />
        </lastName>
        <firstName>
          <xsl:value-of select="json:OBJECT/name/json:OBJECT/given" />
        </firstName>
        <dob>
          <xsl:value-of select="json:OBJECT/birthDate" />
        </dob>
        <address>
          <xsl:value-of select="json:OBJECT/address/json:OBJECT/line" />
        </address>
        <city>
          <xsl:value-of select="json:OBJECT/address/json:OBJECT/city" />
        </city>
        <state>
          <xsl:value-of select="json:OBJECT/address/json:OBJECT/state" />
        </state>
        <postalCode>
          <xsl:value-of select="json:OBJECT/address/json:OBJECT/postalCode" />
        </postalCode>
      </patient>
    </patients>
  </xsl:template>
</xsl:stylesheet>

