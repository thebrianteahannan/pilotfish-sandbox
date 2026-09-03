<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns3="http://hl7.org/fhir" exclude-result-prefixes="ns3" version="3.1">
  <xsl:template match="/ns3:Patient">
    <patients>
      <patient>
        <mrn>
          <xsl:value-of select="ns3:identifier[ns3:label/@value='MRN']/ns3:value/@value" />
        </mrn>
        <lastName>
          <xsl:value-of select="ns3:name/ns3:family/@value" />
        </lastName>
        <firstName>
          <xsl:value-of select="ns3:name/ns3:given/@value" />
        </firstName>
        <dob>
          <xsl:value-of select="ns3:birthDate/@value" />
        </dob>
        <address>
          <xsl:value-of select="ns3:address/ns3:line/@value" />
        </address>
        <city>
          <xsl:value-of select="ns3:address/ns3:city/@value" />
        </city>
        <state>
          <xsl:value-of select="ns3:address/ns3:state/@value" />
        </state>
        <postalCode>
          <xsl:value-of select="ns3:address/ns3:postalCode/@value" />
        </postalCode>
      </patient>
    </patients>
  </xsl:template>
</xsl:stylesheet>

