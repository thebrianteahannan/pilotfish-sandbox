<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://pilotfish.sqlxml" version="1.0">
  <xsl:template match="/patients">
    <ns1:SQLXML>
      <xsl:for-each select="patient">
        <ns1:Insert>
          <PATIENT>
            <LASTNAME>
              <xsl:value-of select="lastName" />
            </LASTNAME>
            <FIRSTNAME>
              <xsl:value-of select="firstName" />
            </FIRSTNAME>
            <DOB>
              <xsl:value-of select="dob" />
            </DOB>
            <ADDRESS>
              <xsl:value-of select="address" />
            </ADDRESS>
            <CITY>
              <xsl:value-of select="city" />
            </CITY>
            <ST>
              <xsl:value-of select="state" />
            </ST>
            <POSTALCODE>
              <xsl:value-of select="postalCode" />
            </POSTALCODE>
            <MRN>
              <xsl:value-of select="mrn" />
            </MRN>
          </PATIENT>
        </ns1:Insert>
      </xsl:for-each>
    </ns1:SQLXML>
  </xsl:template>
</xsl:stylesheet>

