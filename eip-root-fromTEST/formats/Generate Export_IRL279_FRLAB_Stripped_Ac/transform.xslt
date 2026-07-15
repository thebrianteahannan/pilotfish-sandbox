<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:param name="txtInterfaceType"/>
	<xsl:param name="txtFacilityCode"/>
	<xsl:template match="/XCSData">
		<xsl:variable name="stripLocations" select="query_results/TBLIRL279_STRIPLOCATIONS/TBLIRL279_STRIPLOCATIONS"/>
		<XCSExcelBook>
			<XCSExcelSheet name="Export_IRL279_FLAB_Stripped_Acc">
				<XCSExcelRow>
					<admAcctNum>admAcctNum</admAcctNum>
					<admName>admName</admName>
					<admLocation>admLocation</admLocation>
					<Filler2>Filler2</Filler2>
				</XCSExcelRow>
				<xsl:for-each select="Import/Group[@stripped = 'true']/PatientDemographics[admLocation = 'F.RLAB']">
					<xsl:variable name="admLocation" select="admLocation"/>
					<xsl:variable name="Filler2" select="Filler2"/>
					<xsl:if test="count($stripLocations[LOCATION = $admLocation and ((LOCATION2 = $Filler2) or (string-length(LOCATION2) = 0))]) != 0">
						<XCSExcelRow>
							<admAcctNum>
								<xsl:value-of select="admAcctNum"/>
							</admAcctNum>
							<admName>
								<xsl:value-of select="../PatientDemographics/admname"/>
							</admName>
							<admLocation>
								<xsl:value-of select="admLocation"/>
							</admLocation>
							<Filler2>
								<xsl:value-of select="Filler2"/>
							</Filler2>
						</XCSExcelRow>
					</xsl:if>
				</xsl:for-each>
			</XCSExcelSheet>
		</XCSExcelBook>
	</xsl:template>
</xsl:stylesheet>
