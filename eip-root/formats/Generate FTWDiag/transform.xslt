<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
  <xsl:param name="txtInterfaceType" />
  <xsl:param name="txtFacilityCode" />
  <xsl:template match="/XCSData">
    <XCSExcelBook>
      <XCSExcelSheet name="Export_IRLFW279_Report">
        <XCSExcelRow>
          <admAcctNum>admAcctNum</admAcctNum>
          <admName>admName</admName>
          <admLocation>admLocation</admLocation>
          <absAdmitDiag>absAdmitDiag</absAdmitDiag>
          <Diag1>Diag1</Diag1>
          <Diag2>Diag2</Diag2>
          <Diag3>Diag3</Diag3>
          <Diag4>Diag4</Diag4>
          <Diag5>Diag5</Diag5>
          <Diag6>Diag6</Diag6>
          <Diag7>Diag7</Diag7>
          <Diag8>Diag8</Diag8>
          <Diag9>Diag9</Diag9>
          <Diag10>Diag10</Diag10>
          <Diag11>Diag11</Diag11>
          <Diag12>Diag12</Diag12>
          <ChiefComplaint>ChiefComplaint</ChiefComplaint>
        </XCSExcelRow>
        <xsl:for-each select="Import/Group[@stripped = 'false']/DiagnosisCodes">
		  <xsl:sort select="../PatientDemographics/admAcctNum"/>
          <XCSExcelRow>
            <admAcctNum>
              <xsl:value-of select="../PatientDemographics/admAcctNum" />
            </admAcctNum>
            <admName>
              <xsl:value-of select="../PatientDemographics/admname" />
            </admName>
            <admLocation>
              <xsl:value-of select="../PatientDemographics/admLocation" />
            </admLocation>
            <absAdmitDiag>
              <xsl:value-of select="../PatientDemographics/absadmitdiag" />
            </absAdmitDiag>
            <Diag1>
			  <!-- <xsl:value-of select="Diag1" /> -->
			  <xsl:choose>
			    <xsl:when test="string-length(../PatientDemographics/absadmitdiag) &gt; 0">
				  <xsl:value-of select="Diag1[2]" />
				</xsl:when>
				<xsl:otherwise>
				  <xsl:value-of select="Diag1[1]" />
				</xsl:otherwise>
			  </xsl:choose>
            </Diag1>
            <Diag2>
              <!-- <xsl:value-of select="Diag1[2]" /> -->
              <xsl:value-of select="Diag2" />
            </Diag2>
            <Diag3>
              <!-- <xsl:value-of select="Diag1[3]" /> -->
              <xsl:value-of select="Diag3" />
            </Diag3>
            <Diag4>
              <!-- <xsl:value-of select="Diag1[4]" /> -->
              <xsl:value-of select="Diag4" />
            </Diag4>
            <Diag5>
              <!-- <xsl:value-of select="Diag1[5]" /> -->
              <xsl:value-of select="Diag5" />
            </Diag5>
            <Diag6>
              <!-- <xsl:value-of select="Diag1[6]" /> -->
              <xsl:value-of select="Diag6" />
            </Diag6>
            <Diag7>
              <!-- <xsl:value-of select="Diag1[7]" /> -->
              <xsl:value-of select="Diag7" />
            </Diag7>
            <Diag8>
              <!-- <xsl:value-of select="Diag1[8]" /> -->
              <xsl:value-of select="Diag8" />
            </Diag8>
            <Diag9>
              <!-- <xsl:value-of select="Diag1[9]" /> -->
              <xsl:value-of select="Diag9" />
            </Diag9>
            <Diag10>
              <!-- <xsl:value-of select="Diag1[10]" /> -->
              <xsl:value-of select="Diag10" />
            </Diag10>
            <Diag11>
              <!-- <xsl:value-of select="Diag1[11]" /> -->
              <xsl:value-of select="Diag11" />
            </Diag11>
            <Diag12>
              <!-- <xsl:value-of select="Diag1[12]" /> -->
              <xsl:value-of select="Diag12" />
            </Diag12>
            <ChiefComplaint>
              <xsl:value-of select="../PatientDemographics/ChiefComplaint" />
            </ChiefComplaint>
          </XCSExcelRow>
        </xsl:for-each>
      </XCSExcelSheet>
    </XCSExcelBook>
  </xsl:template>
</xsl:stylesheet>

