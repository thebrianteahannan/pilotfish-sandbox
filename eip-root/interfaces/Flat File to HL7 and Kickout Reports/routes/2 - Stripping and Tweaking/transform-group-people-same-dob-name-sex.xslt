<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:template match="/">
    <XSCData>
      <!-- Outer group by patient demographics for Out/Eme -->
      <xsl:for-each-group group-by="concat(PatientDemographics/admname, '|', PatientDemographics/admbirthdate, '|', PatientDemographics/admpatsex, '|', PatientDemographics/admpatienttype)" select="//Group[PatientDemographics/admpatienttype = 'Eme' or PatientDemographics/admpatienttype = 'Out']">
        <xsl:for-each select="current-group()">
          <xsl:variable name="current" select="." />
          <!-- Inner group by unique service date -->
          <xsl:for-each-group group-by="radExamServDate" select="Charge">
            <Group>
              <xsl:attribute name="key" select="$current/PatientDemographics/admAcctNum" />
              <xsl:copy-of select="$current/PatientDemographics" />
              <xsl:copy-of select="$current/Guarantor" />
              <xsl:copy-of select="$current/Insurance1" />
              <xsl:copy-of select="$current/Insurance2" />
              <xsl:copy-of select="$current/Insurance3" />
              <!-- All charges for this patient/date -->
              <xsl:copy-of select="current-group()" />
              <xsl:copy-of select="$current/DiagnosisCodes" />
            </Group>
          </xsl:for-each-group>
        </xsl:for-each>
      </xsl:for-each-group>
      <!-- Group for all others as before -->
      <xsl:for-each-group group-by="concat(PatientDemographics/admname,PatientDemographics/admbirthdate,PatientDemographics/admpatsex,PatientDemographics/admpatienttype)" select="//Group[not(PatientDemographics/admpatienttype = 'Out' or PatientDemographics/admpatienttype = 'Eme')][string-length(@key) != 0]">
        <Group>
          <xsl:attribute name="key" select="@key" />
          <xsl:for-each select="current-group()">
            <xsl:if test="position()=1">
              <xsl:copy-of select="PatientDemographics" />
              <xsl:copy-of select="Guarantor" />
              <xsl:copy-of select="Insurance1" />
              <xsl:copy-of select="Insurance2" />
              <xsl:copy-of select="Insurance3" />
            </xsl:if>
            <xsl:if test="position() != 1">
              <AlternateAccountNumber>
                <xsl:value-of select="PatientDemographics/admAcctNum" />
              </AlternateAccountNumber>
            </xsl:if>
            <xsl:copy-of select="Charge" />
          </xsl:for-each>
          <xsl:copy-of select="DiagnosisCodes" />
        </Group>
      </xsl:for-each-group>
    </XSCData>
  </xsl:template>
</xsl:stylesheet>

