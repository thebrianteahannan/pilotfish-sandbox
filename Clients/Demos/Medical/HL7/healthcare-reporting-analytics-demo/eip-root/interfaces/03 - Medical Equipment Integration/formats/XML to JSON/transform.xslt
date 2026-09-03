<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/XCSData">
    <JSON>
      <xsl:for-each select="*">
        <ElementWrapper>
          <xsl:for-each select="//PID">
            <Patient>
              <Id>
                <xsl:value-of select="PID.3/CX.1" />
              </Id>
              <FirstName>
                <xsl:value-of select="PID.5/XPN.2" />
              </FirstName>
              <LastName>
                <xsl:value-of select="PID.5/XPN.1" />
              </LastName>
              <Address1>
                <xsl:value-of select="PID.11/XAD.1" />
              </Address1>
              <Address2>
                <xsl:value-of select="PID.11/XAD.1[2]" />
              </Address2>
              <City>
                <xsl:value-of select="PID.11/XAD.3" />
              </City>
              <State>
                <xsl:value-of select="PID.11/XAD.4" />
              </State>
              <Zip>
                <xsl:value-of select="PID.11/XAD.5" />
              </Zip>
              <BirthDate>
                <xsl:value-of select="PID.7" />
              </BirthDate>
              <Gender>
                <xsl:value-of select="PID.8" />
              </Gender>
            </Patient>
          </xsl:for-each>
          <Medications>
            <xsl:for-each select="//OBX">
              <Medication>
                <Identifier>
                  <xsl:value-of select="OBX.4" />
                </Identifier>
                <Value>
                  <xsl:value-of select="OBX.5" />
                </Value>
                <Text>
                  <xsl:value-of select="OBX.3/CE.2" />
                </Text>
                <Code>
                  <xsl:value-of select="OBX.3/CE.1" />
                </Code>
                <System>
                  <xsl:value-of select="OBX.3/CE.3" />
                </System>
                <Units>
                  <xsl:value-of select="OBX.6/CE.1" />
                </Units>
              </Medication>
            </xsl:for-each>
          </Medications>
        </ElementWrapper>
      </xsl:for-each>
    </JSON>
  </xsl:template>
</xsl:stylesheet>

