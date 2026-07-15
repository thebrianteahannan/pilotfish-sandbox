<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:param name="txtInterfaceType"/>
	<xsl:param name="txtFacilityCode"/>
	<xsl:template match="/XCSData">
		<XCSExcelBook>
			<XCSExcelSheet name="Export_tblDG1_Order">
				<XCSExcelRow>
					<AccountNumber>AccountNumber</AccountNumber>
					<Diag_Code>Diag_Code</Diag_Code>
				</XCSExcelRow>
				<!-- <xsl:for-each-group select="Import/Group[@stripped = 'false']/DiagnosisCodes/Diag1" group-by="concat(../../PatientDemographics/admAcctNum, .)"> -->
				<xsl:for-each-group select="Import/Group[@stripped = 'false']/DiagnosisCodes/Diag1 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag2 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag3 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag4 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag5 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag6 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag7 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag8 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag9 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag10 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag11 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag12" group-by="concat(../../PatientDemographics/admAcctNum, .)">
				<!-- <xsl:for-each select="Import/Group[@stripped = 'false']/DiagnosisCodes/Diag1 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag2 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag3 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag4 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag5 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag6 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag7 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag8 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag9 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag10 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag11 | Import/Group[@stripped = 'false']/DiagnosisCodes/Diag12"> -->
					<xsl:sort select="../../PatientDemographics/admAcctNum"/>
					<!-- <xsl:if test="../../PatientDemographics/admLocation != 'F.RLAB' and ../../PatientDemographics/admLocation != 'F.LAB'"> -->
						<XCSExcelRow>
							<AccountNumber>
								<xsl:value-of select="../../PatientDemographics/admAcctNum"/>
							</AccountNumber>
							<Diag_Code>
								<xsl:value-of select="."/>
							</Diag_Code>
						</XCSExcelRow>
					<!-- </xsl:if> -->
				</xsl:for-each-group>
			</XCSExcelSheet>
		</XCSExcelBook>
	</xsl:template>
</xsl:stylesheet>
