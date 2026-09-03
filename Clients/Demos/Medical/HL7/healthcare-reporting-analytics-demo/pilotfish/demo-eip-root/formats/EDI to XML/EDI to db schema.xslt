<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <patients>
      <patient>
        <mrn />
        <lastName>
          <xsl:value-of select="Interchange/Group/Transaction/Loop_2000A/Loop_2010AA/NM1/NM103" />
        </lastName>
        <firstName>
          <xsl:value-of select="Interchange/Group/Transaction/Loop_2000A/Loop_2010AA/NM1/NM104" />
        </firstName>
        <dob />
        <address>
          <xsl:value-of select="Interchange/Group/Transaction/Loop_2000A/Loop_2010AA/N3/N301" />
        </address>
        <city>
          <xsl:value-of select="Interchange/Group/Transaction/Loop_2000A/Loop_2010AA/N4/N401" />
        </city>
        <state>
          <xsl:value-of select="Interchange/Group/Transaction/Loop_2000A/Loop_2010AA/N4/N402" />
        </state>
        <postalCode>
          <xsl:value-of select="substring(Interchange/Group/Transaction/Loop_2000A/Loop_2010AA/N4/N403,0,6)" />
        </postalCode>
      </patient>
    </patients>
  </xsl:template>
</xsl:stylesheet>

