<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:param name="txtInterfaceType"/>
	<xsl:param name="txtFacilityCode"/>
	<xsl:template match="/XCSData">
		<XCSExcelBook>
			<XCSExcelSheet name="tblCDMProcNotFound">
				<XCSExcelRow>
					<CDM>CDM</CDM>
					<CPT>CPT</CPT>
					<Department>Department</Department>
					<Description>Description</Description>
					<Interface_Type>Interface_Type</Interface_Type>
					<Facility_Code>Facility_Code</Facility_Code>
				</XCSExcelRow>
				<!-- <xsl:for-each-group select="Import/Group/Charge[(../PatientDemographics/admAcctNum = radAcctNum and ../PatientDemographics/admLocation != 'F.RLAB' and ../PatientDemographics/admLocation != 'F.LAB')]" group-by="concat(radExamBillingCode,radExamCPT,radExamDept,examdesc)"> -->
				<xsl:for-each-group select="Import/Group/Charge[(../PatientDemographics/admAcctNum = radAcctNum and ../PatientDemographics/admLocation != 'F.RLAB' and ../PatientDemographics/admLocation != 'F.LAB') or ((../PatientDemographics/admAcctNum = radAcctNum and ../PatientDemographics/admLocation = 'F.RLAB' and string-length(../PatientDemographics/Filler2) = 0) or (../PatientDemographics/admAcctNum = radAcctNum and ../PatientDemographics/admLocation = 'F.LAB' and count(/XCSData/query_results/TBLIRL279_STRIPLOCATIONS/TBLIRL279_STRIPLOCATIONS[lower-case(LOCATION) = lower-case(../PatientDemographics/Filler2)]) = 0))]" group-by="concat(radExamBillingCode,radExamCPT,radExamDept,examdesc)">
				<xsl:sort select="radExamBillingCode"/>
					<xsl:for-each select="(current-group())[1]">
						<xsl:sort select="radExamBillingCode"/>
						<xsl:variable name="CDM" select="radExamBillingCode"/>
						<xsl:if test="count(/XCSData/query_results/CDMLIST/CDMLIST[lower-case(CDM) = lower-case($CDM)]) = 0">
							<XCSExcelRow>
								<CDM>
									<xsl:value-of select="radExamBillingCode"/>
								</CDM>
								<CPT>
									<xsl:value-of select="radExamCPT"/>
								</CPT>
								<Department>
									<xsl:value-of select="radExamDept"/>
								</Department>
								<Description>
									<xsl:value-of select="examdesc"/>
								</Description>
								<Interface_Type>WAL</Interface_Type>
								<Facility_Code>NM</Facility_Code>
							</XCSExcelRow>
						</xsl:if>
					</xsl:for-each>
				</xsl:for-each-group>
			</XCSExcelSheet>
		</XCSExcelBook>
	</xsl:template>
</xsl:stylesheet>
