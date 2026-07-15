<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XSCData>
      <xsl:for-each-group group-by="@key" select="//Group[string-length(@key) != 0]">
        <Group>
          <xsl:attribute name="key" select="current-grouping-key()" />
          <!-- Handle PatientDemographics -->
          <PatientDemographics>
            <xsl:for-each select="current-group()[1]/PatientDemographics/*">
              <xsl:variable name="currentElement" select="name()" />
              <xsl:variable name="nonEmptyValue" select="(current-group()/PatientDemographics/*[name()=$currentElement][normalize-space()])[1]" />
              <xsl:element name="{$currentElement}">
                <xsl:value-of select="($nonEmptyValue, .)[1]" />
              </xsl:element>
            </xsl:for-each>
          </PatientDemographics>
          <!-- Handle Guarantor -->
          <xsl:if test="current-group()/Guarantor">
            <Guarantor>
              <xsl:for-each select="current-group()[1]/Guarantor/*">
                <xsl:variable name="currentElement" select="name()" />
                <xsl:variable name="nonEmptyValue" select="(current-group()/Guarantor/*[name()=$currentElement][normalize-space()])[1]" />
                <xsl:element name="{$currentElement}">
                  <xsl:value-of select="($nonEmptyValue, .)[1]" />
                </xsl:element>
              </xsl:for-each>
            </Guarantor>
          </xsl:if>
          <!-- Handle Insurance1 -->
          <xsl:if test="current-group()/Insurance1">
            <Insurance1>
              <xsl:for-each select="current-group()[1]/Insurance1/*">
                <xsl:variable name="currentElement" select="name()" />
                <xsl:variable name="nonEmptyValue" select="(current-group()/Insurance1/*[name()=$currentElement][normalize-space()])[1]" />
                <xsl:element name="{$currentElement}">
                  <xsl:value-of select="($nonEmptyValue, .)[1]" />
                </xsl:element>
              </xsl:for-each>
            </Insurance1>
          </xsl:if>
          <!-- Handle Insurance2 -->
          <xsl:if test="current-group()/Insurance2">
            <Insurance2>
              <xsl:for-each select="current-group()[1]/Insurance2/*">
                <xsl:variable name="currentElement" select="name()" />
                <xsl:variable name="nonEmptyValue" select="(current-group()/Insurance2/*[name()=$currentElement][normalize-space()])[1]" />
                <xsl:element name="{$currentElement}">
                  <xsl:value-of select="($nonEmptyValue, .)[1]" />
                </xsl:element>
              </xsl:for-each>
            </Insurance2>
          </xsl:if>
          <!-- Handle Insurance3 -->
          <xsl:if test="current-group()/Insurance3">
            <Insurance3>
              <xsl:for-each select="current-group()[1]/Insurance3/*">
                <xsl:variable name="currentElement" select="name()" />
                <xsl:variable name="nonEmptyValue" select="(current-group()/Insurance3/*[name()=$currentElement][normalize-space()])[1]" />
                <xsl:element name="{$currentElement}">
                  <xsl:value-of select="($nonEmptyValue, .)[1]" />
                </xsl:element>
              </xsl:for-each>
            </Insurance3>
          </xsl:if>
          <!-- Copy all Charge elements -->
          <xsl:for-each select="current-group()/Charge">
            <xsl:copy-of select="." />
          </xsl:for-each>
          <!-- Handle DiagnosisCodes -->
          <DiagnosisCodes>
            <xsl:copy-of select="current-group()[1]/DiagnosisCodes/Diag1CodeSet" />
            <xsl:copy-of select="current-group()[1]/DiagnosisCodes/radAcctNum" />
            <xsl:for-each select="current-group()/DiagnosisCodes/Diag1">
              <xsl:copy-of select="." />
            </xsl:for-each>
          </DiagnosisCodes>
        </Group>
      </xsl:for-each-group>
    </XSCData>
  </xsl:template>
</xsl:stylesheet>

