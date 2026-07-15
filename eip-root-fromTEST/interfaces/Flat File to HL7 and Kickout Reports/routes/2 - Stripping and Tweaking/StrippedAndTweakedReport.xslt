<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <StripsAndTweaks>
      <Stripped>
        <StrippedGroups>
          <xsl:attribute name="count" select="count(//Group[@stripped = 'true'])" />
          <xsl:for-each select="//Group[@stripped = 'true']">
            <Group>
              <xsl:attribute name="stripped" select="'true'" />
              <xsl:attribute name="stripped_reason" select="@stripped_reason" />
              <xsl:attribute name="key" select="@key" />
            </Group>
          </xsl:for-each>
        </StrippedGroups>
        <StrippedDemographics>
          <xsl:attribute name="count" select="count(//PatientDemographics[@stripped = 'true'])" />
          <xsl:for-each select="//PatientDemographics[@stripped = 'true']">
            <xsl:copy-of select="." />
          </xsl:for-each>
        </StrippedDemographics>
        <StrippedCharges>
          <xsl:attribute name="count" select="count(//Charge[@stripped = 'true'])" />
          <xsl:for-each select="//Charge[@stripped = 'true']">
            <xsl:copy-of select="." />
          </xsl:for-each>
        </StrippedCharges>
      </Stripped>
      <Tweaked>
        <TweakedGuarantor>
          <xsl:attribute name="count" select="count(//Guarantor[@tweaked = 'true'])" />
          <xsl:for-each select="//Guarantor[@tweaked = 'true']">
            <xsl:copy-of select="." />
          </xsl:for-each>
        </TweakedGuarantor>
        <TweakedDemographics>
          <xsl:attribute name="count" select="count(//PatientDemographics[@tweaked = 'true'])" />
          <xsl:for-each select="//PatientDemographics[@tweaked = 'true']">
            <Group>
              <xsl:copy-of select="." />
              <xsl:copy-of select="../Insurance1" />
            </Group>
          </xsl:for-each>
        </TweakedDemographics>
        <TweakedCharges>
          <xsl:attribute name="count" select="count(//Charge[@tweaked = 'true'])" />
          <xsl:for-each select="//Charge[@tweaked = 'true']">
            <Charge>
              <xsl:attribute name="tweaked" select="'true'" />
              <xsl:attribute name="tweaked_reason" select="@tweaked_reason" />
              <radAcctNum>
                <xsl:value-of select="radAcctNum" />
              </radAcctNum>
              <radPatientName>
                <xsl:value-of select="radPatientName" />
              </radPatientName>
              <radNumOfTimes>
                <xsl:value-of select="radNumOfTimes" />
              </radNumOfTimes>
              <radExamBillingCode>
                <xsl:value-of select="radExamBillingCode" />
              </radExamBillingCode>
              <radExamCPT>
                <xsl:value-of select="radExamCPT" />
              </radExamCPT>
            </Charge>
          </xsl:for-each>
        </TweakedCharges>
        <TweakedDiagnosisCodes>
          <xsl:variable name="tweakedCount" select="count(//DiagnosisCodes[@tweaked = 'true'])" />
          <xsl:attribute name="count" select="$tweakedCount" />
          <xsl:if test="$tweakedCount &gt; 0">
            <xsl:for-each select="//DiagnosisCodes[@tweaked = 'true']">
              <xsl:if test="position() = 1">
                <DiagnosisCodes>
                  <xsl:attribute name="tweaked">true</xsl:attribute>
                  <xsl:attribute name="tweaked_reason" select="./@tweaked_reason" />
                </DiagnosisCodes>
              </xsl:if>
            </xsl:for-each>
          </xsl:if>
        </TweakedDiagnosisCodes>
      </Tweaked>
      <MedidcaidCodesToAddToTable>
        <xsl:for-each select="//PatientDemographics[@stripped = 'false' and @add_code_to_table = 'true']">
          <PatientDemographics>
            <admAcctNum>
              <xsl:value-of select="admAcctNum" />
            </admAcctNum>
            <admName>
              <xsl:value-of select="admName" />
            </admName>
            <admLocation>
              <xsl:value-of select="admLocation" />
            </admLocation>
            <Filler2>
              <xsl:value-of select="Filler2" />
            </Filler2>
          </PatientDemographics>
        </xsl:for-each>
      </MedidcaidCodesToAddToTable>
    </StripsAndTweaks>
  </xsl:template>
</xsl:stylesheet>

