<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="Interface" />
  <xsl:param name="DefaultFacility" />
  <xsl:param name="Partition" select="''" />
  <xsl:param name="Client" select="''" />
  <xsl:variable name="ap-codes" select="   '84165','84166','85060','85097','86077','86078','86079',   '88104','88106','88108','88112','88120','88121','88125','88141','88160','88161','88162',   '88172','88173','88177','88182','88187','88188','88189','88291',   '88300','88302','88304','88305','88307','88309','88311','88312','88313','88314','88319',   '88321','88323','88325','88329','88331','88332','88333','88334','88341','88342','88344',   '88346','88348','88350','88355','88356','88358','88360','88361','88362','88363','88364',   '88365','88366','88367','88368','88369','88371','88372','88373','88374','88377','88380',   '88381','88387','G0416'  " />
  <xsl:template match="/">
    <XCSData>
      <xsl:for-each select="//Charge[string-length(radAcctNum) != 0][not($Partition = ('PPS','NSP')) or normalize-space(radExamCPT) = $ap-codes]">
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
            <xsl:value-of select="../PatientDemographics/admbirthdate | ../../PatientDemographics/admbirthdate" />
          </DOB>
          <DOS>
            <xsl:value-of select="radExamServDate" />
          </DOS>
          <xsl:if test="($Partition = 'HAL' and $Client = 'HAA') or $Partition = ('PPS','NSP')">
            <PatientZipCode>
              <xsl:value-of select="../PatientDemographics/admzipcode" />
            </PatientZipCode>
            <PatientSex>
              <xsl:value-of select="../PatientDemographics/admpatsex" />
            </PatientSex>
            <AttendingDoctorNPI>
              <xsl:value-of select="../PatientDemographics/AttendDrNPI" />
            </AttendingDoctorNPI>
          </xsl:if>
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
        <xsl:if test="($Partition = 'HAL' and $Client = 'HAA') or $Partition = ('PPS','NSP')">
          <Column name="PatientZipCode" />
          <Column name="PatientSex" />
          <Column name="AttendingDoctorNPI" />
        </xsl:if>
      </Summary>
    </XCSData>
  </xsl:template>
</xsl:stylesheet>

