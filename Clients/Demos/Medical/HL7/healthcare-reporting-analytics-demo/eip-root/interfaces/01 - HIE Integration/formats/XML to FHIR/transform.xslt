<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ns1="http://hl7.org/fhir" version="3.1">
  <xsl:template match="/patients">
    <xsl:for-each select="patient[1]">
      <Patient xmlns="http://hl7.org/fhir">
        <identifier>
          <use value="usual" />
          <system value="urn:oid:2.16.840.1.113883.2.4.6.3" />
          <value value="{mrn}" />
        </identifier>
        <name>
          <use value="usual" />
          <family value="{lastName}" />
          <given value="{firstName}" />
        </name>
        <birthDate value="{dob}" />
        <deceasedBoolean value="false" />
        <address>
          <use value="home" />
          <line value="{address}" />
          <city value="{city}" />
          <postalCode value="{postalCode}" />
          <country value="US" />
        </address>
        <active value="true" />
      </Patient>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>

