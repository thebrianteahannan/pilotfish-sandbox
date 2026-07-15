<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:param name="txtPartition"/>
	<xsl:param name="txtInterfaceType"/>
	<xsl:param name="txtFacilityCode"/>
	<xsl:template match="/XCSData">
		<XCSExcelBook>
			<XCSExcelSheet name="Export_PerfDr_WAL_Report">
				<XCSExcelRow>
					<Partition>Partition</Partition>
					<Interface_Type>Interface_Type</Interface_Type>
					<Location>Location</Location>
					<Account_Number>Account_Number</Account_Number>
					<Patient_Name>Patient_Name</Patient_Name>
					<DOS>DOS</DOS>
					<Units>Units</Units>
					<Performing_Dr_Mnemonic>Performing_Dr_Mnemonic</Performing_Dr_Mnemonic>
					<CDM>CDM</CDM>
					<admInsMne>admInsMne</admInsMne>
					<admInsName>admInsName</admInsName>
				</XCSExcelRow>
				<xsl:for-each-group select="Import/Group/Charge" group-by="concat(radExamServDate,radExamPerformingPhyMne,radExamCPT,radExamBillingCode,radAcctNum)">
					<xsl:sort select="radExamBillingCode"/>
					<xsl:variable name="sumNum" select="sum(current-group()/radNumOfTimes)"/>
					<xsl:if test="number($sumNum) &gt; 0">
						<xsl:for-each select="(current-group())[1]">
							<xsl:sort select="radExamBillingCode"/>
							<xsl:variable name="CDM" select="radExamBillingCode"/>
							<xsl:if test="count(/XCSData/query_results/CDMLIST2/CDMLIST2[lower-case(CDM) = lower-case($CDM)]) != 0">
								<XCSExcelRow>
									<Partition>
										IRL
									</Partition>
									<Interface_Type>
										WAL
									</Interface_Type>
									<Location>
										<xsl:value-of select="../PatientDemographics/admLocation"/>
									</Location>
									<Account_Number>
										<xsl:value-of select="radAcctNum"/>
									</Account_Number>
									<Patient_Name>
										<xsl:value-of select="radPatientName"/>
									</Patient_Name>
									<DOS>
										<xsl:value-of select="radExamServDate"/>
									</DOS>
									<Units>
										<xsl:value-of select="$sumNum"/>
										<!-- <xsl:value-of select="radNumOfTimes"/> -->
									</Units>
									<Performing_Dr_Mnemonic>
										<xsl:value-of select="radExamPerformingPhyMne"/>
									</Performing_Dr_Mnemonic>
									<CDM>
										<xsl:value-of select="radExamBillingCode"/>
									</CDM>
									<admInsMne>
										<xsl:value-of select="../Insurance1/adminsmne"/>
									</admInsMne>
									<admInsName>
										<xsl:value-of select="../Insurance1/admInsName"/>
									</admInsName>
								</XCSExcelRow>
							</xsl:if>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each-group>
			</XCSExcelSheet>
		</XCSExcelBook>
	</xsl:template>
</xsl:stylesheet>
