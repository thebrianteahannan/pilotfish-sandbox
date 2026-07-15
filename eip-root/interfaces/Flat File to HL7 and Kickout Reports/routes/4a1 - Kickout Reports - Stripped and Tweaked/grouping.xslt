<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:template match="/XCSData">
		<XCSData>
			<query_results>
				<xsl:for-each-group select="query_results/LOCATIONS/*" group-by="local-name(.)">
					<xsl:element name="{local-name(.)}">
						<xsl:copy-of select="current-group()"/>
					</xsl:element>
				</xsl:for-each-group>
			</query_results>
			<xsl:copy-of select="xml/Import" />
			<!--<Import>
				<xsl:for-each select="xml/Import">
				<xsl:variable name="PatientDemographics" select="PatientDemographics" />
				<xsl:variable name="Guarantor" select="Guarantor" />
				<xsl:variable name="Insurance1" select="Insurance1" />
				<xsl:variable name="Insurance2" select="Insurance2" />
				<xsl:variable name="Insurance3" select="Insurance3" />
				<xsl:variable name="DiagnosisCodes" select="DiagnosisCodes" />
				<xsl:variable name="Charge" select="Charge" />
				<xsl:for-each-group select="$PatientDemographics" group-by="admAcctNum">
					<xsl:sort select="admAcctNum" />
					<xsl:variable name="groupingKey" select="admAcctNum"/>
					<Group>
						<xsl:copy-of select="(current-group())[1]"/>
						<xsl:copy-of select="($Guarantor[admAcctNum = $groupingKey])[1]"/>
						<xsl:copy-of select="($Insurance1[admAcctNum = $groupingKey])[1]"/>
						<xsl:copy-of select="($Insurance2[admAcctNum = $groupingKey])[1]"/>
						<xsl:copy-of select="($Insurance3[admAcctNum = $groupingKey])[1]"/>
						<!{1}**Deduplicate DiagnosisCodes based on Diag1, Diag2, etc**{1}>
						<xsl:for-each-group select="$DiagnosisCodes[radAcctNum = $groupingKey]" group-by="Diag0,Diag1,Diag2,Diag1CodeSet">
							<xsl:copy-of select="(current-group())[1]"/>
						</xsl:for-each-group>
						<!{1}**Deduplicate Charges based on radExamBillingCode,radExamServDate,radExamCPT,radNumOfTimes,radExamPerformingPhyMne **{1}>
						<xsl:for-each-group select="$Charge[radAcctNum = $groupingKey]" group-by="radExamBillingCode,radExamServDate,radExamCPT,radNumOfTimes,radExamPerformingPhyMne">
							<xsl:copy-of select="(current-group())[1]"/>
						</xsl:for-each-group>
						<!{1}**<xsl:copy-of select="/XCSData/xml/Import/*[local-name() != 'Guarantor' and local-name() != 'PatientDemographics' and admAcctNum = $groupingKey or radAcctNum = $groupingKey]"/>**{1}>
					</Group>
				</xsl:for-each-group>
				</xsl:for-each>
			</Import>-->
		</XCSData>
	</xsl:template>
</xsl:stylesheet>
