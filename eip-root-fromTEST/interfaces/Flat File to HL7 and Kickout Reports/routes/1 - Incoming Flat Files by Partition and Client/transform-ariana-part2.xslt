<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:output encoding="UTF-8" indent="yes" method="xml" version="1.0" />
  <!-- Index all Charge elements by patient and PlaceOfService -->
  <xsl:key match="Charge" name="charges-by-patient-location" use="concat(radAcctNum, '|', PlaceOfService)" />
  <!-- Index all Group elements by patient and PlaceOfService -->
  <xsl:key match="Group" name="group-by-patient-location" use="concat(PatientDemographics/admAcctNum, '|', (Charge/PlaceOfService)[1])" />
  <!-- Copy all attributes and namespaces -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>
  <!-- Root: for each unique patient/location, output a Group -->
  <xsl:template match="XCSData">
    <XCSData xmlns:pf="http://pilotfishtechnology.com" xmlns:xs="http://www.w3.org/2001/XMLSchema">
      <xsl:for-each select="//Charge[generate-id() = generate-id(key('charges-by-patient-location', concat(radAcctNum, '|', PlaceOfService))[1])]">
        <xsl:sort select="radAcctNum" />
        <xsl:sort select="PlaceOfService" />
        <xsl:variable name="acct" select="radAcctNum" />
        <xsl:variable name="loc" select="PlaceOfService" />
        <xsl:variable name="group" select="//Group[PatientDemographics/admAcctNum = $acct][1]" />
        <Group key="{$acct}">
          <xsl:apply-templates select="$group/*[not(self::Charge)]">
            <xsl:with-param name="location" select="$loc" />
          </xsl:apply-templates>
          <xsl:apply-templates select="//Charge[radAcctNum = $acct and PlaceOfService = $loc]" />
        </Group>
      </xsl:for-each>
    </XCSData>
  </xsl:template>
  <!-- Clone PatientDemographics -->
  <xsl:template match="PatientDemographics">
    <xsl:param name="location" />
    <PatientDemographics>
      <xsl:for-each select="*">
        <xsl:choose>
          <xsl:when test="name() = 'admLocation'">
            <admLocation>
              <xsl:value-of select="$location" />
            </admLocation>
          </xsl:when>
          <xsl:otherwise>
            <xsl:element name="{name()}">
              <xsl:value-of select="." />
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </PatientDemographics>
  </xsl:template>
  <!-- Clone Charge elements -->
  <xsl:template match="Charge">
    <Charge>
      <xsl:for-each select="*">
        <xsl:element name="{name()}">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>
      <!-- Add empty elements that are in the desired format -->
      <absPatientUnit />
      <ExamHCPCCode />
      <orderingDrNPI />
      <misOrderingPhyCity />
      <radOrderingPhyUPIN />
      <misOrderingPhyName>
        <xsl:value-of select="radOrderingPhyMne" />
      </misOrderingPhyName>
      <misOrderingPhyAddr />
    </Charge>
  </xsl:template>
  <!-- Clone Guarantor -->
  <xsl:template match="Guarantor">
    <Guarantor>
      <xsl:for-each select="*">
        <xsl:element name="{name()}">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>
    </Guarantor>
  </xsl:template>
  <!-- Clone DiagnosisCodes -->
  <xsl:template match="DiagnosisCodes">
    <DiagnosisCodes>
      <xsl:for-each select="*[not(name()='Diag1CodeSet' or name()='radAcctNum')]">
        <xsl:element name="Diag{position()}">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>
    </DiagnosisCodes>
  </xsl:template>
  <!-- Clone Insurance elements -->
  <xsl:template match="Insurance1|Insurance2|Insurance3">
    <xsl:element name="{name()}">
      <xsl:for-each select="*">
        <xsl:element name="{name()}">
          <xsl:value-of select="." />
        </xsl:element>
      </xsl:for-each>
      <xsl:if test="not(admAcctNum)">
        <admAcctNum />
      </xsl:if>
      <xsl:if test="not(absPatientUnit)">
        <absPatientUnit />
      </xsl:if>
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>

