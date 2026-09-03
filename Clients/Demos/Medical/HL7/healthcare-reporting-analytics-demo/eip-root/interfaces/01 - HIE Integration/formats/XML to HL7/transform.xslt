<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:datetime="http://exslt.org/dates-and-times" xmlns:uuid="xalan://java.util.UUID" exclude-result-prefixes="datetime uuid" version="3.1">
  <xsl:template match="/patients">
    <XCSData>
      <xsl:for-each select="patient">
        <ADT_A01>
          <MSH>
            <MSH.1>|</MSH.1>
            <MSH.2>^~\&amp;amp;</MSH.2>
            <MSH.3>PATACCT</MSH.3>
            <MSH.4>130</MSH.4>
            <MSH.5>MED-DISPENSE</MSH.5>
            <MSH.6>130</MSH.6>
            <MSH.7>
              <xsl:value-of select="translate(substring(datetime:dateTime(), 1, 19), '-:T', '')" />
            </MSH.7>
            <MSH.9>
              <CM_MSG.1>ADT</CM_MSG.1>
              <CM_MSG.2>A08</CM_MSG.2>
            </MSH.9>
            <MSH.10>
              <xsl:value-of select="uuid:randomUUID()" />
            </MSH.10>
            <MSH.11>P</MSH.11>
            <MSH.12>2.3</MSH.12>
            <MSH.13>
              <xsl:value-of select="uuid:randomUUID()" />
            </MSH.13>
            <MSH.17>US</MSH.17>
          </MSH>
          <EVN>
            <EVN.1>A08</EVN.1>
            <EVN.2>
              <xsl:value-of select="translate(substring(datetime:dateTime(), 1, 19), '-:T', '')" />
            </EVN.2>
            <EVN.5>LAV</EVN.5>
          </EVN>
          <PID>
            <PID.1>1</PID.1>
            <PID.3>
              <xsl:value-of select="mrn" />
            </PID.3>
            <PID.5>
              <XPN.1>
                <xsl:value-of select="lastName" />
              </XPN.1>
              <XPN.2>
                <xsl:value-of select="firstName" />
              </XPN.2>
            </PID.5>
            <PID.7>
              <xsl:value-of select="dob" />
            </PID.7>
            <PID.11>
              <XAD.1>
                <xsl:value-of select="address" />
              </XAD.1>
              <XAD.3>
                <xsl:value-of select="city" />
              </XAD.3>
              <XAD.4>
                <xsl:value-of select="state" />
              </XAD.4>
              <XAD.5>
                <xsl:value-of select="postalCode" />
              </XAD.5>
            </PID.11>
          </PID>
        </ADT_A01>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

