<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="Interface" />
  <xsl:param name="DefaultFacility" />
  <xsl:template match="/">
    <XCSData>
      <xsl:for-each select="//Charge[string-length(radExamServDate) = 0 and string-length(radAcctNum) != 0]">
        <XCSRecord row="{position()}">
          <AccountNo>
            <xsl:value-of select="radAcctNum" />
          </AccountNo>
          <Interface>
            <xsl:value-of select="$Interface" />
          </Interface>
          <DefaultFacility>
            <xsl:choose>
              <xsl:when test="misOrderingPhyName = 'CCH CLINICAL LABORATORY'">
                <xsl:value-of select="'PE'" />
              </xsl:when>
              <xsl:when test="misOrderingPhyName = 'GCMC CLINICAL LABORATORY'">
                <xsl:value-of select="'PC'" />
              </xsl:when>
              <xsl:when test="misOrderingPhyName = 'HPMC CLINICAL LABORATORY'">
                <xsl:value-of select="'PD'" />
              </xsl:when>
              <xsl:when test="misOrderingPhyName = 'LHCP CLINICAL LABORATORY'">
                <xsl:value-of select="'PB'" />
              </xsl:when>
              <xsl:when test="misOrderingPhyName = 'LMH CLINICAL LABORATORY'">
                <xsl:value-of select="'PA'" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'PA'" />
              </xsl:otherwise>
            </xsl:choose>
          </DefaultFacility>
          <PatientName>
            <xsl:value-of select="radPatientName" />
          </PatientName>
          <CPT>
            <xsl:value-of select="radExamCPT" />
          </CPT>
          <Units>
            <xsl:value-of select="radNumOfTimes" />
          </Units>
          <SpecimenNo>
            <xsl:value-of select="specimenNo" />
          </SpecimenNo>
          <Pathologist>
            <xsl:value-of select="pathologist" />
          </Pathologist>
          <DOB>
            <xsl:value-of select="../../PatientDemographics/admbirthdate" />
          </DOB>
          <DOS>
            <xsl:value-of select="radExamServDate" />
          </DOS>
        </XCSRecord>
      </xsl:for-each>
      <Summary>
        <Column name="AccountNo" />
        <Column name="Interface" />
        <Column name="DefaultFacility" />
        <Column name="PatientName" />
        <Column name="CPT" />
        <Column name="Units" />
        <Column name="SpecimenNo" />
        <Column name="Pathologist" />
        <Column name="DOB" />
        <Column name="DOS" />
      </Summary>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

