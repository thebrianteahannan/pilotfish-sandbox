<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.1">
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<!--Filter flagged, flab, and frlab charges-->
	<xsl:template match="Charge">
		<xsl:variable name="radAcctNum" select="radAcctNum"/>
		<xsl:variable name="flaggedCount" select="count(/XCSData/query_results/FLAGGED_ACCOUNTS/FLAGGED_ACCOUNT[admAcctNum = $radAcctNum])"/>
		<xsl:variable name="flabCount" select="count(/XCSData/query_results/FLAB_ACCOUNTS/FLAB_ACCOUNT[admAcctNum = $radAcctNum])"/>
		<xsl:variable name="frlabCount" select="count(/XCSData/query_results/FRLAB_ACCOUNTS/FRLAB_ACCOUNT[admAcctNum = $radAcctNum])"/>
		<xsl:if test="$flaggedCount = 0 and $flabCount = 0 and $frlabCount = 0">
			<xsl:copy>
				<xsl:apply-templates select="@*|node()"/>
			</xsl:copy>
		</xsl:if>
	</xsl:template>
	<!--Filter flagged, flab, and frlab patient demographics-->
	<xsl:template match="PatientDemographics">
		<xsl:variable name="admAcctNum" select="admAcctNum"/>
		<xsl:variable name="flaggedCount" select="count(/XCSData/query_results/FLAGGED_ACCOUNTS/FLAGGED_ACCOUNT[admAcctNum = $admAcctNum])"/>
		<xsl:variable name="flabCount" select="count(/XCSData/query_results/FLAB_ACCOUNTS/FLAB_ACCOUNT[admAcctNum = $admAcctNum])"/>
		<xsl:variable name="frlabCount" select="count(/XCSData/query_results/FRLAB_ACCOUNTS/FRLAB_ACCOUNT[admAcctNum = $admAcctNum])"/>
		<xsl:if test="$flaggedCount = 0 and $flabCount = 0 and $frlabCount = 0">
			<xsl:copy>
				<xsl:apply-templates select="@*|node()"/>
			</xsl:copy>
		</xsl:if>
	</xsl:template>
	<!--Filter TBLIRL279_STRIPLOCATIONS-->
	<xsl:template match="Group[not(PatientDemographics/admLocation = 'F.LAB' or PatientDemographics/admLocation = 'F.RLAB')]">
		<xsl:copy>
			<xsl:attribute name="stripped">false</xsl:attribute>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="Group[PatientDemographics/admLocation = 'F.LAB' or PatientDemographics/admLocation = 'F.RLAB']">
		<xsl:variable name="location1" select="PatientDemographics/admLocation"/>
		<xsl:variable name="location2" select="PatientDemographics/Filler2"/>
		<xsl:variable name="count" select="count(/XCSData/query_results/TBLIRL279_STRIPLOCATIONS/TBLIRL279_STRIPLOCATIONS[($location1 = 'F.LAB' and string-length($location1) != 0 and string-length($location2) != 0 and LOCATION = $location1 and LOCATION2 = $location2) or ($location1 = 'F.RLAB' and string-length($location1) != 0 and string-length($location2) != 0 and LOCATION = $location1)])"/>
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$count != 0">
					<xsl:attribute name="stripped">true</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="stripped">false</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<!--Update charge rad-->
	<xsl:template match="Charge[radCRDBIndicator = '1']/radNumOfTimes">
		<radNumOfTimes>
			<xsl:value-of select="number(.) * -1"/>
		</radNumOfTimes>
	</xsl:template>
</xsl:stylesheet>
